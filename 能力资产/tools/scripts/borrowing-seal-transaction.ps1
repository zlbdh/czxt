$ErrorActionPreference = 'Stop'

$ownedObjectPath = Join-Path $PSScriptRoot 'borrowing-owned-object.ps1'
if (-not (Test-Path -LiteralPath $ownedObjectPath -PathType Leaf)) {
  throw 'seal requires the trusted object lifecycle helper'
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
    'seal file canonical path changed'
  Assert-BsiCondition ($Expected.IdentityKey -ceq $Actual.IdentityKey) `
    'seal file identity changed'
  Assert-BsiCondition ([uint64]$Expected.Length -eq [uint64]$Actual.Length) `
    'seal file length changed'
  Assert-BsiCondition (Test-BcvBytesEqual $Expected.Bytes $Actual.Bytes) `
    'seal file bytes changed'
}

function Remove-BsiOwnedTemporaryFile {
  param($Temporary)
  if ($null -eq $Temporary -or
      -not (Test-Path -LiteralPath $Temporary.Path -PathType Leaf)) { return }
  try {
    Remove-BsiBoundOwnedFile $Temporary 'seal temporary file '
  }
  catch { }
}

function Get-BsiHandleIdentity {
  param($Handle)
  $information = New-Object Czxt.B.FI
  if (-not [Czxt.B.NP]::GetFileInformationByHandle($Handle, [ref]$information)) {
    throw 'cannot obtain the seal temporary file identity'
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
      'seal temporary file identity does not match'
    Assert-BsiCondition ([uint64]$snapshot.Length -eq [uint64]$Bytes.LongLength) `
      'seal temporary file length does not match'
    Assert-BsiCondition (Test-BcvBytesEqual $Bytes $snapshot.Bytes) `
      'seal temporary file bytes do not match'
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
    'seal temporary file identity changed'
  Assert-BsiCondition ([uint64]$current.Length -eq [uint64]$ExpectedBytes.LongLength) `
    'seal temporary file length changed'
  Assert-BsiCondition (Test-BcvBytesEqual $ExpectedBytes $current.Bytes) `
    'seal temporary file bytes changed'
}
