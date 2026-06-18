param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
$repoRoot = (Resolve-Path $Root).Path

function Count-PropFilesForHealth {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return 0 }
    return @(
        Get-ChildItem -LiteralPath $Path -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "_模板.md" }
    ).Count
}

$adrDirI = Join-Path $repoRoot "Docs/3-开发文档/adr"
$retroDirI = Join-Path $repoRoot "Docs/7-复盘"
$sotAdrCount = $null
$sotRetroCount = $null

if (Test-Path -LiteralPath $adrDirI) {
    $adrNums = Get-ChildItem -LiteralPath $adrDirI -Filter "ADR-*.md" |
        ForEach-Object { [regex]::Match($_.Name, "ADR-(\d+)").Groups[1].Value } |
        Where-Object { $_ } |
        Sort-Object -Unique
    $sotAdrCount = @($adrNums).Count
}

if (Test-Path -LiteralPath $retroDirI) {
    $retroNums = Get-ChildItem -LiteralPath $retroDirI -Filter "RETRO-*.md" |
        ForEach-Object { [regex]::Match($_.Name, "RETRO-(\d+)").Groups[1].Value } |
        Where-Object { $_ } |
        Sort-Object -Unique
    $sotRetroCount = @($retroNums).Count
}

if (($null -ne $sotAdrCount) -and ($null -ne $sotRetroCount)) {
    Write-Host "  📌 真知识源：$sotAdrCount ADR / $sotRetroCount RETRO（去重编号 / 文件系统）" -ForegroundColor Gray
}

$readmePathI = Join-Path $repoRoot "README.md"
if ((Test-Path -LiteralPath $readmePathI) -and ($null -ne $sotAdrCount)) {
    $rmRawI = Get-Content -LiteralPath $readmePathI -Raw -ErrorAction SilentlyContinue
    $mRmAdr = [regex]::Match($rmRawI, "(\d+)\s*ADR\s*现行")
    if ($mRmAdr.Success) {
        if ([int]$mRmAdr.Groups[1].Value -eq $sotAdrCount) {
            Write-Host "  ✅ README ADR 计数：$($mRmAdr.Groups[1].Value) = 真实 $sotAdrCount" -ForegroundColor Green
        } else {
            Write-Host "  🔴 README ADR 计数漂移：$($mRmAdr.Groups[1].Value) vs 真实 $sotAdrCount" -ForegroundColor Red
            $failures += "README ADR 计数锚点 $($mRmAdr.Groups[1].Value) != 真实 $sotAdrCount"
        }
    } else {
        Write-Host "  ℹ️ README 未找到「N ADR 现行」锚点（跳过）" -ForegroundColor Gray
    }

    if ($null -ne $sotRetroCount) {
        $mRmRetro = [regex]::Match($rmRawI, "现行\s*/\s*(\d+)\s*RETRO")
        if ($mRmRetro.Success) {
            if ([int]$mRmRetro.Groups[1].Value -eq $sotRetroCount) {
                Write-Host "  ✅ README RETRO 计数：$($mRmRetro.Groups[1].Value) = 真实 $sotRetroCount" -ForegroundColor Green
            } else {
                Write-Host "  🔴 README RETRO 计数漂移：$($mRmRetro.Groups[1].Value) vs 真实 $sotRetroCount" -ForegroundColor Red
                $failures += "README RETRO 计数锚点 $($mRmRetro.Groups[1].Value) != 真实 $sotRetroCount"
            }
        } else {
            Write-Host "  ℹ️ README 未找到「现行 / N RETRO」锚点（跳过）" -ForegroundColor Gray
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
            Write-Host "  ✅ PROP README 计数：$propClaimText = 真实 $propActualText（待审批/进行中/已完成/已弃用/拒绝）" -ForegroundColor Green
        } else {
            Write-Host "  🔴 PROP README 计数漂移：$propClaimText vs 真实 $propActualText" -ForegroundColor Red
            $failures += "PROP README 计数锚点 $propClaimText != 真实 $propActualText"
        }
    } else {
        Write-Host "  🔴 PROP README 未找到五列计数行" -ForegroundColor Red
        $failures += "PROP README 五列计数锚点缺失"
    }
} else {
    Write-Host "  🔴 找不到 确认改动/README.md" -ForegroundColor Red
    $failures += "确认改动/README.md 缺失"
}

if ($failures.Count -gt 0) {
    exit 10
}

exit 0
