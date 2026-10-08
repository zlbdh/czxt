param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path,
  [object]$Failures = $null,
  [switch]$ShowLowList
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "framework-scope.ps1")

$localFailures = New-Object System.Collections.Generic.List[string]
$failureSink = $localFailures
if ($null -ne $Failures) {
  $failureSink = $Failures
}

$refScope = @("操作系统", "能力资产", "Docs", "确认改动", "交接区", "PM工作区")
$rootFiles = @("状态.md", "AGENTS.md", "README.md", "TASKS.md")

$allMd = @()
foreach ($s in $refScope) {
  $sp = Join-Path $Root $s
  if (Test-Path -LiteralPath $sp) {
    Get-ChildItem -Recurse -LiteralPath $sp -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
      if (Test-IsFrameworkArchivePath $_.FullName) { return }
      # WinPS 5.1 defaults to ANSI; explicitly read BOM-free Markdown as UTF-8 to preserve Unicode filenames.
      $c = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
      $allMd += @{ Path = $_.FullName; Content = $c }
    }
  }
}
foreach ($rf in $rootFiles) {
  $p = Join-Path $Root $rf
  if (Test-Path -LiteralPath $p -PathType Leaf) {
    $allMd += @{ Path = $p; Content = (Get-Content -LiteralPath $p -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) }
  }
}

$fwScan = @("操作系统", "能力资产")
$agentFiles = @()
foreach ($fw in $fwScan) {
  $fwPath = Join-Path $Root $fw
  if (Test-Path -LiteralPath $fwPath) {
    $agentFiles += Get-ChildItem -Recurse -LiteralPath $fwPath -Filter "*.md" -File -ErrorAction SilentlyContinue |
      Where-Object { -not (Test-IsFrameworkArchivePath $_.FullName) }
  }
}

$refStats = @{ High = 0; Mid = 0; Low = 0; Min = 0; Dead = 0 }
$lowList = New-Object System.Collections.Generic.List[string]
$deadList = New-Object System.Collections.Generic.List[string]

foreach ($af in $agentFiles) {
  $name = $af.Name
  $count = 0
  foreach ($md in $allMd) {
    if ($md.Path -eq $af.FullName) { continue }
    if ($md.Content -and $md.Content.Contains($name)) { $count++ }
  }
  $rel = $af.FullName.Replace("$Root\","").Replace("$Root/","")
  if ($count -ge 10) { $refStats.High++ }
  elseif ($count -ge 5) { $refStats.Mid++ }
  elseif ($count -ge 2) { $refStats.Low++; $lowList.Add("  $rel ($count)") }
  elseif ($count -eq 1) { $refStats.Min++; $lowList.Add("  $rel ($count very low)") }
  else { $refStats.Dead++; $deadList.Add("  $rel") }
}

Write-Host ("  Scanned {0} framework .md files (操作系统 + 能力资产)" -f $agentFiles.Count) -ForegroundColor Gray
Write-Host ("  ⭐ High activity (>=10): {0}" -f $refStats.High) -ForegroundColor Green
Write-Host ("  ✅ Medium frequency (5-9): {0}" -f $refStats.Mid) -ForegroundColor Green
Write-Host ("  🟢 Low frequency (2-4): {0}" -f $refStats.Low) -ForegroundColor Yellow
Write-Host ("  🟡 Very low frequency (1): {0}" -f $refStats.Min) -ForegroundColor Yellow
Write-Host ("  🔴 No references: {0}" -f $refStats.Dead) -ForegroundColor Red

if ($deadList.Count -gt 0) {
  Write-Host ""
  Write-Host "  🔴 Files with no references (consider removal or link repair):" -ForegroundColor Red
  $deadList | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  $failureSink.Add("P4c found $($refStats.Dead) unreferenced framework files; assess removal, consolidation, or link repair")
}

if ($ShowLowList -and $lowList.Count -gt 0) {
  Write-Host ""
  Write-Host "  🟢 Low/very-low-frequency files (manually review entry-point relevance):" -ForegroundColor Yellow
  $lowList | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}
elseif ($refStats.Min -gt 0) {
  Write-Host ""
  Write-Host "  🟡 Very-low-frequency files (assess consolidation or additional entry links):" -ForegroundColor Yellow
  $lowList | Where-Object { $_ -match 'very low' } | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}

if ($localFailures.Count -gt 0) {
  exit 10
}
exit 0
