param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
$frameworkScope = Join-Path $PSScriptRoot "framework-scope.ps1"
if (-not (Test-Path -LiteralPath $frameworkScope -PathType Leaf)) {
  Write-Host "  🔴 framework-scope.ps1 is missing" -ForegroundColor Red
  exit 10
}
. $frameworkScope

$rootMode = Get-CzxtRootMode -Root $Root
if ($rootMode -notin @('template', 'project')) {
  Write-Host "  🔴 Invalid P4q root mode: $rootMode" -ForegroundColor Red
  exit 10
}
$isLegacyProject = Test-IsCzxtLegacyProjectProfile -Root $Root

$helpers = @(
  "os-main-entry-anchor.ps1",
  "governance-semantics-anchor.ps1",
  "os-semantics-anchor.ps1",
  "tool-governance-anchor.ps1",
  "tools-governance-history-anchor.ps1",
  "prop-status-anchor.ps1",
  "docs-edge-ops-anchor.ps1",
  "docs-edge-history-anchor.ps1",
  "adr-history-anchor.ps1",
  "product-docs-anchor.ps1",
  "change-records-history-anchor.ps1",
  "audit-coverage-anchor.ps1",
  "ledger-spec-anchor.ps1",
  "memory-spec-anchor.ps1",
  "workflow-spec-anchor.ps1",
  "architecture-anchor.ps1",
  "agents-playbook-anchor.ps1",
  "shared-skills-safety-anchor.ps1",
  "handoff-spec-anchor.ps1",
  "prop-active-safety-anchor.ps1",
  "prop-template-anchor.ps1",
  "p4b-business-debt-anchor.ps1"
)

if (-not $isLegacyProject) {
  $profileLabel = if ($rootMode -eq 'template') { 'template root mode' } else { 'generic project' }
  Write-Host "  ℹ️ ${profileLabel}: skipping source-project-specific requirements, PROP, and edge-document anchors" -ForegroundColor Gray
  $templateSkip = @(
    "docs-edge-ops-anchor.ps1",
    "docs-edge-history-anchor.ps1",
    "product-docs-anchor.ps1",
    "ledger-spec-anchor.ps1",
    "prop-template-anchor.ps1"
  )
  $helpers = @($helpers | Where-Object { $templateSkip -notcontains $_ })
}

foreach ($helperName in $helpers) {
  $helper = Join-Path (Split-Path -Parent $PSScriptRoot) "check-readme-indexes\$helperName"
  if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    Write-Host "  🔴 $helperName is missing" -ForegroundColor Red
    exit 10
  }
  & $helper -Root $Root
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

exit 0
