$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeConfigContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  Invoke-HooksSmokeConfigPathContracts -Paths $Paths
  Invoke-HooksSmokeConfigManifestContracts -Root $Root -Paths $Paths
  Invoke-HooksSmokeConfigRuntimeContracts -Paths $Paths
  Invoke-HooksSmokeConfigRunnerContracts -Paths $Paths
}
