param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4k-entry-anchor-patterns.ps1")

$hits = @()
foreach ($line in ($script:EntryAnchorPatternRows -split "`r?`n" | Where-Object { $_.Trim() })) {
    $rel, $pattern, $label = $line -split '§', 3
    $path = Join-Path $Root $rel
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $lineNo = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$rel`:L$lineNo $label"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 入口/填实旧口径残留：$($hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ 入口锚点 / PM 工作区 / 填实状态旧口径未回退" -ForegroundColor Green
exit 0
