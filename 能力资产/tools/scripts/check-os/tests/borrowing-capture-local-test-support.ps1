$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function New-BorrowingLocalSourceFixture {
  param([string]$Name, [bool]$Empty = $false)
  $path = Join-Path $script:BorrowingCaptureFixtureRoot $Name
  [void](New-Item -ItemType Directory -Path $path -Force)
  if (-not $Empty) {
    Write-BorrowingFixtureBytes (Join-Path $path 'a.txt') ([Text.Encoding]::UTF8.GetBytes('A'))
    Write-BorrowingFixtureBytes (Join-Path $path 'nested\z.bin') ([byte[]](0x00, 0xFF))
  }
  return $path
}

function Assert-BorrowingSnapshotIdentityEqual {
  param($Left, $Right, [bool]$ExpectedEqual, [string]$Context)
  Assert-CzxtEqual $Left.Entries.Count $Right.Entries.Count ($Context + ' count')
  Assert-CzxtEqual $ExpectedEqual ($Left.RootIdentityKey -ceq $Right.RootIdentityKey) `
    ($Context + ' root identity')
  for ($index = 0; $index -lt $Left.Entries.Count; $index++) {
    Assert-CzxtEqual $Left.Entries[$index].RelativePath $Right.Entries[$index].RelativePath `
      ($Context + ' relative path')
    Assert-CzxtEqual $ExpectedEqual `
      ($Left.Entries[$index].IdentityKey -ceq $Right.Entries[$index].IdentityKey) `
      ($Context + ' file identity ' + $index)
  }
}

function Import-BorrowingLocalTestModules {
  Import-BorrowingCaptureModules @(
    'common', 'file-safety', 'trusted-file-read', 'local'
  )
  foreach ($name in @(
      'New-BorrowingProductionLocalOperations', 'Get-BorrowingLocalSnapshot',
      'New-BorrowingLocalInput', 'New-BorrowingLocalCandidate',
      'Confirm-BorrowingLocalPromotion'
    )) { Assert-BorrowingCommandExists $name }
}
