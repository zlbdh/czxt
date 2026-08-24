$ErrorActionPreference = 'Stop'

function global:Invoke-BorrowingOwnedTreeSealInjection {
  param([string]$Name, $Seal)
  if ($script:BorrowingOwnedTreeSealTestInjections -is
      [Collections.IDictionary] -and
      $script:BorrowingOwnedTreeSealTestInjections.Contains($Name)) {
    & $script:BorrowingOwnedTreeSealTestInjections[$Name] $Seal.RootPath
  }
}

function global:Remove-BorrowingOwnedTreeSealFile {
  param($Entry)
  if ($null -eq $Entry.Native) {
    throw 'owned tree seal file handle is missing'
  }
  Assert-BspS $Entry.Path cleanup cleanup-failed
  $Entry.Native.DeleteBound()
  $Entry.Native = $null
}

function global:Remove-BorrowingOwnedTreeSealDirectory {
  param($Entry, [string]$Context)
  if ($null -eq $Entry.Handle) {
    throw ($Context + 'directory handle is missing')
  }
  Assert-BspS $Entry.Path cleanup cleanup-failed
  $opened = Get-BorrowingOwnedTreeSealDirectoryHandleSnapshot `
    $Entry.Handle cleanup cleanup-failed
  if (-not (Test-BorrowingOwnedSamePath $opened.Path $Entry.Path) -or
      $opened.IdentityKey -cne $Entry.IdentityKey) {
    throw ($Context + 'directory identity changed')
  }
  Set-BsiOwnedHandleDeletePending $Entry.Handle $Context
  $Entry.Handle.Dispose()
  $Entry.Handle = $null
}

function global:Remove-BorrowingOwnedTreeSeal {
  param($Seal)
  if ($null -eq $Seal -or [bool]$Seal.Closed -or [bool]$Seal.Removed) {
    Stop-BorrowingOwnedTreeSeal cleanup cleanup-failed `
      'owned tree seal cannot be removed'
  }
  try {
    Assert-BorrowingOwnedTreeSeal $Seal
    Invoke-BorrowingOwnedTreeSealInjection `
      'after-remove-assert-before-delete' $Seal

    # Never re-inventory into a deletion list here: members created after the
    # assertion are intentionally unknown and must survive a failed cleanup.
    foreach ($entry in @($Seal.Files.Values | Sort-Object Path)) {
      Remove-BorrowingOwnedTreeSealFile $entry
    }
    foreach ($entry in @($Seal.Directories.Values | Sort-Object {
          ([string]$_.Path).Length
        } -Descending)) {
      Remove-BorrowingOwnedTreeSealDirectory $entry `
        'capture sealed directory cleanup '
    }
    Assert-BspS $Seal.RootPath cleanup cleanup-failed
    $Seal.RootOwned.Native.Verify()
    Set-BsiOwnedHandleDeletePending $Seal.RootOwned.Native.Handle `
      'capture sealed root cleanup '
    $Seal.RootOwned.Native.Dispose()
    $Seal.RootOwned.Native = $null
    $Seal.Removed = $true
    $Seal.Closed = $true
  }
  catch {
    Close-BorrowingOwnedTreeSealHandles $Seal
    $Seal.Closed = $true
    Stop-BorrowingOwnedTreeSeal cleanup cleanup-failed `
      'owned tree seal exact removal failed'
  }
}

function global:Assert-BorrowingTreeSealMatchesOwnership {
  param($Ownership, $Seal, [string]$Stage = 'cleanup',
    [string]$ReasonCode = 'cleanup-failed')
  $expectedDirectories = @($Ownership.DirectoryLeases.Values | Where-Object {
      (Get-BorrowingPathRelation $Seal.RootPath $_.Path) -ceq 'ancestor'
    })
  $expectedFiles = @($Ownership.FileLeases.Values | Where-Object {
      (Get-BorrowingPathRelation $Seal.RootPath $_.Path) -ceq 'ancestor'
    })
  if ($Seal.Directories.Count -ne $expectedDirectories.Count -or
      $Seal.Files.Count -ne $expectedFiles.Count) {
    Throw-BorrowingFailure $Stage $ReasonCode `
      'owned cleanup tree contains unregistered members'
  }
  foreach ($entry in @($Seal.Directories.Values)) {
    $owned = Find-BorrowingOwnedDirectoryState $Ownership $entry.Path
    if ($null -eq $owned -or $owned.IdentityKey -cne $entry.IdentityKey) {
      Throw-BorrowingFailure $Stage $ReasonCode `
        'owned cleanup directory is not transaction-owned'
    }
  }
  foreach ($entry in @($Seal.Files.Values)) {
    $owned = Find-BorrowingOwnedFileState $Ownership $entry.Path
    if ($null -eq $owned -or $owned.IdentityKey -cne $entry.IdentityKey -or
        [uint64]$owned.Length -ne [uint64]$entry.Length -or
        (Get-BorrowingSha256Hex ([byte[]]$owned.Bytes)) -cne
          $entry.Sha256) {
      Throw-BorrowingFailure $Stage $ReasonCode `
        'owned cleanup file is not transaction-owned'
    }
  }
}

function global:Remove-BorrowingOwnedRegisteredSubtree {
  param($Ownership, [string]$RootPath, [string]$Stage = 'cleanup',
    [string]$ReasonCode = 'cleanup-failed')
  $seal = $null
  try {
    $seal = New-BorrowingOwnedTreeSeal $Ownership $RootPath $Stage $ReasonCode
    Assert-BorrowingTreeSealMatchesOwnership $Ownership $seal $Stage $ReasonCode
    Remove-BorrowingOwnedTreeSeal $seal
    $seal = $null
  }
  finally { if ($null -ne $seal) { Close-BorrowingOwnedTreeSeal $seal } }
}

function global:Remove-BorrowingOwnedAuxiliaryExactTree {
  param($Ownership)
  Remove-BorrowingOwnedRegisteredSubtree $Ownership $Ownership.StagingPath `
    cleanup cleanup-failed
}
