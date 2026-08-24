$ErrorActionPreference = 'Stop'

function global:Get-BorrowingOwnedRelativePath {
  param($Ownership, [string]$Path, [string]$Stage, [string]$ReasonCode)
  $root = [IO.Path]::GetFullPath([string]$Ownership.StagingLease.Path).TrimEnd('\')
  $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
  if ((Get-BorrowingPathRelation $root $full) -notin @('equal', 'ancestor')) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned content path escaped staging'
  }
  if ((Get-BorrowingPathRelation $root $full) -ceq 'equal') { return '' }
  return $full.Substring($root.Length + 1)
}

function global:Get-BorrowingOwnedDirectoryAtPath {
  param($Ownership, [string]$Path, [string]$Stage = 'capture',
    [string]$ReasonCode = 'source-unsafe')
  $relative = Get-BorrowingOwnedRelativePath $Ownership $Path $Stage $ReasonCode
  if ([string]::IsNullOrEmpty($relative)) {
    $Ownership.StagingLease.Native.Verify()
    return $Ownership.StagingLease
  }
  $current = $Ownership.StagingLease
  foreach ($segment in $relative.Split([char]'\')) {
    $expected = [IO.Path]::GetFullPath((Join-Path $current.Path $segment))
    if ($Ownership.DirectoryLeases.ContainsKey($expected)) {
      $current = $Ownership.DirectoryLeases[$expected]
      $current.Native.Verify()
      continue
    }
    if (Test-Path -LiteralPath $expected) {
      Throw-BorrowingFailure $Stage $ReasonCode `
        'owned directory target already exists outside this transaction'
    }
    $current = New-BorrowingOwnedDirectoryRelative $current $segment $Stage $ReasonCode
    $Ownership.DirectoryLeases.Add($current.Path, $current)
  }
  return $current
}

function global:New-BorrowingOwnedFileAtPath {
  param($Ownership, [string]$Path, [byte[]]$Bytes,
    [string]$Stage = 'capture', [string]$ReasonCode = 'source-unsafe')
  if ($null -eq $Bytes) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file bytes are missing'
  }
  $full = [IO.Path]::GetFullPath($Path)
  [void](Get-BorrowingOwnedRelativePath $Ownership $full $Stage $ReasonCode)
  if (Test-Path -LiteralPath $full) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file target already exists'
  }
  $parent = Get-BorrowingOwnedDirectoryAtPath $Ownership `
    (Split-Path -Parent $full) $Stage $ReasonCode
  $native = $null
  try {
    $native = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $parent.Native.Handle, [IO.Path]::GetFileName($full), $Bytes)
    $canonical = ConvertFrom-BorrowingOwnedNativePath $native.FinalPath $Stage $ReasonCode
    if (-not (Test-BorrowingOwnedSamePath $canonical $full)) {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned file physical path changed'
    }
    $owned = [pscustomobject]@{
      Path = $canonical; CanonicalPath = $canonical
      IdentityKey = Get-BorrowingOwnedNativeIdentity $native
      Length = [uint64]$native.Length; Bytes = [byte[]]$Bytes
      Created = $true; Native = $native
    }
    $Ownership.FileLeases.Add($owned.Path, $owned)
    $native = $null
    return $owned
  }
  catch {
    if ($null -ne $native) {
      try { $native.DeleteCreated() } catch { $native.Dispose() }
    }
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file relative create failed'
  }
}

function global:Test-BorrowingOwnedBytesEqual {
  param([byte[]]$Left, [byte[]]$Right)
  if ($null -eq $Left -or $null -eq $Right -or
      $Left.LongLength -ne $Right.LongLength) { return $false }
  for ($index = 0; $index -lt $Left.Length; $index++) {
    if ($Left[$index] -ne $Right[$index]) { return $false }
  }
  return $true
}

function global:Find-BorrowingOwnedFileState {
  param($Ownership, [string]$Path)
  foreach ($owned in @($Ownership.FileLeases.Values)) {
    if (Test-BorrowingOwnedSamePath ([string]$owned.Path) $Path) { return $owned }
  }
  return $null
}

function global:Open-BorrowingOwnedFileState {
  param($Owned, [string]$Stage, [string]$ReasonCode)
  if ($null -eq $Owned) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file state is missing'
  }
  if ($null -ne $Owned.Native) {
    try { $Owned.Native.Verify(); return $Owned }
    catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned file lease changed' }
  }
  $safe = Get-BorrowingSafePathInfo $Owned.Path File $Stage $ReasonCode
  if ($safe.IdentityKey -cne $Owned.IdentityKey -or
      [uint64]$safe.Length -ne [uint64]$Owned.Length) {
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file identity changed'
  }
  $native = $null
  try {
    $native = [Czxt.B.AtomicOwnedFileLease]::OpenExisting($safe.CanonicalPath)
    $canonical = ConvertFrom-BorrowingOwnedNativePath `
      $native.FinalPath $Stage $ReasonCode
    if (-not (Test-BorrowingOwnedSamePath $canonical $safe.CanonicalPath) -or
        (Get-BorrowingOwnedNativeIdentity $native) -cne $Owned.IdentityKey -or
        [uint64]$native.Length -ne [uint64]$Owned.Length) {
      Throw-BorrowingFailure $Stage $ReasonCode 'opened owned file changed'
    }
    $Owned.Native = $native
    $native = $null
    return $Owned
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file reopen failed'
  }
  finally { if ($null -ne $native) { $native.Dispose() } }
}

function global:Get-BorrowingOwnedFileBytes {
  param($Ownership, [string]$Path, [string]$Stage, [string]$ReasonCode)
  $full = [IO.Path]::GetFullPath($Path)
  $owned = Find-BorrowingOwnedFileState $Ownership $full
  if ($null -ne $owned) {
    if ($null -ne $owned.Native) {
      try { $owned.Native.Verify() }
      catch { Throw-BorrowingFailure $Stage $ReasonCode 'owned file lease changed' }
      return ,([byte[]]$owned.Bytes)
    }
    $snapshot = Read-BorrowingStableSafeFileSnapshot $full $Stage $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $owned $snapshot) -or
        -not (Test-BorrowingOwnedBytesEqual ([byte[]]$owned.Bytes) $snapshot.Bytes)) {
      Throw-BorrowingFailure $Stage $ReasonCode 'closed owned file changed'
    }
    return ,([byte[]]$snapshot.Bytes)
  }
  return ,([byte[]](Read-BorrowingStableSafeFileBytes $full $Stage $ReasonCode))
}

function global:Set-BorrowingOperationProperty {
  param($Operations, [string]$Name, [scriptblock]$Value)
  if ($null -ne $Operations.PSObject.Properties[$Name]) {
    $Operations.$Name = $Value
  }
  else { $Operations | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function global:New-BorrowingOwnedCandidateOperations {
  param($BaseOperations, $Ownership)
  $operations = if ($null -eq $BaseOperations) { [pscustomobject]@{} }
    else { $BaseOperations.PSObject.Copy() }
  $ownedForClosure = $Ownership
  Set-BorrowingOperationProperty $operations GetSafePathInfo {
    param($Path, $Kind, $Stage, $Reason)
    Get-BorrowingSafePathInfo $Path $Kind $Stage $Reason
  }
  Set-BorrowingOperationProperty $operations GetChildren {
    param($Path) Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop
  }
  Set-BorrowingOperationProperty $operations GetPathRelation {
    param($Left, $Right) Get-BorrowingPathRelation $Left $Right
  }
  Set-BorrowingOperationProperty $operations CreateDirectory ({
      param($Path)
      [void](Get-BorrowingOwnedDirectoryAtPath $ownedForClosure $Path capture source-unsafe)
    }.GetNewClosure())
  Set-BorrowingOperationProperty $operations WriteAllBytes ({
      param($Path, [byte[]]$Bytes)
      [void](New-BorrowingOwnedFileAtPath $ownedForClosure $Path $Bytes capture source-unsafe)
    }.GetNewClosure())
  Set-BorrowingOperationProperty $operations ReadAllBytes ({
      param($Path, $Stage = 'capture', $Reason = 'source-unsafe')
      return ,([byte[]](Get-BorrowingOwnedFileBytes `
            $ownedForClosure $Path $Stage $Reason))
    }.GetNewClosure())
  Set-BorrowingOperationProperty $operations CopyFile ({
      param($SourcePath, $DestinationPath, [byte[]]$ExpectedBytes)
      if ($null -eq $ExpectedBytes) {
        Throw-BorrowingFailure capture source-unsafe 'Local bound source bytes are missing'
      }
      [void](New-BorrowingOwnedFileAtPath $ownedForClosure $DestinationPath `
          $ExpectedBytes capture source-unsafe)
    }.GetNewClosure())
  Set-BorrowingOperationProperty $operations ReplaceFileBytes ({
      param($Path, [byte[]]$Bytes)
      $snapshot = Read-BorrowingStableSafeFileSnapshot $Path capture source-unsafe
      Remove-BsiBoundOwnedFile $snapshot 'capture owned replacement '
      [void](New-BorrowingOwnedFileAtPath $ownedForClosure $Path $Bytes `
          capture source-unsafe)
    }.GetNewClosure())
  return $operations
}

