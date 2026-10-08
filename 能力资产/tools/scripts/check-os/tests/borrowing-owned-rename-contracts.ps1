$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..\..\..\..\..'))
$scriptsRoot = Join-Path $repoRoot '能力资产\tools\scripts'
. (Join-Path $scriptsRoot 'borrowing-owned-directory.ps1')
. (Join-Path $scriptsRoot 'borrowing-owned-file.ps1')

function global:Throw-BorrowingFailure {
  param([string]$Stage, [string]$ReasonCode, [string]$Message)
  $failure = [InvalidOperationException]::new($Message)
  $failure.Data['BorrowingStage'] = $Stage
  $failure.Data['BorrowingReasonCode'] = $ReasonCode
  throw $failure
}

function global:Get-BorrowingPathRelation {
  param([string]$Left, [string]$Right)
  $leftFull = [IO.Path]::GetFullPath($Left).TrimEnd('\')
  $rightFull = [IO.Path]::GetFullPath($Right).TrimEnd('\')
  if ([string]::Equals(
      $leftFull, $rightFull, [StringComparison]::OrdinalIgnoreCase)) {
    return 'equal'
  }
  if ($rightFull.StartsWith(
      $leftFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
    return 'ancestor'
  }
  if ($leftFull.StartsWith(
      $rightFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
    return 'descendant'
  }
  return 'disjoint'
}

function global:ConvertFrom-BorrowingOwnedNativePath {
  param([string]$Path, [string]$Stage, [string]$ReasonCode)
  $canonical = ConvertFrom-NativeLeasePath $Path
  return [IO.Path]::GetFullPath($canonical)
}

function global:Test-BorrowingOwnedSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals(
    [IO.Path]::GetFullPath($Left), [IO.Path]::GetFullPath($Right),
    [StringComparison]::OrdinalIgnoreCase)
}

function global:Get-BorrowingOwnedNativeIdentity {
  param($Native)
  return '{0:x8}:{1:x8}:{2:x8}' -f $Native.VolumeSerialNumber,
    $Native.FileIndexHigh, $Native.FileIndexLow
}

function global:Close-BorrowingOwnedDirectoryState {
  param($Owned)
  if ($null -ne $Owned -and $null -ne $Owned.Native) {
    $Owned.Native.Dispose()
    $Owned.Native = $null
  }
}

$ownedStagingModuleRoot = Join-Path $scriptsRoot 'borrowing-capture'
. (Join-Path $ownedStagingModuleRoot 'owned-staging-content.ps1')

$script:Passed = 0

function Assert-Contract {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function ConvertFrom-NativeLeasePath {
  param([string]$Path)
  if ($Path.StartsWith('\\?\UNC\', [StringComparison]::OrdinalIgnoreCase)) {
    return '\\' + $Path.Substring(8)
  }
  if ($Path.StartsWith('\\?\', [StringComparison]::OrdinalIgnoreCase)) {
    return $Path.Substring(4)
  }
  return $Path
}

function Get-RootException {
  param([Exception]$Exception)
  $current = $Exception
  while ($null -ne $current.InnerException) {
    $current = $current.InnerException
  }
  return $current
}

function Invoke-Contract {
  param([string]$Name, [scriptblock]$Body)
  & $Body
  $script:Passed++
  Write-Host ("[PASS] {0}" -f $Name)
}

function New-ContractRoot {
  $path = Join-Path ([IO.Path]::GetTempPath()) (
    'czxt-owned-rename-' + [Guid]::NewGuid().ToString('N'))
  [void][IO.Directory]::CreateDirectory($path)
  return $path
}

Invoke-Contract 'Directory and file leases expose the RenameRelative API' {
  $directoryMethods = @([Czxt.B.AtomicDirectoryLease].GetMethods() |
      Where-Object { $_.Name -ceq 'RenameRelative' })
  $fileMethods = @([Czxt.B.AtomicOwnedFileLease].GetMethods() |
      Where-Object { $_.Name -ceq 'RenameRelative' })
  Assert-Contract ($directoryMethods.Count -eq 1) `
    'AtomicDirectoryLease lacks a unique RenameRelative method'
  Assert-Contract ($fileMethods.Count -eq 1) `
    'AtomicOwnedFileLease lacks a unique RenameRelative method'
}

Invoke-Contract 'Moving a directory between parents preserves identity and updates FinalPath' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $owned = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $sourceParent, 'before')
    $volume = $owned.VolumeSerialNumber
    $indexHigh = $owned.FileIndexHigh
    $indexLow = $owned.FileIndexLow

    $owned.RenameRelative($destinationParent, 'after')

    $expected = [IO.Path]::GetFullPath((Join-Path $destinationPath 'after'))
    Assert-Contract (-not [IO.Directory]::Exists(
        (Join-Path $sourcePath 'before'))) 'Old directory path still exists'
    Assert-Contract ([IO.Directory]::Exists($expected)) 'New directory path does not exist'
    Assert-Contract ($owned.VolumeSerialNumber -eq $volume -and
        $owned.FileIndexHigh -eq $indexHigh -and
        $owned.FileIndexLow -eq $indexLow) 'Directory identity changed after rename'
    Assert-Contract ([string]::Equals(
        (ConvertFrom-NativeLeasePath $owned.FinalPath), $expected,
        [StringComparison]::OrdinalIgnoreCase)) 'Directory FinalPath was not updated'
    $owned.Verify()
    $destinationParent.Verify()
    $owned.DeleteCreated()
    $owned = $null
  }
  finally {
    if ($null -ne $owned) {
      try { $owned.DeleteCreated() } catch { $owned.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) {
      [IO.Directory]::Delete($root, $true)
    }
  }
}

Invoke-Contract 'Directory rename must not overwrite an existing target' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    [void][IO.Directory]::CreateDirectory((Join-Path $destinationPath 'taken'))
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $owned = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $sourceParent, 'owned')
    $failure = $null
    try { $owned.RenameRelative($destinationParent, 'taken') }
    catch { $failure = Get-RootException $_.Exception }

    Assert-Contract ($failure -is [ComponentModel.Win32Exception]) `
      'Directory overwrite was not rejected with a Win32 error'
    Assert-Contract ([IO.Directory]::Exists(
        (Join-Path $sourcePath 'owned'))) 'Source object was lost after directory overwrite failed'
    Assert-Contract ([IO.Directory]::Exists(
        (Join-Path $destinationPath 'taken'))) 'Target object was lost after directory overwrite failed'
    $owned.Verify()
    $owned.DeleteCreated()
    $owned = $null
  }
  finally {
    if ($null -ne $owned) {
      try { $owned.DeleteCreated() } catch { $owned.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) {
      [IO.Directory]::Delete($root, $true)
    }
  }
}

Invoke-Contract 'Renaming the parent after closing descendant leases preserves identity and content' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $ownedDirectory = $null
  $ownedFile = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $ownedDirectory = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $sourceParent, 'tree-before')
    $bytes = [Text.Encoding]::UTF8.GetBytes('movable-child-contract')
    $ownedFile = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $ownedDirectory.Handle, 'child.bin', $bytes)
    $volume = $ownedDirectory.VolumeSerialNumber
    $indexHigh = $ownedDirectory.FileIndexHigh
    $indexLow = $ownedDirectory.FileIndexLow
    $blocked = $null
    try { $ownedDirectory.RenameRelative($destinationParent, 'tree-after') }
    catch { $blocked = Get-RootException $_.Exception }
    Assert-Contract ($blocked -is [ComponentModel.Win32Exception]) `
      'Parent rename was not rejected while a restrictive file-sharing lease was open'
    $ownedFile.Verify()
    $ownedFile.Dispose()
    $ownedFile = $null

    $ownedDirectory.RenameRelative($destinationParent, 'tree-after')

    $expectedDirectory = Join-Path $destinationPath 'tree-after'
    $expectedFile = Join-Path $expectedDirectory 'child.bin'
    Assert-Contract ([IO.Directory]::Exists($expectedDirectory)) `
      'Parent rename did not complete after descendant leases were closed'
    Assert-Contract ([IO.File]::Exists($expectedFile)) `
      'Child file is missing after parent rename'
    Assert-Contract ($ownedDirectory.VolumeSerialNumber -eq $volume -and
        $ownedDirectory.FileIndexHigh -eq $indexHigh -and
        $ownedDirectory.FileIndexLow -eq $indexLow) `
      'Root directory identity changed after parent rename'
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($expectedFile)) -ceq
        [Convert]::ToBase64String($bytes)) `
      'Child file content changed after parent rename'
    $ownedDirectory.Verify()
    $ownedDirectory.Dispose()
    $ownedDirectory = $null
  }
  finally {
    if ($null -ne $ownedFile) {
      try { $ownedFile.DeleteCreated() } catch { $ownedFile.Dispose() }
    }
    if ($null -ne $ownedDirectory) {
      try { $ownedDirectory.DeleteCreated() } catch { $ownedDirectory.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) {
      [IO.Directory]::Delete($root, $true)
    }
  }
}

Invoke-Contract 'Moving a file between parents preserves identity, length, and content and updates FinalPath' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $bytes = [Text.Encoding]::UTF8.GetBytes('owned-rename-contract')
    $owned = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $sourceParent.Handle, 'before.bin', $bytes)
    $volume = $owned.VolumeSerialNumber
    $indexHigh = $owned.FileIndexHigh
    $indexLow = $owned.FileIndexLow
    $length = $owned.Length

    $owned.RenameRelative($destinationParent, 'after.bin')

    $expected = [IO.Path]::GetFullPath(
      (Join-Path $destinationPath 'after.bin'))
    Assert-Contract (-not [IO.File]::Exists(
        (Join-Path $sourcePath 'before.bin'))) 'Old file path still exists'
    Assert-Contract ([IO.File]::Exists($expected)) 'New file path does not exist'
    Assert-Contract ($owned.VolumeSerialNumber -eq $volume -and
        $owned.FileIndexHigh -eq $indexHigh -and
        $owned.FileIndexLow -eq $indexLow -and
        $owned.Length -eq $length) 'File identity or length changed after rename'
    Assert-Contract ([string]::Equals(
        (ConvertFrom-NativeLeasePath $owned.FinalPath), $expected,
        [StringComparison]::OrdinalIgnoreCase)) 'File FinalPath was not updated'
    $owned.Verify()
    $destinationParent.Verify()
    $owned.Dispose()
    $owned = $null
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($expected)) -ceq
        [Convert]::ToBase64String($bytes)) 'File content changed after rename'
    [IO.File]::Delete($expected)
  }
  finally {
    if ($null -ne $owned) {
      try { $owned.DeleteCreated() } catch { $owned.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) {
      [IO.Directory]::Delete($root, $true)
    }
  }
}

