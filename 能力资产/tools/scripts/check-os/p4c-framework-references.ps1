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
      $c = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
      $allMd += @{ Path = $_.FullName; Content = $c }
    }
  }
}
foreach ($rf in $rootFiles) {
  $p = Join-Path $Root $rf
  if (Test-Path -LiteralPath $p -PathType Leaf) {
    $allMd += @{ Path = $p; Content = (Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue) }
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
  elseif ($count -eq 1) { $refStats.Min++; $lowList.Add("  $rel ($count 极低)") }
  else { $refStats.Dead++; $deadList.Add("  $rel") }
}

Write-Host ("  扫描 {0} 个 framework .md 文件（操作系统 + 能力资产）" -f $agentFiles.Count) -ForegroundColor Gray
Write-Host ("  ⭐ 高活跃 (>=10): {0}" -f $refStats.High) -ForegroundColor Green
Write-Host ("  ✅ 中频 (5-9): {0}" -f $refStats.Mid) -ForegroundColor Green
Write-Host ("  🟢 低频 (2-4): {0}" -f $refStats.Low) -ForegroundColor Yellow
Write-Host ("  🟡 极低频 (1): {0}" -f $refStats.Min) -ForegroundColor Yellow
Write-Host ("  🔴 0 引用: {0}" -f $refStats.Dead) -ForegroundColor Red

if ($deadList.Count -gt 0) {
  Write-Host ""
  Write-Host "  🔴 0 引用文件清单（考虑删除或修复链接）：" -ForegroundColor Red
  $deadList | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  $failureSink.Add("P4c framework 死代码 $($refStats.Dead) 项（0 引用，需删除、合并或修复链接）")
}

if ($ShowLowList -and $lowList.Count -gt 0) {
  Write-Host ""
  Write-Host "  🟢 低频/极低频文件清单（用于人工审计入口合理性）：" -ForegroundColor Yellow
  $lowList | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}
elseif ($refStats.Min -gt 0) {
  Write-Host ""
  Write-Host "  🟡 极低频文件清单（建议评估整合或补入口）：" -ForegroundColor Yellow
  $lowList | Where-Object { $_ -match '极低' } | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}

if ($localFailures.Count -gt 0) {
  exit 10
}
exit 0