function global:Initialize-BorrowingOwnedGitRunnerDirectories {
  param($Ownership)
  foreach ($relative in @(
      'git-runner-root', 'git-runner-root\cwd', 'git-runner-home',
      'git-trusted-empty'
    )) {
    [void](Get-BorrowingOwnedDirectoryAtPath $Ownership `
        (Join-Path $Ownership.StagingLease.Path $relative) capture source-unsafe)
  }
}

function global:Initialize-BorrowingOwnedGitDirectories {
  param($Ownership)
  Initialize-BorrowingOwnedGitRunnerDirectories $Ownership
  foreach ($relative in @('快照', '快照\repository.git')) {
    [void](Get-BorrowingOwnedDirectoryAtPath $Ownership `
        (Join-Path $Ownership.StagingLease.Path $relative) capture source-unsafe)
  }
}

function global:Reset-BorrowingOwnedIndexes {
  param($Ownership)
  $directories = New-Object `
    'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($owned in @($Ownership.DirectoryLeases.Values)) {
    $directories.Add([string]$owned.Path, $owned)
  }
  $files = New-Object `
    'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($owned in @($Ownership.FileLeases.Values)) {
    $files.Add([string]$owned.Path, $owned)
  }
  $Ownership.DirectoryLeases = $directories
  $Ownership.FileLeases = $files
}

