param([string]$Root)

$ErrorActionPreference = "Stop"
$rel = "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md"
$path = Join-Path $Root $rel

if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
  Write-Host "  🔴 议题全景历史快照缺失：$rel" -ForegroundColor Red
  exit 10
}

$text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
$failures = @()

if ($text -notmatch '2026-05-22 快照口径') {
  $failures += "缺少历史快照口径提示"
}

foreach ($m in [regex]::Matches($text, '\[[^\]]*PM自纠-[^\]]+\.md\]\(([^)]+)\)')) {
  $target = $m.Groups[1].Value -replace '/', '\'
  $resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $target))
  if (-not $resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
    $failures += "PM自纠链接越界：$($m.Groups[1].Value)"
  } elseif (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    $line = ($text.Substring(0, $m.Index) -split "`n").Count
    $failures += "L$line PM自纠链接断链：$($m.Groups[1].Value)"
  }
}

if ($failures.Count -gt 0) {
  Write-Host "  🔴 议题全景历史快照锚点问题：$($failures.Count) 处" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host "    - $f" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ 议题全景历史快照锚点可解析"
exit 0
