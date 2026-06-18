param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4m-command-scan.ps1")

$checks = @(
    @{ Path = "能力资产/rules/改动分级-扩展规则.md"; Pattern = '拒绝 → 删除|合并到主分支 \+ 打 git tag'; Label = "改动分级仍诱导删除/默认合并打 tag" },
    @{ Path = "能力资产/rules/改动分级.md"; Pattern = '\|\s*\*\*L1\*\*[^\r\n]*\|\s*直接改 \+ 一行 CHANGELOG\s*\|\s*咪咪自己\s*\||L2\*\*[^\r\n]+咪咪自己（提交后|PM 写 PRD → Dev 写代码 → QA|咪咪自己'; Label = "改动分级仍绕过 Q1-Q7/敏感门禁或使用旧 Dev/QA 主语" },
    @{ Path = "能力资产/rules/改动分级-扩展规则.md"; Pattern = 'AI 直接做|每完成 N 个 L3\+'; Label = "改动分级扩展仍含旧自动/RETRO 公式口径" },
    @{ Path = "能力资产/rules/已知技术约束.md"; Pattern = 'APK 只能在 zlbdh 的 Windows'; Label = "已知技术约束仍把 APK 出包绑定为 zlbdh Windows 单一路径" },
    @{ Path = "能力资产/rules/安全与隐私.md"; Pattern = 'mcp__cowork__allow_cowork_file_delete'; Label = "安全隐私仍引用旧 Cowork 删除授权工具名" },
    @{ Path = "能力资产/rules/git-commit-编码规范.md"; Pattern = 'utf8NoBOM|AsByteStream|Codex / Cowork PM'; Label = "git commit 编码规范仍含 PS7 专属参数或旧工具 PM 主语" },
    @{ Path = "能力资产/rules/git-commit-编码规范.md"; Pattern = 'git push origin <branch>'; Label = "git commit 编码规范仍含可复制裸 push 示例" },
    @{ Path = "能力资产/rules/codex-push后防御.md"; Pattern = '\$X{2}DW|Edit / Write / mv|Edit / Write 操作'; Label = "Codex push 防御仍漏 apply_patch 或使用未定义路径变量" },
    @{ Path = "能力资产/rules/codex-push后防御.md"; Pattern = '几乎必现'; Label = "Codex push 防御仍把历史高频写成当前必现事实" },
    @{ Path = "能力资产/rules/写PRD.md"; Pattern = 'F-\d{3}[a-z]\b'; Label = "写 PRD 示例仍使用 F-001a 这类非现行编号" },
    @{ Path = "能力资产/rules/web-api-信源选型.md"; Pattern = '填入 `web-api-信源矩阵\.md` \+ commit msg|关联议题 AT 矩阵」段 \+ commit msg'; Label = "web API 信源选型仍要求非 git 文档改动写 commit msg" },
    @{ Path = "能力资产/rules/写代码.md"; Pattern = 'set(Error|Something)\(`[^`]*e\.message'; Label = "写代码错误提示示例仍把原始错误暴露到 UI" },
    @{ Path = "能力资产/skills/状态推断.md"; Pattern = '新 session 第一个响应前必跑|用户每次回应后，AI 主动更新'; Label = "状态推断仍覆盖 AGENTS 起手或自动写状态.md" },
    @{ Path = "能力资产/skills/状态推断.md"; Pattern = '每次响应必跑'; Label = "状态推断仍要求普通响应每次跑 APK/smoke 推断" },
    @{ Path = "能力资产/skills/状态推断-推断项.md"; Pattern = '每次响应必跑|last_covered=\$\(\(retro_count \* 3\)\)|floor\(已完成 L3\+'; Label = "状态推断推断项仍含旧响应频率或 RETRO 公式" },
    @{ Path = "能力资产/skills/状态推断-跨session监控-附录.md"; Pattern = '(?m)^(最新卡|卡_mtime|最近代码_mtime|卡数|实际|索引)='; Label = "状态推断 Bash fallback 仍含中文变量赋值" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = '待接手数=|Windows/Codex 为 D:\\WGKJ\\{{PROJECT_NAME}}，Cowork'; Label = "项目体检 5-6 仍含不可复制 Bash 变量或误标 Windows/Codex" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = '(?s)检查项 5 / 9：跨 session 同步状态(?:(?!检查项 6 / 9).)*check-handoff-zone\.ps1'; Label = "项目体检检查项 5 仍把 handoff-zone 当作跨 session 对账入口" },
    @{ Path = "能力资产/skills/项目体检-检查项.md"; Pattern = 'floor\(已完成 L3\+ 数 / 3\)'; Label = "项目体检检查项 3 仍用旧 RETRO 固定公式" },
    @{ Path = "能力资产/skills/项目体检-附录.md"; Pattern = '待接手数='; Label = "项目体检附录仍含中文 Bash 变量" }
)

$hits = @(Invoke-P4mPatternChecks -Root $Root -Checks $checks)
Complete-P4mScan -Hits $hits -FailureTitle "rules/skills 可复制性旧口径" -SuccessMessage "rules/skills 可复制命令与起手语义未发现旧口径"
