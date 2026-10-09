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
    @{ Path = "能力资产/skills/状态推断.md"; Pattern = 'ls -t apk/\*\.apk|Sprint-1需求清单\.md'; Label = "State-inference entry still uses obsolete APK paths or hard-coded Sprint-1 values" },
    @{ Path = "能力资产/skills/出APK.md"; Pattern = '(?m)^\s*git add \.|^\s*git commit -m "v\d'; Label = "APK skill still contains directly copyable bare git add/commit commands" },
    @{ Path = "能力资产/skills/状态推断-推断项.md"; Pattern = 'Sprint-1需求清单\.md'; Label = "Basic state-inference items still hard-code the Sprint-1 requirements list" },
    @{ Path = "能力资产/skills/状态推断-跨session监控.md"; Pattern = 'ls -t apk/\*\.apk|Sprint-1需求清单\.md'; Label = "Full state-inference procedure still uses obsolete APK paths or hard-coded Sprint-1 values" },
    @{ Path = "能力资产/skills/状态推断-跨session监控-附录.md"; Pattern = 'ls -t apk/\*\.apk|Sprint-1需求清单\.md'; Label = "Cross-session state-inference appendix still uses obsolete APK paths or hard-coded Sprint-1 values" },
    @{ Path = "能力资产/skills/状态推断-跨session监控-附录.md"; Pattern = '\[ "\$(?:卡数|pending_count)" -ge 3 \]'; Label = "Cross-session state-inference appendix still misclassifies 3 pending handoffs as a backlog" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = 'Sprint-1需求清单\.md'; Label = "Health checks 5-6 still hard-code the Sprint-1 requirements list" },
    @{ Path = "能力资产/skills/项目体检-检查项.md"; Pattern = '(?:检查项|Check) [0-9] / 6'; Label = "Health checks 1-4 still use the obsolete denominator of 6 checks" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = '(?:检查项|Check) [0-9] / 6'; Label = "Health checks 5-6 still use the obsolete denominator of 6 checks" },
    @{ Path = "能力资产/skills/项目体检-附录.md"; Pattern = '(?s)【8 / 9】状态\.md 新鲜度(?:(?!【9 / 9】Mount 缓存陷阱提醒).)*—— 整体|(?s)\[8 / 9\] 状态\.md freshness(?:(?!\[9 / 9\] Mount-cache warning).)*Overall:'; Label = "Health-check appendix report template lacks check 9 for Mount-cache warnings" },
    @{ Path = "能力资产/skills/项目体检-附录.md"; Pattern = 'PROP:\s*0/0/4/0/0\s+ADR:\s*7\s+RETRO:\s*2'; Label = "Health-check appendix still contains obsolete PROP/ADR/RETRO example counts" },
    @{ Path = "能力资产/skills/项目体检-检查项-1-4-附录.md"; Pattern = 'find __CZXT_APP_REPO_DIR_REGEX__/src 操作系统 能力资产 -type f[^\r\n]+-exec wc -c'; Label = "Health checks 1-4 appendix P4b broad scan does not exclude historical/status archives" },
    @{ Path = "能力资产/skills/项目体检-检查项-1-4-附录.md"; Pattern = '(?s)find __CZXT_APP_REPO_DIR_REGEX__/src 操作系统 能力资产 -type f(?:(?!\*\.ps1).)*xargs -r wc -c'; Label = "Health checks 1-4 appendix P4b broad scan does not cover ps1/json tool files" },
    @{ Path = "能力资产/skills/项目体检-检查项-1-4-附录.md"; Pattern = 'lines=\$\(echo -n "\$out" \| wc -l\)'; Label = "Health checks 1-4 appendix still detects obsolete paths with echo -n + wc -l, which may miss a single remaining line" },
    @{ Path = "能力资产/rules/已知技术约束-附录.md"; Pattern = '(?m)^- 6-9KB：优先脚本写入或拆分。$|(?m)^- >9KB：优先拆分；|(?im)^- 6-9KB: prefer scripted writes or splitting\.$|(?im)^- >9KB: prefer splitting;'; Label = "Known technical constraints appendix still presents obsolete 6-9KB/9KB thresholds as current guidance" },
    @{ Path = "操作系统/07_完整工作流/需求接收.md"; Pattern = 'AskUserQuestion|TaskCreate'; Label = "Requirements-intake workflow still references obsolete adapter tool names" },
    @{ Path = "操作系统/02_智能体/产品PM-需求拆解者.md"; Pattern = 'AskUserQuestion'; Label = "Product PM playbook still references obsolete adapter tool names" },
    @{ Path = "操作系统/02_智能体/PM-产品经理.md"; Pattern = 'AskUserQuestion|TaskCreate'; Label = "Product PM historical archive still references obsolete adapter tool names" },
    @{ Path = "能力资产/rules/安全与隐私.md"; Pattern = 'AskUserQuestion'; Label = "Security/privacy rules still reference an obsolete adapter confirmation-tool name" },
    @{ Path = "能力资产/rules/F编号规则.md"; Pattern = '现有占用清单（截至 2026-05-09）|grep -ohE "F-\[A-Z0-9-\]\+" Docs/1-需求文档/Sprint-\*需求清单\.md Docs/1-需求文档/需求历史\.md'; Label = "F-number rules still use an obsolete static allocation list or narrowly scoped query" },
    @{ Path = "能力资产/skills/跑测试.md"; Pattern = '28 passed|2229 modules transformed'; Label = "Run-tests skill still contains obsolete test/build example counts" },
    @{ Path = "能力资产/skills/出APK.md"; Pattern = '28 测试|23 语法|\b28 tests\b|\b23 syntax checks\b'; Label = "APK skill standard response still contains obsolete test counts" },
    @{ Path = "能力资产/skills/出APK.md"; Pattern = 'release APK（v3\.0）|release APK \(v3\.0\)|(?m)^\s*git (tag -a|push origin) vX\.Y\.Z'; Label = "APK skill uses obsolete release/tag wording" },
    @{ Path = "能力资产/skills/README.md"; Pattern = '项目体检\.md\)\s*\|\s*(?:9 项检查|9 checks\b)'; Label = "skills README uses the obsolete 9-check health-check scope" },
    @{ Path = "能力资产/skills/README.md"; Pattern = '\| (?:打 APK|Build an APK) \|[^\r\n]*build-apk\.bat'; Label = "skills README still recommends build-apk.bat as the APK entry point" }
)

$appLiteral = [regex]::Escape('{{APP_REPO_DIR}}')
foreach ($check in $checks) {
  $check.Pattern = $check.Pattern.Replace('__CZXT_APP_REPO_DIR_REGEX__', $appLiteral)
}

$hits = @()
$hits += Test-P4mRequiredFiles -Root $Root -Files $requiredFreshnessFiles
$hits += Invoke-P4mPatternChecks -Root $Root -Checks $checks
Complete-P4mScan -Hits $hits -FailureTitle "skills contain obsolete copyable commands" -SuccessMessage "skills contain no known high-risk obsolete commands, paths, or numeric examples"
