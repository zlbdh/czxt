param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common
$frameworkScope = Join-Path $PSScriptRoot "..\check-os\framework-scope.ps1"
if (-not (Test-Path -LiteralPath $frameworkScope -PathType Leaf)) { throw "Missing framework-scope.ps1" }
. $frameworkScope

$helpers = @(
  "governance-semantics-requirements-tests.ps1",
  "governance-semantics-adr-retro.ps1",
  "governance-semantics-prop.ps1",
  "governance-semantics-active-entry.ps1"
)

if (-not (Test-IsCzxtLegacyProjectProfile -Root $Root)) {
  $profileLabel = if (Test-IsTemplateRoot -Root $Root) { 'template root mode' } else { 'generic project' }
  Write-Host "  ℹ️ ${profileLabel}: skipping source-project-specific requirements/tests and PROP body semantic anchors" -ForegroundColor Gray
  $helpers = @(
    "governance-semantics-adr-retro.ps1",
    "governance-semantics-active-entry.ps1"
  )
}

foreach ($helper in $helpers) {
  $path = Join-Path $PSScriptRoot $helper
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Governance semantics helper is missing: $helper" }
  . $path
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Governance semantic anchors aligned (PROP/ADR/RETRO/requirements and test entries)" -ForegroundColor Green
exit 0
