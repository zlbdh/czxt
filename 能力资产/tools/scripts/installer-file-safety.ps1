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
    [string]$Context = 'Installer file',
    [switch]$AllowHardLinks
  )
  $full = Get-CzxtBorrowingFullPath $Path
  if (($NativeState.Attributes -band 0x400) -ne 0) {
    throw ("{0} is a reparse point: {1}" -f $Context, $full)
  }
  if (($NativeState.Attributes -band 0x10) -ne 0) {
    throw ("{0} is not a file: {1}" -f $Context, $full)
  }
  if ($NativeState.NumberOfLinks -ne 1 -and -not $AllowHardLinks) {
    throw ("{0} rejects hardlinks (NumberOfLinks={1}): {2}" -f `
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
    [string]$Context = 'Installer file',
    [switch]$AllowHardLinks
  )
  $full = Get-CzxtBorrowingFullPath $Path
  if (-not [IO.File]::Exists($full)) { throw ("{0} does not exist: {1}" -f $Context, $full) }
  $native = [Czxt.InstallerNative]::Read($full)
  return ConvertTo-CzxtInstallerFileState -NativeState $native -Path $full `
    -Context $Context -AllowHardLinks:$AllowHardLinks
}
function Assert-CzxtInstallerFileStateStable {
  param([object]$Expected, [object]$Actual, [string]$Context = 'Installer file')
  if ($null -eq $Expected -or $null -eq $Actual -or
      $Expected.Identity -cne $Actual.Identity -or $Actual.NumberOfLinks -ne 1 -or
      $Expected.Length -ne $Actual.Length -or $Expected.Sha256 -cne $Actual.Sha256) {
    $path = if ($null -eq $Actual) { '<missing>' } else { $Actual.Path }
    throw ("{0} file identity changed before writing: {1}" -f $Context, $path)
  }
}
function Get-CzxtInstallerTargetExpectation {
  param(
    [string]$ProjectRoot,
    [string]$TargetPath,
    [string]$Context = 'Installer target',
    [switch]$AllowExisting
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  if ([IO.File]::Exists($target)) {
    if (-not $AllowExisting) {
      throw ("{0} already exists: {1}" -f $Context, $target)
    }
    return [pscustomobject]@{
      Mode = 'ExpectedPresent'
      State = Get-CzxtInstallerFileState -Path $target -Context $Context
    }
  }
  if (Test-Path -LiteralPath $target) {
    throw ("{0} is occupied by a directory: {1}" -f $Context, $target)
  }
  return [pscustomobject]@{ Mode = 'ExpectAbsent'; State = $null }
}
function Set-CzxtInstallerPreparedFile {
  param(
    [string]$ProjectRoot,
    [string]$PreparedPath,
    [string]$TargetPath,
    [string]$Context = 'Installer file write',
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
    throw ("{0} must declare exactly one of ExpectAbsent or ExpectedPresentState." -f $Context)
  }
  if ($null -eq $ExpectedPreparedState) { throw ($Context + ' is missing temporary-file ownership state') }
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $prepared = Get-CzxtBorrowingFullPath $PreparedPath
  if (-not (Test-CzxtBorrowingPathWithinRoot $prepared $ProjectRoot)) {
    throw ("{0} temporary file is outside ProjectRoot: {1}" -f $Context, $prepared)
  }
  $ownsParentLease = $null -eq $ParentDirectoryLease
  $parentLease = if ($ownsParentLease) {
    Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context ($Context + ' parent directory')
  } else { $ParentDirectoryLease }
  try {
    if ($null -eq $parentLease.Native -or $null -eq $parentLease.State -or
        [string]::IsNullOrWhiteSpace([string]$parentLease.Parent)) {
      throw ($Context + ' parent-directory lease is invalid')
    }
    $targetParent = Get-CzxtBorrowingFullPath (Split-Path -Parent $target)
    if (-not $targetParent.Equals(
        $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + ' target does not match the locked parent directory')
    }
    $preparedParent = Get-CzxtBorrowingFullPath (Split-Path -Parent $prepared)
    if (-not $preparedParent.Equals(
        $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + ' temporary file and target must share the same locked parent directory')
    }
    $preparedState = Get-CzxtInstallerFileState -Path $prepared `
      -Context ($Context + ' temporary file')
    Assert-CzxtInstallerStateMaterialEqual $ExpectedPreparedState $preparedState `
      ($Context + ' temporary file changed before commit')
    if ($null -ne $BeforeTargetCommit) { & $BeforeTargetCommit $target $prepared }
    $preparedState = Get-CzxtInstallerFileState -Path $prepared `
      -Context ($Context + ' temporary file')
    Assert-CzxtInstallerStateMaterialEqual $ExpectedPreparedState $preparedState `
      ($Context + ' temporary file changed before commit')
    if ([IO.File]::Exists($target)) {
      if ($ExpectAbsent) {
        throw ("{0} target was expected to be absent but appeared before commit: {1}" -f $Context, $target)
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
        throw ("{0} target changed before writing: {1}" -f $Context, $target)
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
    [string]$Context = 'Installer file copy', [switch]$ExpectAbsent,
    [object]$ExpectedPresentState, [object]$ExpectedSourceState,
    [object]$InstalledFiles,
    [scriptblock]$BeforeTargetCommit, [object]$ParentDirectoryLease
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context ($Context + ' parent directory'))
  }
  $ownsParentLease = $null -eq $ParentDirectoryLease
  $parentLease = if ($ownsParentLease) {
    Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context ($Context + ' parent directory')
  } else { $ParentDirectoryLease }
  try {
    if ($null -eq $parentLease.Native -or $null -eq $parentLease.State -or
        [string]::IsNullOrWhiteSpace([string]$parentLease.Parent) -or
        -not $parent.Equals(
          $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + ' parent-directory lease does not match the target')
    }
    $temp = Join-Path $parentLease.Parent `
      ('.czxt-install-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $preparedState = $null
    try {
      if ($null -eq $ExpectedSourceState) { throw ($Context + ' is missing trusted source state') }
      $preparedState = Copy-CzxtInstallerTrustedSource -SourcePath $SourcePath `
        -DestinationPath $temp -ExpectedState $ExpectedSourceState `
        -Context ($Context + ' source')
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
          -Context ($Context + ' temporary file')
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
    [Text.Encoding]$Encoding, [string]$Context = 'Installer text write',
    [switch]$ExpectAbsent, [object]$ExpectedPresentState, [object]$InstalledFiles,
    [scriptblock]$BeforePreparedWrite, [scriptblock]$BeforePreparedCleanup,
    [object]$ParentDirectoryLease
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context ($Context + ' parent directory'))
  }
  $ownsParentLease = $null -eq $ParentDirectoryLease
  $parentLease = if ($ownsParentLease) {
    Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
      -TargetPath $target -Context ($Context + ' parent directory')
  } else { $ParentDirectoryLease }
  try {
    if ($null -eq $parentLease.Native -or $null -eq $parentLease.State -or
        [string]::IsNullOrWhiteSpace([string]$parentLease.Parent) -or
        -not $parent.Equals(
          $parentLease.Parent, [StringComparison]::OrdinalIgnoreCase)) {
      throw ($Context + ' parent-directory lease does not match the target')
    }
    $temp = Join-Path $parentLease.Parent `
      ('.czxt-install-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $preparedState = $null
    try {
      if ($null -ne $BeforePreparedWrite) { & $BeforePreparedWrite $temp }
      $preparedState = New-CzxtInstallerPreparedFile -DestinationPath $temp `
        -FirstBytes $Encoding.GetPreamble() -SecondBytes $Encoding.GetBytes($Content) `
        -Context ($Context + ' temporary file')
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
          -Context ($Context + ' temporary file')
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
    [Text.Encoding]$Encoding, [string]$Context = 'Installer text append',
    [object]$ExpectedPresentState, [object]$InstalledFiles,
    [scriptblock]$BeforeSnapshotRead, [scriptblock]$AfterSnapshotRead
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parentLease = Open-CzxtInstallerParentDirectoryLease -ProjectRoot $ProjectRoot `
    -TargetPath $target -Context ($Context + ' parent directory')
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
        -Context ($Context + ' temporary file')
      [void](Set-CzxtInstallerPreparedFile -ProjectRoot $ProjectRoot -PreparedPath $temp `
        -TargetPath $target -Context $Context -ExpectedPresentState $snapshot.State `
        -ExpectedPreparedState $preparedState `
        -InstalledFiles $InstalledFiles -ParentDirectoryLease $parentLease)
    }
    finally {
      if ($null -ne $preparedState -and [IO.File]::Exists($temp)) {
        Remove-CzxtInstallerOwnedTransactionFile -Path $temp -ExpectedState $preparedState `
          -Context ($Context + ' temporary file')
      }
    }
  }
  finally { $parentLease.Native.Dispose() }
}
