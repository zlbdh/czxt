param([string]$Root)

$ErrorActionPreference = "Stop"
$ok = $true

function Get-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-Host "  🔴 Missing file: $Rel" -ForegroundColor Red
    $script:ok = $false
    return ""
  }
  Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Assert-Match([string]$Rel, [string]$Pattern, [string]$Label) {
  $text = Get-Text $Rel
  if ($text -notmatch $Pattern) {
    Write-Host "  🔴 $Label：$Rel" -ForegroundColor Red
    $script:ok = $false
  }
}

function Assert-FrontName([string]$Rel, [string]$Expected) {
  $text = Get-Text $Rel
  if ($text -notmatch "(?m)^name:\s*$([regex]::Escape($Expected))\s*$") {
    Write-Host "  🔴 Frontmatter name drift: $Rel must be $Expected" -ForegroundColor Red
    $script:ok = $false
  }
}

Assert-FrontName "操作系统\06_工具治理\操作系统改进研究-2026-05-21.md" "os-improvement-research-2026-05-21-entry"
Assert-FrontName "操作系统\06_工具治理\操作系统全景图-2026-05-21.md" "os-panorama-2026-05-21-entry"
Assert-FrontName "操作系统\06_工具治理\操作系统终态愿景-v4.0-2026-05-21.md" "os-vision-v4-2026-05-21-entry"
Assert-FrontName "操作系统\06_工具治理\记忆治理方案-2026-05-22.md" "memory-governance-plan-entry"

Assert-Match "操作系统\06_工具治理\历史归档\2026-05\操作系统改进研究-2026-05-21.md" "非待办、非当前规范|not as a to-do list or current standard" "Improvement research historical boundary is missing"
Assert-Match "操作系统\06_工具治理\历史归档\2026-05\操作系统全景图-2026-05-21.md" "历史档案 / 已被取代 / 残篇|Historical archive / superseded / fragment" "Panorama historical-fragment boundary is missing"
Assert-Match "操作系统\06_工具治理\历史归档\2026-05\操作系统终态愿景-v4.0-2026-05-21.md" "历史快照说明.*不能作为当前真相源|Historical snapshot note.*cannot serve as current truth\." "End-state vision historical boundary is missing"
Assert-Match "操作系统\06_工具治理\历史归档\2026-05\记忆治理方案-2026-05-22.md" "历史快照 / 非当前执行入口|Historical snapshot / not a current execution entry point" "Memory governance historical boundary is missing"

$panorama = Get-Text "操作系统\06_工具治理\历史归档\2026-05\操作系统全景图-2026-05-21.md"
$tail = (($panorama -split "`r?`n") | Select-Object -Last 5) -join "`n"
if (($tail -match "起手 S|Startup S") -and ($panorama -notmatch "残篇|fragment")) {
  Write-Host "  🔴 Panorama tail appears incomplete without a fragment declaration" -ForegroundColor Red
  $ok = $false
}

Assert-Match "操作系统\06_工具治理\README.md" "不参与 P4b/P4c/P4o 活跃体检，P4q 只守首屏历史边界与残篇声明|Excluded from active P4b/P4c/P4o checks; P4q checks only the first-screen historical boundary and fragment notice" "06 README historical-archive health-check boundary is missing"
Assert-Match "操作系统\04_台账\逐文件审计覆盖台账.md" "操作系统/06_工具治理" "Tool governance coverage-ledger registration is missing"

if (-not $ok) { exit 10 }
Write-Host "  ✅ Tool governance historical-archive boundary anchors are aligned"
exit 0