Invoke-Contract 'File rename must not overwrite an existing target' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $collisionPath = Join-Path $destinationPath 'taken.bin'
    [IO.File]::WriteAllBytes($collisionPath, [byte[]](9, 8, 7))
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $owned = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $sourceParent.Handle, 'owned.bin', [byte[]](1, 2, 3))
    $failure = $null
    try { $owned.RenameRelative($destinationParent, 'taken.bin') }
    catch { $failure = Get-RootException $_.Exception }

    Assert-Contract ($failure -is [ComponentModel.Win32Exception]) `
      'File overwrite was not rejected with a Win32 error'
    Assert-Contract ([IO.File]::Exists(
        (Join-Path $sourcePath 'owned.bin'))) 'Source object was lost after file overwrite failed'
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($collisionPath)) -ceq 'CQgH') `
      'Target content changed after file overwrite failed'
    $owned.Verify()
    $owned.DeleteCreated()
    $owned = $null
  }
  finally {
    if ($null -ne $owned) {
      try { $owned.DeleteCreated() } catch { $owned.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) {
      [IO.Directory]::Delete($root, $true)
    }
  }
}

Invoke-Contract 'File rename rejects cross-volume targets before entering the system call' {
  $sourceRoot = New-ContractRoot
  $crossRoot = $null
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourceDrive = [IO.Path]::GetPathRoot($sourceRoot)
    $repoDrive = [IO.Path]::GetPathRoot($repoRoot)
    if ([string]::Equals(
        $sourceDrive, $repoDrive, [StringComparison]::OrdinalIgnoreCase)) {
      Write-Host '[SKIP] No writable second volume is available in this environment'
      return
    }
    $sourcePath = Join-Path $sourceRoot 'source'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    $crossRoot = Join-Path $repoRoot (
      '项目区\本地实例\.owned-rename-cross-volume-' +
      [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($crossRoot)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($crossRoot)
    $owned = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $sourceParent.Handle, 'owned.bin', [byte[]](4, 5, 6))
    $failure = $null
    try { $owned.RenameRelative($destinationParent, 'moved.bin') }
    catch { $failure = Get-RootException $_.Exception }

    Assert-Contract ($failure -is [IO.IOException] -and
        $failure.Message -match 'different volume') `
      'Same-volume guard did not reject the cross-volume file rename'
    Assert-Contract ([IO.File]::Exists(
        (Join-Path $sourcePath 'owned.bin'))) 'Source file was lost after cross-volume rejection'
    Assert-Contract (-not [IO.File]::Exists(
        (Join-Path $crossRoot 'moved.bin'))) 'Target file was created after cross-volume rejection'
    $owned.Verify()
    $owned.DeleteCreated()
    $owned = $null
  }
  finally {
    if ($null -ne $owned) {
      try { $owned.DeleteCreated() } catch { $owned.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ($null -ne $crossRoot -and [IO.Directory]::Exists($crossRoot)) {
      [IO.Directory]::Delete($crossRoot, $true)
    }
    if ([IO.Directory]::Exists($sourceRoot)) {
      [IO.Directory]::Delete($sourceRoot, $true)
    }
  }
}

Invoke-Contract 'Directory and file leases refresh committed state from the same handle' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $ownedDirectory = $null
  $ownedFile = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)

    $ownedDirectory = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $sourceParent, 'directory-before')
    $directoryIdentity = '{0:x8}:{1:x8}:{2:x8}' -f `
      $ownedDirectory.VolumeSerialNumber, $ownedDirectory.FileIndexHigh,
      $ownedDirectory.FileIndexLow
    [void][Czxt.B.AtomicDirectoryLease]::RenameHandleRelative(
      $ownedDirectory.Handle, $ownedDirectory.VolumeSerialNumber,
      $destinationParent, 'directory-after')
    $ownedDirectory.RefreshFromHandle()
    Assert-Contract (('{0:x8}:{1:x8}:{2:x8}' -f `
          $ownedDirectory.VolumeSerialNumber, $ownedDirectory.FileIndexHigh,
          $ownedDirectory.FileIndexLow) -ceq $directoryIdentity) `
      'Same-handle directory refresh changed identity'
    Assert-Contract ((ConvertFrom-NativeLeasePath $ownedDirectory.FinalPath) -ceq
        (Join-Path $destinationPath 'directory-after')) `
      'Same-handle directory refresh did not synchronize the actual FinalPath'
    $ownedDirectory.Verify()

    $ownedFile = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $sourceParent.Handle, 'file-before.bin', [byte[]](7, 8, 9))
    $fileIdentity = '{0:x8}:{1:x8}:{2:x8}' -f `
      $ownedFile.VolumeSerialNumber, $ownedFile.FileIndexHigh,
      $ownedFile.FileIndexLow
    [void][Czxt.B.AtomicDirectoryLease]::RenameHandleRelative(
      $ownedFile.Handle, $ownedFile.VolumeSerialNumber,
      $destinationParent, 'file-after.bin')
    $ownedFile.RefreshFromHandle()
    Assert-Contract (('{0:x8}:{1:x8}:{2:x8}' -f `
          $ownedFile.VolumeSerialNumber, $ownedFile.FileIndexHigh,
          $ownedFile.FileIndexLow) -ceq $fileIdentity) `
      'Same-handle file refresh changed identity'
    Assert-Contract ((ConvertFrom-NativeLeasePath $ownedFile.FinalPath) -ceq
        (Join-Path $destinationPath 'file-after.bin')) `
      'Same-handle file refresh did not synchronize the actual FinalPath'
    $ownedFile.Verify()

    $ownedFile.DeleteCreated(); $ownedFile = $null
    $ownedDirectory.DeleteCreated(); $ownedDirectory = $null
  }
  finally {
    if ($null -ne $ownedFile) {
      try { $ownedFile.DeleteCreated() } catch { $ownedFile.Dispose() }
    }
    if ($null -ne $ownedDirectory) {
      try { $ownedDirectory.DeleteCreated() } catch { $ownedDirectory.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) { [IO.Directory]::Delete($root, $true) }
  }
}

Invoke-Contract 'An exception after directory rename commits reconciles ownership and marks committed' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $native = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $sourceParent, 'before')
    $owned = [pscustomobject]@{
      Path = Join-Path $sourcePath 'before'
      CanonicalPath = Join-Path $sourcePath 'before'
      IdentityKey = '{0:x8}:{1:x8}:{2:x8}' -f `
        $native.VolumeSerialNumber, $native.FileIndexHigh, $native.FileIndexLow
      Native = $native
    }
    $directories = New-Object `
      'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
    $directories.Add($owned.Path, $owned)
    $ownership = [pscustomobject]@{
      DirectoryLeases = $directories
      FileLeases = New-Object `
        'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
    }
    $destination = [pscustomobject]@{
      Path = $destinationPath; Native = $destinationParent
    }
    $script:BorrowingOwnedStagingTestInjections = @{
      'after-native-rename-before-state-update' = {
        param($Context)
        if ($Context.Kind -ceq 'directory') {
          throw [InvalidOperationException]::new('directory-injected-after-commit')
        }
      }
    }
    $failure = $null
    try {
      [void](Move-BorrowingOwnedDirectoryTree $ownership $owned $destination `
          'after' promotion source-unsafe)
    }
    catch { $failure = $_.Exception }
    finally { $script:BorrowingOwnedStagingTestInjections = $null }

    $expected = Join-Path $destinationPath 'after'
    Assert-Contract ($failure.Message -ceq 'directory-injected-after-commit') `
      ("Injected post-commit directory exception was not propagated unchanged: {0}; exists={1}; final={2}; expected={3}" -f `
        $failure.Message, [IO.Directory]::Exists($expected),
        $owned.Native.FinalPath, $expected)
    Assert-Contract ($failure.Data['BorrowingRenameCommitted'] -eq $true) `
      'Post-commit directory exception was not marked committed'
    Assert-Contract ([IO.Directory]::Exists($expected)) 'Native directory rename did not commit'
    Assert-Contract ($owned.Path -ceq $expected -and
        $owned.CanonicalPath -ceq $expected) 'Directory wrapper did not reconcile the actual path'
    Assert-Contract ($ownership.DirectoryLeases.ContainsKey($expected) -and
        -not $ownership.DirectoryLeases.ContainsKey(
          (Join-Path $sourcePath 'before'))) 'Directory ownership index was not reconciled'
    $owned.Native.Verify()
    $owned.Native.DeleteCreated(); $owned.Native = $null
  }
  finally {
    $script:BorrowingOwnedStagingTestInjections = $null
    if ($null -ne $owned -and $null -ne $owned.Native) {
      try { $owned.Native.DeleteCreated() } catch { $owned.Native.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) { [IO.Directory]::Delete($root, $true) }
  }
}

Invoke-Contract 'An exception after file rename commits reconciles ownership and marks committed' {
  $root = New-ContractRoot
  $sourceParent = $null
  $destinationParent = $null
  $owned = $null
  try {
    $sourcePath = Join-Path $root 'source'
    $destinationPath = Join-Path $root 'destination'
    [void][IO.Directory]::CreateDirectory($sourcePath)
    [void][IO.Directory]::CreateDirectory($destinationPath)
    $sourceParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting($sourcePath)
    $destinationParent = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      $destinationPath)
    $native = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $sourceParent.Handle, 'before.bin', [byte[]](1, 3, 5))
    $owned = [pscustomobject]@{
      Path = Join-Path $sourcePath 'before.bin'
      CanonicalPath = Join-Path $sourcePath 'before.bin'
      IdentityKey = '{0:x8}:{1:x8}:{2:x8}' -f `
        $native.VolumeSerialNumber, $native.FileIndexHigh, $native.FileIndexLow
      Length = [uint64]$native.Length
      Native = $native
    }
    $files = New-Object `
      'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
    $files.Add($owned.Path, $owned)
    $ownership = [pscustomobject]@{
      DirectoryLeases = New-Object `
        'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
      FileLeases = $files
    }
    $destination = [pscustomobject]@{
      Path = $destinationPath; Native = $destinationParent
    }
    $script:BorrowingOwnedStagingTestInjections = @{
      'after-native-rename-before-state-update' = {
        param($Context)
        if ($Context.Kind -ceq 'file') {
          throw [InvalidOperationException]::new('file-injected-after-commit')
        }
      }
    }
    $failure = $null
    try {
      [void](Move-BorrowingOwnedFileState $owned $destination 'after.bin' `
          promotion source-unsafe $ownership)
    }
    catch { $failure = $_.Exception }
    finally { $script:BorrowingOwnedStagingTestInjections = $null }

    $expected = Join-Path $destinationPath 'after.bin'
    Assert-Contract ($failure.Message -ceq 'file-injected-after-commit') `
      ("Injected post-commit file exception was not propagated unchanged: {0}" -f $failure.Message)
    Assert-Contract ($failure.Data['BorrowingRenameCommitted'] -eq $true) `
      'Post-commit file exception was not marked committed'
    Assert-Contract ([IO.File]::Exists($expected)) 'Native file rename did not commit'
    Assert-Contract ($owned.Path -ceq $expected -and
        $owned.CanonicalPath -ceq $expected) 'File wrapper did not reconcile the actual path'
    Assert-Contract ($ownership.FileLeases.ContainsKey($expected) -and
        -not $ownership.FileLeases.ContainsKey(
          (Join-Path $sourcePath 'before.bin'))) 'File ownership index was not reconciled'
    $owned.Native.Verify()
    $owned.Native.DeleteCreated(); $owned.Native = $null
  }
  finally {
    $script:BorrowingOwnedStagingTestInjections = $null
    if ($null -ne $owned -and $null -ne $owned.Native) {
      try { $owned.Native.DeleteCreated() } catch { $owned.Native.Dispose() }
    }
    if ($null -ne $destinationParent) { $destinationParent.Dispose() }
    if ($null -ne $sourceParent) { $sourceParent.Dispose() }
    if ([IO.Directory]::Exists($root)) { [IO.Directory]::Delete($root, $true) }
  }
}

Write-Host ("borrowing owned rename contracts: {0}/10 passed" -f $script:Passed)
