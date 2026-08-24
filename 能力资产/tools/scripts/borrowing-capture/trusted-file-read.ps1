$ErrorActionPreference = 'Stop'

$trustedFileReadRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Throw-BorrowingFailure -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $trustedFileReadRoot 'common.ps1')
}
if (-not (Get-Command Get-BorrowingSafePathInfo -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $trustedFileReadRoot 'file-safety.ps1')
}

function global:Get-BorrowingTrustedHandleSnapshot {
  param($Handle, [string]$Stage, [string]$ReasonCode)
  try {
    $information = New-Object Czxt.B.FI
    if (-not [Czxt.B.NP]::GetFileInformationByHandle($Handle, [ref]$information)) {
      throw 'trusted handle information failed'
    }
    if (($information.FileAttributes -band 0x410) -ne 0 -or
        $information.NumberOfLinks -ne 1) {
      throw 'trusted handle kind is unsafe'
    }
    $buffer = New-Object Text.StringBuilder 32768
    $count = [Czxt.B.NP]::GetFinalPathNameByHandleW(
      $Handle, $buffer, [uint32]$buffer.Capacity, 0)
    if ($count -eq 0 -or $count -ge $buffer.Capacity) {
      throw 'trusted handle canonical path failed'
    }
    $canonical = $buffer.ToString().Normalize(
      [Text.NormalizationForm]::FormC).Replace('/', '\')
    if (-not $canonical.StartsWith('\\?\', [StringComparison]::Ordinal) -or
        $canonical.Length -lt 7) {
      throw 'trusted handle canonical path is unsafe'
    }
    $canonical = $canonical.Substring(4)
    if ($canonical -notmatch '\A[A-Za-z]:\\') {
      throw 'trusted handle canonical path is not a fixed-drive path'
    }
    $canonical = $canonical.Substring(0, 1).ToUpperInvariant() +
      $canonical.Substring(1)
    $length = ([uint64]$information.FileSizeHigh * 4294967296) +
      [uint64]$information.FileSizeLow
    return [pscustomobject]@{
      CanonicalPath = $canonical
      IdentityKey = '{0:x8}:{1:x8}:{2:x8}' -f `
        $information.VolumeSerialNumber, $information.FileIndexHigh,
        $information.FileIndexLow
      Length = $length
    }
  }
  catch { Throw-BorrowingFailure $Stage $ReasonCode 'trusted file handle is unsafe' }
}

function global:Test-BorrowingTrustedSnapshotEqual {
  param($Expected, $Actual)
  return $null -ne $Expected -and $null -ne $Actual -and
    ([string]$Expected.CanonicalPath).Equals(
      [string]$Actual.CanonicalPath, [StringComparison]::OrdinalIgnoreCase) -and
    [string]$Expected.IdentityKey -ceq [string]$Actual.IdentityKey -and
    [uint64]$Expected.Length -eq [uint64]$Actual.Length
}

function global:Read-BorrowingStableSafeFileSnapshot {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Stage,
    [Parameter(Mandatory = $true)][string]$ReasonCode
  )
  $stream = $null
  try {
    $before = Get-BorrowingSafePathInfo $Path File $Stage $ReasonCode
    if ($script:BorrowingTrustedReadTestInjections -is [Collections.IDictionary] -and
        $script:BorrowingTrustedReadTestInjections.Contains('before-handle-open')) {
      & $script:BorrowingTrustedReadTestInjections['before-handle-open']
    }
    # FileShare.Read|Delete 与持有 DELETE 权限的树封印只读句柄兼容。
    # 普通读取窗口仍禁止写入；若无树封印时发生改名或替换，下面的
    # handle/path 双重身份复核会令本次读取失败关闭。
    $stream = New-Object IO.FileStream(
      $before.CanonicalPath, [IO.FileMode]::Open, [IO.FileAccess]::Read,
      ([IO.FileShare]::Read -bor [IO.FileShare]::Delete))
    $opened = Get-BorrowingTrustedHandleSnapshot $stream.SafeFileHandle $Stage $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $before $opened) -or
        [uint64]$opened.Length -gt [uint64][int]::MaxValue) {
      throw 'trusted file identity changed before handle open'
    }
    if ($script:BorrowingTrustedReadTestInjections -is `
        [Collections.IDictionary] -and
        $script:BorrowingTrustedReadTestInjections.Contains(
          'after-handle-open-before-read')) {
      & $script:BorrowingTrustedReadTestInjections[
        'after-handle-open-before-read']
    }
    [byte[]]$bytes = New-Object byte[] ([int]$opened.Length)
    $offset = 0
    while ($offset -lt $bytes.Length) {
      $read = $stream.Read($bytes, $offset, $bytes.Length - $offset)
      if ($read -le 0) { throw 'trusted file read ended early' }
      $offset += $read
    }
    $handleAfter = Get-BorrowingTrustedHandleSnapshot `
      $stream.SafeFileHandle $Stage $ReasonCode
    $pathAfter = Get-BorrowingSafePathInfo `
      $before.CanonicalPath File $Stage $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $opened $handleAfter) -or
        -not (Test-BorrowingTrustedSnapshotEqual $opened $pathAfter) -or
        [uint64]$opened.Length -ne [uint64]$bytes.LongLength) {
      throw 'trusted file changed while reading'
    }
    return [pscustomobject]@{
      Path = $opened.CanonicalPath
      CanonicalPath = $opened.CanonicalPath
      IdentityKey = $opened.IdentityKey
      Length = [uint64]$opened.Length
      Bytes = $bytes
    }
  }
  catch { Throw-BorrowingFailure $Stage $ReasonCode 'trusted file read failed' }
  finally { if ($null -ne $stream) { $stream.Dispose() } }
}

function global:Read-BorrowingStableSafeFileBytes {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Stage,
    [Parameter(Mandatory = $true)][string]$ReasonCode
  )
  $snapshot = Read-BorrowingStableSafeFileSnapshot $Path $Stage $ReasonCode
  return ,([byte[]]$snapshot.Bytes)
}
