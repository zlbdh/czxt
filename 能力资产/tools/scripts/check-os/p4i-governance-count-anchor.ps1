param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
$repoRoot = (Resolve-Path $Root).Path
. (Join-Path $PSScriptRoot "adr-governance-truth.ps1")

function Count-PropFilesForHealth {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return 0 }
    return @(
        Get-ChildItem -LiteralPath $Path -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "_模板.md" }
    ).Count
}

$retroDirI = Join-Path $repoRoot "Docs/7-复盘"
$sotRetroCount = $null

$adrTruth = Get-CzxtAdrGovernanceTruth -Root $repoRoot
Write-Host "  📌 Authoritative ADR counts: $($adrTruth.Text) (total/current/superseded; filesystem + ADR index status)" -ForegroundColor Gray
foreach ($failure in $adrTruth.Failures) {
    Write-Host "  🔴 ADR source check failed: $failure" -ForegroundColor Red
    $failures += $failure
}

$entryFailures = @(Test-CzxtAdrMainEntryAnchor -Root $repoRoot -Truth $adrTruth)
if ($entryFailures.Count -eq 0) {
    Write-Host "  ✅ Main-entry ADR count: $($adrTruth.Text) = authoritative source" -ForegroundColor Green
} else {
    foreach ($failure in $entryFailures) {
        Write-Host "  🔴 Main-entry ADR count mismatch: $failure" -ForegroundColor Red
        $failures += $failure
    }
}

if (Test-Path -LiteralPath $retroDirI) {
    $retroNums = Get-ChildItem -LiteralPath $retroDirI -Filter "RETRO-*.md" |
        ForEach-Object { [regex]::Match($_.Name, "RETRO-(\d+)").Groups[1].Value } |
        Where-Object { $_ } |
        Sort-Object -Unique
    $sotRetroCount = @($retroNums).Count
}

if ($null -ne $sotRetroCount) {
    Write-Host "  📌 Authoritative RETRO count: $sotRetroCount RETROs (deduplicated numbers / filesystem)" -ForegroundColor Gray
}

$readmePathI = Join-Path $repoRoot "README.md"
if (Test-Path -LiteralPath $readmePathI) {
    $rmRawI = Get-Content -LiteralPath $readmePathI -Raw -ErrorAction SilentlyContinue
    if ($null -ne $sotRetroCount) {
        $mRmRetro = [regex]::Match($rmRawI, "现行\s*/\s*(\d+)\s*RETRO")
        if ($mRmRetro.Success) {
            if ([int]$mRmRetro.Groups[1].Value -eq $sotRetroCount) {
                Write-Host "  ✅ README RETRO count: $($mRmRetro.Groups[1].Value) = actual $sotRetroCount" -ForegroundColor Green
            } else {
                Write-Host "  🔴 README RETRO count mismatch: $($mRmRetro.Groups[1].Value) vs actual $sotRetroCount" -ForegroundColor Red
                $failures += "README RETRO count anchor $($mRmRetro.Groups[1].Value) != actual $sotRetroCount"
            }
        } else {
            Write-Host "  ℹ️ README has no current / N RETRO anchor; skipping" -ForegroundColor Gray
        }
    }
}

$propReadmeI = Join-Path $repoRoot "确认改动/README.md"
if (Test-Path -LiteralPath $propReadmeI) {
    $propActual = @(
        (Count-PropFilesForHealth -Path (Join-Path $repoRoot "确认改动/待审批")),
        (Count-PropFilesForHealth -Path (Join-Path $repoRoot "确认改动/已审批/进行中")),
        (Count-PropFilesForHealth -Path (Join-Path $repoRoot "确认改动/已审批/已完成")),
        (Count-PropFilesForHealth -Path (Join-Path $repoRoot "确认改动/已审批/已弃用")),
        (Count-PropFilesForHealth -Path (Join-Path $repoRoot "确认改动/拒绝"))
    )
    $propRawI = Get-Content -LiteralPath $propReadmeI -Raw -ErrorAction SilentlyContinue
    $mPropCounts = [regex]::Match($propRawI, '(?m)^\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|')
    if ($mPropCounts.Success) {
        $propClaim = @(
            [int]$mPropCounts.Groups[1].Value,
            [int]$mPropCounts.Groups[2].Value,
            [int]$mPropCounts.Groups[3].Value,
            [int]$mPropCounts.Groups[4].Value,
            [int]$mPropCounts.Groups[5].Value
        )
        $propClaimText = $propClaim -join "/"
        $propActualText = $propActual -join "/"
        if ($propClaimText -eq $propActualText) {
            Write-Host "  ✅ PROP README counts: $propClaimText = actual $propActualText (pending/active/completed/deprecated/rejected)" -ForegroundColor Green
        } else {
            Write-Host "  🔴 PROP README count mismatch: $propClaimText vs actual $propActualText" -ForegroundColor Red
            $failures += "PROP README count anchor $propClaimText != actual $propActualText"
        }
    } else {
        Write-Host "  🔴 PROP README lacks the five-column count row" -ForegroundColor Red
        $failures += "PROP README five-column count anchor is missing"
    }
} else {
    Write-Host "  🔴 确认改动/README.md is missing" -ForegroundColor Red
    $failures += "确认改动/README.md 缺失"
}

if ($failures.Count -gt 0) {
    exit 10
}

exit 0
