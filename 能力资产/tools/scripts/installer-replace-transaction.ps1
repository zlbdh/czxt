$ErrorActionPreference = 'Stop'

function Test-CzxtInstallerStateMaterialEqual {
  param([object]$Expected, [object]$Actual, [switch]$AllowHardLinks)
  if ($null -eq $Expected -or $null -eq $Actual) { return $false }
  if (-not $AllowHardLinks -and ($Expected.NumberOfLinks -ne 1 -or
      $Actual.NumberOfLinks -ne 1)) { return $false }
  return $Expected.Identity -ceq $Actual.Identity -and
    $Expected.NumberOfLinks -eq $Actual.NumberOfLinks -and
    $Expected.Length -eq $Actual.Length -and $Expected.Sha256 -ceq $Actual.Sha256
}

function Assert-CzxtInstallerStateMaterialEqual {
  param(
    [object]$Expected, [object]$Actual, [string]$Message,
    [switch]$AllowHardLinks
  )
  if (-not (Test-CzxtInstallerStateMaterialEqual $Expected $Actual `
      -AllowHardLinks:$AllowHardLinks)) { throw $Message }
}

function New-CzxtInstallerTransactionPath {
  param([string]$Directory, [string]$Kind)
  for ($attempt = 0; $attempt -lt 16; $attempt++) {
    $path = Join-Path $Directory `
      ('.czxt-' + $Kind + '-' + [guid]::NewGuid().ToString('N') + '.tmp')
    if (-not [IO.File]::Exists($path) -and -not [IO.Directory]::Exists($path)) {
      return $path
    }
  }
  throw ("无法分配实例化事务路径：{0}" -f $Kind)
}

function Remove-CzxtInstallerOwnedTransactionFile {
  param(
    [string]$Path, [object]$ExpectedState, [string]$Context,
    [scriptblock]$BeforeOwnedDelete
  )
  $lease = Open-CzxtInstallerFileLease -Path $Path -ExpectedState $ExpectedState `
    -Context $Context -ForDelete -AllowHardLinks
  try {
    if ($null -ne $BeforeOwnedDelete) { & $BeforeOwnedDelete $Path }
    $lease.Native.DeleteBound()
  }
  finally { $lease.Native.Dispose() }
}

function Invoke-CzxtInstallerPreparedReplace {
  param(
    [string]$PreparedPath,
    [string]$TargetPath,
    [object]$ExpectedTargetState,
    [object]$PreparedState,
    [string]$Context,
    [scriptblock]$BeforeReplace,
    [scriptblock]$BeforeRecovery,
    [scriptblock]$BeforeCommitVerification,
    [scriptblock]$BeforeOwnedDelete,
    [scriptblock]$AfterCommitTargetRead,
    [scriptblock]$BeforeRestoreReplace,
    [scriptblock]$BeforeBackupMove,
    [scriptblock]$BeforePreparedMove
  )
  if ($null -ne $BeforeReplace) { & $BeforeReplace $TargetPath $PreparedPath }
  $backup = New-CzxtInstallerTransactionPath `
    -Directory (Split-Path -Parent $TargetPath) -Kind 'backup'
  if ($null -ne $BeforeBackupMove) {
    & $BeforeBackupMove $TargetPath $PreparedPath $backup
  }
  [IO.File]::Move($TargetPath, $backup)
  if ($null -ne $BeforePreparedMove) {
    & $BeforePreparedMove $TargetPath $PreparedPath $backup
  }
  try { [IO.File]::Move($PreparedPath, $TargetPath) }
  catch {
    $message = ("{0}提交未完成；backup={1}；" +
      'backup=retained,target=untouched,prepared=retained-for-owned-cleanup') -f `
      $Context, $backup
    $failure = [InvalidOperationException]::new($message, $_.Exception)
    $failure.Data['CzxtInstallerBackupPath'] = $backup
    $failure.Data['CzxtInstallerPreserved'] = `
      'backup=retained,target=untouched,prepared=retained-for-owned-cleanup'
    throw $failure
  }

  $backupState = $null
  $backupError = ''
  try {
    $backupState = Get-CzxtInstallerFileState -Path $backup `
      -Context ($Context + '被替换目标备份') -AllowHardLinks
  }
  catch { $backupError = $_.Exception.Message }
  $installedState = $null
  $installedError = ''
  try {
    $installedState = Get-CzxtInstallerFileState -Path $TargetPath `
      -Context ($Context + '已落盘目标')
  }
  catch { $installedError = $_.Exception.Message }
  $backupMatches = Test-CzxtInstallerStateMaterialEqual `
    $ExpectedTargetState $backupState -AllowHardLinks
  $installedMatches = Test-CzxtInstallerStateMaterialEqual $PreparedState $installedState

  if (-not $backupMatches) {
    if ($null -ne $BeforeRecovery) { & $BeforeRecovery $TargetPath $backup }
    if ($null -ne $BeforeRestoreReplace) { & $BeforeRestoreReplace $TargetPath $backup }
    throw ("{0}CAS 身份漂移；禁止 path-based 恢复并保留全部对象：{1}；{2}" -f `
      $Context, $backup, ($backupError + $installedError))
  }
  if (-not $installedMatches) {
    throw ("{0}已落盘目标发生变化；backup 保留于 {1}：{2}" -f `
      $Context, $backup, $installedError)
  }

  if ($null -ne $BeforeCommitVerification) {
    & $BeforeCommitVerification $TargetPath $backup
  }
  $targetLease = Open-CzxtInstallerFileLease -Path $TargetPath `
    -ExpectedState $PreparedState -Context ($Context + '提交目标')
  try {
    if ($null -ne $AfterCommitTargetRead) { & $AfterCommitTargetRead $TargetPath }
    Remove-CzxtInstallerOwnedTransactionFile -Path $backup `
      -ExpectedState $ExpectedTargetState -Context ($Context + 'backup ') `
      -BeforeOwnedDelete $BeforeOwnedDelete
    return $targetLease.State
  }
  finally { $targetLease.Native.Dispose() }
}
