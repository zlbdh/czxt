$ErrorActionPreference = 'Stop'
if (-not ('Czxt.InstallerNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using Microsoft.Win32.SafeHandles;
namespace Czxt {
  [StructLayout(LayoutKind.Sequential)] public struct InstallerFt { public uint Low, High; }
  [StructLayout(LayoutKind.Sequential)] public struct InstallerInfo {
    public uint Attributes; public InstallerFt Creation, Access, Write;
    public uint VolumeSerialNumber, SizeHigh, SizeLow, NumberOfLinks, FileIndexHigh, FileIndexLow;
  }
  public sealed class InstallerState {
    public uint Attributes, VolumeSerialNumber, NumberOfLinks, FileIndexHigh, FileIndexLow;
    public ulong Length; public string Sha256; public byte[] Bytes;
  }
  public static class InstallerNative {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint access, uint share,
      IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool GetFileInformationByHandle(SafeFileHandle handle, out InstallerInfo info);
    static InstallerState ReadCore(string path, bool includeBytes) {
      using (SafeFileHandle handle = CreateFileW(path, 0x80000080, 1, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero)) {
        if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        InstallerInfo info;
        if (!GetFileInformationByHandle(handle, out info))
          throw new Win32Exception(Marshal.GetLastWin32Error());
        byte[] digest;
        byte[] bytes = null;
        using (FileStream stream = new FileStream(handle, FileAccess.Read, 81920, false)) {
          if (includeBytes) {
            using (MemoryStream memory = new MemoryStream()) {
              stream.CopyTo(memory); bytes = memory.ToArray();
            }
            using (SHA256 sha256 = SHA256.Create()) { digest = sha256.ComputeHash(bytes); }
          } else {
            using (SHA256 sha256 = SHA256.Create()) { digest = sha256.ComputeHash(stream); }
          }
        }
        ulong length = ((ulong)info.SizeHigh << 32) | info.SizeLow;
        if (includeBytes && (ulong)bytes.LongLength != length)
          throw new IOException("file length changed while reading snapshot");
        return new InstallerState { Attributes=info.Attributes,
          VolumeSerialNumber=info.VolumeSerialNumber, NumberOfLinks=info.NumberOfLinks,
          FileIndexHigh=info.FileIndexHigh, FileIndexLow=info.FileIndexLow,
          Length=length, Sha256=BitConverter.ToString(digest).Replace("-", "").ToLowerInvariant(),
          Bytes=bytes };
      }
    }
    public static InstallerState Read(string path) { return ReadCore(path, false); }
    public static InstallerState ReadSnapshot(string path) { return ReadCore(path, true); }
  }
}
'@
}
function ConvertTo-CzxtInstallerFileState {
  param(
    [object]$NativeState,
    [string]$Path,
    [string]$Context = '实例化文件',
    [switch]$AllowHardLinks
  )
  $full = Get-CzxtBorrowingFullPath $Path
  if (($NativeState.Attributes -band 0x400) -ne 0) {
    throw ("{0}是 reparse point：{1}" -f $Context, $full)
  }
  if (($NativeState.Attributes -band 0x10) -ne 0) {
    throw ("{0}不是文件：{1}" -f $Context, $full)
  }
  if ($NativeState.NumberOfLinks -ne 1 -and -not $AllowHardLinks) {
    throw ("{0}拒绝硬链接（NumberOfLinks={1}）：{2}" -f `
      $Context, $NativeState.NumberOfLinks, $full)
  }
  return [pscustomobject]@{
    Path = $full
    Identity = ('{0:x8}:{1:x8}:{2:x8}' -f $NativeState.VolumeSerialNumber,
      $NativeState.FileIndexHigh, $NativeState.FileIndexLow)
    NumberOfLinks = [uint32]$NativeState.NumberOfLinks
    Length = [uint64]$NativeState.Length
    Sha256 = [string]$NativeState.Sha256
  }
}
function Get-CzxtInstallerFileState {
  param(
    [string]$Path,
    [string]$Context = '实例化文件',
    [switch]$AllowHardLinks
  )
  $full = Get-CzxtBorrowingFullPath $Path
  if (-not [IO.File]::Exists($full)) { throw ("{0}不存在：{1}" -f $Context, $full) }
  $native = [Czxt.InstallerNative]::Read($full)
  return ConvertTo-CzxtInstallerFileState -NativeState $native -Path $full `
    -Context $Context -AllowHardLinks:$AllowHardLinks
}
function Assert-CzxtInstallerFileStateStable {
  param([object]$Expected, [object]$Actual, [string]$Context = '实例化文件')
  if ($null -eq $Expected -or $null -eq $Actual -or
      $Expected.Identity -cne $Actual.Identity -or $Actual.NumberOfLinks -ne 1 -or
      $Expected.Length -ne $Actual.Length -or $Expected.Sha256 -cne $Actual.Sha256) {
    $path = if ($null -eq $Actual) { '<missing>' } else { $Actual.Path }
    throw ("{0}文件身份在写入前发生变化：{1}" -f $Context, $path)
  }
}
function Get-CzxtInstallerTargetExpectation {
  param(
    [string]$ProjectRoot,
    [string]$TargetPath,
    [string]$Context = '实例化目标',
    [switch]$AllowExisting
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  if ([IO.File]::Exists($target)) {
    if (-not $AllowExisting) {
      throw ("{0}已存在：{1}" -f $Context, $target)
    }
    return [pscustomobject]@{
      Mode = 'ExpectedPresent'
      State = Get-CzxtInstallerFileState -Path $target -Context $Context
    }
  }
  if (Test-Path -LiteralPath $target) {
    throw ("{0}已被目录占用：{1}" -f $Context, $target)
  }
  return [pscustomobject]@{ Mode = 'ExpectAbsent'; State = $null }
}
function Set-CzxtInstallerPreparedFile {
  param(
    [string]$ProjectRoot,
    [string]$PreparedPath,
    [string]$TargetPath,
    [string]$Context = '实例化文件写入',
    [switch]$ExpectAbsent,
    [object]$ExpectedPresentState,
    [object]$ExpectedPreparedState,
    [object]$InstalledFiles,
    [scriptblock]$BeforeTargetCommit,
    [scriptblock]$BeforeReplace,
    [scriptblock]$BeforeRecovery,
    [scriptblock]$BeforeCommitVerification,
    [scriptblock]$BeforeOwnedDelete,
    [scriptblock]$AfterCommitTargetRead,
    [scriptblock]$BeforeRestoreReplace,
    [scriptblock]$BeforeBackupMove,
    [scriptblock]$BeforePreparedMove,
    [object]$ParentDirectoryLease
  )
  if ($ExpectAbsent.IsPresent -eq ($null -ne $ExpectedPresentState)) {
    throw ("{0}必须且只能声明 ExpectAbsent 或 ExpectedPresentState。" -f $Context)
  }
  if ($null -eq $ExpectedPreparedState) { throw ($Context + '缺少临时文件所有权状态') }
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $prepared = Get-CzxtBorrowingFullPath $PreparedPath
  if (-not (Test-CzxtBorrowingPathWithinRoot $prepared $ProjectRoot)) {
    throw ("{0}临时文件越出 ProjectRoot：{1}" -f $Context, $prepared)
  }
  $ownsParentLease = $null -eq $ParentDirectoryLease
  $parentLease = if ($ownsParentLease) {
    Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context ($Context + '父目录')
  } else { $ParentDirectoryLease }
  try {
    if ($null -eq $parentLease.Native -or $null -eq $parentLease.State -or
        [string]::IsNullOrWhiteSpace([string]$parentLease.Parent)) {
      throw ($Context + '父目录 lease 无效')
    }
    $targetParent = Get-CzxtBorrowingFullPath (Split-Path -Parent $target)
    if (-not $targetParent.Equals(
        $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + '目标与受锁父目录不匹配')
    }
    $preparedParent = Get-CzxtBorrowingFullPath (Split-Path -Parent $prepared)
    if (-not $preparedParent.Equals(
        $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + '临时文件与目标必须位于同一受锁父目录')
    }
    $preparedState = Get-CzxtInstallerFileState -Path $prepared `
      -Context ($Context + '临时文件')
    Assert-CzxtInstallerStateMaterialEqual $ExpectedPreparedState $preparedState `
      ($Context + '临时文件在提交前发生变化')
    if ($null -ne $BeforeTargetCommit) { & $BeforeTargetCommit $target $prepared }
    $preparedState = Get-CzxtInstallerFileState -Path $prepared `
      -Context ($Context + '临时文件')
    Assert-CzxtInstallerStateMaterialEqual $ExpectedPreparedState $preparedState `
      ($Context + '临时文件在提交前发生变化')
    if ([IO.File]::Exists($target)) {
      if ($ExpectAbsent) {
        throw ("{0}目标原应不存在，但在提交前出现：{1}" -f $Context, $target)
      }
      $targetState = Get-CzxtInstallerFileState -Path $target -Context $Context
      Assert-CzxtInstallerFileStateStable $ExpectedPresentState $targetState $Context
      $finalState = Get-CzxtInstallerFileState -Path $target -Context $Context
      Assert-CzxtInstallerFileStateStable $targetState $finalState $Context
      [void](Invoke-CzxtInstallerPreparedReplace -PreparedPath $prepared `
        -TargetPath $target -ExpectedTargetState $finalState `
        -PreparedState $preparedState -Context $Context -BeforeReplace $BeforeReplace `
        -BeforeRecovery $BeforeRecovery `
        -BeforeCommitVerification $BeforeCommitVerification `
        -BeforeOwnedDelete $BeforeOwnedDelete `
        -AfterCommitTargetRead $AfterCommitTargetRead `
        -BeforeRestoreReplace $BeforeRestoreReplace `
        -BeforeBackupMove $BeforeBackupMove `
        -BeforePreparedMove $BeforePreparedMove)
    } else {
      if ($null -ne $ExpectedPresentState -or [IO.Directory]::Exists($target)) {
        throw ("{0}目标在写入前发生变化：{1}" -f $Context, $target)
      }
      [IO.File]::Move($prepared, $target)
    }
    $writtenState = Get-CzxtInstallerFileState -Path $target -Context $Context
    Assert-CzxtInstallerFileStateStable $preparedState $writtenState $Context
    Set-CzxtInstallerOutputState -InstalledFiles $InstalledFiles -State $writtenState
    return $writtenState
  }
  finally {
    if ($ownsParentLease) { $parentLease.Native.Dispose() }
  }
}
function Copy-CzxtInstallerFile {
  param(
    [string]$ProjectRoot, [string]$SourcePath, [string]$TargetPath,
    [string]$Context = '实例化文件复制', [switch]$ExpectAbsent,
    [object]$ExpectedPresentState, [object]$ExpectedSourceState,
    [object]$InstalledFiles,
    [scriptblock]$BeforeTargetCommit, [object]$ParentDirectoryLease
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context ($Context + '父目录'))
  }
  $ownsParentLease = $null -eq $ParentDirectoryLease
  $parentLease = if ($ownsParentLease) {
    Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context ($Context + '父目录')
  } else { $ParentDirectoryLease }
  try {
    if ($null -eq $parentLease.Native -or $null -eq $parentLease.State -or
        [string]::IsNullOrWhiteSpace([string]$parentLease.Parent) -or
        -not $parent.Equals(
          $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + '父目录 lease 与目标不匹配')
    }
    $temp = Join-Path $parentLease.Parent `
      ('.czxt-install-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $preparedState = $null
    try {
      if ($null -eq $ExpectedSourceState) { throw ($Context + '缺少受信来源状态') }
      $preparedState = Copy-CzxtInstallerTrustedSource -SourcePath $SourcePath `
        -DestinationPath $temp -ExpectedState $ExpectedSourceState `
        -Context ($Context + '来源')
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $ProjectRoot -PreparedPath $temp `
        -TargetPath $target -Context $Context -ExpectAbsent:$ExpectAbsent `
        -ExpectedPresentState $ExpectedPresentState -ExpectedPreparedState $preparedState `
        -InstalledFiles $InstalledFiles `
        -BeforeTargetCommit $BeforeTargetCommit `
        -ParentDirectoryLease $parentLease)
    }
    finally {
      if ($null -ne $preparedState -and [IO.File]::Exists($temp)) {
        Remove-CzxtInstallerOwnedTransactionFile -Path $temp -ExpectedState $preparedState `
          -Context ($Context + '临时文件')
      }
    }
  }
  finally {
    if ($ownsParentLease) { $parentLease.Native.Dispose() }
  }
}
function Write-CzxtInstallerTextFile {
  param(
    [string]$ProjectRoot, [string]$TargetPath, [string]$Content,
    [Text.Encoding]$Encoding, [string]$Context = '实例化文本写入',
    [switch]$ExpectAbsent, [object]$ExpectedPresentState, [object]$InstalledFiles,
    [scriptblock]$BeforePreparedWrite, [scriptblock]$BeforePreparedCleanup,
    [object]$ParentDirectoryLease
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context ($Context + '父目录'))
  }
  $ownsParentLease = $null -eq $ParentDirectoryLease
  $parentLease = if ($ownsParentLease) {
    Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context ($Context + '父目录')
  } else { $ParentDirectoryLease }
  try {
    if ($null -eq $parentLease.Native -or $null -eq $parentLease.State -or
        [string]::IsNullOrWhiteSpace([string]$parentLease.Parent) -or
        -not $parent.Equals(
          $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + '父目录 lease 与目标不匹配')
    }
    $temp = Join-Path $parentLease.Parent `
      ('.czxt-install-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $preparedState = $null
    try {
      if ($null -ne $BeforePreparedWrite) { & $BeforePreparedWrite $temp }
      $preparedState = New-CzxtInstallerPreparedFile -DestinationPath $temp `
        -FirstBytes $Encoding.GetPreamble() -SecondBytes $Encoding.GetBytes($Content) `
        -Context ($Context + '临时文件')
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $ProjectRoot -PreparedPath $temp `
        -TargetPath $target -Context $Context -ExpectAbsent:$ExpectAbsent `
        -ExpectedPresentState $ExpectedPresentState `
        -ExpectedPreparedState $preparedState `
        -InstalledFiles $InstalledFiles -ParentDirectoryLease $parentLease)
    }
    finally {
      if ($null -ne $BeforePreparedCleanup) { & $BeforePreparedCleanup $temp }
      if ($null -ne $preparedState -and [IO.File]::Exists($temp)) {
        Remove-CzxtInstallerOwnedTransactionFile -Path $temp -ExpectedState $preparedState `
          -Context ($Context + '临时文件')
      }
    }
  }
  finally {
    if ($ownsParentLease) { $parentLease.Native.Dispose() }
  }
}
function Add-CzxtInstallerTextFile {
  param(
    [string]$ProjectRoot, [string]$TargetPath, [string]$Content,
    [Text.Encoding]$Encoding, [string]$Context = '实例化文本追加',
    [object]$ExpectedPresentState, [object]$InstalledFiles,
    [scriptblock]$BeforeSnapshotRead, [scriptblock]$AfterSnapshotRead
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parentLease = Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
    -TargetPath $target -Context ($Context + '父目录')
  try {
    $snapshot = Get-CzxtInstallerFileSnapshot -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context $Context -ExpectedTargetState $ExpectedPresentState `
      -BeforeSnapshotRead $BeforeSnapshotRead `
      -AfterSnapshotRead $AfterSnapshotRead
    $temp = Join-Path $parentLease.Parent `
      ('.czxt-install-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $preparedState = $null
    try {
      $preparedState = New-CzxtInstallerPreparedFile -DestinationPath $temp `
        -FirstBytes $snapshot.Bytes -SecondBytes $Encoding.GetBytes($Content) `
        -Context ($Context + '临时文件')
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $ProjectRoot -PreparedPath $temp `
        -TargetPath $target -Context $Context -ExpectedPresentState $snapshot.State `
        -ExpectedPreparedState $preparedState `
        -InstalledFiles $InstalledFiles -ParentDirectoryLease $parentLease)
    }
    finally {
      if ($null -ne $preparedState -and [IO.File]::Exists($temp)) {
        Remove-CzxtInstallerOwnedTransactionFile -Path $temp -ExpectedState $preparedState `
          -Context ($Context + '临时文件')
      }
    }
  }
  finally { $parentLease.Native.Dispose() }
}
