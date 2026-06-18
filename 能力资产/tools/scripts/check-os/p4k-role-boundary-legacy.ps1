param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4k-role-boundary-patterns.ps1")

$hits = @()
foreach ($check in $checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $hits += "$($check.Path) $($check.Label)（守卫目标文件缺失）"
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
        $line = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$($check.Path):L$line $($check.Label)"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 角色边界/安全旧口径残留：$($hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ 角色边界 / B-C 类 / 发布 DoD 旧口径未回退" -ForegroundColor Green
exit 0