function global:Update-BorrowingOwnedPathPrefix {
  param($Ownership, [string]$OldPrefix, [string]$NewPrefix)
  foreach ($owned in @($Ownership.DirectoryLeases.Values) +
      @($Ownership.FileLeases.Values)) {
    if ((Get-BorrowingPathRelation $OldPrefix $owned.Path) -eq 'ancestor') {
      $suffix = $owned.Path.Substring($OldPrefix.Length)
      $owned.Path = $NewPrefix + $suffix
      $owned.CanonicalPath = $owned.Path
    }
  }
  Reset-BorrowingOwnedIndexes $Ownership
}

function global:Invoke-BorrowingOwnedRenameTestInjection {
  param([string]$Name, $Context)
  if ($script:BorrowingOwnedStagingTestInjections -is `
      [Collections.IDictionary] -and
      $script:BorrowingOwnedStagingTestInjections.Contains($Name)) {
    & $script:BorrowingOwnedStagingTestInjections[$Name] $Context
  }
}

function global:Set-BorrowingOwnedRenameCommittedFailure {
  param([Exception]$Failure, $Owned)
  $Failure.Data['BorrowingRenameCommitted'] = $true
  $Failure.Data['BorrowingRenameState'] = 'committed'
  $Failure.Data['BorrowingRenameCommittedPath'] = [string]$Owned.Path
  $Failure.Data['BorrowingRenameCommittedIdentityKey'] = `
    [string]$Owned.IdentityKey
}

function global:Sync-BorrowingOwnedDirectoryRenameState {
  param($Ownership, $Directory, [string]$OldPath, [string]$ExpectedPath,
    [string]$Stage, [string]$ReasonCode)
  $Directory.Native.RefreshFromHandle()
  $newPath = ConvertFrom-BorrowingOwnedNativePath `
    $Directory.Native.FinalPath $Stage $ReasonCode
  if (-not (Test-BorrowingOwnedSamePath $newPath $ExpectedPath)) {
    return $false
  }
  $Directory.Path = $newPath
  $Directory.CanonicalPath = $newPath
  $Directory.IdentityKey = Get-BorrowingOwnedNativeIdentity $Directory.Native
  Update-BorrowingOwnedPathPrefix $Ownership $OldPath $newPath
  return $true
}

function global:Sync-BorrowingOwnedFileRenameState {
  param($Ownership, $Owned, [string]$ExpectedPath,
    [string]$Stage, [string]$ReasonCode)
  $Owned.Native.RefreshFromHandle()
  $newPath = ConvertFrom-BorrowingOwnedNativePath `
    $Owned.Native.FinalPath $Stage $ReasonCode
  if (-not (Test-BorrowingOwnedSamePath $newPath $ExpectedPath)) {
    return $false
  }
  $Owned.Path = $newPath
  $Owned.CanonicalPath = $newPath
  $Owned.IdentityKey = Get-BorrowingOwnedNativeIdentity $Owned.Native
  $Owned.Length = [uint64]$Owned.Native.Length
  if ($null -ne $Ownership) { Reset-BorrowingOwnedIndexes $Ownership }
  return $true
}

function global:Close-BorrowingOwnedDescendantDirectories {
  param($Ownership, [string]$RootPath, [switch]$KeepRoot)
  $targets = @($Ownership.DirectoryLeases.Values | Where-Object {
      $relation = Get-BorrowingPathRelation $RootPath $_.Path
      $relation -eq 'ancestor' -or (-not $KeepRoot -and $relation -eq 'equal')
    } | Sort-Object { ([string]$_.Path).Length } -Descending)
  foreach ($owned in $targets) { Close-BorrowingOwnedDirectoryState $owned }
}

function global:Close-BorrowingOwnedDescendantFiles {
  param($Ownership, [string]$RootPath)
  foreach ($owned in @($Ownership.FileLeases.Values)) {
    if ($null -eq $owned.Native) { continue }
    if ((Get-BorrowingPathRelation $RootPath $owned.Path) -ceq 'ancestor') {
      $owned.Native.Dispose()
      $owned.Native = $null
    }
  }
}

function global:Move-BorrowingOwnedDirectoryTree {
  param($Ownership, $Directory, $DestinationParent, [string]$LeafName,
    [string]$Stage, [string]$ReasonCode)
  $oldPath = [string]$Directory.Path
  $expected = [IO.Path]::GetFullPath(
    (Join-Path $DestinationParent.Path $LeafName))
  try {
    Close-BorrowingOwnedDescendantFiles $Ownership $Directory.Path
    Close-BorrowingOwnedDescendantDirectories $Ownership $Directory.Path -KeepRoot
    $DestinationParent.Native.Verify()
    $Directory.Native.RenameRelative($DestinationParent.Native, $LeafName)
    Invoke-BorrowingOwnedRenameTestInjection `
      'after-native-rename-before-state-update' ([pscustomobject]@{
          Kind = 'directory'; Ownership = $Ownership; Owned = $Directory
          OldPath = $oldPath; ExpectedPath = $expected
        })
    if (-not (Sync-BorrowingOwnedDirectoryRenameState $Ownership $Directory `
          $oldPath $expected $Stage $ReasonCode)) {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned directory rename path changed'
    }
    return $Directory
  }
  catch {
    $renameFailure = $_
    $committed = $false
    try {
      $committed = Sync-BorrowingOwnedDirectoryRenameState $Ownership `
        $Directory $oldPath $expected $Stage $ReasonCode
    }
    catch { $committed = $false }
    if ($committed) {
      Set-BorrowingOwnedRenameCommittedFailure `
        $renameFailure.Exception $Directory
      throw $renameFailure.Exception
    }
    if ($renameFailure.Exception.Data['BorrowingStage']) {
      throw $renameFailure.Exception
    }
    Throw-BorrowingFailure $Stage $ReasonCode 'owned directory rename failed'
  }
}

