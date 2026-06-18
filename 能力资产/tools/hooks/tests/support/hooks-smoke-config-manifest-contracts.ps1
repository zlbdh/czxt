$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeConfigManifestContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  $manifest = Get-Content -LiteralPath $Paths.Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
  $expectedHookIds = @(
    "readme-index-check",
    "adr-readme-dry-run",
    "pm-tracking-check",
    "handoff-zone-check",
    "chat-summary-check",
    "hook-install-check",
    "framework-health-check",
    "pre-release-check",
    "retro-cadence-check"
  )
  Assert-True ($manifest.hooks.Count -eq $expectedHookIds.Count) "manifest hook count drift: $($manifest.hooks.Count) != $($expectedHookIds.Count)"
  foreach ($hookId in $expectedHookIds) {
    Assert-True ($manifest.hooks.id -contains $hookId) "missing hook $hookId"
  }

  foreach ($hook in @($manifest.hooks)) {
    $scriptPath = Join-Path $Root ([string]$hook.script -replace '/', '\')
    Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "manifest script missing for $($hook.id): $($hook.script)"
  }

  $frameworkHook = @($manifest.hooks | Where-Object { $_.id -eq "framework-health-check" })[0]
  Assert-True ($null -ne $frameworkHook) "missing framework-health-check contract"
  Assert-True (@($frameworkHook.triggers).Count -eq 1 -and @($frameworkHook.triggers)[0] -eq "scheduled") "framework-health-check trigger drift"
  Assert-True ([string]$frameworkHook.script -eq "能力资产/tools/scripts/check-operating-system.ps1") "framework-health-check script drift"
  Assert-True (@($frameworkHook.allowExitCodes).Count -eq 1 -and [int]@($frameworkHook.allowExitCodes)[0] -eq 0) "framework-health-check allowExitCodes drift"
}
