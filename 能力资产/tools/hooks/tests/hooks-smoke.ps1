param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {
}

$supportRoot = Join-Path $PSScriptRoot "support"
. (Join-Path $supportRoot "hooks-smoke-core.ps1")
Assert-HooksSmokeSupportFiles -SupportRoot $supportRoot
. (Join-Path $supportRoot "hooks-smoke-codex-stop-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-codex-tool-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-config-path-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-config-manifest-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-config-map.ps1")
. (Join-Path $supportRoot "hooks-smoke-config-runtime-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-config-runner-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-config-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-chat-output-accepted-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-chat-output-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-codex-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-claude-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-p4b-touch-contracts.ps1")
. (Join-Path $supportRoot "hooks-smoke-lifecycle-contracts.ps1")

$paths = Get-HooksSmokePaths -Root $Root
Invoke-HooksSmokeConfigContracts -Root $Root -Paths $paths
Invoke-HooksSmokeLifecycleContracts -Root $Root -Paths $paths

Write-Host "hooks-smoke PASS"
