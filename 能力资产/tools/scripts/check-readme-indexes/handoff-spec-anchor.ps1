param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

Assert-Contains "操作系统\03_交接\README.md" '完整文件基础 ①-⑥ \+ 可选文件 ⑦ \+ chat 简版 ①-⑦|full file requires ①-⑥ \+ optional file section ⑦ \+ short chat handoff ①-⑦' "03 README section counts"
Assert-Contains "操作系统\03_交接\README.md" 'DONE / BLOCKED / HANDOFF / RISK / OBSERVE' "03 README five Status states"

Assert-Contains "操作系统\03_交接\交接卡格式.md" 'frontmatter `status` 必须先是 `pending`|Frontmatter `status` must initially be `pending`' "Handoff template pending frontmatter"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '(?s)```markdown\s*---\s*status: pending\s*from:' "Handoff template YAML example"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '待接手 `pending`，接收后 `accepted`|pending is `pending`, accepted is `accepted`' "Frontmatter status routing states"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '正文 `Status:`=交付警戒态|Body `Status:` is the delivery caution state' "Body Status caution state"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '⑥ 必须用纯文本路径指向 `交接区/待接手/`|section ⑥ must use a plain-text path to an existing `\.md` file under `交接区/待接手/`' "Chat section ⑥ default pending path"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '接收归档收尾且 `交接区/待接手/` 为空时，可指向 `交接区/已接手/` 下 `status: accepted`|When finalizing acceptance/archive work and `交接区/待接手/` is empty, it may point to a `status: accepted` `\.md` file under `交接区/已接手/`' "Chat section ⑥ accepted-card exception"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '不要写 Markdown 链接|Do not use Markdown links' "Chat section ⑥ excludes Markdown links"
Assert-Contains "操作系统\03_交接\交接卡格式.md" '当前主会话按 PM 帽子确认后落笔|The current main session confirms card moves, summaries, and sections ①-⑦ under its PM role before writing them' "Handoff final writer"
Assert-NotContains "操作系统\03_交接\交接卡格式.md" '必须由项目 PM 主会话|must be done by the Project PM main session' "Obsolete overly narrow card-move authority"

Assert-Contains "操作系统\03_交接\交接卡格式-附录.md" '不会自动把卡从 `待接手/` 移到 `已接手/`|does not automatically move cards from `待接手/` to `已接手/`' "Appendix prohibits automatic moves"
Assert-Contains "操作系统\03_交接\交接卡格式-附录.md" '不会替 PM 追加轨迹|does not append PM-transition rows on a PM.s behalf' "Appendix prohibits automatic trace appends"

Assert-Contains "交接区\README.md" '⑥ 追加问答（标题必留，内容可写“暂无”）' "Handoff-area README requires section ⑥ heading"
Assert-Contains "交接区\README.md" '等下一棒 PM / 等 zlbdh confirm' "Handoff-area README next PM"
Assert-Contains "交接区\README.md" '接手者 / 当前 session' "Handoff-area README move authority"
Assert-Contains "交接区\README.md" '不会静默移动文件' "Handoff-area README hooks do not move cards"
Assert-NotContains "交接区\README.md" '下一个工具' "Handoff-area README obsolete tool actor"

Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" '待接手卡 frontmatter status 应为 pending' "handoff guard pending frontmatter"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" '缺少完整交接卡基础标题' "Handoff guard sections ①-⑥"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" 'DONE\|BLOCKED\|HANDOFF\|RISK\|OBSERVE' "Handoff guard five Status states"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\card-format.ps1" '已接手卡 frontmatter 仍为 status: pending' "handoff guard accepted metadata"
Assert-Contains "能力资产\tools\scripts\check-handoff-zone\file-list.ps1" '② 文件变更路径不存在' "Handoff guard section ② path exists"

Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" '交接区\\待接手\\' "chat guard pending path"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" '交接区\\已接手\\' "chat guard accepted done path"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" 'status:\\s\*accepted' "chat guard accepted frontmatter"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" '状态\\\.md\\s\+L' "Chat guard status line number"
Assert-Contains "能力资产\tools\hooks\chat-output\check-chat-summary.ps1" 'N=0\\s\*/\\s\*(?:本 session 无切帽子|\(\?:本 session 无切帽子\|no role switch this session\))' "Chat guard N=0 exception"
Assert-Contains "能力资产\tools\hooks\codex\stop-chat-summary.ps1" 'if \(\$readOnlyNoChange\)' "Codex Stop read-only bypass"
Assert-Contains "能力资产\tools\hooks\claude\stop-chat-summary.ps1" 'if \(\$readOnlyNoChange\)' "Claude Stop read-only bypass"
Assert-Contains "能力资产\tools\hooks\tests\support\hooks-smoke-codex-stop-contracts.ps1" 'line-start circled numbers' "Codex Stop read-only circled-marker smoke"
Assert-Contains "能力资产\tools\hooks\tests\support\hooks-smoke-claude-contracts.ps1" 'line-start circled numbers' "Claude Stop read-only circled-marker smoke"

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 03 handoff specification anchors aligned" -ForegroundColor Green
exit 0
