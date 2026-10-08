param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$adrDir = Join-Path $Root "Docs/3-开发文档/adr"
$adrReadmePath = Join-Path $adrDir "README.md"
if ((Test-Path -LiteralPath $adrDir) -and (Test-Path -LiteralPath $adrReadmePath)) {
    $adrFiles = (Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md").Count
    $adrReadmeRows = (Get-Content -LiteralPath $adrReadmePath -Encoding UTF8 | Select-String -Pattern "^\| ADR-").Count
    if ($adrFiles -eq $adrReadmeRows) {
        Write-Host "  ✅ ADR README: $adrFiles files = $adrReadmeRows README table rows" -ForegroundColor Green
    } else {
        Write-Host "  🔴 ADR README mismatch: $adrFiles files vs $adrReadmeRows README table rows (self-correction #91 recurrence)" -ForegroundColor Red
        $failures.Add("ADR README consistency: $adrFiles files vs $adrReadmeRows README rows")
    }
} else {
    Write-Host "  ⚠️ ADR directory or README is missing" -ForegroundColor Yellow
}

$panoramaPaths = @(
    (Join-Path $Root "操作系统/04_台账/议题全景.md"),
    (Join-Path $Root "操作系统/04_台账/历史归档/2026-05/议题全景-2026-05-22-历史快照.md")
)
$panoramaFound = $false
$panoramaAdrRows = 0
foreach ($panoramaPath in $panoramaPaths) {
    if (Test-Path -LiteralPath $panoramaPath) {
        $panoramaFound = $true
        $panoramaAdrRows += (Get-Content -LiteralPath $panoramaPath -Encoding UTF8 | Select-String -Pattern "^\| \*\*(?:🆕 )?ADR-").Count
    }
}
if ($panoramaFound) {
    Write-Host "  ℹ️ Issue-panorama ADR scan complete (main document + historical snapshots; manual semantic tables do not automatically block)" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️ 议题全景.md is missing" -ForegroundColor Yellow
}

$poolPath = Join-Path $Root "操作系统/01_架构/元规则池.md"
if (Test-Path -LiteralPath $poolPath) {
    $poolContent = Get-Content -LiteralPath $poolPath -Raw -Encoding UTF8
    $section2 = if ($poolContent -match "(?s)## (?:二、|2\.).*?(?=## (?:三、|3\.))") { $matches[0] } else { "" }
    $poolRows = ([regex]::Matches($section2, "(?m)^\| \*\*")).Count
    $claimMatch = [regex]::Match($poolContent, "\*\*v3\.\d+(?:\.\d+)?\*\*[^|]*\| \*\*(?:当前|Current)\*\*[^|]*\| \*\*(\d+)")
    if ($claimMatch.Success) {
        $poolClaim = [int]$claimMatch.Groups[1].Value
        if ($poolRows -eq $poolClaim) {
            Write-Host "  ✅ Meta-rule pool: $poolRows rows in table two = $poolClaim declared permanent rules" -ForegroundColor Green
        } else {
            Write-Host "  🔴 Meta-rule pool mismatch: $poolRows table-two rows vs $poolClaim declared permanent rules" -ForegroundColor Red
            $failures.Add("Meta-rule pool consistency: $poolRows table-two rows vs $poolClaim declared")
        }
    } else {
        Write-Host "  ℹ️ Permanent meta-rule count could not be recognized (no regex match; check manually)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️ 元规则池.md is missing" -ForegroundColor Yellow
}

$readmes = Get-ChildItem -LiteralPath $Root -Filter "README.md" -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch "\\\.git\\|\\node_modules\\|\\已接手\\|\\状态-archive\\|CHANGELOG-2026|\\本地实例\\"
}
$total = $readmes.Count
$withFm = 0
foreach ($r in $readmes) {
    $firstLine = Get-Content -LiteralPath $r.FullName -TotalCount 1 -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($firstLine -eq "---") { $withFm++ }
}
if ($total -gt 0) {
    $pct = [math]::Round($withFm * 100 / $total)
    if ($pct -eq 100) {
        Write-Host "  ✅ README frontmatter coverage: $withFm / $total = 100%" -ForegroundColor Green
    } elseif ($pct -ge 80) {
        Write-Host "  🟡 README frontmatter coverage: $withFm / $total = $pct% (issue CW / ADR-028; incomplete)" -ForegroundColor Yellow
        $warnings.Add("README frontmatter coverage $pct% ($($total-$withFm) files remaining)")
    } else {
        Write-Host "  🔴 README frontmatter coverage: $withFm / $total = $pct% (issue CW; substantial gaps)" -ForegroundColor Red
        $failures.Add("README frontmatter coverage is only $pct%")
    }
}

if ($failures.Count -gt 0) { exit 10 }
if ($warnings.Count -gt 0) { exit 5 }
exit 0
