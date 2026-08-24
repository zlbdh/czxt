$ErrorActionPreference = 'Stop'

$ownedObjectPath = Join-Path $PSScriptRoot 'borrowing-owned-object.ps1'
if (-not (Test-Path -LiteralPath $ownedObjectPath -PathType Leaf)) {
  throw 'seal 缺少受信对象生命周期 helper'
}
. $ownedObjectPath

function Get-BsiStableSnapshot {
  param([string]$Path)
  $snapshot = Read-BorrowingStableSafeFileSnapshot $Path seal source-unsafe
  return [pscustomobject]@{
    Path = $snapshot.CanonicalPath
    IdentityKey = $snapshot.IdentityKey
    Length = [uint64]$snapshot.Length
    Bytes = [byte[]]$snapshot.Bytes
  }
}

function Assert-BsiSnapshotUnchanged {
  param($Expected, $Actual)
  Assert-BsiCondition (Test-BsiSamePath $Expected.Path $Actual.Path) `
    'seal 文件规范路径改变'
  Assert-BsiCondition ($Expected.IdentityKey -ceq $Actual.IdentityKey) `
    'seal 文件身份改变'
  Assert-BsiCondition ([uint64]$Expected.Length -eq [uint64]$Actual.Length) `
    'seal 文件长度改变'
  Assert-BsiCondition (Test-BcvBytesEqual $Expected.Bytes $Actual.Bytes) `
    'seal 文件字节改变'
}

function Remove-BsiOwnedTemporaryFile {
  param($Temporary)
  if ($null -eq $Temporary -or
      -not (Test-Path -LiteralPath $Temporary.Path -PathType Leaf)) { return }
  try {
    Remove-BsiBoundOwnedFile $Temporary 'seal 临时文件 '
  }
  catch { }
}

function Get-BsiHandleIdentity {
  param($Handle)
  $information = New-Object Czxt.B.FI
  if (-not [Czxt.B.NP]::GetFileInformationByHandle($Handle, [ref]$information)) {
    throw '无法取得 seal 临时文件身份'
  }
  return '{0:x8}:{1:x8}:{2:x8}' -f $information.VolumeSerialNumber,
    $information.FileIndexHigh, $information.FileIndexLow
}

function New-BsiTemporaryFile {
  param([string]$Directory, [byte[]]$Bytes)
  $path = Join-Path $Directory `
    ('.staging-seal-' + [guid]::NewGuid().ToString('N') + '.tmp')
  $stream = $null
  $owned = $null
  $complete = $false
  try {
    $stream = New-Object IO.FileStream(
      $path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $owned = [pscustomobject]@{
      Path = [IO.Path]::GetFullPath($path)
      IdentityKey = Get-BsiHandleIdentity $stream.SafeFileHandle
      Length = [uint64]0
      Bytes = [byte[]]@()
    }
    $stream.Write($Bytes, 0, $Bytes.Length)
    $stream.Flush($true)
    $stream.Dispose()
    $stream = $null

    $snapshot = Get-BsiStableSnapshot $owned.Path
    Assert-BsiCondition ($snapshot.IdentityKey -ceq $owned.IdentityKey) `
      'seal 临时文件身份不一致'
    Assert-BsiCondition ([uint64]$snapshot.Length -eq [uint64]$Bytes.LongLength) `
      'seal 临时文件长度不一致'
    Assert-BsiCondition (Test-BcvBytesEqual $Bytes $snapshot.Bytes) `
      'seal 临时文件字节不一致'
    $owned.Path = $snapshot.Path
    $owned.Length = [uint64]$snapshot.Length
    $owned.Bytes = [byte[]]$snapshot.Bytes
    $complete = $true
    return $owned
  }
  finally {
    if ($null -ne $stream) {
      try { $stream.Dispose() }
      catch { }
    }
    if (-not $complete) { Remove-BsiOwnedTemporaryFile $owned }
  }
}

function Assert-BsiTemporaryUnchanged {
  param($Temporary, [byte[]]$ExpectedBytes)
  $current = Get-BsiStableSnapshot $Temporary.Path
  Assert-BsiCondition ($current.IdentityKey -ceq $Temporary.IdentityKey) `
    'seal 临时文件身份改变'
  Assert-BsiCondition ([uint64]$current.Length -eq [uint64]$ExpectedBytes.LongLength) `
    'seal 临时文件长度改变'
  Assert-BsiCondition (Test-BcvBytesEqual $ExpectedBytes $current.Bytes) `
    'seal 临时文件字节改变'
}
