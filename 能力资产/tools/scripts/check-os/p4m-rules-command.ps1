param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4m-command-scan.ps1")

$checks = @(
    @{ Path = "能力资产/rules/改动分级-扩展规则.md"; Pattern = '拒绝 → 删除|合并到主分支 \+ 打 git tag|(?i:Rejected → delete|merge into the main branch \+ create a git tag)'; Label = "Change classification still encourages deletion or default merge/tag creation" },
    @{ Path = "能力资产/rules/改动分级.md"; Pattern = '\|\s*\*\*L1\*\*[^\r\n]*\|\s*直接改 \+ 一行 CHANGELOG\s*\|\s*咪咪自己\s*\||L2\*\*[^\r\n]+咪咪自己（提交后|PM 写 PRD → Dev 写代码 → QA|咪咪自己|(?i:PM writes the PRD → Dev writes code → QA|Mimi alone)'; Label = "Change classification still bypasses Q1-Q7/sensitive gates or uses obsolete Dev/QA responsibility language" },
    @{ Path = "能力资产/rules/改动分级-扩展规则.md"; Pattern = 'AI 直接做|每完成 N 个 L3\+|(?i:AI acts directly|after every N completed L3\+)'; Label = "Extended change classification still uses obsolete automatic-action or RETRO formulas" },
    @{ Path = "能力资产/rules/已知技术约束.md"; Pattern = 'APK 只能在 zlbdh 的 Windows|(?i:APKs can only be built on zlbdh.s Windows)'; Label = "Technical constraints still restrict APK builds exclusively to zlbdh's Windows machine" },
    @{ Path = "能力资产/rules/安全与隐私.md"; Pattern = 'mcp__cowork__allow_cowork_file_delete'; Label = "Security/privacy rules still refer to an obsolete Cowork deletion-authorization tool" },
    @{ Path = "能力资产/rules/git-commit-编码规范.md"; Pattern = 'utf8NoBOM|AsByteStream|Codex / Cowork PM'; Label = "Git commit encoding rules still use PS7-only parameters or obsolete tool-as-PM language" },
    @{ Path = "能力资产/rules/git-commit-编码规范.md"; Pattern = 'git push origin <branch>'; Label = "Git commit encoding rules still provide an executable push example without preflight checks" },
    @{ Path = "能力资产/rules/codex-push后防御.md"; Pattern = '\$X{2}DW|Edit / Write / mv|Edit / Write 操作|(?i:Edit / Write operations)'; Label = "Codex push safeguards still omit apply_patch or use an undefined path variable" },
    @{ Path = "能力资产/rules/codex-push后防御.md"; Pattern = '几乎必现|(?i:almost certain to occur)'; Label = "Codex push safeguards still present historical frequency as a current certainty" },
    @{ Path = "能力资产/rules/写PRD.md"; Pattern = 'F-\d{3}[a-z]\b'; Label = "PRD examples still use obsolete identifiers such as F-001a" },
    @{ Path = "能力资产/rules/web-api-信源选型.md"; Pattern = '填入 `web-api-信源矩阵\.md` \+ commit msg|关联议题 AT 矩阵」段 \+ commit msg|(?i:fill in `web-api-信源矩阵\.md` \+ commit msg|related issue AT matrix section \+ commit msg)'; Label = "Web API source selection still requires commit messages for nongit document changes" },
    @{ Path = "能力资产/rules/写代码.md"; Pattern = 'set(Error|Something)\(`[^`]*e\.message'; Label = "Coding error-message examples still expose raw errors in the UI" },
    @{ Path = "能力资产/skills/状态推断.md"; Pattern = '新 session 第一个响应前必跑|用户每次回应后，AI 主动更新'; Label = "State inference still overrides AGENTS startup or automatically writes 状态.md" },
    @{ Path = "能力资产/skills/状态推断.md"; Pattern = '每次响应必跑'; Label = "State inference still requires APK/smoke inference for every ordinary response" },
    @{ Path = "能力资产/skills/状态推断-推断项.md"; Pattern = '每次响应必跑|last_covered=\$\(\(retro_count \* 3\)\)|floor\(已完成 L3\+'; Label = "State-inference items still use obsolete response frequency or RETRO formulas" },
    @{ Path = "能力资产/skills/状态推断-跨session监控-附录.md"; Pattern = '(?m)^(最新卡|卡_mtime|最近代码_mtime|卡数|实际|索引)='; Label = "State-inference Bash fallback still assigns Unicode variable names" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = '待接手数=|Windows/Codex 为 D:\\WGKJ\\__CZXT_PROJECT_NAME_REGEX__，Cowork'; Label = "Health checks 5-6 still contain unusable Bash variables or mislabel Windows/Codex" },
    @{ Path = "能力资产/skills/项目体检-检查项-5-6.md"; Pattern = '(?s)检查项 5 / 9：跨 session 同步状态(?:(?!检查项 6 / 9).)*check-handoff-zone\.ps1'; Label = "Health check 5 still uses handoff-zone as the cross-session reconciliation entry" },
    @{ Path = "能力资产/skills/项目体检-检查项.md"; Pattern = 'floor\(已完成 L3\+ 数 / 3\)'; Label = "Health check 3 still uses the obsolete fixed RETRO formula" },
    @{ Path = "能力资产/skills/项目体检-附录.md"; Pattern = '待接手数='; Label = "Health-check appendix still contains Unicode Bash variables" }
)

$projectLiteral = [regex]::Escape('{{PROJECT_NAME}}')
foreach ($check in $checks) {
  $check.Pattern = $check.Pattern.Replace('__CZXT_PROJECT_NAME_REGEX__', $projectLiteral)
}

$hits = @(Invoke-P4mPatternChecks -Root $Root -Checks $checks)
Complete-P4mScan -Hits $hits -FailureTitle "rules/skills 可复制性旧口径" -SuccessMessage "rules/skills 可复制命令与起手语义未发现旧口径"
