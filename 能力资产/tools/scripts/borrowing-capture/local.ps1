$ErrorActionPreference = 'Stop'

foreach ($leaf in @('local-manifest.ps1', 'local-identity.ps1', 'local-capture.ps1')) {
  . (Join-Path $PSScriptRoot $leaf)
}
