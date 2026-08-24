$ErrorActionPreference = 'Stop'

if (-not ('Czxt.B.AtomicDirectoryLease' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Czxt.B {
  [StructLayout(LayoutKind.Sequential)]
  internal struct AtomicUnicodeString {
    internal ushort Length;
    internal ushort MaximumLength;
    internal IntPtr Buffer;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct AtomicObjectAttributes {
    internal uint Length;
    internal IntPtr RootDirectory;
    internal IntPtr ObjectName;
    internal uint Attributes;
    internal IntPtr SecurityDescriptor;
    internal IntPtr SecurityQualityOfService;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct AtomicIoStatusBlock {
    internal IntPtr Status;
    internal UIntPtr Information;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct AtomicFileTime { internal uint Low, High; }

  [StructLayout(LayoutKind.Sequential)]
  internal struct AtomicFileInformation {
    internal uint FileAttributes;
    internal AtomicFileTime CreationTime, LastAccessTime, LastWriteTime;
    internal uint VolumeSerialNumber;
    internal uint FileSizeHigh, FileSizeLow, NumberOfLinks;
    internal uint FileIndexHigh, FileIndexLow;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct AtomicDispositionInformation {
    [MarshalAs(UnmanagedType.U1)] internal bool DeleteFile;
  }

  public sealed class AtomicDirectoryLease : IDisposable {
    [DllImport("ntdll.dll")]
    static extern int NtCreateFile(out SafeFileHandle fileHandle,
      uint desiredAccess, ref AtomicObjectAttributes objectAttributes,
      out AtomicIoStatusBlock ioStatusBlock, IntPtr allocationSize,
      uint fileAttributes, uint shareAccess, uint createDisposition,
      uint createOptions, IntPtr eaBuffer, uint eaLength);

    [DllImport("ntdll.dll")]
    static extern int NtSetInformationFile(SafeFileHandle fileHandle,
      out AtomicIoStatusBlock ioStatusBlock, IntPtr fileInformation,
      uint length, int fileInformationClass);

    [DllImport("ntdll.dll")]
    static extern uint RtlNtStatusToDosError(int status);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint desiredAccess,
      uint shareMode, IntPtr securityAttributes, uint creationDisposition,
      uint flagsAndAttributes, IntPtr templateFile);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool GetFileInformationByHandle(
      SafeFileHandle handle, out AtomicFileInformation information);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern uint GetFinalPathNameByHandleW(
      SafeFileHandle handle, StringBuilder path, uint length, uint flags);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool SetFileInformationByHandle(SafeFileHandle handle,
      int informationClass, ref AtomicDispositionInformation information,
      uint bufferSize);

    public SafeFileHandle Handle { get; private set; }
    public uint VolumeSerialNumber { get; private set; }
    public uint FileIndexHigh { get; private set; }
    public uint FileIndexLow { get; private set; }
    public string FinalPath { get; private set; }
    public bool Created { get; private set; }

    static void AssertNativeLayout() {
      int expectedUnicode = IntPtr.Size == 8 ? 16 : 8;
      int expectedAttributes = IntPtr.Size == 8 ? 48 : 24;
      int expectedStatus = IntPtr.Size == 8 ? 16 : 8;
      if (Marshal.SizeOf(typeof(AtomicUnicodeString)) != expectedUnicode ||
          Marshal.SizeOf(typeof(AtomicObjectAttributes)) != expectedAttributes ||
          Marshal.SizeOf(typeof(AtomicIoStatusBlock)) != expectedStatus ||
          Marshal.SizeOf(typeof(AtomicFileInformation)) != 52)
        throw new PlatformNotSupportedException(
          "atomic directory native layout is unsupported");
    }

    static AtomicFileInformation ReadInformation(
        SafeFileHandle handle, bool allowReparse) {
      AtomicFileInformation information;
      if (!GetFileInformationByHandle(handle, out information))
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "atomic directory identity failed");
      if ((information.FileAttributes & 0x10) == 0 ||
          (!allowReparse && (information.FileAttributes & 0x400) != 0))
        throw new System.IO.IOException("atomic directory kind is unsafe");
      return information;
    }

    static string ReadFinalPath(SafeFileHandle handle) {
      StringBuilder path = new StringBuilder(32768);
      uint count = GetFinalPathNameByHandleW(
        handle, path, (uint)path.Capacity, 0);
      if (count == 0 || count >= path.Capacity)
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "atomic directory final path failed");
      return path.ToString();
    }

    static AtomicDirectoryLease FromHandle(
        SafeFileHandle handle, bool created) {
      if (handle == null || handle.IsInvalid)
        throw new System.IO.IOException("atomic directory handle is invalid");
      AtomicFileInformation information = ReadInformation(handle, false);
      string finalPath = ReadFinalPath(handle);
      return new AtomicDirectoryLease {
        Handle = handle,
        VolumeSerialNumber = information.VolumeSerialNumber,
        FileIndexHigh = information.FileIndexHigh,
        FileIndexLow = information.FileIndexLow,
        FinalPath = finalPath,
        Created = created
      };
    }

    public static AtomicDirectoryLease OpenExisting(string fullDosPath) {
      AssertNativeLayout();
      SafeFileHandle handle = CreateFileW(fullDosPath, 0x001100A1, 3,
        IntPtr.Zero, 3, 0x02200000, IntPtr.Zero);
      if (handle == null || handle.IsInvalid) {
        int code = Marshal.GetLastWin32Error();
        if (handle != null) handle.Dispose();
        throw new Win32Exception(code, "atomic parent directory open failed");
      }
      try {
        AtomicDirectoryLease lease = FromHandle(handle, false);
        handle = null;
        return lease;
      }
      finally { if (handle != null) handle.Dispose(); }
    }

    public static AtomicDirectoryLease CreateRelative(
        AtomicDirectoryLease parent, string leafName) {
      AssertNativeLayout();
      if (parent == null) throw new ArgumentNullException("parent");
      if (String.IsNullOrEmpty(leafName) || leafName == "." || leafName == ".." ||
          leafName.IndexOfAny(new char[] {'\\', '/', ':'}) >= 0)
        throw new ArgumentException("atomic directory leaf is unsafe", "leafName");
      parent.Verify();
      IntPtr buffer = IntPtr.Zero;
      IntPtr unicodePointer = IntPtr.Zero;
      SafeFileHandle handle = null;
      bool parentReference = false;
      bool created = false;
      try {
        buffer = Marshal.StringToHGlobalUni(leafName);
        AtomicUnicodeString unicode = new AtomicUnicodeString {
          Length = checked((ushort)(leafName.Length * 2)),
          MaximumLength = checked((ushort)((leafName.Length + 1) * 2)),
          Buffer = buffer
        };
        unicodePointer = Marshal.AllocHGlobal(
          Marshal.SizeOf(typeof(AtomicUnicodeString)));
        Marshal.StructureToPtr(unicode, unicodePointer, false);
        parent.Handle.DangerousAddRef(ref parentReference);
        AtomicObjectAttributes attributes = new AtomicObjectAttributes {
          Length = (uint)Marshal.SizeOf(typeof(AtomicObjectAttributes)),
          RootDirectory = parent.Handle.DangerousGetHandle(),
          ObjectName = unicodePointer,
          Attributes = 0x1040,
          SecurityDescriptor = IntPtr.Zero,
          SecurityQualityOfService = IntPtr.Zero
        };
        AtomicIoStatusBlock statusBlock;
        int status = NtCreateFile(out handle, 0x001100A1, ref attributes,
          out statusBlock, IntPtr.Zero, 0x80, 3, 2, 0x00200021,
          IntPtr.Zero, 0);
        if (status < 0) {
          if (handle != null) handle.Dispose();
          handle = null;
          throw new Win32Exception((int)RtlNtStatusToDosError(status),
            "atomic directory create failed");
        }
        if (handle == null || handle.IsInvalid ||
            statusBlock.Information.ToUInt64() != 2)
          throw new System.IO.IOException(
            "atomic directory create did not return FILE_CREATED");
        created = true;
        AtomicDirectoryLease lease = FromHandle(handle, true);
        handle = null;
        return lease;
      }
      catch (Exception creationFailure) {
        Exception cleanupFailure = null;
        if (created && handle != null && !handle.IsInvalid) {
          try {
            AtomicDispositionInformation disposition =
              new AtomicDispositionInformation { DeleteFile = true };
            if (!SetFileInformationByHandle(handle, 4, ref disposition,
                (uint)Marshal.SizeOf(typeof(AtomicDispositionInformation))))
              cleanupFailure = new Win32Exception(Marshal.GetLastWin32Error(),
                "atomic directory create compensation failed");
          }
          catch (Exception error) { cleanupFailure = error; }
        }
        if (cleanupFailure != null)
          throw new System.IO.IOException(
            "atomic directory create failed and compensation failed",
            new AggregateException(creationFailure, cleanupFailure));
        throw;
      }
      finally {
        if (handle != null) handle.Dispose();
        if (parentReference) parent.Handle.DangerousRelease();
        if (unicodePointer != IntPtr.Zero) Marshal.FreeHGlobal(unicodePointer);
        if (buffer != IntPtr.Zero) Marshal.FreeHGlobal(buffer);
      }
    }

    public static string RenameHandleRelative(SafeFileHandle sourceHandle,
        uint sourceVolumeSerialNumber, AtomicDirectoryLease destinationParent,
        string leafName) {
      AssertNativeLayout();
      if (sourceHandle == null || sourceHandle.IsInvalid || sourceHandle.IsClosed)
        throw new ArgumentException("atomic rename source is invalid",
          "sourceHandle");
      if (destinationParent == null)
        throw new ArgumentNullException("destinationParent");
      if (String.IsNullOrEmpty(leafName) || leafName == "." || leafName == ".." ||
          leafName.IndexOfAny(new char[] {'\\', '/', ':'}) >= 0)
        throw new ArgumentException("atomic rename leaf is unsafe", "leafName");
      destinationParent.Verify();
      if (sourceVolumeSerialNumber != destinationParent.VolumeSerialNumber)
        throw new System.IO.IOException(
          "atomic rename cannot target a different volume");

      byte[] nameBytes = Encoding.Unicode.GetBytes(leafName);
      int rootOffset = IntPtr.Size == 8 ? 8 : 4;
      int lengthOffset = checked(rootOffset + IntPtr.Size);
      int nameOffset = checked(lengthOffset + 4);
      int structureSize = IntPtr.Size == 8 ? 24 : 16;
      int bufferSize = checked(structureSize + nameBytes.Length);
      byte[] zeroed = new byte[bufferSize];
      IntPtr renameBuffer = IntPtr.Zero;
      SafeFileHandle destinationHandle = destinationParent.Handle;
      bool destinationReference = false;
      try {
        destinationHandle.DangerousAddRef(ref destinationReference);
        renameBuffer = Marshal.AllocHGlobal(bufferSize);
        Marshal.Copy(zeroed, 0, renameBuffer, bufferSize);
        Marshal.WriteInt32(renameBuffer, 0, 0);
        Marshal.WriteIntPtr(renameBuffer, rootOffset,
          destinationHandle.DangerousGetHandle());
        Marshal.WriteInt32(renameBuffer, lengthOffset, nameBytes.Length);
        Marshal.Copy(nameBytes, 0, IntPtr.Add(renameBuffer, nameOffset),
          nameBytes.Length);
        AtomicIoStatusBlock statusBlock;
        int status = NtSetInformationFile(sourceHandle, out statusBlock,
          renameBuffer, (uint)bufferSize, 10);
        if (status < 0)
          throw new Win32Exception((int)RtlNtStatusToDosError(status),
            "atomic handle-relative rename failed");

        string finalPath = ReadFinalPath(sourceHandle);
        string expectedPath = destinationParent.FinalPath.TrimEnd('\\') +
          "\\" + leafName;
        if (!String.Equals(finalPath, expectedPath,
            StringComparison.OrdinalIgnoreCase))
          throw new System.IO.IOException(
            "atomic handle-relative rename final path changed");
        destinationParent.Verify();
        return finalPath;
      }
      finally {
        if (renameBuffer != IntPtr.Zero) Marshal.FreeHGlobal(renameBuffer);
        if (destinationReference) destinationHandle.DangerousRelease();
      }
    }

    public void RenameRelative(AtomicDirectoryLease destinationParent,
        string leafName) {
      Verify();
      string finalPath = RenameHandleRelative(Handle, VolumeSerialNumber,
        destinationParent, leafName);
      FinalPath = finalPath;
      RefreshFromHandle();
    }

    public void RefreshFromHandle() {
      if (Handle == null || Handle.IsInvalid || Handle.IsClosed)
        throw new ObjectDisposedException("AtomicDirectoryLease");
      AtomicFileInformation information = ReadInformation(Handle, false);
      string finalPath = ReadFinalPath(Handle);
      if (information.VolumeSerialNumber != VolumeSerialNumber ||
          information.FileIndexHigh != FileIndexHigh ||
          information.FileIndexLow != FileIndexLow)
        throw new System.IO.IOException(
          "atomic directory identity changed during refresh");
      FinalPath = finalPath;
    }

    public void Verify() {
      if (Handle == null || Handle.IsInvalid || Handle.IsClosed)
        throw new ObjectDisposedException("AtomicDirectoryLease");
      AtomicFileInformation information = ReadInformation(Handle, false);
      string finalPath = ReadFinalPath(Handle);
      if (information.VolumeSerialNumber != VolumeSerialNumber ||
          information.FileIndexHigh != FileIndexHigh ||
          information.FileIndexLow != FileIndexLow ||
          !String.Equals(finalPath, FinalPath,
            StringComparison.OrdinalIgnoreCase))
        throw new System.IO.IOException("atomic directory lease changed");
    }

    public void DeleteCreated() {
      if (!Created) throw new InvalidOperationException(
        "only an atomically created directory can be deleted by this lease");
      if (Handle == null || Handle.IsInvalid || Handle.IsClosed)
        throw new ObjectDisposedException("AtomicDirectoryLease");
      AtomicFileInformation information = ReadInformation(Handle, true);
      if (information.VolumeSerialNumber != VolumeSerialNumber ||
          information.FileIndexHigh != FileIndexHigh ||
          information.FileIndexLow != FileIndexLow)
        throw new System.IO.IOException(
          "atomic directory delete ownership changed");
      AtomicDispositionInformation disposition =
        new AtomicDispositionInformation { DeleteFile = true };
      if (!SetFileInformationByHandle(Handle, 4, ref disposition,
          (uint)Marshal.SizeOf(typeof(AtomicDispositionInformation))))
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "atomic directory handle delete failed");
      Dispose();
    }

    public void Dispose() {
      SafeFileHandle handle = Handle;
      Handle = null;
      if (handle != null) handle.Dispose();
    }
  }
}
'@
}

function ConvertFrom-BctNativeDirectoryPath {
  param([string]$Path)
  $canonical = $Path.Normalize([Text.NormalizationForm]::FormC).Replace('/', '\')
  Assert-BciCondition ($canonical.StartsWith('\\?\', [StringComparison]::Ordinal) -and
      $canonical.Length -ge 7) 'close staging 原子目录最终路径无效'
  $canonical = $canonical.Substring(4)
  Assert-BciCondition ($canonical -match '\A[A-Za-z]:\\') `
    'close staging 原子目录不是盘符路径'
  return $canonical.Substring(0, 1).ToUpperInvariant() + $canonical.Substring(1)
}

function Open-BctOwnedParentDirectory {
  param($Expected)
  Assert-BciCondition ($null -ne $Expected -and
      -not [string]::IsNullOrWhiteSpace([string]$Expected.CanonicalPath) -and
      -not [string]::IsNullOrWhiteSpace([string]$Expected.IdentityKey)) `
    'close staging 缺少受信父目录快照'
  $lease = $null
  try {
    $lease = [Czxt.B.AtomicDirectoryLease]::OpenExisting(
      [string]$Expected.CanonicalPath)
    $canonical = ConvertFrom-BctNativeDirectoryPath $lease.FinalPath
    Assert-BciCondition ([string]::Equals(
        $canonical, [string]$Expected.CanonicalPath,
        [StringComparison]::OrdinalIgnoreCase)) `
      'close staging 父目录物理路径改变'
    $identity = '{0:x8}:{1:x8}:{2:x8}' -f `
      $lease.VolumeSerialNumber, $lease.FileIndexHigh, $lease.FileIndexLow
    Assert-BciCondition ($identity -ceq [string]$Expected.IdentityKey) `
      'close staging 父目录身份改变'
    return [pscustomobject]@{
      Path = $canonical
      CanonicalPath = $canonical
      IdentityKey = $identity
      Native = $lease
    }
  }
  catch {
    if ($null -ne $lease) { $lease.Dispose() }
    throw
  }
}

function New-BctOwnedDirectory {
  param($Parent, [string]$LeafName)
  $parentLease = Open-BctOwnedParentDirectory $Parent
  $lease = $null
  try {
    $expected = [IO.Path]::GetFullPath(
      (Join-Path $parentLease.CanonicalPath $LeafName)).Normalize(
        [Text.NormalizationForm]::FormC)
    $lease = [Czxt.B.AtomicDirectoryLease]::CreateRelative(
      $parentLease.Native, $LeafName)
    $canonical = ConvertFrom-BctNativeDirectoryPath $lease.FinalPath
    Assert-BciCondition ([string]::Equals(
        $canonical, $expected, [StringComparison]::OrdinalIgnoreCase)) `
      'close staging 原子目录物理路径改变'
    return [pscustomobject]@{
      Path = $canonical
      CanonicalPath = $canonical
      IdentityKey = '{0:x8}:{1:x8}:{2:x8}' -f `
        $lease.VolumeSerialNumber, $lease.FileIndexHigh, $lease.FileIndexLow
      Native = $lease
      Parent = $parentLease
    }
  }
  catch {
    $creationFailure = $_
    $cleanupFailure = $null
    if ($null -ne $lease) {
      try { $lease.DeleteCreated() }
      catch { $cleanupFailure = $_; try { $lease.Dispose() } catch { } }
    }
    try { $parentLease.Native.Dispose() } catch { }
    $parentLease.Native = $null
    if ($null -ne $cleanupFailure) {
      throw ('close staging 原子目录验证失败且同句柄补偿失败：' +
        $cleanupFailure.Exception.Message)
    }
    throw $creationFailure
  }
}

function Assert-BctOwnedDirectoryLease {
  param($Directory)
  Assert-BciCondition ($null -ne $Directory -and $null -ne $Directory.Native) `
    'close staging 缺少原子目录 lease'
  Assert-BciCondition ($null -ne $Directory.Parent -and
      $null -ne $Directory.Parent.Native) 'close staging 缺少父目录 lease'
  $Directory.Parent.Native.Verify()
  $Directory.Native.Verify()
}

function Close-BctOwnedDirectoryLease {
  param($Directory)
  if ($null -eq $Directory) { return }
  if ($null -ne $Directory.Native) {
    $Directory.Native.Dispose()
    $Directory.Native = $null
  }
  if ($null -ne $Directory.Parent -and $null -ne $Directory.Parent.Native) {
    $Directory.Parent.Native.Dispose()
    $Directory.Parent.Native = $null
  }
}

function Remove-BctOwnedDirectory {
  param($Directory)
  Assert-BctOwnedDirectoryLease $Directory
  try {
    $Directory.Native.DeleteCreated()
    $Directory.Native = $null
  }
  finally { Close-BctOwnedDirectoryLease $Directory }
  Assert-BciCondition (-not [IO.Directory]::Exists([string]$Directory.Path)) `
    'close staging 原子目录删除后仍存在'
}
