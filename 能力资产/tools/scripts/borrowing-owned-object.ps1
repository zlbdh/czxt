$ErrorActionPreference = 'Stop'

if (-not ('Czxt.B.OwnedObjectNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
namespace Czxt.B {
  [StructLayout(LayoutKind.Sequential)]
  public struct FileDispositionInfo {
    [MarshalAs(UnmanagedType.Bool)] public bool DeleteFile;
  }
  public static class OwnedObjectNative {
    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetFileInformationByHandle(
      SafeFileHandle handle, int informationClass,
      ref FileDispositionInfo information, uint bufferSize);
  }
}
'@
}

function global:Test-BsiOwnedBytesEqual {
  param([byte[]]$Left, [byte[]]$Right)
  if ($null -eq $Left -or $null -eq $Right -or $Left.Length -ne $Right.Length) {
    return $false
  }
  for ($index = 0; $index -lt $Left.Length; $index++) {
    if ($Left[$index] -ne $Right[$index]) { return $false }
  }
  return $true
}

function global:Invoke-BsiOwnedObjectInjection {
  param([string]$Name, [string]$Path, [string]$Context)
  if ($script:BsiOwnedObjectTestInjections -is [Collections.IDictionary] -and
      $script:BsiOwnedObjectTestInjections.Contains($Name)) {
    & $script:BsiOwnedObjectTestInjections[$Name] ([pscustomobject]@{
        Path = $Path; Context = $Context
      })
  }
}

function global:Open-BsiOwnedFileLock {
  param($Expected, [string]$Context)
  if ($null -eq $Expected -or [string]::IsNullOrWhiteSpace($Expected.Path)) {
    throw ($Context + '缺少受信文件快照')
  }
  Invoke-BsiOwnedObjectInjection 'before-file-handle-open' $Expected.Path $Context
  $handle = $null
  $stream = $null
  try {
    $handle = [Czxt.B.NP]::CreateFileW(
      $Expected.Path, [uint32]2147549312, 0, [IntPtr]::Zero, 3,
      [uint32]0x00200000, [IntPtr]::Zero)
    if ($null -eq $handle -or $handle.IsInvalid) {
      throw ($Context + '无法独占打开受信文件')
    }
    $stream = New-Object IO.FileStream($handle, [IO.FileAccess]::Read)
    $handle = $null
    $opened = Get-BorrowingTrustedHandleSnapshot `
      $stream.SafeFileHandle close source-unsafe
    if (-not [string]::Equals($opened.CanonicalPath, $Expected.Path,
        [StringComparison]::OrdinalIgnoreCase) -or
        $opened.IdentityKey -cne $Expected.IdentityKey -or
        [uint64]$opened.Length -ne [uint64]$Expected.Length -or
        [uint64]$opened.Length -gt [uint64][int]::MaxValue) {
      throw ($Context + '受信文件身份或长度改变')
    }
    [byte[]]$bytes = New-Object byte[] ([int]$opened.Length)
    $offset = 0
    while ($offset -lt $bytes.Length) {
      $read = $stream.Read($bytes, $offset, $bytes.Length - $offset)
      if ($read -le 0) { throw ($Context + '受信文件读取提前结束') }
      $offset += $read
    }
    if (-not (Test-BsiOwnedBytesEqual $bytes ([byte[]]$Expected.Bytes))) {
      throw ($Context + '受信文件字节改变')
    }
    return [pscustomobject]@{
      Stream = $stream
      Context = $Context
      Snapshot = [pscustomobject]@{
        Path = $opened.CanonicalPath
        IdentityKey = $opened.IdentityKey
        Length = [uint64]$opened.Length
        Bytes = $bytes
      }
    }
  }
  catch {
    if ($null -ne $stream) { $stream.Dispose() }
    elseif ($null -ne $handle) { $handle.Dispose() }
    throw
  }
}

function global:Close-BsiOwnedFileLock {
  param($Lock, [switch]$IgnoreCloseFailure)
  if ($null -eq $Lock -or $null -eq $Lock.Stream) { return }
  $closeFailure = $null
  try {
    Invoke-BsiOwnedObjectInjection 'before-file-lock-dispose' `
      $Lock.Snapshot.Path $Lock.Context
  }
  catch { $closeFailure = $_ }
  try { $Lock.Stream.Dispose() }
  catch { if ($null -eq $closeFailure) { $closeFailure = $_ } }
  if ($null -ne $closeFailure -and -not $IgnoreCloseFailure) {
    throw $closeFailure
  }
}

function global:Set-BsiOwnedHandleDeletePending {
  param($Handle, [string]$Context)
  $disposition = New-Object Czxt.B.FileDispositionInfo
  $disposition.DeleteFile = $true
  if (-not [Czxt.B.OwnedObjectNative]::SetFileInformationByHandle(
      $Handle, 4, [ref]$disposition,
      [Runtime.InteropServices.Marshal]::SizeOf($disposition))) {
    $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw ($Context + '同句柄删除失败，错误码：' + $code)
  }
}

function global:Remove-BsiBoundOwnedFile {
  param($Expected, [string]$Context)
  $lock = Open-BsiOwnedFileLock $Expected $Context
  $deleteFailure = $null
  try { Set-BsiOwnedHandleDeletePending $lock.Stream.SafeFileHandle $Context }
  catch { $deleteFailure = $_ }
  Close-BsiOwnedFileLock $lock -IgnoreCloseFailure
  if ($null -ne $deleteFailure) { throw $deleteFailure }
}

function global:Remove-BsiBoundEmptyDirectory {
  param($Expected, [string]$Context)
  if ($null -eq $Expected -or [string]::IsNullOrWhiteSpace($Expected.Path)) {
    throw ($Context + '缺少受信目录快照')
  }
  Invoke-BsiOwnedObjectInjection 'before-directory-handle-open' `
    $Expected.Path $Context
  $handle = $null
  try {
    $handle = [Czxt.B.NP]::CreateFileW(
      $Expected.Path, [uint32]0x00010080, 0, [IntPtr]::Zero, 3,
      [uint32]0x02200000, [IntPtr]::Zero)
    if ($null -eq $handle -or $handle.IsInvalid) {
      throw ($Context + '无法独占打开受信目录')
    }
    $information = New-Object Czxt.B.FI
    if (-not [Czxt.B.NP]::GetFileInformationByHandle(
        $handle, [ref]$information)) {
      throw ($Context + '无法读取受信目录身份')
    }
    $identity = '{0:x8}:{1:x8}:{2:x8}' -f `
      $information.VolumeSerialNumber, $information.FileIndexHigh,
      $information.FileIndexLow
    if (($information.FileAttributes -band 0x10) -eq 0 -or
        ($information.FileAttributes -band 0x400) -ne 0 -or
        $identity -cne $Expected.IdentityKey) {
      throw ($Context + '受信目录身份或类型改变')
    }
    Set-BsiOwnedHandleDeletePending $handle $Context
  }
  finally { if ($null -ne $handle) { $handle.Dispose() } }
}
