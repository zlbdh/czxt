param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

$rel = "操作系统\04_台账\逐文件审计覆盖台账.md"
$path = Join-Path $Root $rel
$detailRel = "操作系统\04_台账\逐文件审计覆盖台账-明细.md"
$detailPath = Join-Path $Root $detailRel
$indexPath = Join-Path $Root "操作系统\04_台账\INDEX.md"

if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
  Add-Failure "缺少逐文件审计覆盖台账：$rel"
} else {
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  foreach ($needle in @(
    '自动守卫通过不等于人工逐字覆盖',
    '覆盖类型边界',
    '已登记覆盖片段',
    '逐文件审计覆盖台账-明细.md',
    '不得单独声称“逐字已证明”',
    '操作系统/00_总入口.md'
  )) {
    if (-not $text.Contains($needle)) {
      Add-Failure "$rel 缺少覆盖台账锚点：$needle"
    }
  }

  $files = @(Get-ChildItem -LiteralPath (Join-Path $Root "操作系统") -Recurse -File -Filter "*.md")
  $history = @($files | Where-Object {
    $_.FullName -match '\\历史归档\\|\\状态-archive\\|CHANGELOG-2026|CHANGELOG-2026H1|agent-.*历史\.md'
  })
  $expected = "$($files.Count) 个 Markdown；活跃 $($files.Count - $history.Count) / 历史 $($history.Count)"
  if (-not $text.Contains($expected)) {
    Add-Failure "$rel 时点基线未匹配当前文件系统计数：应包含「$expected」"
  }
}

if (-not (Test-Path -LiteralPath $detailPath -PathType Leaf)) {
  Add-Failure "缺少逐文件审计覆盖明细：$detailRel"
} else {
  $detailText = Get-Content -LiteralPath $detailPath -Raw -Encoding UTF8
  foreach ($needle in @('95 个审计对象', '29 + 25 + 15 + 26', '019ed184-ba7b', '019ed184-cdc7', '019ed184-e1ad', '019ed184-f547')) {
    if (-not $detailText.Contains($needle)) {
      Add-Failure "$detailRel 缺少全量逐文件证据锚点：$needle"
    }
  }
}

if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
  Add-Failure "缺少台账 INDEX.md"
} else {
  $indexText = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
  if ($indexText -notmatch "逐文件审计覆盖台账\.md" -or $indexText -notmatch "逐文件审计覆盖台账-明细\.md" -or $indexText -notmatch "不把自动守卫误当人工逐字证明") {
    Add-Failure "04_台账/INDEX.md 未登记逐文件审计覆盖台账"
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ 逐文件审计覆盖台账锚点对齐" -ForegroundColor Green
exit 0
