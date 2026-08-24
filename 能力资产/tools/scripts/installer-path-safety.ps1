$ErrorActionPreference = 'Stop'

if (-not ('Czxt.InstallerPathNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;
namespace Czxt {
  [StructLayout(LayoutKind.Sequential)] public struct InstallerPathFt { public uint Low, High; }
  [StructLayout(LayoutKind.Sequential)] public struct InstallerPathInfo {
    public uint Attributes; public InstallerPathFt Creation, Access, Write;
    public uint VolumeSerialNumber, SizeHigh, SizeLow, NumberOfLinks, FileIndexHigh, FileIndexLow;
  }
  public sealed class InstallerPathState {
    public uint Attributes, VolumeSerialNumber, NumberOfLinks, FileIndexHigh, FileIndexLow;
    public string FinalPath;
  }
  public static class InstallerPathNative {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint access, uint share,
      IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern uint GetFinalPathNameByHandleW(SafeFileHandle handle,
      StringBuilder path, uint length, uint flags);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool GetFileInformationByHandle(SafeFileHandle handle,
      out InstallerPathInfo info);
    public static InstallerPathState Read(string path) {
      using (SafeFileHandle handle = CreateFileW(path, 0x80, 7, IntPtr.Zero,
          3, 0x02000000, IntPtr.Zero)) {
        if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        InstallerPathInfo info;
        if (!GetFileInformationByHandle(handle, out info))
          throw new Win32Exception(Marshal.GetLastWin32Error());
        StringBuilder buffer = new StringBuilder(32768);
        uint count = GetFinalPathNameByHandleW(handle, buffer,
          (uint)buffer.Capacity, 0x2);
        if (count == 0 || count >= buffer.Capacity)
          throw new Win32Exception(Marshal.GetLastWin32Error());
        return new InstallerPathState { Attributes=info.Attributes,
          VolumeSerialNumber=info.VolumeSerialNumber, NumberOfLinks=info.NumberOfLinks,
          FileIndexHigh=info.FileIndexHigh, FileIndexLow=info.FileIndexLow,
          FinalPath=buffer.ToString() };
      }
    }
    public static string GetNtPath(string path) { return Read(path).FinalPath; }
  }
}
'@
}

function Get-CzxtBorrowingFullPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { throw '路径不能为空。' }
  $full = [IO.Path]::GetFullPath($Path)
  $pathRoot = [IO.Path]::GetPathRoot($full)
  if ($full.Equals($pathRoot, [StringComparison]::OrdinalIgnoreCase)) { return $pathRoot }
  return $full.TrimEnd('\', '/')
}

function Test-CzxtBorrowingPathWithinRoot {
  param([string]$CandidatePath, [string]$RootPath)
  $candidate = Get-CzxtBorrowingFullPath $CandidatePath
  $root = Get-CzxtBorrowingFullPath $RootPath
  if ($candidate.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $candidate.StartsWith(($root + [IO.Path]::DirectorySeparatorChar),
    [StringComparison]::OrdinalIgnoreCase)
}

function Test-CzxtBorrowingPathStrictlyWithinRoot {
  param([string]$CandidatePath, [string]$RootPath)
  $candidate = Get-CzxtBorrowingFullPath $CandidatePath
  $root = Get-CzxtBorrowingFullPath $RootPath
  if ($candidate.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { return $false }
  return Test-CzxtBorrowingPathWithinRoot $candidate $root
}

function Assert-CzxtBorrowingNoReparseAncestor {
  param([string]$Path, [string]$Context)
  $full = Get-CzxtBorrowingFullPath $Path
  $pathRoot = [IO.Path]::GetPathRoot($full)
  if ([string]::IsNullOrWhiteSpace($pathRoot)) {
    throw ("{0}不是受支持的绝对路径：{1}" -f $Context, $Path)
  }
  $walk = New-Object 'Collections.Generic.List[string]'
  $walk.Add($pathRoot)
  $current = $pathRoot
  foreach ($segment in $full.Substring($pathRoot.Length).Split(
      @('\', '/'), [StringSplitOptions]::RemoveEmptyEntries)) {
    $current = Join-Path $current $segment
    $walk.Add($current)
  }
  foreach ($candidate in $walk) {
    if (-not (Test-Path -LiteralPath $candidate)) { break }
    $item = Get-Item -LiteralPath $candidate -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw ("{0}路径链包含 reparse point：{1}" -f $Context, $candidate)
    }
    if (-not $item.PSIsContainer -and
        -not $candidate.Equals($full, [StringComparison]::OrdinalIgnoreCase)) {
      throw ("{0}路径祖先不是目录：{1}" -f $Context, $candidate)
    }
  }
  return $full
}

function Assert-CzxtInstallerTargetPath {
  param([string]$ProjectRoot, [string]$CandidatePath, [string]$Context = '实例化目标')
  $project = Get-CzxtBorrowingFullPath $ProjectRoot
  $candidate = Get-CzxtBorrowingFullPath $CandidatePath
  if (-not (Test-CzxtBorrowingPathWithinRoot $candidate $project)) {
    throw ("{0}路径越出 ProjectRoot：{1}" -f $Context, $candidate)
  }
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $candidate -Context $Context)
  return $candidate
}

function Get-CzxtInstallerDirectoryState {
  param([string]$Path, [string]$Context = '实例化目录')
  $full = Get-CzxtBorrowingFullPath $Path
  if (-not [IO.Directory]::Exists($full)) { throw ("{0}不存在：{1}" -f $Context, $full) }
  $native = [Czxt.InstallerPathNative]::Read($full)
  if (($native.Attributes -band 0x400) -ne 0 -or
      ($native.Attributes -band 0x10) -eq 0) {
    throw ("{0}不是受信目录：{1}" -f $Context, $full)
  }
  $canonical = $native.FinalPath.Normalize([Text.NormalizationForm]::FormC)
  $canonical = $canonical.Replace('/', '\').TrimEnd('\')
  return [pscustomobject]@{
    Path = $full
    Identity = ('{0:x8}:{1:x8}:{2:x8}' -f $native.VolumeSerialNumber,
      $native.FileIndexHigh, $native.FileIndexLow)
    VolumeSerialNumber = [uint32]$native.VolumeSerialNumber
    FileIndexHigh = [uint32]$native.FileIndexHigh
    FileIndexLow = [uint32]$native.FileIndexLow
    NumberOfLinks = [uint32]$native.NumberOfLinks
    CanonicalPath = $canonical
  }
}

function Assert-CzxtInstallerDirectoryStateStable {
  param([object]$Expected, [object]$Actual, [string]$Context = '实例化目录')
  if ($null -eq $Expected -or $null -eq $Actual -or
      $Expected.Identity -cne $Actual.Identity -or
      $Expected.NumberOfLinks -ne $Actual.NumberOfLinks -or
      $Expected.CanonicalPath -cne $Actual.CanonicalPath) {
    $actualPath = if ($null -eq $Actual) { '<missing>' } else { $Actual.Path }
    throw ("{0}身份在预检后发生变化：{1}" -f $Context, $actualPath)
  }
}

function Resolve-CzxtInstallerFinalPath {
  param([string]$Path, [string]$Context = '实例化路径')
  $full = Get-CzxtBorrowingFullPath $Path
  [void](Assert-CzxtBorrowingNoReparseAncestor -Path $full -Context $Context)
  $probe = $full
  $suffix = New-Object 'Collections.Generic.List[string]'
  while (-not [IO.File]::Exists($probe) -and -not [IO.Directory]::Exists($probe)) {
    $leaf = [IO.Path]::GetFileName($probe)
    $parent = [IO.Directory]::GetParent($probe)
    if ([string]::IsNullOrEmpty($leaf) -or $null -eq $parent) {
      throw ("{0}无法定位已存在祖先：{1}" -f $Context, $full)
    }
    $suffix.Insert(0, $leaf)
    $probe = $parent.FullName
  }
  $canonical = [Czxt.InstallerPathNative]::GetNtPath($probe)
  $canonical = $canonical.Normalize([Text.NormalizationForm]::FormC)
  $canonical = $canonical.Replace('/', '\').TrimEnd('\')
  foreach ($segment in $suffix) { $canonical += '\' + $segment }
  return $canonical
}

function Test-CzxtInstallerCanonicalPathWithinRoot {
  param([string]$CandidatePath, [string]$RootPath)
  if ($CandidatePath.Equals($RootPath, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $CandidatePath.StartsWith(($RootPath.TrimEnd('\') + '\'),
    [StringComparison]::OrdinalIgnoreCase)
}

function Test-CzxtInstallerPathsOverlapFinal {
  param([string]$FirstPath, [string]$SecondPath)
  $first = Resolve-CzxtInstallerFinalPath $FirstPath '重叠路径 A'
  $second = Resolve-CzxtInstallerFinalPath $SecondPath '重叠路径 B'
  return (Test-CzxtInstallerCanonicalPathWithinRoot $first $second) -or
    (Test-CzxtInstallerCanonicalPathWithinRoot $second $first)
}
