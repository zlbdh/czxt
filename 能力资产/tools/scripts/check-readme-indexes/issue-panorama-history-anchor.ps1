param([string]$Root)

$ErrorActionPreference = "Stop"
$rel = "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md"
$path = Join-Path $Root $rel

if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
  Write-Host "  🔴 Issue-panorama historical snapshot is missing: $rel" -ForegroundColor Red
  exit 10
}

$text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
$failures = @()

if ($text -notmatch '2026-05-22 快照口径|refer to the 2026-05-22 snapshot') {
  $failures += "Historical snapshot guidance is missing"
}

foreach ($m in [regex]::Matches($text, '\[[^\]]*PM自纠-[^\]]+\.md\]\(([^)]+)\)')) {
  $target = $m.Groups[1].Value -replace '/', '\'
  $resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $target))
  if (-not $resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
    $failures += "PM self-correction link escapes the root: $($m.Groups[1].Value)"
  } elseif (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    $line = ($text.Substring(0, $m.Index) -split "`n").Count
    $failures += "L$line PM self-correction link is broken: $($m.Groups[1].Value)"
  }
}

if ($failures.Count -gt 0) {
  Write-Host "  🔴 Issue-panorama historical-snapshot anchor issues: $($failures.Count) findings" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host "    - $f" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ Issue-panorama historical-snapshot anchors resolve"
exit 0