function global:Move-BorrowingOwnedFileState {
  param($Owned, $DestinationParent, [string]$LeafName,
    [string]$Stage, [string]$ReasonCode, $Ownership)
  $expected = [IO.Path]::GetFullPath(
    (Join-Path $DestinationParent.Path $LeafName))
  try {
    $DestinationParent.Native.Verify()
    $Owned.Native.RenameRelative($DestinationParent.Native, $LeafName)
    Invoke-BorrowingOwnedRenameTestInjection `
      'after-native-rename-before-state-update' ([pscustomobject]@{
          Kind = 'file'; Ownership = $Ownership; Owned = $Owned
          ExpectedPath = $expected
        })
    if (-not (Sync-BorrowingOwnedFileRenameState $Ownership $Owned `
          $expected $Stage $ReasonCode)) {
      Throw-BorrowingFailure $Stage $ReasonCode 'owned file rename path changed'
    }
    return $Owned
  }
  catch {
    $renameFailure = $_
    $committed = $false
    try {
      $committed = Sync-BorrowingOwnedFileRenameState $Ownership $Owned `
        $expected $Stage $ReasonCode
    }
    catch { $committed = $false }
    if ($committed) {
      Set-BorrowingOwnedRenameCommittedFailure $renameFailure.Exception $Owned
      throw $renameFailure.Exception
    }
    if ($renameFailure.Exception.Data['BorrowingStage']) {
      throw $renameFailure.Exception
    }
    Throw-BorrowingFailure $Stage $ReasonCode 'owned file rename failed'
  }
}

. (Join-Path $ownedStagingModuleRoot 'owned-staging-cleanup.ps1')
