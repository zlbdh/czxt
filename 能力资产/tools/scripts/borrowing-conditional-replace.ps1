$ErrorActionPreference = 'Stop'

function Test-BsiSnapshotMaterialEqual {
  param($Expected, $Actual)
  return $null -ne $Expected -and $null -ne $Actual -and
    $Expected.IdentityKey -ceq $Actual.IdentityKey -and
    [uint64]$Expected.Length -eq [uint64]$Actual.Length -and
    (Test-BcvBytesEqual $Expected.Bytes $Actual.Bytes)
}

function Assert-BsiSnapshotMaterialEqual {
  param($Expected, $Actual, [string]$Message)
  Assert-BsiCondition (Test-BsiSnapshotMaterialEqual $Expected $Actual) $Message
}

function New-BsiReplacementSiblingPath {
  param([string]$Directory, [string]$Kind)
  for ($attempt = 0; $attempt -lt 16; $attempt++) {
    $path = Join-Path $Directory `
      ('.staging-replace-' + $Kind + '-' + [guid]::NewGuid().ToString('N') + '.tmp')
    if (-not [IO.File]::Exists($path) -and -not [IO.Directory]::Exists($path)) {
      return [IO.Path]::GetFullPath($path)
    }
  }
  throw 'cannot allocate a same-directory path for conditional replacement'
}

function Remove-BsiOwnedSnapshotFile {
  param($Owned, [string]$Context)
  Remove-BsiBoundOwnedFile $Owned $Context
}

function Get-BsiHandleBoundCurrentSnapshot {
  param($Expected, [string]$Context)
  $lock = $null
  try {
    $lock = Open-BsiOwnedFileLock $Expected $Context
    return $lock.Snapshot
  }
  finally { Close-BsiOwnedFileLock $lock }
}

function Move-BsiOwnedSnapshotOnceToEmptyPath {
  param($Expected, [string]$DestinationPath, [string]$Context)
  $destination = [IO.Path]::GetFullPath($DestinationPath)
  Assert-BsiCondition (-not [IO.File]::Exists($destination) -and
      -not [IO.Directory]::Exists($destination)) `
    ($Context + 'target path is already occupied')
  $current = Get-BsiHandleBoundCurrentSnapshot $Expected $Context
  Assert-BsiSnapshotMaterialEqual $Expected $current `
    ($Context + 'source object changed before the move')
  [IO.File]::Move($current.Path, $destination)
  $moved = Get-BsiStableSnapshot $destination
  Assert-BsiSnapshotMaterialEqual $Expected $moved `
    ($Context + 'moved object is not the trusted source object')
  return $moved
}

function Move-BsiOwnedSnapshotToEmptyPath {
  param($Expected, [string]$DestinationPath, [string]$Context)
  try {
    return Move-BsiOwnedSnapshotOnceToEmptyPath `
      $Expected $DestinationPath $Context
  }
  catch {
    $primaryFailure = $_
    $sourceExists = [IO.File]::Exists([string]$Expected.Path) -or
      [IO.Directory]::Exists([string]$Expected.Path)
    if (-not $sourceExists -and [IO.File]::Exists($DestinationPath)) {
      try {
        $observed = Get-BsiStableSnapshot $DestinationPath
        [void](Move-BsiOwnedSnapshotOnceToEmptyPath $observed `
            ([string]$Expected.Path) ($Context + 'compensation '))
      }
      catch {
        throw ($Context + ' failed and compensation also failed; no objects were overwritten: ' +
          $_.Exception.Message)
      }
    }
    throw $primaryFailure
  }
}

