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
    Add-Failure "产品文档锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$rootReadme = Read-Text "README.md"
if ($rootReadme -match "目标.*v3\.0 完整版.*产品路线图") {
  Add-Failure "根 README 仍把历史 v3.0 路线图写成当前目标"
}
if ($rootReadme -notmatch "当前推进以.*状态\.md.*TASKS\.md.*为准" -or $rootReadme -notmatch "历史 v3\.0.*产品路线图") {
  Add-Failure "根 README 未同时声明当前目标来源与历史 v3.0 蓝图边界"
}

$intro = Read-Text "Docs\2-产品文档\产品介绍.md"
foreach ($term in @("今日", "健康", "聊天", "记账", "时光")) {
  if ($intro -notmatch $term) { Add-Failure "产品介绍缺当前底部 Tab：$term" }
}
if ($intro -match "切到「我」tab") {
  Add-Failure "产品介绍仍写「我」为底部 Tab"
}
if ($intro -notmatch "右上角头像") {
  Add-Failure "产品介绍未声明档案/设置从右上角头像进入"
}
if ($intro -notmatch "API Key" -or $intro -notmatch "不要公开分享|tracked 文件") {
  Add-Failure "产品介绍未说明备份/API Key 本机安全边界"
}

$ia = Read-Text "Docs\2-产品文档\信息架构.md"
$iaHead = (($ia -split "`r?`n") | Select-Object -First 8) -join "`n"
if ($iaHead -notmatch "历史 IA 快照" -or $iaHead -notmatch "AppShell\.jsx") {
  Add-Failure "信息架构首屏未声明历史快照与 AppShell.jsx 当前来源"
}
if ($ia -match "即将实现") {
  Add-Failure "信息架构仍含未加历史边界的「即将实现」"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ 产品文档当前口径锚点对齐" -ForegroundColor Green
exit 0
