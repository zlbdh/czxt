param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4m-command-scan.ps1")
$requiredFreshnessFiles = @(
    "能力资产/skills/状态推断.md",
    "能力资产/skills/状态推断-推断项.md",
    "能力资产/skills/状态推断-跨session监控.md",
    "能力资产/skills/状态推断-跨session监控-附录.md"
)

$checks = @(
    @{ Path = "能力资产/skills/状态推断.md"; Pattern = 'ls -t apk/\*\.apk|Sprint-1需求清单\.md'; Label = "状态推断入口仍使用旧 APK 路径或 Sprint-1 硬编码" },
    @{ Path = "能力资产/skills/出APK.md"; Pattern = '(?m)^\s*git add \.|^\s*git commit -m "v\d'; Label = "出APK skill 仍含可直接复制的裸 git add/commit" },
    @{ Path = "能力资产/skills/状态推断-推断项.md"; Pattern = 'Sprint-1需求清单\.md'; Label = "状态推断基础项仍硬编码 Sprint-1 需求清单" },
    @{ Path = "能力资产/skills/状态推断-跨session监控.md"; Pattern = 'ls -t apk/\*\.apk|Sprint-1需求清单\.md'; Label = "状态推断完整跑法仍使用旧 APK 路径或 Sprint-1 硬编码" },
    @{ Path = "能力资产/skills/状态推断-跨session监控-附录.md"; Pattern = 'ls -t apk/\*\.apk|Sprint-1需求清单\.md'; Label = "状态推断跨 session 附录仍使用旧 APK 路径或 Sprint-1 硬编码" },
    @{ Path = "能力资产/skills/状态推断-跨session监控-附录.md"; Pattern = '\[ "\$卡数" -ge 3 \]'; Label = "状态推断跨 session 附录仍把 3 张待接手误判为积压" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = 'Sprint-1需求清单\.md'; Label = "项目体检 5-6 仍硬编码 Sprint-1 需求清单" },
    @{ Path = "能力资产/skills/项目体检-检查项.md"; Pattern = '检查项 [0-9] / 6'; Label = "项目体检 1-4 仍使用旧 6 项分母" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = '检查项 [0-9] / 6'; Label = "项目体检 5-6 仍使用旧 6 项分母" },
    @{ Path = "能力资产/skills/项目体检-附录.md"; Pattern = '(?s)【8 / 9】状态\.md 新鲜度(?:(?!【9 / 9】Mount 缓存陷阱提醒).)*—— 整体'; Label = "项目体检附录报告模板缺第 9 项 Mount 缓存提醒" },
    @{ Path = "能力资产/skills/项目体检-附录.md"; Pattern = 'PROP:\s*0/0/4/0/0\s+ADR:\s*7\s+RETRO:\s*2'; Label = "项目体检附录仍含旧 PROP/ADR/RETRO 样例计数" },
    @{ Path = "能力资产/skills/项目体检-检查项-1-4-附录.md"; Pattern = 'find {{APP_REPO_DIR}}/src 操作系统 能力资产 -type f[^\r\n]+-exec wc -c'; Label = "项目体检 1-4 附录 P4b 粗扫命令未排除历史归档/状态归档" },
    @{ Path = "能力资产/skills/项目体检-检查项-1-4-附录.md"; Pattern = '(?s)find {{APP_REPO_DIR}}/src 操作系统 能力资产 -type f(?:(?!\*\.ps1).)*xargs -r wc -c'; Label = "项目体检 1-4 附录 P4b 粗扫命令未覆盖 ps1/json 工具文件" },
    @{ Path = "能力资产/skills/项目体检-检查项-1-4-附录.md"; Pattern = 'lines=\$\(echo -n "\$out" \| wc -l\)'; Label = "项目体检 1-4 附录旧路径判断仍用 echo -n + wc -l，可能漏报单行残留" },
    @{ Path = "能力资产/rules/已知技术约束-附录.md"; Pattern = '(?m)^- 6-9KB：优先脚本写入或拆分。$|(?m)^- >9KB：优先拆分；'; Label = "已知技术约束附录仍把旧 6-9KB/9KB 粗阈值写成现行建议" },
    @{ Path = "操作系统/07_完整工作流/需求接收.md"; Pattern = 'AskUserQuestion|TaskCreate'; Label = "需求接收流程仍引用旧载体工具名" },
    @{ Path = "操作系统/02_智能体/产品PM-需求拆解者.md"; Pattern = 'AskUserQuestion'; Label = "产品 PM playbook 仍引用旧载体工具名" },
    @{ Path = "操作系统/02_智能体/PM-产品经理.md"; Pattern = 'AskUserQuestion|TaskCreate'; Label = "产品 PM 历史档案仍引用旧载体工具名" },
    @{ Path = "能力资产/rules/安全与隐私.md"; Pattern = 'AskUserQuestion'; Label = "安全隐私规则仍引用旧载体确认工具名" },
    @{ Path = "能力资产/rules/F编号规则.md"; Pattern = '现有占用清单（截至 2026-05-09）|grep -ohE "F-\[A-Z0-9-\]\+" Docs/1-需求文档/Sprint-\*需求清单\.md Docs/1-需求文档/需求历史\.md'; Label = "F编号规则仍使用旧静态占用清单或窄范围查询命令" },
    @{ Path = "能力资产/skills/跑测试.md"; Pattern = '28 passed|2229 modules transformed'; Label = "跑测试 skill 仍含旧测试/构建数字样例" },
    @{ Path = "能力资产/skills/出APK.md"; Pattern = '28 测试|23 语法'; Label = "出APK skill 标准回复仍含旧测试数字" },
    @{ Path = "能力资产/skills/出APK.md"; Pattern = 'release APK（v3\.0）|(?m)^\s*git (tag -a|push origin) vX\.Y\.Z'; Label = "出APK skill release/tag 旧口径" },
    @{ Path = "能力资产/skills/README.md"; Pattern = '项目体检\.md\)\s*\|\s*9 项检查'; Label = "skills README 项目体检旧 9 项口径" },
    @{ Path = "能力资产/skills/README.md"; Pattern = '\| 打 APK \|[^\r\n]*build-apk\.bat'; Label = "skills README 仍把 build-apk.bat 作为打 APK 推荐入口" }
)

$hits = @()
$hits += Test-P4mRequiredFiles -Root $Root -Files $requiredFreshnessFiles
$hits += Invoke-P4mPatternChecks -Root $Root -Checks $checks
Complete-P4mScan -Hits $hits -FailureTitle "skills 可复制命令旧口径" -SuccessMessage "skills 未发现已知高风险旧命令/旧路径/旧数字样例"
