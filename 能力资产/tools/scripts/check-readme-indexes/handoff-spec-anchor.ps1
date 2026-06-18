param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common

Assert-Contains "操作系统\03_交接\README.md" '完整文件基础 ①-⑥ \+ 可选文件 ⑦ \+ chat 简版 ①-⑦' "03 README 段数口径"
Assert-Contains "操作系统\03_交接\README.md" 'DONE / BLOCKED / HANDOFF / RISK / OBSERVE' "03 README Status 五态"

Assert-Contains "操作系统\03_交接\交接卡格式.md" 'frontmatter `status` 必须先是 `pending`' "交接模板 frontmatter pending"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '(?s)```markdown\s*---\s*status: pending\s*from:' "交接模板 YAML 示例"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '待接手 `pending`，接收后 `accepted`' "frontmatter status 流转态"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '正文 `Status:`=交付警戒态' "正文 Status 警戒态"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '⑥ 必须用纯文本路径指向 `交接区/待接手/`' "chat ⑥ 默认待接手路径"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '接收归档收尾且 `交接区/待接手/` 为空时，可指向 `交接区/已接手/` 下 `status: accepted`' "chat ⑥ 已接手例外"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '不要写 Markdown 链接' "chat ⑥ 禁 Markdown 链接"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '当前主会话按 PM 帽子确认后落笔' "交接落笔主体"
Assert-NotContains "操作系统\03_交接\交接卡格式.md" '必须由项目 PM 主会话' "交接移动主体过窄旧口径"

Assert-Contains "操作系统\03_交接\交接卡格式-附录.md" '不会自动把卡从 `待接手/` 移到 `已接手/`' "附录不自动移动"
Assert-Contains "操作系统\03_交接\交接卡格式-附录.md" '不会替 PM 追加轨迹' "附录不自动追加轨迹"

Assert-Contains "交接区\README.md" '⑥ 追加问答（标题必留，内容可写“暂无”）' "交接区 README ⑥ 标题必留"
Assert-Contains "交接区\README.md" '等下一棒 PM / 等 zlbdh confirm' "交接区 README 下一棒 PM"
Assert-Contains "交接区\README.md" '接手者 / 当前 session' "交接区 README mv 主体"
Assert-Contains "交接区\README.md" '不会静默移动文件' "交接区 README hooks 不移动"
Assert-NotContains "交接区\README.md" '下一个工具' "交接区 README 旧工具主体"

Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" '待接手卡 frontmatter status 应为 pending' "handoff guard pending frontmatter"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" '缺少完整交接卡基础标题' "handoff guard ①-⑥"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" 'DONE\|BLOCKED\|HANDOFF\|RISK\|OBSERVE' "handoff guard Status 五态"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" '已接手卡 frontmatter 仍为 status: pending' "handoff guard accepted metadata"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\file-list.ps1" '② 文件变更路径不存在' "handoff guard ② path exists"

Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" '交接区\\待接手\\' "chat guard pending path"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" '交接区\\已接手\\' "chat guard accepted done path"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" 'status:\\s\*accepted' "chat guard accepted frontmatter"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" '状态\\\.md\\s\+L' "chat guard 状态行号"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" 'N=0\\s\*/\\s\*本 session 无切帽子' "chat guard N=0 例外"
Assert-Contains "能力资产\tools\hooks\codex\stop-chat-summary.ps1" 'if \(\$readOnlyNoChange\)' "Codex Stop 只读直通"
Assert-Contains "能力资产\tools\hooks\claude\stop-chat-summary.ps1" 'if \(\$readOnlyNoChange\)' "Claude Stop 只读直通"
Assert-Contains "能力资产\tools\hooks\tests\support\hooks-smoke-codex-stop-contracts.ps1" 'line-start circled numbers' "Codex Stop 只读圈号 smoke"
Assert-Contains "能力资产\tools\hooks\tests\support\hooks-smoke-claude-contracts.ps1" 'line-start circled numbers' "Claude Stop 只读圈号 smoke"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 03_交接规格锚点对齐" -ForegroundColor Green
exit 0
