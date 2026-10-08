param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch { }
$warnings = @()
. (Join-Path $PSScriptRoot "framework-scope.ps1")
$isTemplateRoot = Test-IsTemplateRoot -Root $Root

function Invoke-ChildScript {
  param(
    [string]$Path,
    [string[]]$ScriptArgs = @()
  )
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs 2>&1
    $code = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  foreach ($line in @($output)) { Write-Host $line }
  return $code
}

foreach ($helperName in @(
  "hooks-doc-count-anchor.ps1",
  "hooks-sop-anchor.ps1",
  "hooks-event-matrix-anchor.ps1"
)) {
  $helper = Join-Path (Split-Path -Parent $PSScriptRoot) "check-readme-indexes\$helperName"
  if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    Write-Host "  🔴 $helperName is missing" -ForegroundColor Red
    exit 10
  }
  $code = Invoke-ChildScript -Path $helper -ScriptArgs @("-Root", $Root)
  if ($code -ne 0) { exit $code }
}

$smokeSupportRoot = Join-Path $Root "能力资产\tools\hooks\tests\support"
. (Join-Path $smokeSupportRoot "hooks-smoke-core.ps1")
. (Join-Path $smokeSupportRoot "hooks-smoke-config-map.ps1")
. (Join-Path $smokeSupportRoot "hooks-smoke-config-runtime-contracts.ps1")
$smokePaths = Get-HooksSmokePaths -Root $Root
Invoke-HooksSmokeConfigRuntimeContracts -Paths $smokePaths

$installHooks = Join-Path $Root "能力资产\tools\hooks\install-hooks.ps1"
if (-not (Test-Path -LiteralPath $installHooks -PathType Leaf)) {
  Write-Host "  🔴 install-hooks.ps1 is missing" -ForegroundColor Red
  exit 10
}
$businessGitPath = Join-Path $Root "{{APP_REPO_DIR}}\.git"
if ((Get-CzxtRootMode -Root $Root) -eq 'project' -and
    -not (Test-Path -LiteralPath $businessGitPath)) {
  Write-Host "  ℹ️ Generic project has no bound application repository; skipping Git hooks and related runtime checks" -ForegroundColor Gray
  exit 0
}
$code = Invoke-ChildScript -Path $installHooks -ScriptArgs @("-Mode", "Check", "-Root", $Root)
if ($code -eq 5 -and $isTemplateRoot) {
  $warnings += "Git hooks wrapper (template root has no instantiated application repository)"
} elseif ($code -ne 0) { exit 10 }

foreach ($entry in @(
  @{ Label = "scheduled framework check"; Path = "能力资产\tools\hooks\scheduled\install-scheduled-task.ps1" },
  @{ Label = "ADR watch task"; Path = "能力资产\tools\hooks\watch\install-adr-watch-task.ps1" }
)) {
  $scriptPath = Join-Path $Root $entry.Path
  if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Write-Host "  🔴 $($entry.Label) install script is missing" -ForegroundColor Red
    exit 10
  }
  $code = Invoke-ChildScript -Path $scriptPath -ScriptArgs @("-Mode", "Check", "-Root", $Root)
  if ($code -eq 5) {
    $warnings += $entry.Label
  } elseif ($code -ne 0) {
    exit 10
  }
}

if ($warnings.Count -gt 0) {
  Write-Host "  🟡 Hooks runtime checks have advisory findings: $($warnings -join ', ')" -ForegroundColor Yellow
  exit 5
}

Write-Host "  ✅ Hooks configuration and runtime anchors aligned" -ForegroundColor Green
exit 0
