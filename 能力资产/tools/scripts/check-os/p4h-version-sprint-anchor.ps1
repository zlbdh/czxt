param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
$repoRoot = (Resolve-Path $Root).Path

# Authoritative source 1: {{APP_REPO_DIR}}/package.json version.
$pkgPath = Join-Path $repoRoot "{{APP_REPO_DIR}}/package.json"
$sotVersion = $null
if (Test-Path -LiteralPath $pkgPath) {
    try { $sotVersion = (Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json).version } catch { $sotVersion = $null }
}

# Authoritative source 2: the Sprint-N startup-reference heading in 状态.md.
$statePathH = Join-Path $repoRoot "状态.md"
$sotSprint = $null
if (Test-Path -LiteralPath $statePathH) {
    $stateRaw = Get-Content -LiteralPath $statePathH -Raw -ErrorAction SilentlyContinue
    $mSp = [regex]::Match($stateRaw, '3 秒起手速查（[^）]*?Sprint-(?<sprint>\d+)|(?m:^## 3-Second Startup Reference \(Sprint-(?<sprint>\d+)\)[ \t]*\r?$)')
    if ($mSp.Success) { $sotSprint = $mSp.Groups[1].Value }
}

if ($null -eq $sotVersion) {
    Write-Host "  ℹ️ Cannot parse authoritative version ({{APP_REPO_DIR}}/package.json missing or invalid JSON); skipping P4h version check" -ForegroundColor Gray
} else {
    $sprintDisplay = if ($sotSprint) { "Sprint-$sotSprint" } else { "unresolved" }
    Write-Host "  📌 Authoritative sources: version v$sotVersion (package.json) / $sprintDisplay (状态.md)" -ForegroundColor Gray
}

# Check target: README.md.
$readmePathH = Join-Path $repoRoot "README.md"
if ((Test-Path -LiteralPath $readmePathH) -and ($null -ne $sotVersion)) {
    $rmRaw = Get-Content -LiteralPath $readmePathH -Raw -ErrorAction SilentlyContinue

    $mRmVer = [regex]::Match($rmRaw, '当前最新[^\r\n]*?v(?<version>\d+\.\d+\.\d+)|(?m:^\| `v(?<version>\d+\.\d+\.\d+)` \| Current version anchor \|[ \t]*\r?$)')
    if ($mRmVer.Success) {
        if ($mRmVer.Groups[1].Value -eq $sotVersion) {
            Write-Host "  ✅ README latest version: v$($mRmVer.Groups[1].Value) = package.json" -ForegroundColor Green
        } else {
            Write-Host "  🔴 README latest-version anchor mismatch: v$($mRmVer.Groups[1].Value) vs package.json v$sotVersion" -ForegroundColor Red
            $failures += "README latest-version anchor v$($mRmVer.Groups[1].Value) != package.json v$sotVersion"
        }
    } else {
        Write-Host "  ℹ️ README has no current-latest vX.Y.Z anchor; skipping" -ForegroundColor Gray
    }

    $mRmShip = [regex]::Match($rmRaw, "\*\*v(\d+\.\d+\.\d+) ship\*\*")
    if ($mRmShip.Success) {
        if ($mRmShip.Groups[1].Value -eq $sotVersion) {
            Write-Host "  ✅ README current ship status: v$($mRmShip.Groups[1].Value) = package.json" -ForegroundColor Green
        } else {
            Write-Host "  🔴 README current ship-status mismatch: v$($mRmShip.Groups[1].Value) vs package.json v$sotVersion" -ForegroundColor Red
            $failures += "README current ship-status anchor v$($mRmShip.Groups[1].Value) != package.json v$sotVersion"
        }
    }

    if ($null -ne $sotSprint) {
        $mRmSp = [regex]::Match($rmRaw, '当前 Sprint[\*\s：:]*Sprint-(?<sprint>\d+)|(?m:^\| `Sprint-(?<sprint>\d+)` \| Current sprint anchor \|[ \t]*\r?$)')
        if ($mRmSp.Success) {
            if ($mRmSp.Groups[1].Value -eq $sotSprint) {
                Write-Host "  ✅ README current Sprint: Sprint-$($mRmSp.Groups[1].Value) = 状态.md" -ForegroundColor Green
            } else {
                Write-Host "  🔴 README current Sprint mismatch: Sprint-$($mRmSp.Groups[1].Value) vs 状态.md Sprint-$sotSprint" -ForegroundColor Red
                $failures += "README current Sprint anchor Sprint-$($mRmSp.Groups[1].Value) != 状态.md Sprint-$sotSprint"
            }
        } else {
            Write-Host "  ℹ️ README has no current Sprint-N anchor; skipping" -ForegroundColor Gray
        }
    }
} elseif ($null -ne $sotVersion) {
    Write-Host "  ⚠️ README.md is missing; P4a should already have reported it" -ForegroundColor Yellow
}

# Check AGENTS.md only when anchors exist; AGENTS has no version anchor by default.
$agentsPathH = Join-Path $repoRoot "AGENTS.md"
if ((Test-Path -LiteralPath $agentsPathH) -and ($null -ne $sotVersion)) {
    $agRaw = Get-Content -LiteralPath $agentsPathH -Raw -ErrorAction SilentlyContinue
    $mAgVer = [regex]::Match($agRaw, "当前最新[^\r\n]*?v(\d+\.\d+\.\d+)")
    if ($mAgVer.Success) {
        if ($mAgVer.Groups[1].Value -eq $sotVersion) {
            Write-Host "  ✅ AGENTS latest version: v$($mAgVer.Groups[1].Value) = package.json" -ForegroundColor Green
        } else {
            Write-Host "  🔴 AGENTS latest-version anchor mismatch: v$($mAgVer.Groups[1].Value) vs package.json v$sotVersion" -ForegroundColor Red
            $failures += "AGENTS latest-version anchor v$($mAgVer.Groups[1].Value) != package.json v$sotVersion"
        }
    } else {
        Write-Host "  ℹ️ AGENTS has no current-latest vX.Y.Z anchor by design; skipping" -ForegroundColor Gray
    }

    if ($null -ne $sotSprint) {
        $mAgSp = [regex]::Match($agRaw, "当前 Sprint[\*\s：:]*Sprint-(\d+)")
        if ($mAgSp.Success -and $mAgSp.Groups[1].Value -ne $sotSprint) {
            Write-Host "  🔴 AGENTS current Sprint mismatch: Sprint-$($mAgSp.Groups[1].Value) vs 状态.md Sprint-$sotSprint" -ForegroundColor Red
            $failures += "AGENTS current Sprint anchor Sprint-$($mAgSp.Groups[1].Value) != 状态.md Sprint-$sotSprint"
        } elseif ($mAgSp.Success) {
            Write-Host "  ✅ AGENTS current Sprint: Sprint-$($mAgSp.Groups[1].Value) = 状态.md" -ForegroundColor Green
        }
    }
}

if ($failures.Count -gt 0) {
    exit 10
}

exit 0
