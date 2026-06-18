param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

Assert-Contains "操作系统\07_完整工作流\需求接收.md" "确认改动/待审批|确认改动\\待审批" "需求接收大改先走 PROP"
Assert-Contains "操作系统\07_完整工作流\需求接收.md" "审批与归档\.md" "需求接收审批路由"
Assert-NotContains "操作系统\07_完整工作流\需求接收.md" "Dev playbook|Dev 帽子" "需求接收旧 Dev 主语"

Assert-NotContains "操作系统\07_完整工作流\decision-checkpoint-判定细则.md" "决策 PM / 沉淀 PM可由主会话承载|决策 PM / 沉淀 PM 可由主会话承载" "Q6 口头主会话承载"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint-判定细则.md" "除项目 PM 主会话外.*真实 agent" "Q7 真实 agent 默认"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint-判定细则.md" "子agent调度机制\.md" "Q7 单源禁并行清单"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint.md" "三类行为铁律\.md" "decision-checkpoint C 类真源"
Assert-Contains "操作系统\07_完整工作流\decision-checkpoint-附录.md" "当时旧 5 PM 路径案例；现行按 9 PM 路径白名单" "decision-checkpoint 附录旧 5 PM 边界"

Assert-NotContains "操作系统\07_完整工作流\审批与归档.md" "任何 AI" "审批归档工具主语"
Assert-Contains "操作系统\07_完整工作流\审批与归档.md" "Q1-Q7" "审批归档先跑 decision-checkpoint"
Assert-Contains "操作系统\07_完整工作流\审批与归档.md" "产品 PM.*PRD" "审批归档产品 PM 路由"
Assert-Contains "操作系统\07_完整工作流\审批与归档.md" "操作系统 PM.*ADR" "审批归档操作系统 PM 路由"

Assert-Contains "操作系统\07_完整工作流\发布流程.md" "release keystore[\s\S]{0,120}zlbdh 手动" "release keystore 手动边界"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "AI 不处理密码" "release keystore AI 禁区"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "已存在.*停手.*不覆盖历史 APK" "APK 归档不覆盖"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "git流程\.md.*B 类 6 条件" "dev 发布 push 收口"
Assert-Contains "操作系统\07_完整工作流\发布流程.md" "package\.json.*Android 版本.*APK 命名.*交接卡版本" "release 版本一致性"

Assert-Contains "操作系统\07_完整工作流\git流程.md" "git branch --show-current" "git 示例 main preflight"
Assert-Contains "操作系统\07_完整工作流\git流程.md" "git remote get-url origin" "git 示例 remote preflight"
Assert-Contains "操作系统\07_完整工作流\git流程.md" "contextual 授权" "git 示例授权 preflight"
Assert-NotContains "操作系统\07_完整工作流\git流程.md" "commit-msg\.tmp|WriteAllText|utf8NoBom|utf8NoBOM" "git 示例旧临时文件写法"

Assert-Contains "操作系统\07_完整工作流\实施循环-DoD.md" '完整卡 \+ chat ①-⑦ \+ `状态\.md L<line>`' "L1/L2 交接闭环"
Assert-Contains "操作系统\07_完整工作流\实施循环-DoD.md" "失败回退[\s\S]{0,240}交接区/待接手" "失败回退跨 session 交接"

Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP.md" "scheduled runner：索引、PM 轨迹、交接区、framework health、RETRO 节奏" "scheduled 真实范围"
Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP.md" "PreToolUse.*ask.*PostToolUse.*systemMessage" "Claude ask 边界"
Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP.md" "疑似实施收尾[\s\S]{0,80}只读审计 / 未改文件有豁免" "Stop 触发豁免"
Assert-Contains "操作系统\07_完整工作流\hooks-运行SOP-附录.md" "startup\\\|resume\\\|clear\\\|compact" "Codex SessionStart matcher"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 07_完整工作流语义锚点对齐" -ForegroundColor Green
exit 0
