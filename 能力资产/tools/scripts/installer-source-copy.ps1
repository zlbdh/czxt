$ErrorActionPreference = 'Stop'

if (-not ('Czxt.InstallerSourceNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using Microsoft.Win32.SafeHandles;
namespace Czxt {
  [StructLayout(LayoutKind.Sequential)] public struct InstallerSourceFt { public uint Low, High; }
  [StructLayout(LayoutKind.Sequential)] public struct InstallerSourceInfo {
    public uint Attributes; public InstallerSourceFt Creation, Access, Write;
    public uint VolumeSerialNumber, SizeHigh, SizeLow, NumberOfLinks, FileIndexHigh, FileIndexLow;
  }
  [StructLayout(LayoutKind.Sequential)] public struct InstallerSourceDisposition {
    [MarshalAs(UnmanagedType.Bool)] public bool DeleteFile;
  }
  public sealed class InstallerSourceState {
    public uint Attributes, VolumeSerialNumber, NumberOfLinks, FileIndexHigh, FileIndexLow;
    public ulong Length; public string Sha256;
  }
  public sealed class InstallerSourceCopyResult {
    public InstallerSourceState Source, Destination;
  }
  public static class InstallerSourceNative {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint access, uint share,
      IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool GetFileInformationByHandle(SafeFileHandle handle,
      out InstallerSourceInfo info);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool SetFileInformationByHandle(SafeFileHandle handle,
      int infoClass, ref InstallerSourceDisposition info, uint size);
    static ulong Length(InstallerSourceInfo info) {
      return ((ulong)info.SizeHigh << 32) | info.SizeLow;
    }
    static InstallerSourceState State(InstallerSourceInfo info, ulong length, byte[] digest) {
      return new InstallerSourceState { Attributes=info.Attributes,
        VolumeSerialNumber=info.VolumeSerialNumber, NumberOfLinks=info.NumberOfLinks,
        FileIndexHigh=info.FileIndexHigh, FileIndexLow=info.FileIndexLow,
        Length=length, Sha256=BitConverter.ToString(digest).Replace("-", "").ToLowerInvariant() };
    }
    static void AssertExpected(InstallerSourceInfo info, uint volume,
        uint indexHigh, uint indexLow, uint links, ulong length) {
      if ((info.Attributes & 0x410) != 0 || info.VolumeSerialNumber != volume ||
          info.FileIndexHigh != indexHigh || info.FileIndexLow != indexLow ||
          info.NumberOfLinks != links || Length(info) != length)
        throw new IOException("trusted source identity changed before streaming copy");
    }
    static SafeFileHandle CreateOwnedDestination(string path) {
      SafeFileHandle handle = CreateFileW(path, 0x40010080, 0,
        IntPtr.Zero, 1, 0x80000000, IntPtr.Zero);
      if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
      return handle;
    }
    static void DeleteOwnedDestination(SafeFileHandle handle) {
      InstallerSourceDisposition disposition =
        new InstallerSourceDisposition { DeleteFile=true };
      if (!SetFileInformationByHandle(handle, 4, ref disposition,
          (uint)Marshal.SizeOf(typeof(InstallerSourceDisposition))))
        throw new Win32Exception(Marshal.GetLastWin32Error());
    }
    public static InstallerSourceCopyResult CopyBound(string source, string destination,
        uint volume, uint indexHigh, uint indexLow, uint links, ulong length,
        string expectedSha256) {
      using (SafeFileHandle handle = CreateFileW(source, 0x80000080, 1,
          IntPtr.Zero, 3, 0x00200000, IntPtr.Zero)) {
        if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        InstallerSourceInfo before;
        if (!GetFileInformationByHandle(handle, out before))
          throw new Win32Exception(Marshal.GetLastWin32Error());
        AssertExpected(before, volume, indexHigh, indexLow, links, length);
        SafeFileHandle destinationHandle = CreateOwnedDestination(destination);
        bool keepDestination = false, deleteMarked = false;
        try {
          using (FileStream input = new FileStream(handle, FileAccess.Read, 81920, false))
          using (FileStream output = new FileStream(destinationHandle,
              FileAccess.Write, 81920, false))
          using (SHA256 sha256 = SHA256.Create()) {
            try {
              byte[] buffer = new byte[81920]; ulong copied = 0;
              int read;
              while ((read = input.Read(buffer, 0, buffer.Length)) > 0) {
                output.Write(buffer, 0, read);
                sha256.TransformBlock(buffer, 0, read, buffer, 0);
                copied += (uint)read;
              }
              sha256.TransformFinalBlock(new byte[0], 0, 0);
              output.Flush(true);
              byte[] digest = sha256.Hash;
              InstallerSourceInfo destinationInfo;
              if (!GetFileInformationByHandle(output.SafeFileHandle, out destinationInfo))
                throw new Win32Exception(Marshal.GetLastWin32Error());
              InstallerSourceInfo after;
              if (!GetFileInformationByHandle(handle, out after))
                throw new Win32Exception(Marshal.GetLastWin32Error());
              AssertExpected(after, volume, indexHigh, indexLow, links, length);
              string hash = BitConverter.ToString(digest).Replace("-", "").ToLowerInvariant();
              if (copied != length || !String.Equals(hash, expectedSha256,
                  StringComparison.Ordinal))
                throw new IOException("trusted source digest changed during streaming copy");
              if (Length(destinationInfo) != copied)
                throw new IOException("prepared destination length changed during streaming copy");
              InstallerSourceCopyResult result = new InstallerSourceCopyResult {
                Source=State(before, length, digest),
                Destination=State(destinationInfo, copied, digest) };
              keepDestination = true;
              return result;
            } catch {
              DeleteOwnedDestination(output.SafeFileHandle); deleteMarked = true; throw;
            }
          }
        } catch {
          if (!keepDestination && !deleteMarked && !destinationHandle.IsClosed) {
            DeleteOwnedDestination(destinationHandle);
          }
          throw;
        } finally { destinationHandle.Dispose(); }
      }
    }
    public static InstallerSourceState WriteNew(string destination, byte[] first, byte[] second) {
      if (first == null) first = new byte[0];
      if (second == null) second = new byte[0];
      SafeFileHandle destinationHandle = CreateOwnedDestination(destination);
      bool keepDestination = false, deleteMarked = false;
      try {
        using (FileStream output = new FileStream(destinationHandle,
            FileAccess.Write, 81920, false))
        using (SHA256 sha256 = SHA256.Create()) {
          try {
            if (first.Length > 0) { output.Write(first, 0, first.Length);
              sha256.TransformBlock(first, 0, first.Length, first, 0); }
            if (second.Length > 0) { output.Write(second, 0, second.Length);
              sha256.TransformBlock(second, 0, second.Length, second, 0); }
            sha256.TransformFinalBlock(new byte[0], 0, 0);
            output.Flush(true);
            InstallerSourceInfo info;
            if (!GetFileInformationByHandle(output.SafeFileHandle, out info))
              throw new Win32Exception(Marshal.GetLastWin32Error());
            ulong length = (ulong)first.LongLength + (ulong)second.LongLength;
            if (Length(info) != length) throw new IOException("prepared write length mismatch");
            InstallerSourceState result = State(info, length, sha256.Hash);
            keepDestination = true;
            return result;
          } catch {
            DeleteOwnedDestination(output.SafeFileHandle); deleteMarked = true; throw;
          }
        }
      } catch {
        if (!keepDestination && !deleteMarked && !destinationHandle.IsClosed) {
          DeleteOwnedDestination(destinationHandle);
        }
        throw;
      } finally { destinationHandle.Dispose(); }
    }
  }
}
'@
}

function Copy-CzxtInstallerTrustedSource {
  param(
    [string]$SourcePath,
    [string]$DestinationPath,
    [object]$ExpectedState,
    [string]$Context = '实例化来源文件'
  )
  if ($null -eq $ExpectedState) { throw ($Context + '缺少预检状态') }
  $identity = @($ExpectedState.Identity -split ':')
  if ($identity.Count -ne 3) { throw ($Context + '预检 identity 无效') }
  $result = [Czxt.InstallerSourceNative]::CopyBound(
    $SourcePath, $DestinationPath,
    [Convert]::ToUInt32($identity[0], 16),
    [Convert]::ToUInt32($identity[1], 16),
    [Convert]::ToUInt32($identity[2], 16),
    [uint32]$ExpectedState.NumberOfLinks,
    [uint64]$ExpectedState.Length,
    [string]$ExpectedState.Sha256)
  $actual = ConvertTo-CzxtInstallerFileState -NativeState $result.Source `
    -Path $SourcePath -Context $Context
  Assert-CzxtInstallerFileStateStable $ExpectedState $actual $Context
  return ConvertTo-CzxtInstallerFileState -NativeState $result.Destination `
    -Path $DestinationPath -Context ($Context + '临时文件')
}

function New-CzxtInstallerPreparedFile {
  param(
    [string]$DestinationPath, [byte[]]$FirstBytes, [byte[]]$SecondBytes,
    [string]$Context = '实例化临时文件'
  )
  $native = [Czxt.InstallerSourceNative]::WriteNew(
    $DestinationPath, $FirstBytes, $SecondBytes)
  return ConvertTo-CzxtInstallerFileState -NativeState $native `
    -Path $DestinationPath -Context $Context
}
