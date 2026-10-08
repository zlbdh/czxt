param(
    [string]$Root = "",
    [int]$Threshold = 30
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) "check-pm-tracking.ps1"
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Write-Host "  ⚠️ check-pm-tracking.ps1 is missing; full PROP-027 v2 implementation is absent" -ForegroundColor Yellow
    exit 5
}

& $scriptPath -Root $Root -Threshold $Threshold
$pmTrackingExit = $LASTEXITCODE

if ($pmTrackingExit -eq 5) {
    Write-Host "  🟡 PM trace age exceeds the threshold without framework changes; monitor" -ForegroundColor Yellow
    exit 0
}

exit $pmTrackingExit
