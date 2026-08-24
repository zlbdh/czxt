$ErrorActionPreference = 'Stop'

$sourceCardModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $sourceCardModuleRoot 'source-card-skeleton.ps1')
. (Join-Path $sourceCardModuleRoot 'source-card-renderer.ps1')
