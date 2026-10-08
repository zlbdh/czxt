# 能力资产/tools/scripts/check-retro-cadence.ps1
# Retrospective cadence alert — issue CK / Layer 4 automation for retrospective triggers (PROP-044 hooks lineage)
#
# Monitor RETRO cadence: when CHANGELOG accumulates ≥N framework activity day-batches after the latest RETRO,
# remind the Project PM to assign the Knowledge PM to write a new RETRO (never let the Knowledge PM self-activate; that breaks the single entry point).
# Same hooks lineage: pm-tracking protects records / P4h protects anchors / pre-release protects releases.
#
# Usage:
#   powershell -File 能力资产/tools/scripts/check-retro-cadence.ps1
#   powershell -File 能力资产/tools/scripts/check-retro-cadence.ps1 -Threshold 3
#
# Exit codes: 0 = normal cadence / unavailable data (fail-safe) | 5 = nonblocking reminder (accumulation ≥ threshold)
# Design: this is a reminder, not a blocker; exit 5 is a nonblocking warning (runner allowExitCodes includes 5).

param(
    [int]$Threshold = 2   # Threshold for CHANGELOG activity day-batches since the latest RETRO; default 2
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Aligned with check-operating-system.ps1: from 能力资产\tools\scripts\, ascend 3 levels to the project root
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")

$retroDir = Join-Path $root "Docs\7-复盘"
$changelogPath = Join-Path $root "操作系统\00_变更记录\CHANGELOG.md"

Write-Host ""
Write-Host "🔔 Retrospective cadence alert (issue CK / Layer 4 — RETRO trigger)" -ForegroundColor Cyan

# ===== Step 1: find the latest RETRO (highest number) =====
if (-not (Test-Path -LiteralPath $retroDir -PathType Container)) {
    Write-Host "🟡 Cannot find retrospective directory ($retroDir) — fail-safe skip without a false blocking report" -ForegroundColor Yellow
    exit 0
}

$retroFiles = @(Get-ChildItem -LiteralPath $retroDir -File -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^RETRO-(\d+)-' } |
    ForEach-Object {
        [PSCustomObject]@{ File = $_; Num = [int]([regex]::Match($_.Name, '^RETRO-(\d+)-').Groups[1].Value) }
    })

if ($retroFiles.Count -eq 0) {
    Write-Host "🟡 No RETRO-NNN- files in the retrospective directory — fail-safe skip without a false blocking report" -ForegroundColor Yellow
    exit 0
}

$latest = $retroFiles | Sort-Object Num -Descending | Select-Object -First 1
$retroNum = $latest.Num
$retroFile = $latest.File

# Parse the latest RETRO date: use the first YYYY-MM-DD in its content; if unavailable, fall back to filename YYYY-MM + "-01"
$retroDate = $null
$retroContent = Get-Content -LiteralPath $retroFile.FullName -Raw -ErrorAction SilentlyContinue
if ($retroContent) {
    $mDate = [regex]::Match($retroContent, '\d{4}-\d{2}-\d{2}')
    if ($mDate.Success) {
        try { $retroDate = [datetime]::ParseExact($mDate.Value, "yyyy-MM-dd", $null) } catch { $retroDate = $null }
    }
}
if ($null -eq $retroDate) {
    # Fall back to filename YYYY-MM plus "-01"
    $mName = [regex]::Match($retroFile.Name, '(\d{4}-\d{2})')
    if ($mName.Success) {
        try { $retroDate = [datetime]::ParseExact($mName.Groups[1].Value + "-01", "yyyy-MM-dd", $null) } catch { $retroDate = $null }
    }
}

if ($null -eq $retroDate) {
    Write-Host "🟡 Cannot parse a date for RETRO-$retroNum ($($retroFile.Name)) — fail-safe skip without a false blocking report" -ForegroundColor Yellow
    exit 0
}

$retroDateStr = $retroDate.ToString("yyyy-MM-dd")

# ===== Step 2: count CHANGELOG activity day-batches since the latest RETRO =====
if (-not (Test-Path -LiteralPath $changelogPath -PathType Leaf)) {
    Write-Host "🟡 Cannot find CHANGELOG ($changelogPath) — fail-safe skip without a false blocking report" -ForegroundColor Yellow
    exit 0
}

$changelogContent = Get-Content -LiteralPath $changelogPath -Raw -ErrorAction SilentlyContinue
$dateMatches = [regex]::Matches($changelogContent, '(?m)^## (\d{4}-\d{2}-\d{2})')
$sinceDates = @($dateMatches | ForEach-Object {
    try { [datetime]::ParseExact($_.Groups[1].Value, "yyyy-MM-dd", $null) } catch { $null }
} | Where-Object { $_ -ne $null -and $_ -gt $retroDate } | Sort-Object -Unique)
$sinceCount = @($sinceDates).Count

# ===== Step 3: decide and report (following check-pm-tracking style) =====
Write-Host "  Latest RETRO: RETRO-$retroNum (date $retroDateStr · $($retroFile.Name))"
Write-Host "  Framework activity day-batches since the latest RETRO: $sinceCount (threshold $Threshold)"

if ($sinceCount -ge $Threshold) {
    Write-Host ""
    Write-Host "🟡 Retrospective cadence reminder: since RETRO-$retroNum, $sinceCount framework activity batches have accumulated. Recommend that the Project PM assign the Knowledge PM to write a new RETRO (one retrospective per 3 L3+ changes / RETRO cadence)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Entry prompt: Project PM assigns the Knowledge PM to draft RETRO-$($retroNum + 1), covering the period since RETRO-$retroNum ($sinceCount activity batches)" -ForegroundColor Yellow
    exit 5
} else {
    Write-Host ""
    Write-Host "✅ Retrospective cadence is normal (since RETRO-$retroNum, activity batches $sinceCount < threshold $Threshold)" -ForegroundColor Green
    exit 0
}
