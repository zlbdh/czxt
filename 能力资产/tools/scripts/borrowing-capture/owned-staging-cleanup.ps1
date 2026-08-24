$ErrorActionPreference = 'Stop'

function global:Find-BorrowingOwnedDirectoryState {
  param($Ownership, [string]$Path)
  if (Test-BorrowingOwnedSamePath $Ownership.StagingLease.Path $Path) {
    return $Ownership.StagingLease
  }
  foreach ($owned in @($Ownership.DirectoryLeases.Values)) {
    if (Test-BorrowingOwnedSamePath ([string]$owned.Path) $Path) { return $owned }
  }
  return $null
}

function global:Get-BorrowingOwnedTreeInventory {
  param($Ownership, [string]$RootPath,
    [string]$Stage, [string]$ReasonCode)
  $root = Get-BorrowingSafePathInfo $RootPath Directory $Stage $ReasonCode
  $rootOwned = Find-BorrowingOwnedDirectoryState $Ownership $root.CanonicalPath
  if ($null -ne $rootOwned -and $root.IdentityKey -cne $rootOwned.IdentityKey) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup root identity changed'
  }
  $files = New-Object 'Collections.Generic.List[object]'
  $directories = New-Object 'Collections.Generic.List[object]'
  try { $items = @(Get-ChildItem -LiteralPath $root.CanonicalPath -Recurse -Force) }
  catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup tree is unreadable' }
  foreach ($item in $items) {
    $kind = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
    $safe = Get-BorrowingSafePathInfo $item.FullName $kind $Stage $ReasonCode
    if ((Get-BorrowingPathRelation $root.CanonicalPath $safe.CanonicalPath) -cne `
        'ancestor') {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup item escaped its root'
    }
    if ($kind -ceq 'Directory') { $directories.Add($safe) }
    else { $files.Add($safe) }
  }
  return [pscustomobject]@{
    Root = $root; RootOwned = $rootOwned
    Files = @($files | Sort-Object { ([string]$_.CanonicalPath).Length } -Descending)
    Directories = @($directories | Sort-Object {
        ([string]$_.CanonicalPath).Length
      } -Descending)
  }
}

function global:Remove-BorrowingOwnedFileState {
  param($Ownership, $Safe, [string]$Stage, [string]$ReasonCode)
  $owned = Find-BorrowingOwnedFileState $Ownership $Safe.CanonicalPath
  if ($null -ne $owned) {
    if ($owned.IdentityKey -cne $Safe.IdentityKey -or
        [uint64]$owned.Length -ne [uint64]$Safe.Length) {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup file identity changed'
    }
    if ($null -ne $owned.Native) {
      if ([bool]$owned.Native.Created) {
        try { $owned.Native.DeleteCreated(); $owned.Native = $null }
        catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup file delete failed' }
        return
      }
      try { $owned.Native.Dispose(); $owned.Native = $null }
      catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup file close failed' }
    }
    $snapshot = Read-BorrowingStableSafeFileSnapshot `
      $Safe.CanonicalPath $Stage $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $owned $snapshot) -or
        -not (Test-BorrowingOwnedBytesEqual ([byte[]]$owned.Bytes) $snapshot.Bytes)) {
      Throw-BorrowingFailure $Stage $ReasonCode 'closed owned cleanup file changed'
    }
    try { Remove-BsiBoundOwnedFile $snapshot 'capture owned cleanup file ' }
    catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup bound file delete failed' }
    return
  }
  $snapshot = Read-BorrowingStableSafeFileSnapshot `
    $Safe.CanonicalPath $Stage $ReasonCode
  if (-not (Test-BorrowingTrustedSnapshotEqual $Safe $snapshot)) {
    Throw-BorrowingFailure $Stage $ReasonCode 'unregistered cleanup file changed'
  }
  try { Remove-BsiBoundOwnedFile $snapshot 'capture owned cleanup file ' }
  catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup bound file delete failed' }
}

function global:Remove-BorrowingOwnedDirectoryState {
  param($Ownership, $Safe, [string]$Stage, [string]$ReasonCode)
  $owned = Find-BorrowingOwnedDirectoryState $Ownership $Safe.CanonicalPath
  if ($null -ne $owned) {
    if ($owned.IdentityKey -cne $Safe.IdentityKey -or -not [bool]$owned.Created) {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup directory identity changed'
    }
    if ($null -ne $owned.Native) {
      try { $owned.Native.DeleteCreated(); $owned.Native = $null }
      catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup directory delete failed' }
      return
    }
    try {
      Remove-BsiBoundEmptyDirectory ([pscustomobject]@{
          Path = $Safe.CanonicalPath; IdentityKey = $Safe.IdentityKey
        }) 'capture owned cleanup directory '
    }
    catch {
      Throw-BorrowingFailure $Stage $ReasonCode `
        'owned cleanup bound directory delete failed'
    }
    return
  }
  try {
    Remove-BsiBoundEmptyDirectory ([pscustomobject]@{
        Path = $Safe.CanonicalPath; IdentityKey = $Safe.IdentityKey
      }) 'capture owned cleanup directory '
  }
  catch {
    Throw-BorrowingFailure $Stage $ReasonCode `
      'owned cleanup bound directory delete failed'
  }
}

function global:Remove-BorrowingOwnedTree {
  param($Ownership, [string]$RootPath,
    [string]$Stage = 'cleanup', [string]$ReasonCode = 'cleanup-failed')
  $inventory = Get-BorrowingOwnedTreeInventory $Ownership $RootPath $Stage $ReasonCode
  foreach ($safe in $inventory.Files) {
    Remove-BorrowingOwnedFileState $Ownership $safe $Stage $ReasonCode
  }
  foreach ($safe in $inventory.Directories) {
    Remove-BorrowingOwnedDirectoryState $Ownership $safe $Stage $ReasonCode
  }
  $rootNow = Get-BorrowingSafePathInfo $inventory.Root.CanonicalPath Directory `
    $Stage $ReasonCode
  if ($rootNow.IdentityKey -cne $inventory.Root.IdentityKey) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned cleanup root changed before delete'
  }
  Remove-BorrowingOwnedDirectoryState $Ownership $rootNow $Stage $ReasonCode
}

function global:Remove-BorrowingOwnedGitRunnerArtifacts {
  param($Ownership, $Runner)
  foreach ($path in @(
      $Runner.RunnerRoot, $Runner.Home, $Runner.TrustedEmptyDirectory
    )) {
    if (Test-Path -LiteralPath $path -PathType Container) {
      Remove-BorrowingOwnedRegisteredSubtree $Ownership $path `
        capture source-unsafe
    }
  }
}

function global:Get-BorrowingOwnedDirectChildDirectory {
  param($Ownership, [string]$LeafName,
    [string]$Stage, [string]$ReasonCode)
  $path = Join-Path $Ownership.StagingLease.Path $LeafName
  $owned = Find-BorrowingOwnedDirectoryState $Ownership $path
  if ($null -eq $owned -or $null -eq $owned.Native) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned child directory lease is missing'
  }
  return $owned
}

function global:Get-BorrowingOwnedDirectChildFile {
  param($Ownership, [string]$LeafName,
    [string]$Stage, [string]$ReasonCode)
  $path = Join-Path $Ownership.StagingLease.Path $LeafName
  $owned = Find-BorrowingOwnedFileState $Ownership $path
  if ($null -eq $owned) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned child file lease is missing'
  }
  return $owned
}
