param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4k-role-boundary-patterns.ps1")

$hits = @()
foreach ($check in $checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $hits += "$($check.Path) $($check.Label) (guard target file missing)"
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
        $line = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$($check.Path):L$line $($check.Label)"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 Obsolete role-boundary/safety language remains: $($hits.Count) matches" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ Role boundaries, Class B/C rules, and release DoD contain no obsolete language" -ForegroundColor Green
exit 0
