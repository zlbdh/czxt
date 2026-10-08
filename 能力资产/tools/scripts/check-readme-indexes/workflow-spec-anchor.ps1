param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

Assert-Contains "操作系统\07_完整工作流\需求接收.md" "确认改动/待审批|确认改动\\待审批" "Major requirements changes begin with PROP"
Assert-Contains "操作系统\07_完整工作流\需求接收.md" "审批与归档\.md" "Requirements approval route"
Assert-NotContains "操作系统\07_完整工作流\需求接收.md" "Dev playbook|Dev 帽子|Dev role" "Obsolete Dev subject in requirements intake"

Assert-NotContains "操作系统\07_完整工作流\decision-checkpoint-判定细则.md" "决策 PM / 沉淀 PM可由主会话承载|决策 PM / 沉淀 PM 可由主会话承载|Decision PM / Knowledge PM may be hosted by the main session" "Q6 verbal claim of main-session execution"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint-判定细则.md" "(?:除项目 PM 主会话外.*真实 agent|Except for the Project PM.s main session, each PM.s actual work defaults to a real agent)" "Q7 real-agent default"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint-判定细则.md" "子agent调度机制\.md" "Q7 single-source no-parallel-write list"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint.md" "三类行为铁律\.md" "Decision-checkpoint Class C authority"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint-附录.md" "(?:当时旧 5 PM 路径案例；现行按 9 PM 路径白名单|then-current five-PM path example\.[\s\S]{0,90}Current work follows the nine-PM path allowlist)" "Decision-checkpoint appendix historical five-PM boundary"

Assert-NotContains "操作系统\07_完整工作流\审批与归档.md" "任何 AI|Any AI" "Approval/archive tool subject"
Assert-Contains "操作系统\07_完整工作流\审批与归档.md" "Q1-Q7" "Approval/archive begins with decision-checkpoint"
Assert-Contains "操作系统\07_完整工作流\审批与归档.md" "产品 PM.*PRD|Product PM.*PRD" "Approval/archive Product PM route"
Assert-Contains "操作系统\07_完整工作流\审批与归档.md" "操作系统 PM.*ADR|Operating System PM.*ADR" "Approval/archive Operating System PM route"

Assert-Contains "操作系统\07_完整工作流\发布流程.md" "(?:release keystore[\s\S]{0,120}zlbdh 手动|release keystore[\s\S]{0,120}zlbdh performs this step manually)" "Release-keystore manual boundary"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "(?:AI 不处理密码|AI must not handle passwords)" "Release-keystore AI restriction"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "(?:已存在.*停手.*不覆盖历史 APK|already exists, stop\. Do not overwrite a historical APK)" "APK archives must not be overwritten"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "(?:git流程\.md.*B 类 6 条件|six Class B conditions in the \[Git flow\]\(git流程\.md\))" "Development release-push completion"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "(?:package\.json.*Android 版本.*APK 命名.*交接卡版本|package\.json.*Android version.*APK name.*handoff card all identify the same version)" "Release version consistency"

Assert-Contains "操作系统\07_完整工作流\git流程.md" "git branch --show-current" "Git example main-branch preflight"
Assert-Contains "操作系统\07_完整工作流\git流程.md" "git remote get-url origin" "Git example remote preflight"
Assert-Contains "操作系统\07_完整工作流\git流程.md" "(?:contextual 授权|Contextual authorization)" "Git example authorization preflight"
Assert-NotContains "操作系统\07_完整工作流\git流程.md" "commit-msg\.tmp|WriteAllText|utf8NoBom|utf8NoBOM" "Obsolete temporary-file syntax in Git examples"

Assert-Contains "操作系统\07_完整工作流\实施循环-DoD.md" '(?:完整卡 \+ chat ①-⑦ \+ `状态\.md L<line>`|full handoff card, chat ①–⑦, and `状态\.md L<line>`)' "L1/L2 handoff completion"
Assert-Contains "操作系统\07_完整工作流\实施循环-DoD.md" "(?:失败回退[\s\S]{0,240}交接区/待接手|Failure fallback[\s\S]{0,450}交接区/待接手)" "Cross-session handoff after failure"

Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP.md" "(?:scheduled runner：索引、PM 轨迹、交接区、framework health、RETRO 节奏|scheduled runner: indexes, PM transitions, handoff area, framework health, and RETRO cadence)" "Actual scheduled scope"
Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP.md" "PreToolUse.*ask.*PostToolUse.*systemMessage" "Claude ask boundary"
Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP.md" "(?:疑似实施收尾[\s\S]{0,80}只读审计 / 未改文件有豁免|only when implementation appears to be closing\. Read-only audits and sessions without file changes are exempt)" "Stop-trigger exemptions"
Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP-附录.md" "startup\\\|resume\\\|clear\\\|compact" "Codex SessionStart matcher"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Full-workflow semantic anchors aligned" -ForegroundColor Green
exit 0
