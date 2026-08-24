$ErrorActionPreference = 'Stop'

$borrowingItemCardsRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $borrowingItemCardsRoot 'borrowing-items.ps1')
