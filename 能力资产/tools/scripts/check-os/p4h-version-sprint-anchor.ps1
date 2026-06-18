param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
$repoRoot = (Resolve-Path $Root).Path

# 真知识源 1：{{APP_REPO_DIR}}/package.json version
$pkgPath = Join-Path $repoRoot "{{APP_REPO_DIR}}/package.json"
$sotVersion = $null
if (Test-Path -LiteralPath $pkgPath) {
    try { $sotVersion = (Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json).version } catch { $sotVersion = $null }
}

# 真知识源 2：状态.md 起手速查标题 Sprint-N
$statePathH = Join-Path $repoRoot "状态.md"
$sotSprint = $null
if (Test-Path -LiteralPath $statePathH) {
    $stateRaw = Get-Content -LiteralPath $statePathH -Raw -ErrorAction SilentlyContinue
    $mSp = [regex]::Match($stateRaw, "3 秒起手速查（[^）]*?Sprint-(\d+)")
    if ($mSp.Success) { $sotSprint = $mSp.Groups[1].Value }
}

if ($null -eq $sotVersion) {
    Write-Host "  ℹ️ 真知识源 version 未解析（{{APP_REPO_DIR}}/package.json 缺失或非法 JSON）— 跳过 P4h 版本核查" -ForegroundColor Gray
} else {
    $sprintDisplay = if ($sotSprint) { "Sprint-$sotSprint" } else { "未解析" }
    Write-Host "  📌 真知识源：版本 v$sotVersion（package.json）/ $sprintDisplay（状态.md）" -ForegroundColor Gray
}

# 核查目标：README.md
$readmePathH = Join-Path $repoRoot "README.md"
if ((Test-Path -LiteralPath $readmePathH) -and ($null -ne $sotVersion)) {
    $rmRaw = Get-Content -LiteralPath $readmePathH -Raw -ErrorAction SilentlyContinue

    $mRmVer = [regex]::Match($rmRaw, "当前最新[^\r\n]*?v(\d+\.\d+\.\d+)")
    if ($mRmVer.Success) {
        if ($mRmVer.Groups[1].Value -eq $sotVersion) {
            Write-Host "  ✅ README 当前最新：v$($mRmVer.Groups[1].Value) = package.json" -ForegroundColor Green
        } else {
            Write-Host "  🔴 README 当前最新锚点漂移：v$($mRmVer.Groups[1].Value) vs package.json v$sotVersion" -ForegroundColor Red
            $failures += "README 当前最新版本锚点 v$($mRmVer.Groups[1].Value) != package.json v$sotVersion"
        }
    } else {
        Write-Host "  ℹ️ README 未找到「当前最新 vX.Y.Z」锚点（跳过）" -ForegroundColor Gray
    }

    $mRmShip = [regex]::Match($rmRaw, "\*\*v(\d+\.\d+\.\d+) ship\*\*")
    if ($mRmShip.Success) {
        if ($mRmShip.Groups[1].Value -eq $sotVersion) {
            Write-Host "  ✅ README 当前状态 ship：v$($mRmShip.Groups[1].Value) = package.json" -ForegroundColor Green
        } else {
            Write-Host "  🔴 README 当前状态 ship 漂移：v$($mRmShip.Groups[1].Value) vs package.json v$sotVersion" -ForegroundColor Red
            $failures += "README 当前状态 ship 锚点 v$($mRmShip.Groups[1].Value) != package.json v$sotVersion"
        }
    }

    if ($null -ne $sotSprint) {
        $mRmSp = [regex]::Match($rmRaw, "当前 Sprint[\*\s：:]*Sprint-(\d+)")
        if ($mRmSp.Success) {
            if ($mRmSp.Groups[1].Value -eq $sotSprint) {
                Write-Host "  ✅ README 当前 Sprint：Sprint-$($mRmSp.Groups[1].Value) = 状态.md" -ForegroundColor Green
            } else {
                Write-Host "  🔴 README 当前 Sprint 漂移：Sprint-$($mRmSp.Groups[1].Value) vs 状态.md Sprint-$sotSprint" -ForegroundColor Red
                $failures += "README 当前 Sprint 锚点 Sprint-$($mRmSp.Groups[1].Value) != 状态.md Sprint-$sotSprint"
            }
        } else {
            Write-Host "  ℹ️ README 未找到「当前 Sprint：Sprint-N」锚点（跳过）" -ForegroundColor Gray
        }
    }
} elseif ($null -ne $sotVersion) {
    Write-Host "  ⚠️ README.md 不存在 — P4a 已应触发" -ForegroundColor Yellow
}

# 核查目标：AGENTS.md（仅当锚点存在时核查 / AGENTS 默认无版本锚点）
$agentsPathH = Join-Path $repoRoot "AGENTS.md"
if ((Test-Path -LiteralPath $agentsPathH) -and ($null -ne $sotVersion)) {
    $agRaw = Get-Content -LiteralPath $agentsPathH -Raw -ErrorAction SilentlyContinue
    $mAgVer = [regex]::Match($agRaw, "当前最新[^\r\n]*?v(\d+\.\d+\.\d+)")
    if ($mAgVer.Success) {
        if ($mAgVer.Groups[1].Value -eq $sotVersion) {
            Write-Host "  ✅ AGENTS 当前最新：v$($mAgVer.Groups[1].Value) = package.json" -ForegroundColor Green
        } else {
            Write-Host "  🔴 AGENTS 当前最新锚点漂移：v$($mAgVer.Groups[1].Value) vs package.json v$sotVersion" -ForegroundColor Red
            $failures += "AGENTS 当前最新版本锚点 v$($mAgVer.Groups[1].Value) != package.json v$sotVersion"
        }
    } else {
        Write-Host "  ℹ️ AGENTS 无「当前最新 vX.Y.Z」锚点（设计如此 / 跳过）" -ForegroundColor Gray
    }

    if ($null -ne $sotSprint) {
        $mAgSp = [regex]::Match($agRaw, "当前 Sprint[\*\s：:]*Sprint-(\d+)")
        if ($mAgSp.Success -and $mAgSp.Groups[1].Value -ne $sotSprint) {
            Write-Host "  🔴 AGENTS 当前 Sprint 漂移：Sprint-$($mAgSp.Groups[1].Value) vs 状态.md Sprint-$sotSprint" -ForegroundColor Red
            $failures += "AGENTS 当前 Sprint 锚点 Sprint-$($mAgSp.Groups[1].Value) != 状态.md Sprint-$sotSprint"
        } elseif ($mAgSp.Success) {
            Write-Host "  ✅ AGENTS 当前 Sprint：Sprint-$($mAgSp.Groups[1].Value) = 状态.md" -ForegroundColor Green
        }
    }
}

if ($failures.Count -gt 0) {
    exit 10
}

exit 0
