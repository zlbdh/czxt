$ErrorActionPreference = 'Stop'

if (-not ('Czxt.B.AtomicOwnedFileLease' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Czxt.B {
  [StructLayout(LayoutKind.Sequential)]
  internal struct OwnedUnicodeString {
    internal ushort Length;
    internal ushort MaximumLength;
    internal IntPtr Buffer;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct OwnedObjectAttributes {
    internal uint Length;
    internal IntPtr RootDirectory;
    internal IntPtr ObjectName;
    internal uint Attributes;
    internal IntPtr SecurityDescriptor;
    internal IntPtr SecurityQualityOfService;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct OwnedIoStatusBlock {
    internal IntPtr Status;
    internal UIntPtr Information;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct OwnedFileTime { internal uint Low, High; }

  [StructLayout(LayoutKind.Sequential)]
  internal struct OwnedFileInformation {
    internal uint FileAttributes;
    internal OwnedFileTime CreationTime, LastAccessTime, LastWriteTime;
    internal uint VolumeSerialNumber;
    internal uint FileSizeHigh, FileSizeLow, NumberOfLinks;
    internal uint FileIndexHigh, FileIndexLow;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct OwnedFileDisposition {
    [MarshalAs(UnmanagedType.U1)] internal bool DeleteFile;
  }

  public sealed class AtomicOwnedFileLease : IDisposable {
    [DllImport("ntdll.dll")]
    static extern int NtCreateFile(out SafeFileHandle fileHandle,
      uint desiredAccess, ref OwnedObjectAttributes objectAttributes,
      out OwnedIoStatusBlock ioStatusBlock, IntPtr allocationSize,
      uint fileAttributes, uint shareAccess, uint createDisposition,
      uint createOptions, IntPtr eaBuffer, uint eaLength);

    [DllImport("ntdll.dll")]
    static extern uint RtlNtStatusToDosError(int status);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool GetFileInformationByHandle(
      SafeFileHandle handle, out OwnedFileInformation information);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern uint GetFinalPathNameByHandleW(
      SafeFileHandle handle, StringBuilder path, uint length, uint flags);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool WriteFile(SafeFileHandle handle, IntPtr bytes,
      uint count, out uint written, IntPtr overlapped);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool FlushFileBuffers(SafeFileHandle handle);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool SetFileInformationByHandle(SafeFileHandle handle,
      int informationClass, ref OwnedFileDisposition information,
      uint bufferSize);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint desiredAccess,
      uint shareMode, IntPtr securityAttributes, uint creationDisposition,
      uint flagsAndAttributes, IntPtr templateFile);

    public SafeFileHandle Handle { get; private set; }
    public uint VolumeSerialNumber { get; private set; }
    public uint FileIndexHigh { get; private set; }
    public uint FileIndexLow { get; private set; }
    public ulong Length { get; private set; }
    public string FinalPath { get; private set; }
    public bool Created { get; private set; }

    static void AssertNativeLayout() {
      int expectedUnicode = IntPtr.Size == 8 ? 16 : 8;
      int expectedAttributes = IntPtr.Size == 8 ? 48 : 24;
      int expectedStatus = IntPtr.Size == 8 ? 16 : 8;
      if (Marshal.SizeOf(typeof(OwnedUnicodeString)) != expectedUnicode ||
          Marshal.SizeOf(typeof(OwnedObjectAttributes)) != expectedAttributes ||
          Marshal.SizeOf(typeof(OwnedIoStatusBlock)) != expectedStatus ||
          Marshal.SizeOf(typeof(OwnedFileInformation)) != 52)
        throw new PlatformNotSupportedException(
          "atomic owned file native layout is unsupported");
    }

    static OwnedFileInformation ReadInformation(SafeFileHandle handle) {
      OwnedFileInformation information;
      if (!GetFileInformationByHandle(handle, out information))
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "atomic owned file identity failed");
      if ((information.FileAttributes & 0x10) != 0 ||
          (information.FileAttributes & 0x400) != 0 ||
          information.NumberOfLinks != 1)
        throw new System.IO.IOException("atomic owned file kind is unsafe");
      return information;
    }

    static string ReadFinalPath(SafeFileHandle handle) {
      StringBuilder path = new StringBuilder(32768);
      uint count = GetFinalPathNameByHandleW(
        handle, path, (uint)path.Capacity, 0);
      if (count == 0 || count >= path.Capacity)
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "atomic owned file final path failed");
      return path.ToString();
    }

    static void WriteAll(SafeFileHandle handle, byte[] bytes) {
      GCHandle pinned = new GCHandle();
      bool hasPin = false;
      try {
        if (bytes.Length > 0) {
          pinned = GCHandle.Alloc(bytes, GCHandleType.Pinned);
          hasPin = true;
          int offset = 0;
          while (offset < bytes.Length) {
            uint request = (uint)Math.Min(1048576, bytes.Length - offset);
            uint written;
            if (!WriteFile(handle,
                IntPtr.Add(pinned.AddrOfPinnedObject(), offset), request,
                out written, IntPtr.Zero))
              throw new Win32Exception(Marshal.GetLastWin32Error(),
                "atomic owned file write failed");
            if (written == 0 || written > request)
              throw new System.IO.IOException(
                "atomic owned file write made no valid progress");
            offset = checked(offset + (int)written);
          }
        }
        if (!FlushFileBuffers(handle))
          throw new Win32Exception(Marshal.GetLastWin32Error(),
            "atomic owned file flush failed");
      }
      finally { if (hasPin) pinned.Free(); }
    }

    static AtomicOwnedFileLease FromHandle(
        SafeFileHandle handle, bool created) {
      OwnedFileInformation information = ReadInformation(handle);
      string finalPath = ReadFinalPath(handle);
      return new AtomicOwnedFileLease {
        Handle = handle,
        VolumeSerialNumber = information.VolumeSerialNumber,
        FileIndexHigh = information.FileIndexHigh,
        FileIndexLow = information.FileIndexLow,
        Length = ((ulong)information.FileSizeHigh << 32) |
          information.FileSizeLow,
        FinalPath = finalPath,
        Created = created
      };
    }

    public static AtomicOwnedFileLease OpenExisting(string fullDosPath) {
      AssertNativeLayout();
      if (String.IsNullOrEmpty(fullDosPath))
        throw new ArgumentNullException("fullDosPath");
      SafeFileHandle handle = CreateFileW(fullDosPath, 0x00110080, 1,
        IntPtr.Zero, 3, 0x00200000, IntPtr.Zero);
      if (handle == null || handle.IsInvalid) {
        int code = Marshal.GetLastWin32Error();
        if (handle != null) handle.Dispose();
        throw new Win32Exception(code,
          "atomic owned existing file open failed");
      }
      try {
        AtomicOwnedFileLease lease = FromHandle(handle, false);
        handle = null;
        return lease;
      }
      finally { if (handle != null) handle.Dispose(); }
    }

    public static AtomicOwnedFileLease CreateRelative(
        SafeFileHandle parentHandle, string leafName, byte[] bytes) {
      AssertNativeLayout();
      if (parentHandle == null || parentHandle.IsInvalid || parentHandle.IsClosed)
        throw new ArgumentException("atomic owned file parent is invalid",
          "parentHandle");
      if (bytes == null) throw new ArgumentNullException("bytes");
      if (String.IsNullOrEmpty(leafName) || leafName == "." || leafName == ".." ||
          leafName.IndexOfAny(new char[] {'\\', '/', ':'}) >= 0)
        throw new ArgumentException("atomic owned file leaf is unsafe", "leafName");
      IntPtr buffer = IntPtr.Zero;
      IntPtr unicodePointer = IntPtr.Zero;
      SafeFileHandle handle = null;
      bool parentReference = false;
      bool created = false;
      try {
        buffer = Marshal.StringToHGlobalUni(leafName);
        OwnedUnicodeString unicode = new OwnedUnicodeString {
          Length = checked((ushort)(leafName.Length * 2)),
          MaximumLength = checked((ushort)((leafName.Length + 1) * 2)),
          Buffer = buffer
        };
        unicodePointer = Marshal.AllocHGlobal(
          Marshal.SizeOf(typeof(OwnedUnicodeString)));
        Marshal.StructureToPtr(unicode, unicodePointer, false);
        parentHandle.DangerousAddRef(ref parentReference);
        OwnedObjectAttributes attributes = new OwnedObjectAttributes {
          Length = (uint)Marshal.SizeOf(typeof(OwnedObjectAttributes)),
          RootDirectory = parentHandle.DangerousGetHandle(),
          ObjectName = unicodePointer,
          Attributes = 0x1040,
          SecurityDescriptor = IntPtr.Zero,
          SecurityQualityOfService = IntPtr.Zero
        };
        OwnedIoStatusBlock statusBlock;
        int status = NtCreateFile(out handle, 0x00110083, ref attributes,
          out statusBlock, IntPtr.Zero, 0x80, 1, 2, 0x00200060,
          IntPtr.Zero, 0);
        if (status < 0) {
          if (handle != null) handle.Dispose();
          handle = null;
          throw new Win32Exception((int)RtlNtStatusToDosError(status),
            "atomic owned file create failed");
        }
        if (handle == null || handle.IsInvalid ||
            statusBlock.Information.ToUInt64() != 2)
          throw new System.IO.IOException(
            "atomic owned file create did not return FILE_CREATED");
        created = true;
        WriteAll(handle, bytes);
        AtomicOwnedFileLease lease = FromHandle(handle, true);
        if (lease.Length != (ulong)bytes.LongLength)
          throw new System.IO.IOException("atomic owned file length changed");
        handle = null;
        return lease;
      }
      catch (Exception creationFailure) {
        Exception cleanupFailure = null;
        if (created && handle != null && !handle.IsInvalid) {
          try {
            OwnedFileDisposition disposition =
              new OwnedFileDisposition { DeleteFile = true };
            if (!SetFileInformationByHandle(handle, 4, ref disposition,
                (uint)Marshal.SizeOf(typeof(OwnedFileDisposition))))
              cleanupFailure = new Win32Exception(Marshal.GetLastWin32Error(),
                "atomic owned file create compensation failed");
          }
          catch (Exception error) { cleanupFailure = error; }
        }
        if (cleanupFailure != null)
          throw new System.IO.IOException(
            "atomic owned file create failed and compensation failed",
            new AggregateException(creationFailure, cleanupFailure));
        throw;
      }
      finally {
        if (handle != null) handle.Dispose();
        if (parentReference) parentHandle.DangerousRelease();
        if (unicodePointer != IntPtr.Zero) Marshal.FreeHGlobal(unicodePointer);
        if (buffer != IntPtr.Zero) Marshal.FreeHGlobal(buffer);
      }
    }

    public void RenameRelative(object destinationParent, string leafName) {
      Verify();
      if (destinationParent == null)
        throw new ArgumentNullException("destinationParent");
      Type destinationType = destinationParent.GetType();
      if (!String.Equals(destinationType.FullName,
          "Czxt.B.AtomicDirectoryLease", StringComparison.Ordinal))
        throw new ArgumentException(
          "atomic owned file destination lease has the wrong type",
          "destinationParent");
      MethodInfo rename = destinationType.GetMethod("RenameHandleRelative",
        BindingFlags.Public | BindingFlags.Static);
      if (rename == null)
        throw new MissingMethodException(destinationType.FullName,
          "RenameHandleRelative");
      string finalPath;
      try {
        finalPath = rename.Invoke(null, new object[] { Handle,
          VolumeSerialNumber, destinationParent, leafName }) as string;
      }
      catch (TargetInvocationException error) {
        if (error.InnerException != null) throw error.InnerException;
        throw;
      }
      if (finalPath == null)
        throw new System.IO.IOException(
          "atomic owned file rename returned no final path");
      FinalPath = finalPath;
      RefreshFromHandle();
    }

    public void RefreshFromHandle() {
      if (Handle == null || Handle.IsInvalid || Handle.IsClosed)
        throw new ObjectDisposedException("AtomicOwnedFileLease");
      OwnedFileInformation information = ReadInformation(Handle);
      string finalPath = ReadFinalPath(Handle);
      ulong length = ((ulong)information.FileSizeHigh << 32) |
        information.FileSizeLow;
      if (information.VolumeSerialNumber != VolumeSerialNumber ||
          information.FileIndexHigh != FileIndexHigh ||
          information.FileIndexLow != FileIndexLow || length != Length)
        throw new System.IO.IOException(
          "atomic owned file identity changed during refresh");
      FinalPath = finalPath;
    }

    public void Verify() {
      if (Handle == null || Handle.IsInvalid || Handle.IsClosed)
        throw new ObjectDisposedException("AtomicOwnedFileLease");
      OwnedFileInformation information = ReadInformation(Handle);
      string finalPath = ReadFinalPath(Handle);
      ulong length = ((ulong)information.FileSizeHigh << 32) |
        information.FileSizeLow;
      if (information.VolumeSerialNumber != VolumeSerialNumber ||
          information.FileIndexHigh != FileIndexHigh ||
          information.FileIndexLow != FileIndexLow || length != Length ||
          !String.Equals(finalPath, FinalPath,
            StringComparison.OrdinalIgnoreCase))
        throw new System.IO.IOException("atomic owned file lease changed");
    }

    public void DeleteCreated() {
      if (!Created) throw new InvalidOperationException(
        "only an atomically created file can be deleted by this lease");
      Verify();
      OwnedFileDisposition disposition =
        new OwnedFileDisposition { DeleteFile = true };
      if (!SetFileInformationByHandle(Handle, 4, ref disposition,
          (uint)Marshal.SizeOf(typeof(OwnedFileDisposition))))
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "atomic owned file handle delete failed");
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

function New-BctOwnedFileRelative {
  param($Directory, [string]$LeafName, [byte[]]$Bytes)
  Assert-BctOwnedDirectoryLease $Directory
  Invoke-BctStagingTestInjection `
    'after-staging-directory-verified-before-relative-file-create' `
    ([pscustomobject]@{
        Path = $Directory.CanonicalPath
        Directory = $Directory
        LeafName = $LeafName
      })
  $lease = $null
  try {
    $expected = [IO.Path]::GetFullPath(
      (Join-Path $Directory.CanonicalPath $LeafName)).Normalize(
        [Text.NormalizationForm]::FormC)
    $lease = [Czxt.B.AtomicOwnedFileLease]::CreateRelative(
      $Directory.Native.Handle, $LeafName, $Bytes)
    $canonical = ConvertFrom-BctNativeDirectoryPath $lease.FinalPath
    Assert-BciCondition ([string]::Equals(
        $canonical, $expected, [StringComparison]::OrdinalIgnoreCase)) `
      'close staging 原子文件物理路径改变'
    return [pscustomobject]@{
      Path = $canonical
      IdentityKey = '{0:x8}:{1:x8}:{2:x8}' -f `
        $lease.VolumeSerialNumber, $lease.FileIndexHigh, $lease.FileIndexLow
      Length = [uint64]$lease.Length
      Bytes = [byte[]]$Bytes
      Native = $lease
    }
  }
  catch {
    $creationFailure = $_
    $cleanupFailure = $null
    if ($null -ne $lease) {
      try { $lease.DeleteCreated() }
      catch { $cleanupFailure = $_; try { $lease.Dispose() } catch { } }
    }
    if ($null -ne $cleanupFailure) {
      throw ('close staging 原子文件验证失败且同句柄补偿失败：' +
        $cleanupFailure.Exception.Message)
    }
    throw $creationFailure
  }
}

function Assert-BctOwnedFileLease {
  param($Owned)
  Assert-BciCondition ($null -ne $Owned -and $null -ne $Owned.Native) `
    'close staging 缺少原子文件 lease'
  $Owned.Native.Verify()
  $canonical = ConvertFrom-BctNativeDirectoryPath $Owned.Native.FinalPath
  $identity = '{0:x8}:{1:x8}:{2:x8}' -f `
    $Owned.Native.VolumeSerialNumber, $Owned.Native.FileIndexHigh,
    $Owned.Native.FileIndexLow
  Assert-BciCondition ([string]::Equals(
      $canonical, [string]$Owned.Path, [StringComparison]::OrdinalIgnoreCase) -and
      $identity -ceq [string]$Owned.IdentityKey -and
      [uint64]$Owned.Native.Length -eq [uint64]$Owned.Length) `
    'close staging 原子文件 lease 绑定改变'
}

function Close-BctOwnedFileLease {
  param($Owned)
  if ($null -ne $Owned -and $null -ne $Owned.Native) {
    $Owned.Native.Dispose()
    $Owned.Native = $null
  }
}

function Remove-BctOwnedFileLease {
  param($Owned)
  Assert-BctOwnedFileLease $Owned
  $Owned.Native.DeleteCreated()
  $Owned.Native = $null
}
