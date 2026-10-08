param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path,
    [object]$Warnings = $null
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
. (Join-Path $PSScriptRoot "framework-scope.ps1")
. (Join-Path $PSScriptRoot "p4b-size-classification.ps1")

if ($null -eq $Warnings) {
    $Warnings = New-Object System.Collections.Generic.List[string]
}

$targetExtensions = Get-FrameworkTargetExtensions
$scopes = @("{{APP_REPO_DIR}}/src", "操作系统", "能力资产")
$sizeStats = @{ Total = 0; Safe = 0; Warn = 0; Soft = 0; Danger = 0 }
$areaStats = @{}
foreach ($scope in $scopes) {
    $areaStats[$scope] = @{ Total = 0; Safe = 0; Warn = 0; Soft = 0; Danger = 0 }
}
$sizeList = New-Object System.Collections.Generic.List[PSObject]
$businessDebtList = New-Object System.Collections.Generic.List[PSObject]

foreach ($scope in $scopes) {
    $scopePath = Join-Path $Root $scope
    if (-not (Test-Path -LiteralPath $scopePath)) { continue }
    Get-ChildItem -Recurse -LiteralPath $scopePath -File -ErrorAction SilentlyContinue |
        Where-Object { $targetExtensions -contains $_.Extension.ToLowerInvariant() } |
        ForEach-Object {
        $rel = $_.FullName.Replace("$Root\", "").Replace("$Root/", "")
        if (Test-IsFrameworkArchivePath $rel) { return }

        $sizeStats.Total++
        $areaStats[$scope].Total++
        $size = $_.Length
        Add-P4bSizeFinding -Rel $rel -Size $size -Scope $scope -SizeStats $sizeStats -AreaStats $areaStats -Warnings $Warnings -SizeList $sizeList -BusinessDebtList $businessDebtList
    }
}

Write-Host (("  Scanned {0} files (" -f $sizeStats.Total) + $scopes[0] + " + 操作系统 + 能力资产)") -ForegroundColor Gray
Write-Host ("  ✅ Safe (<6000B): {0}" -f $sizeStats.Safe) -ForegroundColor Green
if ($sizeStats.Warn -gt 0) { Write-Host ("  🟢 Caution (6000-6500B): {0}" -f $sizeStats.Warn) -ForegroundColor Green }
if ($sizeStats.Soft -gt 0) { Write-Host ("  🟡 Advisory (6500-8000B): {0}" -f $sizeStats.Soft) -ForegroundColor Yellow }
if ($sizeStats.Danger -gt 0) { Write-Host ("  🔴 Danger (>=8000B): {0}" -f $sizeStats.Danger) -ForegroundColor Red }
Write-Host "  📦 Summary by area:" -ForegroundColor Gray
foreach ($scope in $scopes) {
    $stats = $areaStats[$scope]
    if ($stats.Total -eq 0) { continue }
    $line = "    {0}: safe {1} / warn {2} / soft {3} / danger {4}" -f $scope, $stats.Safe, $stats.Warn, $stats.Soft, $stats.Danger
    if ($stats.Danger -gt 0) { Write-Host $line -ForegroundColor Red }
    elseif ($stats.Soft -gt 0) { Write-Host $line -ForegroundColor Yellow }
    elseif ($stats.Warn -gt 0) { Write-Host $line -ForegroundColor Green }
    else { Write-Host $line -ForegroundColor Green }
}

if ($businessDebtList.Count -gt 0) {
    $prodCount = @($businessDebtList | Where-Object { $_.Kind -eq "prod" }).Count
    $testCount = @($businessDebtList | Where-Object { $_.Kind -eq "test" }).Count
    $dangerCount = @($businessDebtList | Where-Object { $_.Level -eq "danger" }).Count
    $softCount = @($businessDebtList | Where-Object { $_.Level -eq "soft" }).Count
    Write-Host ""
    Write-Host "  🧭 {{APP_REPO_DIR}}/src business P4b governance summary (owner=Development PM 'Implementer'; does not indicate unfinished operating-system work)" -ForegroundColor Gray
    Write-Host ("    Danger/advisory: danger {0} / soft {1}; prod {2} / test {3}" -f $dangerCount, $softCount, $prodCount, $testCount) -ForegroundColor Gray
    Write-Host "    Assess separability and core responsibilities first; split when a feature change calls for it, not solely to reduce a number." -ForegroundColor Gray
    Write-Host "    Leading directory areas:" -ForegroundColor Gray
    $businessDebtList |
        Group-Object Domain |
        Sort-Object -Property @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Ascending = $true } |
        Select-Object -First 8 |
        ForEach-Object {
            Write-Host ("      - {0}: {1} items" -f $_.Name, $_.Count) -ForegroundColor Gray
        }
}

if ($sizeList.Count -gt 0) {
    Write-Host ""
    Write-Host "  📋 Files by descending byte size ({{APP_REPO_DIR}}/src + 操作系统 + 能力资产):" -ForegroundColor Gray
    $sizeList | Sort-Object Size -Descending | ForEach-Object {
        $line = "    {0} {1,5}B  {2}  ({3})" -f $_.Tag, $_.Size, $_.Rel, $_.Note
        if ($_.Tag -eq '🔴') { Write-Host $line -ForegroundColor Red }
        elseif ($_.Tag -eq '🟡') { Write-Host $line -ForegroundColor Yellow }
        else { Write-Host $line -ForegroundColor Green }
    }
}

exit 0
