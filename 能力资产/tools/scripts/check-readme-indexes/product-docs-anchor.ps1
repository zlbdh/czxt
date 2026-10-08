param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "Product-document anchor file is missing: $Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$rootReadme = Read-Text "README.md"
if ($rootReadme -match "目标.*v3\.0 完整版.*产品路线图") {
  Add-Failure "Root README still presents the historical v3.0 roadmap as the current goal"
}
if ($rootReadme -notmatch "当前推进以.*状态\.md.*TASKS\.md.*为准" -or $rootReadme -notmatch "历史 v3\.0.*产品路线图") {
  Add-Failure "Root README lacks both the current-goal source and historical v3.0 blueprint boundary"
}

$intro = Read-Text "Docs\2-产品文档\产品介绍.md"
foreach ($term in @("今日", "健康", "聊天", "记账", "时光")) {
  if ($intro -notmatch $term) { Add-Failure "Product introduction lacks a current bottom tab: $term" }
}
if ($intro -match "切到「我」tab") {
  Add-Failure "Product introduction still lists the profile as a bottom tab"
}
if ($intro -notmatch "右上角头像") {
  Add-Failure "Product introduction does not route profile/settings through the top-right avatar"
}
if ($intro -notmatch "API Key" -or $intro -notmatch "不要公开分享|tracked 文件") {
  Add-Failure "Product introduction lacks local backup/API-key safety boundaries"
}

$ia = Read-Text "Docs\2-产品文档\信息架构.md"
$iaHead = (($ia -split "`r?`n") | Select-Object -First 8) -join "`n"
if ($iaHead -notmatch "历史 IA 快照" -or $iaHead -notmatch "AppShell\.jsx") {
  Add-Failure "Information architecture lacks a historical-snapshot notice and current AppShell.jsx source near the top"
}
if ($ia -match "即将实现") {
  Add-Failure "Information architecture still promises upcoming implementation without a historical boundary"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Current product-document guidance anchors aligned" -ForegroundColor Green
exit 0