function Restore-BsiDisplacedTarget {
  param(
    [string]$TargetPath, $Displaced, $Installed,
    [byte[]]$ReplacementBytes
  )
  $currentDisplaced = Get-BsiStableSnapshot $Displaced.Path
  Assert-BsiSnapshotMaterialEqual $Displaced $currentDisplaced `
    'conditional replacement backup changed before restoration'
  $currentInstalled = Get-BsiStableSnapshot $TargetPath
  Assert-BsiSnapshotMaterialEqual $Installed $currentInstalled `
    'conditional replacement target changed before restoration'
  $rescuePath = New-BsiReplacementSiblingPath `
    (Split-Path -Parent $TargetPath) 'rescue'
  $rescued = Move-BsiOwnedSnapshotToEmptyPath $currentInstalled `
    $rescuePath 'conditional replacement move installed aside '
  try {
    $restored = Move-BsiOwnedSnapshotToEmptyPath $currentDisplaced `
      $TargetPath 'conditional replacement restore displaced '
  }
  catch {
    $restoreFailure = $_
    if (-not [IO.File]::Exists($TargetPath) -and
        -not [IO.Directory]::Exists($TargetPath) -and
        [IO.File]::Exists($rescuePath)) {
      try {
        [void](Move-BsiOwnedSnapshotToEmptyPath $rescued `
            $TargetPath 'conditional replacement restore installed ')
      }
      catch {
        throw ('conditional replacement restoration failed and installed could not be returned; no objects were overwritten: ' +
          $_.Exception.Message)
      }
    }
    throw $restoreFailure
  }
  Assert-BsiSnapshotMaterialEqual $Displaced $restored `
    'conditional replacement could not restore the old object'
  Remove-BsiOwnedSnapshotFile $rescued 'conditional replacement rescue '
  return $restored
}

function Assert-BsiPendingReplaceTransaction {
  param($Transaction)
  Assert-BsiCondition ($null -ne $Transaction -and
      $Transaction.State -ceq 'pending') 'conditional replacement transaction is not pending'
}

function Start-BsiConditionalReplace {
  param(
    $Temporary, [string]$TargetPath, $ExpectedSnapshot,
    [byte[]]$ReplacementBytes
  )
  Assert-BsiCondition ($null -ne $Temporary -and $null -ne $ExpectedSnapshot) `
    'conditional replacement is missing a trusted snapshot'
  $targetDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $TargetPath))
  $temporaryDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $Temporary.Path))
  Assert-BsiCondition ([string]::Equals($targetDirectory, $temporaryDirectory,
      [StringComparison]::OrdinalIgnoreCase)) 'conditional replacement temporary file is not in the target directory'

  $current = Get-BsiStableSnapshot $TargetPath
  Assert-BsiSnapshotUnchanged $ExpectedSnapshot $current
  Assert-BsiTemporaryUnchanged $Temporary $ReplacementBytes
  $backupPath = New-BsiReplacementSiblingPath $targetDirectory 'backup'
  # 2026-07-21 by Codex — Use only non-overwriting moves; stop on an ABA reservation race and preserve the objects.
  $displaced = Move-BsiOwnedSnapshotToEmptyPath $current `
    $backupPath 'conditional replacement move target aside '
  try {
    $installed = Move-BsiOwnedSnapshotToEmptyPath $Temporary `
      $TargetPath 'conditional replacement install temporary '
  }
  catch {
    $installFailure = $_
    if (-not [IO.File]::Exists($TargetPath) -and
        -not [IO.Directory]::Exists($TargetPath) -and
        [IO.File]::Exists($backupPath)) {
      try {
        [void](Move-BsiOwnedSnapshotToEmptyPath $displaced `
            $TargetPath 'conditional replacement restore target after installation failure ')
      }
      catch {
        throw ('conditional replacement installation failed and the old object could not be returned; no objects were overwritten: ' +
          $_.Exception.Message)
      }
    }
    throw $installFailure
  }

  return [pscustomobject]@{
    State = 'pending'
    TargetPath = $installed.Path
    Displaced = $displaced
    Installed = $installed
    ReplacementBytes = $ReplacementBytes
  }
}

function Undo-BsiConditionalReplace {
  param($Transaction)
  Assert-BsiPendingReplaceTransaction $Transaction
  $restored = Restore-BsiDisplacedTarget $Transaction.TargetPath `
    $Transaction.Displaced $Transaction.Installed $Transaction.ReplacementBytes
  $Transaction.State = 'undone'
  return $restored
}

function Complete-BsiConditionalReplace {
  param($Transaction)
  Assert-BsiPendingReplaceTransaction $Transaction
  $targetLock = $null
  $current = $null
  $cleanupFailure = $null
  try {
    $targetLock = Open-BsiOwnedFileLock $Transaction.Installed `
      'conditional replacement commit target '
    $current = $targetLock.Snapshot
    Remove-BsiOwnedSnapshotFile $Transaction.Displaced 'conditional replacement backup '
    $Transaction.State = 'completed'
  }
  catch {
    $cleanupFailure = $_
  }
  finally {
    Close-BsiOwnedFileLock $targetLock -IgnoreCloseFailure
  }
  if ($null -ne $cleanupFailure) {
    try {
      [void](Undo-BsiConditionalReplace $Transaction)
    }
    catch {
      throw ('conditional replacement backup cleanup and restoration both failed; objects were preserved: ' +
        $_.Exception.Message)
    }
    throw $cleanupFailure
  }
  return $current
}

function Invoke-BsiConditionalReplace {
  param(
    $Temporary, [string]$TargetPath, $ExpectedSnapshot,
    [byte[]]$ReplacementBytes
  )
  $transaction = Start-BsiConditionalReplace $Temporary $TargetPath `
    $ExpectedSnapshot $ReplacementBytes
  return Complete-BsiConditionalReplace $transaction
}
