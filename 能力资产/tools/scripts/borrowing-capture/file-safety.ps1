$ErrorActionPreference = 'Stop'

$fileSafetyModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $fileSafetyModuleRoot 'file-safety-relation.ps1')

if (-not ('Czxt.B.NP' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;
namespace Czxt.B {
 [StructLayout(LayoutKind.Sequential)] public struct FT { public uint L,H; }
 [StructLayout(LayoutKind.Sequential)] public struct FI {
  public uint FileAttributes; public FT C,A,W; public uint VolumeSerialNumber;
  public uint FileSizeHigh,FileSizeLow,NumberOfLinks,FileIndexHigh,FileIndexLow;
 }
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] public struct SD {
  public long Size;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=296)] public string StreamName;
 }
  public static class NP {
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
  public static extern SafeFileHandle CreateFileW(string n,uint a,uint s,IntPtr p,uint c,uint f,IntPtr t);
  [DllImport("kernel32.dll",SetLastError=true)]
  public static extern bool GetFileInformationByHandle(SafeFileHandle h,out FI i);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
  public static extern uint GetFinalPathNameByHandleW(SafeFileHandle h,StringBuilder p,uint l,uint f);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode)] public static extern uint GetDriveTypeW(string r);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
  public static extern uint QueryDosDeviceW(string d,StringBuilder t,uint l);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
  public static extern IntPtr FindFirstStreamW(string n,int l,out SD d,uint f);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
  public static extern bool FindNextStreamW(IntPtr f,out SD d);
  [DllImport("kernel32.dll",SetLastError=true)] public static extern bool FindClose(IntPtr f);
  }
}
'@
}

function global:Stop-Bsp {
  param($Stage, $ReasonCode)
  Throw-BorrowingFailure -Stage $Stage -ReasonCode $ReasonCode -Reason 'unsafe path'
}

function global:Test-BspR {
  param($Segment)
  $stem = ($Segment -split '\.', 2)[0]
  return $stem -match '^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])$'
}

