$ErrorActionPreference = 'Stop'

if (-not ('Czxt.InstallerDirectoryLease' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Win32.SafeHandles;
namespace Czxt {
  [StructLayout(LayoutKind.Sequential)] public struct InstallerLeaseFt { public uint Low, High; }
  [StructLayout(LayoutKind.Sequential)] public struct InstallerLeaseInfo {
    public uint Attributes; public InstallerLeaseFt Creation, Access, Write;
    public uint VolumeSerialNumber, SizeHigh, SizeLow, NumberOfLinks, FileIndexHigh, FileIndexLow;
  }
  [StructLayout(LayoutKind.Sequential)] public struct InstallerDisposition {
    [MarshalAs(UnmanagedType.Bool)] public bool DeleteFile;
  }
  static class InstallerLeaseNative {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    internal static extern SafeFileHandle CreateFileW(string path, uint access,
      uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError=true)]
    internal static extern bool GetFileInformationByHandle(SafeFileHandle handle,
      out InstallerLeaseInfo info);
    [DllImport("kernel32.dll", SetLastError=true)]
    internal static extern bool ReadFile(SafeFileHandle handle, byte[] buffer,
      uint count, out uint read, IntPtr overlapped);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    internal static extern uint GetFinalPathNameByHandleW(SafeFileHandle handle,
      StringBuilder path, uint length, uint flags);
    [DllImport("kernel32.dll", SetLastError=true)]
    internal static extern bool SetFileInformationByHandle(SafeFileHandle handle,
      int infoClass, ref InstallerDisposition info, uint size);
    internal static InstallerLeaseInfo Info(SafeFileHandle handle) {
      InstallerLeaseInfo info;
      if (!GetFileInformationByHandle(handle, out info))
        throw new Win32Exception(Marshal.GetLastWin32Error());
      return info;
    }
    internal static SafeFileHandle Open(string path, uint access, uint flags, uint share) {
      SafeFileHandle handle = CreateFileW(path, access, share, IntPtr.Zero, 3, flags, IntPtr.Zero);
      if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
      return handle;
    }
    internal static string FinalPath(SafeFileHandle handle) {
      StringBuilder buffer = new StringBuilder(32768);
      uint count = GetFinalPathNameByHandleW(handle, buffer, (uint)buffer.Capacity, 2);
      if (count == 0 || count >= buffer.Capacity)
        throw new Win32Exception(Marshal.GetLastWin32Error());
      return buffer.ToString();
    }
    internal static ulong Length(InstallerLeaseInfo info) {
      return ((ulong)info.SizeHigh << 32) | info.SizeLow;
    }
  }
  public sealed class InstallerDirectoryLease : IDisposable {
    SafeFileHandle handle, marker;
    public uint Attributes, VolumeSerialNumber, NumberOfLinks, FileIndexHigh, FileIndexLow;
    public string FinalPath;
    public static InstallerDirectoryLease Open(string path, uint expectedVolume,
        uint expectedIndexHigh, uint expectedIndexLow) {
      return Open(path, expectedVolume, expectedIndexHigh, expectedIndexLow, true);
    }
    public static InstallerDirectoryLease Open(string path, uint expectedVolume,
        uint expectedIndexHigh, uint expectedIndexLow, bool createMarker) {
      SafeFileHandle handle = InstallerLeaseNative.Open(path, 0x80, 0x02200000, 3);
      SafeFileHandle marker = null;
      try {
        InstallerLeaseInfo info = InstallerLeaseNative.Info(handle);
        if (info.VolumeSerialNumber != expectedVolume ||
            info.FileIndexHigh != expectedIndexHigh || info.FileIndexLow != expectedIndexLow)
          throw new System.IO.IOException("directory changed before binding lease");
        if (createMarker) {
          string markerPath = System.IO.Path.Combine(path,
            ".czxt-dir-lock-" + Guid.NewGuid().ToString("N") + ".tmp");
          marker = InstallerLeaseNative.CreateFileW(markerPath, 0x10080, 3,
            IntPtr.Zero, 1, 0x04200000, IntPtr.Zero);
          if (marker.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        }
        using (SafeFileHandle verify = InstallerLeaseNative.Open(path, 0x80, 0x02200000, 3)) {
          InstallerLeaseInfo rebound = InstallerLeaseNative.Info(verify);
          if (info.VolumeSerialNumber != rebound.VolumeSerialNumber ||
              info.FileIndexHigh != rebound.FileIndexHigh || info.FileIndexLow != rebound.FileIndexLow)
            throw new System.IO.IOException("directory changed while binding lease");
        }
        return new InstallerDirectoryLease { handle=handle, marker=marker,
          Attributes=info.Attributes,
          VolumeSerialNumber=info.VolumeSerialNumber, NumberOfLinks=info.NumberOfLinks,
          FileIndexHigh=info.FileIndexHigh, FileIndexLow=info.FileIndexLow,
          FinalPath=InstallerLeaseNative.FinalPath(handle) };
      } catch {
        if (marker != null) marker.Dispose();
        handle.Dispose(); throw;
      }
    }
    public void Dispose() {
      if (marker != null) { marker.Dispose(); marker=null; }
      if (handle != null) { handle.Dispose(); handle=null; }
    }
  }
  public sealed class InstallerFileLease : IDisposable {
    SafeFileHandle handle; bool canDelete;
    public uint Attributes, VolumeSerialNumber, NumberOfLinks, FileIndexHigh, FileIndexLow;
    public ulong Length; public string Sha256;
    public static InstallerFileLease Open(string path, bool forDelete) {
      uint access = 0x80000080 | (forDelete ? 0x10000u : 0u);
      SafeFileHandle handle = InstallerLeaseNative.Open(path, access, 0x00200000, 1);
      try {
        InstallerLeaseInfo before = InstallerLeaseNative.Info(handle);
        byte[] buffer = new byte[81920]; uint read; ulong length = 0;
        string hash;
        using (SHA256 sha256 = SHA256.Create()) {
          while (true) {
            if (!InstallerLeaseNative.ReadFile(handle, buffer, (uint)buffer.Length,
                out read, IntPtr.Zero))
              throw new Win32Exception(Marshal.GetLastWin32Error());
            if (read == 0) break;
            sha256.TransformBlock(buffer, 0, (int)read, buffer, 0); length += read;
          }
          sha256.TransformFinalBlock(new byte[0], 0, 0);
          hash = BitConverter.ToString(sha256.Hash).Replace("-", "").ToLowerInvariant();
        }
        InstallerLeaseInfo after = InstallerLeaseNative.Info(handle);
        if (before.VolumeSerialNumber != after.VolumeSerialNumber ||
            before.FileIndexHigh != after.FileIndexHigh || before.FileIndexLow != after.FileIndexLow ||
            InstallerLeaseNative.Length(before) != length ||
            InstallerLeaseNative.Length(after) != length)
          throw new System.IO.IOException("file changed while opening bound lease");
        return new InstallerFileLease { handle=handle, canDelete=forDelete,
          Attributes=after.Attributes, VolumeSerialNumber=after.VolumeSerialNumber,
          NumberOfLinks=after.NumberOfLinks, FileIndexHigh=after.FileIndexHigh,
          FileIndexLow=after.FileIndexLow, Length=length, Sha256=hash };
      } catch { handle.Dispose(); throw; }
    }
    public void DeleteBound() {
      if (!canDelete) throw new InvalidOperationException("lease has no delete access");
      InstallerDisposition disposition = new InstallerDisposition { DeleteFile=true };
      if (!InstallerLeaseNative.SetFileInformationByHandle(handle, 4,
          ref disposition, (uint)Marshal.SizeOf(typeof(InstallerDisposition))))
        throw new Win32Exception(Marshal.GetLastWin32Error());
    }
    public void Dispose() { if (handle != null) { handle.Dispose(); handle=null; } }
  }
}
'@
}

function Open-CzxtInstallerDirectoryLease {
  param(
    [string]$Path, [object]$ExpectedState, [string]$Context = '实例化目录',
    [switch]$WithoutMarker
  )
  foreach ($property in @('VolumeSerialNumber', 'FileIndexHigh', 'FileIndexLow')) {
    if ($null -eq $ExpectedState -or
        $null -eq $ExpectedState.PSObject.Properties[$property]) {
      throw ($Context + '缺少原生身份字段')
    }
  }
  $lease = [Czxt.InstallerDirectoryLease]::Open(
    $Path, [uint32]$ExpectedState.VolumeSerialNumber,
    [uint32]$ExpectedState.FileIndexHigh, [uint32]$ExpectedState.FileIndexLow,
    (-not $WithoutMarker.IsPresent))
  try {
    $canonical = $lease.FinalPath.Normalize([Text.NormalizationForm]::FormC)
    $canonical = $canonical.Replace('/', '\').TrimEnd('\')
    $actual = [pscustomobject]@{
      Path = Get-CzxtBorrowingFullPath $Path
      Identity = ('{0:x8}:{1:x8}:{2:x8}' -f $lease.VolumeSerialNumber,
        $lease.FileIndexHigh, $lease.FileIndexLow)
      VolumeSerialNumber = [uint32]$lease.VolumeSerialNumber
      FileIndexHigh = [uint32]$lease.FileIndexHigh
      FileIndexLow = [uint32]$lease.FileIndexLow
      NumberOfLinks = [uint32]$lease.NumberOfLinks
      CanonicalPath = $canonical
    }
    if (($lease.Attributes -band 0x400) -ne 0 -or ($lease.Attributes -band 0x10) -eq 0) {
      throw ($Context + '不是受信目录')
    }
    Assert-CzxtInstallerDirectoryStateStable $ExpectedState $actual $Context
    return [pscustomobject]@{ Native = $lease; State = $actual; Parent = $actual.Path }
  }
  catch { $lease.Dispose(); throw }
}

function Open-CzxtInstallerFileLease {
  param(
    [string]$Path, [object]$ExpectedState, [string]$Context = '实例化文件',
    [switch]$ForDelete, [switch]$AllowHardLinks
  )
  $lease = [Czxt.InstallerFileLease]::Open($Path, $ForDelete.IsPresent)
  try {
    $actual = ConvertTo-CzxtInstallerFileState -NativeState $lease -Path $Path `
      -Context $Context -AllowHardLinks:$AllowHardLinks
    Assert-CzxtInstallerStateMaterialEqual $ExpectedState $actual `
      ($Context + '身份在句柄绑定前发生变化') `
      -AllowHardLinks:$AllowHardLinks
    return [pscustomobject]@{ Native = $lease; State = $actual }
  }
  catch { $lease.Dispose(); throw }
}

function Open-CzxtInstallerParentDirectoryLease {
  param(
    [string]$ProjectRoot, [string]$TargetPath,
    [string]$Context = '实例化文件父目录'
  )
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $TargetPath -Context $Context
  $parent = Split-Path -Parent $target
  [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $parent -Context $Context)
  $parentState = Get-CzxtInstallerDirectoryState -Path $parent -Context $Context
  $lease = Open-CzxtInstallerDirectoryLease -Path $parent `
    -ExpectedState $parentState -Context $Context
  return [pscustomobject]@{
    Native = $lease.Native
    State = $lease.State
    Target = $target
    Parent = $parent
  }
}

function New-CzxtInstallerBoundProjectRoot {
  param(
    [string]$ProjectRoot, [string]$Context = '实例化 ProjectRoot 创建',
    [scriptblock]$BeforeParentLease, [scriptblock]$AfterParentLease
  )
  $target = Get-CzxtBorrowingFullPath $ProjectRoot
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $target -Context $Context)
  if ([IO.File]::Exists($target)) { throw ($Context + '被文件占用：' + $target) }

  $anchor = $target
  while (-not [IO.Directory]::Exists($anchor)) {
    if ([IO.File]::Exists($anchor)) { throw ($Context + '路径祖先不是目录：' + $anchor) }
    $parent = [IO.Directory]::GetParent($anchor)
    if ($null -eq $parent) { throw ($Context + '无法定位已存在祖先：' + $target) }
    $anchor = Get-CzxtBorrowingFullPath $parent.FullName
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $anchor -Context $Context)
  $relative = $target.Substring($anchor.Length).TrimStart('\', '/')
  $segments = if ([string]::IsNullOrEmpty($relative)) { @() } else { @($relative -split '[\\/]') }
  $current = $anchor
  $currentState = Get-CzxtInstallerDirectoryState -Path $current -Context $Context
  $currentLease = $null
  try {
    if ($segments.Count -eq 0) {
      $currentLease = Open-CzxtInstallerDirectoryLease -Path $current `
        -ExpectedState $currentState -Context $Context
      return $currentLease.State
    }
    foreach ($segment in $segments) {
      if ([string]::IsNullOrWhiteSpace($segment)) { throw ($Context + '路径段无效') }
      $next = Join-Path $current $segment
      if ($null -ne $BeforeParentLease) { & $BeforeParentLease $current $next }
      if ($null -eq $currentLease) {
        $currentLease = Open-CzxtInstallerDirectoryLease -Path $current `
          -ExpectedState $currentState -Context ($Context + '父目录')
      }
      if ($null -ne $AfterParentLease) { & $AfterParentLease $current $next }
      [void](Assert-CzxtBorrowingNoReparseAncestor -Path $next -Context $Context)
      if ([IO.File]::Exists($next)) { throw ($Context + '被文件占用：' + $next) }
      if (-not [IO.Directory]::Exists($next)) {
        [void][IO.Directory]::CreateDirectory($next)
      }
      [void](Assert-CzxtBorrowingNoReparseAncestor -Path $next -Context $Context)
      $nextState = Get-CzxtInstallerDirectoryState -Path $next -Context $Context
      $nextLease = Open-CzxtInstallerDirectoryLease -Path $next `
        -ExpectedState $nextState -Context $Context
      $currentLease.Native.Dispose()
      $currentLease = $nextLease
      $current = $next
      $currentState = $nextLease.State
    }
    return $currentState
  }
  finally {
    if ($null -ne $currentLease) { $currentLease.Native.Dispose() }
  }
}

function New-CzxtInstallerBoundDirectory {
  param(
    [string]$ProjectRoot, [string]$TargetPath,
    [string]$Context = '实例化目录创建', [scriptblock]$BeforeParentLease
  )
  $root = Get-CzxtBorrowingFullPath $ProjectRoot
  if (-not [IO.Directory]::Exists($root)) { throw ($Context + ' ProjectRoot 不存在') }
  $target = Assert-CzxtInstallerTargetPath -ProjectRoot $root `
    -CandidatePath $TargetPath -Context $Context
  if ($target.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
    return Get-CzxtInstallerDirectoryState $root $Context
  }
  $relative = $target.Substring($root.Length).TrimStart('\', '/')
  $current = $root
  $currentState = Get-CzxtInstallerDirectoryState $current $Context
  foreach ($segment in @($relative -split '[\\/]')) {
    if ([string]::IsNullOrWhiteSpace($segment)) { throw ($Context + '路径段无效') }
    $next = Join-Path $current $segment
    if ($null -ne $BeforeParentLease) { & $BeforeParentLease $current $next }
    $parentLease = Open-CzxtInstallerDirectoryLease -Path $current `
      -ExpectedState $currentState -Context ($Context + '父目录')
    try {
      [void](Assert-CzxtInstallerTargetPath -ProjectRoot $root `
        -CandidatePath $next -Context $Context)
      if ([IO.File]::Exists($next)) { throw ($Context + '被文件占用：' + $next) }
      if (-not [IO.Directory]::Exists($next)) {
        [void][IO.Directory]::CreateDirectory($next)
      }
      $currentState = Get-CzxtInstallerDirectoryState $next $Context
    }
    finally { $parentLease.Native.Dispose() }
    $current = $next
  }
  return $currentState
}
