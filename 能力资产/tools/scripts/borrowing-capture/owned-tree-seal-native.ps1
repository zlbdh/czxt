$ErrorActionPreference = 'Stop'

if (-not ('Czxt.B.BorrowingTreeFileLease' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Czxt.B {
  [StructLayout(LayoutKind.Sequential)]
  internal struct TreeFileTime { internal uint Low, High; }

  [StructLayout(LayoutKind.Sequential)]
  internal struct TreeFileInformation {
    internal uint FileAttributes;
    internal TreeFileTime CreationTime, LastAccessTime, LastWriteTime;
    internal uint VolumeSerialNumber;
    internal uint FileSizeHigh, FileSizeLow, NumberOfLinks;
    internal uint FileIndexHigh, FileIndexLow;
  }

  [StructLayout(LayoutKind.Sequential)]
  internal struct TreeFileDisposition {
    [MarshalAs(UnmanagedType.U1)] internal bool DeleteFile;
  }

  public sealed class BorrowingTreeFileLease : IDisposable {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint desiredAccess,
      uint shareMode, IntPtr securityAttributes, uint creationDisposition,
      uint flagsAndAttributes, IntPtr templateFile);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool GetFileInformationByHandle(SafeFileHandle handle,
      out TreeFileInformation information);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern uint GetFinalPathNameByHandleW(SafeFileHandle handle,
      StringBuilder path, uint length, uint flags);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool SetFilePointerEx(SafeFileHandle handle,
      long distance, out long newPosition, uint moveMethod);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool ReadFile(SafeFileHandle handle, IntPtr buffer,
      uint count, out uint read, IntPtr overlapped);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool SetFileInformationByHandle(SafeFileHandle handle,
      int informationClass, ref TreeFileDisposition information,
      uint bufferSize);

    public SafeFileHandle Handle { get; private set; }
    public uint VolumeSerialNumber { get; private set; }
    public uint FileIndexHigh { get; private set; }
    public uint FileIndexLow { get; private set; }
    public ulong Length { get; private set; }
    public string FinalPath { get; private set; }
    public byte[] Digest { get; private set; }

    static TreeFileInformation ReadInformation(SafeFileHandle handle) {
      TreeFileInformation information;
      if (!GetFileInformationByHandle(handle, out information))
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "tree seal file identity failed");
      if ((information.FileAttributes & 0x10) != 0 ||
          (information.FileAttributes & 0x400) != 0 ||
          information.NumberOfLinks != 1)
        throw new System.IO.IOException("tree seal file kind is unsafe");
      return information;
    }

    static ulong GetLength(TreeFileInformation information) {
      return ((ulong)information.FileSizeHigh << 32) |
        information.FileSizeLow;
    }

    static string ReadFinalPath(SafeFileHandle handle) {
      StringBuilder path = new StringBuilder(32768);
      uint count = GetFinalPathNameByHandleW(handle, path,
        (uint)path.Capacity, 0);
      if (count == 0 || count >= path.Capacity)
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "tree seal file final path failed");
      return path.ToString();
    }

    static byte[] ReadDigest(SafeFileHandle handle, ulong length) {
      long position;
      if (!SetFilePointerEx(handle, 0, out position, 0) || position != 0)
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "tree seal file seek failed");
      byte[] buffer = new byte[1048576];
      GCHandle pinned = GCHandle.Alloc(buffer, GCHandleType.Pinned);
      try {
        using (SHA256 sha256 = SHA256.Create()) {
          ulong remaining = length;
          while (remaining > 0) {
            uint request = (uint)Math.Min((ulong)buffer.Length, remaining);
            uint read;
            if (!ReadFile(handle, pinned.AddrOfPinnedObject(), request,
                out read, IntPtr.Zero))
              throw new Win32Exception(Marshal.GetLastWin32Error(),
                "tree seal file read failed");
            if (read == 0 || read > request)
              throw new System.IO.IOException(
                "tree seal file read made no valid progress");
            sha256.TransformBlock(buffer, 0, (int)read, null, 0);
            remaining -= read;
          }
          sha256.TransformFinalBlock(new byte[0], 0, 0);
          return sha256.Hash;
        }
      }
      finally { pinned.Free(); }
    }

    static bool BytesEqual(byte[] left, byte[] right) {
      if (left == null || right == null || left.Length != right.Length)
        return false;
      for (int index = 0; index < left.Length; index++)
        if (left[index] != right[index]) return false;
      return true;
    }

    byte[] ReadVerifiedDigest() {
      if (Handle == null || Handle.IsInvalid || Handle.IsClosed)
        throw new ObjectDisposedException("BorrowingTreeFileLease");
      TreeFileInformation before = ReadInformation(Handle);
      string beforePath = ReadFinalPath(Handle);
      ulong length = GetLength(before);
      byte[] digest = ReadDigest(Handle, length);
      TreeFileInformation after = ReadInformation(Handle);
      string afterPath = ReadFinalPath(Handle);
      if (before.VolumeSerialNumber != VolumeSerialNumber ||
          before.FileIndexHigh != FileIndexHigh ||
          before.FileIndexLow != FileIndexLow || length != Length ||
          after.VolumeSerialNumber != VolumeSerialNumber ||
          after.FileIndexHigh != FileIndexHigh ||
          after.FileIndexLow != FileIndexLow ||
          GetLength(after) != Length ||
          !String.Equals(beforePath, FinalPath,
            StringComparison.OrdinalIgnoreCase) ||
          !String.Equals(afterPath, FinalPath,
            StringComparison.OrdinalIgnoreCase))
        throw new System.IO.IOException("tree seal file lease changed");
      return digest;
    }

    public static BorrowingTreeFileLease OpenReadLocked(string path) {
      if (String.IsNullOrEmpty(path)) throw new ArgumentNullException("path");
      SafeFileHandle handle = CreateFileW(path, 0x80110080, 1,
        IntPtr.Zero, 3, 0x00200000, IntPtr.Zero);
      if (handle == null || handle.IsInvalid) {
        int code = Marshal.GetLastWin32Error();
        if (handle != null) handle.Dispose();
        throw new Win32Exception(code, "tree seal file open failed");
      }
      try {
        TreeFileInformation information = ReadInformation(handle);
        BorrowingTreeFileLease lease = new BorrowingTreeFileLease {
          Handle = handle,
          VolumeSerialNumber = information.VolumeSerialNumber,
          FileIndexHigh = information.FileIndexHigh,
          FileIndexLow = information.FileIndexLow,
          Length = GetLength(information),
          FinalPath = ReadFinalPath(handle)
        };
        lease.Digest = lease.ReadVerifiedDigest();
        handle = null;
        return lease;
      }
      finally { if (handle != null) handle.Dispose(); }
    }

    public void Verify() {
      if (!BytesEqual(Digest, ReadVerifiedDigest()))
        throw new System.IO.IOException("tree seal file bytes changed");
    }

    public void DeleteBound() {
      Verify();
      TreeFileDisposition disposition =
        new TreeFileDisposition { DeleteFile = true };
      if (!SetFileInformationByHandle(Handle, 4, ref disposition,
          (uint)Marshal.SizeOf(typeof(TreeFileDisposition))))
        throw new Win32Exception(Marshal.GetLastWin32Error(),
          "tree seal file handle delete failed");
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
