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

Invoke-Contract '目录和文件 lease 暴露 RenameRelative API' {
  $directoryMethods = @([Czxt.B.AtomicDirectoryLease].GetMethods() |
      Where-Object { $_.Name -ceq 'RenameRelative' })
  $fileMethods = @([Czxt.B.AtomicOwnedFileLease].GetMethods() |
      Where-Object { $_.Name -ceq 'RenameRelative' })
  Assert-Contract ($directoryMethods.Count -eq 1) `
    'AtomicDirectoryLease 缺少唯一 RenameRelative 方法'
  Assert-Contract ($fileMethods.Count -eq 1) `
    'AtomicOwnedFileLease 缺少唯一 RenameRelative 方法'
}

Invoke-Contract '目录跨父级重命名保持身份并更新 FinalPath' {
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
        (Join-Path $sourcePath 'before'))) '目录旧路径仍然存在'
    Assert-Contract ([IO.Directory]::Exists($expected)) '目录新路径不存在'
    Assert-Contract ($owned.VolumeSerialNumber -eq $volume -and
        $owned.FileIndexHigh -eq $indexHigh -and
        $owned.FileIndexLow -eq $indexLow) '目录 identity 在重命名后改变'
    Assert-Contract ([string]::Equals(
        (ConvertFrom-NativeLeasePath $owned.FinalPath), $expected,
        [StringComparison]::OrdinalIgnoreCase)) '目录 FinalPath 未更新'
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

Invoke-Contract '目录重命名禁止覆盖现有目标' {
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
      '目录覆盖未以 Win32 错误拒绝'
    Assert-Contract ([IO.Directory]::Exists(
        (Join-Path $sourcePath 'owned'))) '目录覆盖失败后源对象丢失'
    Assert-Contract ([IO.Directory]::Exists(
        (Join-Path $destinationPath 'taken'))) '目录覆盖失败后目标对象丢失'
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

Invoke-Contract '关闭后代 lease 后父目录重命名保持身份和内容' {
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
      '强共享文件 lease 打开时父目录重命名未被拒绝'
    $ownedFile.Verify()
    $ownedFile.Dispose()
    $ownedFile = $null

    $ownedDirectory.RenameRelative($destinationParent, 'tree-after')

    $expectedDirectory = Join-Path $destinationPath 'tree-after'
    $expectedFile = Join-Path $expectedDirectory 'child.bin'
    Assert-Contract ([IO.Directory]::Exists($expectedDirectory)) `
      '关闭后代 lease 后父目录未完成重命名'
    Assert-Contract ([IO.File]::Exists($expectedFile)) `
      '父目录重命名后子文件不存在'
    Assert-Contract ($ownedDirectory.VolumeSerialNumber -eq $volume -and
        $ownedDirectory.FileIndexHigh -eq $indexHigh -and
        $ownedDirectory.FileIndexLow -eq $indexLow) `
      '父目录重命名后根目录 identity 改变'
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($expectedFile)) -ceq
        [Convert]::ToBase64String($bytes)) `
      '父目录重命名后子文件内容改变'
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

Invoke-Contract '文件跨父级重命名保持身份、长度、内容并更新 FinalPath' {
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
        (Join-Path $sourcePath 'before.bin'))) '文件旧路径仍然存在'
    Assert-Contract ([IO.File]::Exists($expected)) '文件新路径不存在'
    Assert-Contract ($owned.VolumeSerialNumber -eq $volume -and
        $owned.FileIndexHigh -eq $indexHigh -and
        $owned.FileIndexLow -eq $indexLow -and
        $owned.Length -eq $length) '文件 identity 或长度在重命名后改变'
    Assert-Contract ([string]::Equals(
        (ConvertFrom-NativeLeasePath $owned.FinalPath), $expected,
        [StringComparison]::OrdinalIgnoreCase)) '文件 FinalPath 未更新'
    $owned.Verify()
    $destinationParent.Verify()
    $owned.Dispose()
    $owned = $null
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($expected)) -ceq
        [Convert]::ToBase64String($bytes)) '文件内容在重命名后改变'
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

Invoke-Contract '文件重命名禁止覆盖现有目标' {
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
      '文件覆盖未以 Win32 错误拒绝'
    Assert-Contract ([IO.File]::Exists(
        (Join-Path $sourcePath 'owned.bin'))) '文件覆盖失败后源对象丢失'
    Assert-Contract ([Convert]::ToBase64String(
        [IO.File]::ReadAllBytes($collisionPath)) -ceq 'CQgH') `
      '文件覆盖失败后目标内容改变'
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

Invoke-Contract '文件重命名在进入系统调用前拒绝跨卷目标' {
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
      Write-Host '[SKIP] 当前环境没有可写的第二卷'
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
      '跨卷文件重命名未被同卷护栏拒绝'
    Assert-Contract ([IO.File]::Exists(
        (Join-Path $sourcePath 'owned.bin'))) '跨卷拒绝后源文件丢失'
    Assert-Contract (-not [IO.File]::Exists(
        (Join-Path $crossRoot 'moved.bin'))) '跨卷拒绝后创建了目标文件'
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

Invoke-Contract '目录和文件 lease 可从同一 handle 刷新提交后的真值' {
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
      '目录同句柄刷新改变了 identity'
    Assert-Contract ((ConvertFrom-NativeLeasePath $ownedDirectory.FinalPath) -ceq
        (Join-Path $destinationPath 'directory-after')) `
      '目录同句柄刷新未同步真实 FinalPath'
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
      '文件同句柄刷新改变了 identity'
    Assert-Contract ((ConvertFrom-NativeLeasePath $ownedFile.FinalPath) -ceq
        (Join-Path $destinationPath 'file-after.bin')) `
      '文件同句柄刷新未同步真实 FinalPath'
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

Invoke-Contract '目录 rename 已提交后异常会对账 ownership 并标记 committed' {
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
      ("目录提交后注入异常未原样抛出：{0}; exists={1}; final={2}; expected={3}" -f `
        $failure.Message, [IO.Directory]::Exists($expected),
        $owned.Native.FinalPath, $expected)
    Assert-Contract ($failure.Data['BorrowingRenameCommitted'] -eq $true) `
      '目录提交后异常未标记 committed'
    Assert-Contract ([IO.Directory]::Exists($expected)) '目录原生 rename 未提交'
    Assert-Contract ($owned.Path -ceq $expected -and
        $owned.CanonicalPath -ceq $expected) '目录 wrapper 未对账真实路径'
    Assert-Contract ($ownership.DirectoryLeases.ContainsKey($expected) -and
        -not $ownership.DirectoryLeases.ContainsKey(
          (Join-Path $sourcePath 'before'))) '目录 ownership index 未对账'
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

Invoke-Contract '文件 rename 已提交后异常会对账 ownership 并标记 committed' {
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
      ("文件提交后注入异常未原样抛出：{0}" -f $failure.Message)
    Assert-Contract ($failure.Data['BorrowingRenameCommitted'] -eq $true) `
      '文件提交后异常未标记 committed'
    Assert-Contract ([IO.File]::Exists($expected)) '文件原生 rename 未提交'
    Assert-Contract ($owned.Path -ceq $expected -and
        $owned.CanonicalPath -ceq $expected) '文件 wrapper 未对账真实路径'
    Assert-Contract ($ownership.FileLeases.ContainsKey($expected) -and
        -not $ownership.FileLeases.ContainsKey(
          (Join-Path $sourcePath 'before.bin'))) '文件 ownership index 未对账'
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
