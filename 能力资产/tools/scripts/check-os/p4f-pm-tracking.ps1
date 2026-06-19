param(
    [string]$Root = "",
    [int]$Threshold = 30
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) "check-pm-tracking.ps1"
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Write-Host "  ⚠️ check-pm-tracking.ps1 不存在 — PROP-027 v2 完整版未落地" -ForegroundColor Yellow
    exit 5
}

& $scriptPath -Root $Root -Threshold $Threshold
$pmTrackingExit = $LASTEXITCODE

if ($pmTrackingExit -eq 5) {
    Write-Host "  🟡 PM 轨迹时间超阈值但 framework 无改动 — 监控" -ForegroundColor Yellow
    exit 0
}

exit $pmTrackingExit
