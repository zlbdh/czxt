param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "p4k-tool-subject-patterns.ps1")
. (Join-Path $PSScriptRoot "p4k-tool-subject-patterns-workflows.ps1")
$checks = @($script:P4kToolSubjectChecks) + @($script:P4kToolSubjectWorkflowChecks)

$hits = @()
foreach ($check in $checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
        $line = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$($check.Path):L$line $($check.Label)"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 工具主语旧口径残留：$($hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ 工具主语 / 工具战场旧口径未回退" -ForegroundColor Green
exit 0
