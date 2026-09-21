param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4k-entry-anchor-patterns.ps1")

$hits = @()
foreach ($check in @(Get-P4kEntryAnchorChecks)) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
        $lineNo = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$($check.Path)`:L$lineNo $($check.Label)"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 入口/填实旧口径残留：$($hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ 入口锚点 / PM 工作区 / 填实状态旧口径未回退" -ForegroundColor Green
exit 0
