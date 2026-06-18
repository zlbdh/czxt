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

Write-Host ("  扫描 {0} 文件 ({{APP_REPO_DIR}}/src + 操作系统 + 能力资产)" -f $sizeStats.Total) -ForegroundColor Gray
Write-Host ("  ✅ 安全 (<6000B): {0}" -f $sizeStats.Safe) -ForegroundColor Green
if ($sizeStats.Warn -gt 0) { Write-Host ("  🟢 警戒 (6000-6500B): {0}" -f $sizeStats.Warn) -ForegroundColor Green }
if ($sizeStats.Soft -gt 0) { Write-Host ("  🟡 软建议 (6500-8000B): {0}" -f $sizeStats.Soft) -ForegroundColor Yellow }
if ($sizeStats.Danger -gt 0) { Write-Host ("  🔴 危险 (>=8000B): {0}" -f $sizeStats.Danger) -ForegroundColor Red }
Write-Host "  📦 分域摘要：" -ForegroundColor Gray
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
    Write-Host "  🧭 {{APP_REPO_DIR}}/src 业务 P4b 治理摘要（owner=开发 PM「实施者」；不代表操作系统未完成）" -ForegroundColor Gray
    Write-Host ("    红区/软区：danger {0} / soft {1}；prod {2} / test {3}" -f $dangerCount, $softCount, $prodCount, $testCount) -ForegroundColor Gray
    Write-Host "    原则：先判可拆性 vs 核心性；按功能触发拆，不为数字清零单独动业务代码。" -ForegroundColor Gray
    Write-Host "    目录域 Top：" -ForegroundColor Gray
    $businessDebtList |
        Group-Object Domain |
        Sort-Object -Property @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Name }; Ascending = $true } |
        Select-Object -First 8 |
        ForEach-Object {
            Write-Host ("      - {0}: {1} 个" -f $_.Name, $_.Count) -ForegroundColor Gray
        }
}

if ($sizeList.Count -gt 0) {
    Write-Host ""
    Write-Host "  📋 文件清单（按字节降序，{{APP_REPO_DIR}}/src + 操作系统 + 能力资产 范围）：" -ForegroundColor Gray
    $sizeList | Sort-Object Size -Descending | ForEach-Object {
        $line = "    {0} {1,5}B  {2}  ({3})" -f $_.Tag, $_.Size, $_.Rel, $_.Note
        if ($_.Tag -eq '🔴') { Write-Host $line -ForegroundColor Red }
        elseif ($_.Tag -eq '🟡') { Write-Host $line -ForegroundColor Yellow }
        else { Write-Host $line -ForegroundColor Green }
    }
}

exit 0
