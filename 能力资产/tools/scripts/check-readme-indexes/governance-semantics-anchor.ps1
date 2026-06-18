param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
. $common
$frameworkScope = Join-Path $PSScriptRoot "..\check-os\framework-scope.ps1"
if (-not (Test-Path -LiteralPath $frameworkScope -PathType Leaf)) { throw "缺少 framework-scope.ps1" }
. $frameworkScope

$helpers = @(
  "governance-semantics-requirements-tests.ps1",
  "governance-semantics-adr-retro.ps1",
  "governance-semantics-prop.ps1",
  "governance-semantics-active-entry.ps1"
)

if (Test-IsTemplateRoot -Root $Root) {
  Write-Host "  ℹ️ 模板根模式：跳过项目实例需求/测试与来源项目 PROP 正文语义锚点" -ForegroundColor Gray
  $helpers = @(
    "governance-semantics-adr-retro.ps1",
    "governance-semantics-active-entry.ps1"
  )
}

foreach ($helper in $helpers) {
  $path = Join-Path $PSScriptRoot $helper
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "缺少治理语义 helper：$helper" }
  . $path
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 治理语义锚点对齐（PROP/ADR/RETRO/需求测试入口）" -ForegroundColor Green
exit 0
