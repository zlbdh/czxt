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
  throw '无法分配条件替换同目录路径'
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
    ($Context + '目标路径已被占用')
  $current = Get-BsiHandleBoundCurrentSnapshot $Expected $Context
  Assert-BsiSnapshotMaterialEqual $Expected $current `
    ($Context + '源对象在移动前改变')
  [IO.File]::Move($current.Path, $destination)
  $moved = Get-BsiStableSnapshot $destination
  Assert-BsiSnapshotMaterialEqual $Expected $moved `
    ($Context + '移动后的对象不是受信源对象')
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
            ([string]$Expected.Path) ($Context + '补偿 '))
      }
      catch {
        throw ($Context + '失败且补偿失败；对象均未覆盖：' +
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
    '条件替换 backup 在恢复前改变'
  $currentInstalled = Get-BsiStableSnapshot $TargetPath
  Assert-BsiSnapshotMaterialEqual $Installed $currentInstalled `
    '条件替换目标在恢复前改变'
  $rescuePath = New-BsiReplacementSiblingPath `
    (Split-Path -Parent $TargetPath) 'rescue'
  $rescued = Move-BsiOwnedSnapshotToEmptyPath $currentInstalled `
    $rescuePath '条件替换移出 installed '
  try {
    $restored = Move-BsiOwnedSnapshotToEmptyPath $currentDisplaced `
      $TargetPath '条件替换恢复 displaced '
  }
  catch {
    $restoreFailure = $_
    if (-not [IO.File]::Exists($TargetPath) -and
        -not [IO.Directory]::Exists($TargetPath) -and
        [IO.File]::Exists($rescuePath)) {
      try {
        [void](Move-BsiOwnedSnapshotToEmptyPath $rescued `
            $TargetPath '条件替换恢复 installed ')
      }
      catch {
        throw ('条件替换恢复失败且 installed 无法归位；对象均未覆盖：' +
          $_.Exception.Message)
      }
    }
    throw $restoreFailure
  }
  Assert-BsiSnapshotMaterialEqual $Displaced $restored `
    '条件替换未能恢复旧对象'
  Remove-BsiOwnedSnapshotFile $rescued '条件替换 rescue '
  return $restored
}

function Assert-BsiPendingReplaceTransaction {
  param($Transaction)
  Assert-BsiCondition ($null -ne $Transaction -and
      $Transaction.State -ceq 'pending') '条件替换事务不是 pending'
}

function Start-BsiConditionalReplace {
  param(
    $Temporary, [string]$TargetPath, $ExpectedSnapshot,
    [byte[]]$ReplacementBytes
  )
  Assert-BsiCondition ($null -ne $Temporary -and $null -ne $ExpectedSnapshot) `
    '条件替换缺少受信快照'
  $targetDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $TargetPath))
  $temporaryDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $Temporary.Path))
  Assert-BsiCondition ([string]::Equals($targetDirectory, $temporaryDirectory,
      [StringComparison]::OrdinalIgnoreCase)) '条件替换临时文件不在目标同目录'

  $current = Get-BsiStableSnapshot $TargetPath
  Assert-BsiSnapshotUnchanged $ExpectedSnapshot $current
  Assert-BsiTemporaryUnchanged $Temporary $ReplacementBytes
  $backupPath = New-BsiReplacementSiblingPath $targetDirectory 'backup'
  # 2026-07-21 by Codex — 仅用不覆盖 move，ABA 占位必须停止并保留对象。
  $displaced = Move-BsiOwnedSnapshotToEmptyPath $current `
    $backupPath '条件替换移出 target '
  try {
    $installed = Move-BsiOwnedSnapshotToEmptyPath $Temporary `
      $TargetPath '条件替换安装 temporary '
  }
  catch {
    $installFailure = $_
    if (-not [IO.File]::Exists($TargetPath) -and
        -not [IO.Directory]::Exists($TargetPath) -and
        [IO.File]::Exists($backupPath)) {
      try {
        [void](Move-BsiOwnedSnapshotToEmptyPath $displaced `
            $TargetPath '条件替换安装失败恢复 target ')
      }
      catch {
        throw ('条件替换安装失败且旧对象无法归位；对象均未覆盖：' +
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
      '条件替换 commit target '
    $current = $targetLock.Snapshot
    Remove-BsiOwnedSnapshotFile $Transaction.Displaced '条件替换 backup '
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
      throw ('条件替换 backup 清理失败且恢复失败，对象已保留：' +
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