function global:ConvertTo-Bsp {
  param($Path, $Stage, $ReasonCode)
  try {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'x' }
    $value = $Path.Normalize([Text.NormalizationForm]::FormC).Replace('/', '\')
    if ($value -notmatch '^[A-Za-z]:\\') { throw 'x' }
    if ($value.IndexOf(':', 2) -ge 0) { throw 'x' }
    foreach ($character in $value.ToCharArray()) {
      $code = [int]$character
      if ($code -le 31 -or ($code -ge 127 -and $code -le 159) -or
          $code -eq 0x2028 -or $code -eq 0x2029) { throw 'x' }
    }
    $tail = $value.Substring(3)
    if ($tail.Length -gt 0) {
      foreach ($segment in $tail.Split([char]'\')) {
        if ($segment.Length -eq 0 -or $segment.EndsWith(' ') -or
            $segment.EndsWith('.') -or $segment -match '[<>"|?*]' -or
            (Test-BspR $segment)) { throw 'x' }
      }
    }
    $full = [IO.Path]::GetFullPath($value).Normalize([Text.NormalizationForm]::FormC)
    return $full.Substring(0, 1).ToUpperInvariant() + $full.Substring(1)
  }
  catch {
    Stop-Bsp $Stage $ReasonCode
  }
}

function global:Assert-BspS {
  param($Path, $Stage, $ReasonCode)
  $data = New-Object Czxt.B.SD
  $find = [Czxt.B.NP]::FindFirstStreamW($Path, 0, [ref]$data, 0)
  $invalid = [IntPtr](-1)
  if ($find -eq $invalid) {
    if ([Runtime.InteropServices.Marshal]::GetLastWin32Error() -eq 38) { return }
    Stop-Bsp $Stage $ReasonCode
  }
  try {
    while ($true) {
      if ($data.StreamName -cne '::$DATA') {
        Stop-Bsp $Stage $ReasonCode
      }
      $data = New-Object Czxt.B.SD
      if (-not [Czxt.B.NP]::FindNextStreamW($find, [ref]$data)) {
        if ([Runtime.InteropServices.Marshal]::GetLastWin32Error() -ne 38) {
          Stop-Bsp $Stage $ReasonCode
        }
        break
      }
    }
  }
  finally { [void][Czxt.B.NP]::FindClose($find) }
}

function global:Open-Bsp {
  param($Path, $Stage, $ReasonCode)
  $handle = [Czxt.B.NP]::CreateFileW(
    $Path, 0x80, 7, [IntPtr]::Zero, 3, 0x02200000, [IntPtr]::Zero
  )
  if ($null -eq $handle -or $handle.IsInvalid) {
    if ($null -ne $handle) { $handle.Dispose() }
    Stop-Bsp $Stage $ReasonCode
  }
  try {
    $info = New-Object Czxt.B.FI
    if (-not [Czxt.B.NP]::GetFileInformationByHandle($handle, [ref]$info)) {
      Stop-Bsp $Stage $ReasonCode
    }
    $buffer = New-Object Text.StringBuilder 32768
    $count = [Czxt.B.NP]::GetFinalPathNameByHandleW(
      $handle, $buffer, [uint32]$buffer.Capacity, 0
    )
    if ($count -eq 0 -or $count -ge $buffer.Capacity) {
      Stop-Bsp $Stage $ReasonCode
    }
    return [pscustomobject]@{ Information = $info; FinalPath = $buffer.ToString() }
  }
  finally { $handle.Dispose() }
}

function global:Get-BorrowingSafePathInfo {
  param(
    $Path,
    $ExpectedKind,
    $Stage,
    $ReasonCode,
    [bool]$AllowHardLinks = $false,
    [bool]$AllowAncestorStreams = $false
  )
  if ($ExpectedKind -notin @('File', 'Directory')) {
    Stop-Bsp $Stage $ReasonCode
  }
  $full = ConvertTo-Bsp $Path $Stage $ReasonCode
  $root = $full.Substring(0, 3)
  if ([Czxt.B.NP]::GetDriveTypeW($root) -ne 3) {
    Stop-Bsp $Stage $ReasonCode
  }
  $mapping = New-Object Text.StringBuilder 32768
  if ([Czxt.B.NP]::QueryDosDeviceW(
      $full.Substring(0, 2), $mapping, [uint32]$mapping.Capacity) -eq 0) {
    Stop-Bsp $Stage $ReasonCode
  }
  $target = $mapping.ToString()
  $isSubst = $false
  foreach ($prefix in @('\??\', '\DosDevices\')) {
    if ($target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
      $rest = $target.Substring($prefix.Length)
      if ($rest -match '^[A-Za-z]:\\') { $isSubst = $true }
    }
  }
  if ($isSubst) { Stop-Bsp $Stage $ReasonCode }

  $walk = @($root)
  $current = $root.TrimEnd('\')
  foreach ($segment in $full.Substring(3).Split([char]'\')) {
    if ($segment.Length -gt 0) {
      $current += '\' + $segment
      $walk += $current
    }
  }
  $final = $null
  foreach ($candidate in $walk) {
    $native = Open-Bsp $candidate $Stage $ReasonCode
    $attributes = [uint32]$native.Information.FileAttributes
    if (($attributes -band 0x400) -ne 0) {
      Stop-Bsp $Stage $ReasonCode
    }
    $isDirectory = ($attributes -band 0x10) -ne 0
    if ($candidate -ne $full -and -not $isDirectory) {
      Stop-Bsp $Stage $ReasonCode
    }
    # 卷根 ADS 属卷元数据；目标及项目内祖先仍必查。
    $isVolumeRoot = $candidate.Equals($root, [StringComparison]::OrdinalIgnoreCase)
    if ($candidate -eq $full -or
        (-not $AllowAncestorStreams -and -not $isVolumeRoot)) {
      Assert-BspS $candidate $Stage $ReasonCode
    }
    $final = $native
  }
  $kind = if (($final.Information.FileAttributes -band 0x10) -ne 0) { 'Directory' } else { 'File' }
  if ($kind -cne $ExpectedKind) {
    Stop-Bsp $Stage $ReasonCode
  }
  if ($kind -eq 'File' -and -not $AllowHardLinks -and `
      $final.Information.NumberOfLinks -ne 1) {
    Stop-Bsp $Stage $ReasonCode
  }
  $canonical = $final.FinalPath.Normalize([Text.NormalizationForm]::FormC).Replace('/', '\')
  if (-not $canonical.StartsWith('\\?\', [StringComparison]::Ordinal)) {
    Stop-Bsp $Stage $ReasonCode
  }
  $canonical = $canonical.Substring(4)
  if ($canonical -notmatch '^[A-Za-z]:\\') {
    Stop-Bsp $Stage $ReasonCode
  }
  $canonical = $canonical.Substring(0, 1).ToUpperInvariant() + $canonical.Substring(1)
  $length = ([uint64]$final.Information.FileSizeHigh * 4294967296) +
    [uint64]$final.Information.FileSizeLow
  $identity = '{0:x8}:{1:x8}:{2:x8}' -f $final.Information.VolumeSerialNumber,
    $final.Information.FileIndexHigh, $final.Information.FileIndexLow
  return [pscustomobject]@{
    Schema = 'borrowing-safe-path/v1'
    Kind = $kind
    CanonicalPath = $canonical
    IdentityKey = $identity
    Length = $length
    NumberOfLinks = [uint32]$final.Information.NumberOfLinks
    DriveType = 'Fixed'
    IsSubst = $false
  }
}
