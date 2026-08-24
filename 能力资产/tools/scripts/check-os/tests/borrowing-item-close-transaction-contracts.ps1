[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-item-test-support.ps1')

$script:CloseFacadeRelative = '能力资产\tools\scripts\close-borrowing-item.ps1'
$script:CloseFacadeTemplatePath = Join-Path $script:P4tTemplateRoot $script:CloseFacadeRelative
$script:CloseHelperRoot = Split-Path -Parent $script:CloseFacadeTemplatePath
$script:CloseCaptureRoot = Join-Path $script:CloseHelperRoot 'borrowing-capture'

function Assert-BsiCondition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Test-BsiSamePath {
  param([string]$Left, [string]$Right)
  return [string]::Equals($Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

. (Join-Path $script:CloseCaptureRoot 'common.ps1')
. (Join-Path $script:CloseCaptureRoot 'file-safety.ps1')
. (Join-Path $script:CloseCaptureRoot 'source-candidate-parser.ps1')
. (Join-Path $script:CloseHelperRoot 'borrowing-seal-transaction.ps1')
. (Join-Path $script:CloseHelperRoot 'borrowing-conditional-replace.ps1')
. (Join-Path $script:CloseHelperRoot 'borrowing-seal-attestation.ps1')
. (Join-Path $script:CloseHelperRoot 'borrowing-close-candidate.ps1')
. (Join-Path $script:CloseHelperRoot 'borrowing-close-transaction.ps1')

if (-not ('Czxt.B.Tests.CloseReparseRaceNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Czxt.B.Tests {
  public static class CloseReparseRaceNative {
    const uint GENERIC_WRITE = 0x40000000;
    const uint FILE_SHARE_ALL = 7;
    const uint OPEN_EXISTING = 3;
    const uint OPEN_REPARSE_DIRECTORY = 0x02200000;
    const uint FSCTL_SET_REPARSE_POINT = 0x000900A4;
    const uint FSCTL_DELETE_REPARSE_POINT = 0x000900AC;
    const uint IO_REPARSE_TAG_MOUNT_POINT = 0xA0000003;

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string path, uint access,
      uint share, IntPtr security, uint creation, uint flags, IntPtr template);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool DeviceIoControl(SafeFileHandle handle, uint controlCode,
      byte[] input, uint inputLength, IntPtr output, uint outputLength,
      out uint returned, IntPtr overlapped);

    static SafeFileHandle OpenForReparse(string path) {
      SafeFileHandle handle = CreateFileW(path, GENERIC_WRITE, FILE_SHARE_ALL,
        IntPtr.Zero, OPEN_EXISTING, OPEN_REPARSE_DIRECTORY, IntPtr.Zero);
      if (handle == null || handle.IsInvalid) {
        int code = Marshal.GetLastWin32Error();
        if (handle != null) handle.Dispose();
        throw new Win32Exception(code,
          "real FSCTL reparse handle open failed");
      }
      return handle;
    }

    static void PutUInt16(byte[] buffer, int offset, ushort value) {
      byte[] encoded = BitConverter.GetBytes(value);
      Buffer.BlockCopy(encoded, 0, buffer, offset, encoded.Length);
    }

    static void PutUInt32(byte[] buffer, int offset, uint value) {
      byte[] encoded = BitConverter.GetBytes(value);
      Buffer.BlockCopy(encoded, 0, buffer, offset, encoded.Length);
    }

    public static void SetMountPoint(string path, string target) {
      string fullTarget = Path.GetFullPath(target);
      string substitute = @"\??\" + fullTarget;
      byte[] substituteBytes = Encoding.Unicode.GetBytes(substitute);
      byte[] printBytes = Encoding.Unicode.GetBytes(fullTarget);
      int pathBytes = substituteBytes.Length + 2 + printBytes.Length + 2;
      byte[] buffer = new byte[16 + pathBytes];
      PutUInt32(buffer, 0, IO_REPARSE_TAG_MOUNT_POINT);
      PutUInt16(buffer, 4, checked((ushort)(8 + pathBytes)));
      PutUInt16(buffer, 8, 0);
      PutUInt16(buffer, 10, checked((ushort)substituteBytes.Length));
      PutUInt16(buffer, 12, checked((ushort)(substituteBytes.Length + 2)));
      PutUInt16(buffer, 14, checked((ushort)printBytes.Length));
      Buffer.BlockCopy(substituteBytes, 0, buffer, 16, substituteBytes.Length);
      Buffer.BlockCopy(printBytes, 0, buffer,
        16 + substituteBytes.Length + 2, printBytes.Length);
      using (SafeFileHandle handle = OpenForReparse(path)) {
        uint returned;
        if (!DeviceIoControl(handle, FSCTL_SET_REPARSE_POINT, buffer,
            (uint)buffer.Length, IntPtr.Zero, 0, out returned, IntPtr.Zero))
          throw new Win32Exception(Marshal.GetLastWin32Error(),
            "real FSCTL_SET_REPARSE_POINT failed");
      }
    }

    public static void DeleteMountPoint(string path) {
      byte[] buffer = new byte[8];
      PutUInt32(buffer, 0, IO_REPARSE_TAG_MOUNT_POINT);
      using (SafeFileHandle handle = OpenForReparse(path)) {
        uint returned;
        if (!DeviceIoControl(handle, FSCTL_DELETE_REPARSE_POINT, buffer,
            (uint)buffer.Length, IntPtr.Zero, 0, out returned, IntPtr.Zero))
          throw new Win32Exception(Marshal.GetLastWin32Error(),
            "real FSCTL_DELETE_REPARSE_POINT failed");
      }
    }
  }
}
'@
}
foreach ($dependency in @(
    (Join-Path $script:P4tModuleRoot 'borrowing-mode.ps1'),
    (Join-Path $script:P4tModuleRoot 'borrowing-source-cards.ps1'),
    (Join-Path $script:P4tModuleRoot 'borrowing-item-cards.ps1'),
    (Join-Path $script:CloseCaptureRoot 'process.ps1'),
    (Join-Path $script:CloseCaptureRoot 'p4t-runner.ps1'))) {
  . $dependency
}

function Copy-P4tCloseRuntime {
  param([string]$Root)
  foreach ($relative in @(
      $script:CloseFacadeRelative,
      '能力资产\tools\scripts\borrowing-close-transaction.ps1',
      '能力资产\tools\scripts\borrowing-close-staging.ps1',
      '能力资产\tools\scripts\borrowing-close-candidate.ps1',
      '能力资产\tools\scripts\borrowing-owned-directory.ps1',
      '能力资产\tools\scripts\borrowing-owned-file.ps1',
      '能力资产\tools\scripts\seal-borrowing-item.ps1',
      '能力资产\tools\scripts\borrowing-seal-transaction.ps1',
      '能力资产\tools\scripts\borrowing-owned-object.ps1',
      '能力资产\tools\scripts\borrowing-conditional-replace.ps1',
      '能力资产\tools\scripts\borrowing-seal-attestation.ps1',
      '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1')) {
    Copy-P4tTemplateFile -RelativePath $relative -Root $Root
  }
  foreach ($directory in @(
      '能力资产\tools\scripts\borrowing-capture',
      '能力资产\tools\scripts\check-os\p4t')) {
    $sourceRoot = Join-Path $script:P4tTemplateRoot $directory
    foreach ($file in @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File)) {
      $relative = $file.FullName.Substring($script:P4tTemplateRoot.Length).TrimStart('\')
      Copy-P4tTemplateFile -RelativePath $relative -Root $Root
    }
  }
}

function New-P4tClosableItem {
  param([string]$Name, [switch]$BreakIsolation)
  $root = New-ProjectSkeleton ('close-transaction-' + $Name)
  Copy-P4tCloseRuntime $root
  $source = New-P4tSourceCapture $root local 'source-close'
  Set-P4tSourceReuseScope $source adapt-internal-approved
  $item = New-P4tItemCard -Root $root -BorrowId ('borrow-20260719-' + $Name) `
    -Bindings @($source) -Status verifying -Decision adapt
  if ($BreakIsolation) {
    Write-P4tUtf8 (Join-Path $root 'app\isolation.ps1') `
      "Get-Content '..\借鉴区\事项\forbidden.txt'`n"
  }
  return [pscustomobject]@{ Root = $root; Source = $source; Item = $item }
}

function Invoke-P4tCloseFacade {
  param($Fixture)
  $path = Join-Path $Fixture.Root $script:CloseFacadeRelative
  return Invoke-CzxtPowerShell -ScriptPath $path -ScriptArguments @(
    '-Root', $Fixture.Root,
    '-CardPath', $Fixture.Item.CardPath,
    '-ClosedAt', '2026-07-19T06:00:00+00:00',
    '-Reason', 'fresh 验证通过',
    '-Confirmation', 'fixture-owner'
  ) -TimeoutMilliseconds 300000
}

function Invoke-P4tCloseInProcess {
  param($Fixture, [hashtable]$TestInjections)
  $previous = Get-Variable -Name BctTestInjections -Scope Script `
    -ErrorAction SilentlyContinue
  try {
    $script:BctTestInjections = $TestInjections
    return Invoke-BorrowingCloseTransaction -Root $Fixture.Root `
      -CardPath $Fixture.Item.CardPath `
      -ClosedAt '2026-07-19T06:00:00+00:00' `
      -Reason 'fresh 验证通过' -Confirmation 'fixture-owner'
  }
  finally {
    if ($null -ne $previous) {
      $script:BctTestInjections = $previous.Value
    }
    else {
      Remove-Variable -Name BctTestInjections -Scope Script -ErrorAction SilentlyContinue
    }
  }
}

function Invoke-P4tStagingInProcess {
  param(
    [string]$ItemRoot, [byte[]]$OriginalBytes, [byte[]]$CandidateBytes,
    [hashtable]$TestInjections, [AllowNull()][object]$AttemptedPath = $null
  )
  $previous = Get-Variable -Name BctTestInjections -Scope Script `
    -ErrorAction SilentlyContinue
  try {
    $script:BctTestInjections = $TestInjections
    if ($null -ne $AttemptedPath) {
      return New-BctStaging $ItemRoot $OriginalBytes $CandidateBytes `
        -AttemptedPath $AttemptedPath
    }
    return New-BctStaging $ItemRoot $OriginalBytes $CandidateBytes
  }
  finally {
    if ($null -ne $previous) {
      $script:BctTestInjections = $previous.Value
    }
    else {
      Remove-Variable -Name BctTestInjections -Scope Script -ErrorAction SilentlyContinue
    }
  }
}

function Set-P4tCloseSealAttestationOverride {
  param([string]$Root, [ValidateSet('malformed', 'field-mismatch')][string]$Mode)
  $path = Join-Path $Root '能力资产\tools\scripts\borrowing-seal-attestation.ps1'
  $body = if ($Mode -ceq 'malformed') {
    "`nfunction New-BsiSealAttestationLine { param([string]`$BorrowId, `$Snapshot); return 'BROKEN' }`n"
  }
  else {
    @'

function New-BsiSealAttestationLine {
  param([string]$BorrowId, $Snapshot)
  $hash = Get-BorrowingSha256Hex -Bytes $Snapshot.Bytes
  return 'SEALED borrow_id=borrow-20260720-other identity_key={0} length={1} sha256={2}' -f `
    $Snapshot.IdentityKey, ([uint64]$Snapshot.Length), $hash
}
'@
  }
  [IO.File]::AppendAllText($path, $body, $script:P4tUtf8NoBom)
}

Initialize-P4tTestFixture
try {
  $script:CloseReady = $false
  Invoke-CzxtContract 'close transaction façade and single-responsibility helpers exist' {
    Assert-CzxtTrue (Test-Path -LiteralPath $script:CloseFacadeTemplatePath -PathType Leaf) `
      ('missing close façade: ' + $script:CloseFacadeTemplatePath)
    foreach ($name in @(
        'borrowing-close-transaction.ps1', 'borrowing-close-staging.ps1',
        'borrowing-close-candidate.ps1', 'borrowing-owned-directory.ps1',
        'borrowing-owned-file.ps1')) {
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path `
          (Split-Path -Parent $script:CloseFacadeTemplatePath) $name) -PathType Leaf) `
        ('missing close helper: ' + $name)
    }
    $script:CloseReady = $true
  }

  if ($script:CloseReady) {
    Invoke-CzxtContract 'staging compensates a directory-stage failure' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-directory-failure'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      $script:BctDirectoryStageFailureSeen = $false
      $rejected = $false
      try {
        [void](Invoke-P4tStagingInProcess $itemRoot `
            ([Text.Encoding]::UTF8.GetBytes("original`n")) `
            ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
            'after-staging-directory-created' = {
              param($Context)
              $script:BctDirectoryStageFailureSeen = $true
              throw 'contract injected staging directory snapshot failure'
            }
          })
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $script:BctDirectoryStageFailureSeen `
        'staging directory-stage injection did not run'
      Assert-CzxtTrue $rejected 'staging directory-stage failure was accepted'
      Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $itemRoot -Force).Count `
        'staging directory-stage failure leaked its directory'
    }

    Invoke-CzxtContract 'staging rejects a preoccupied transaction directory without deleting it' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-preoccupied'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      $script:BctPreoccupiedPath = $null
      $rejected = $false
      try {
        [void](Invoke-P4tStagingInProcess $itemRoot `
            ([Text.Encoding]::UTF8.GetBytes("original`n")) `
            ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
            'before-staging-directory-create' = {
              param($Context)
              $script:BctPreoccupiedPath = $Context.Path
              [void][IO.Directory]::CreateDirectory($Context.Path)
              [IO.File]::WriteAllText(
                (Join-Path $Context.Path 'later-owner.txt'), 'later-owner')
            }
          })
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $rejected 'preoccupied staging directory was accepted'
      Assert-CzxtTrue (Test-Path -LiteralPath $script:BctPreoccupiedPath -PathType Container) `
        'preoccupied staging directory was deleted'
      Assert-CzxtEqual 'later-owner' ([IO.File]::ReadAllText(
          (Join-Path $script:BctPreoccupiedPath 'later-owner.txt'))) `
        'preoccupied staging directory content changed'
    }

    Invoke-CzxtContract 'staging rejects a parent reparse swap before relative create without writes' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-parent-swap'
      $preserved = $itemRoot + '.preserved'
      $outside = Join-Path $script:P4tFixtureRoot 'close-staging-parent-swap-outside'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      [void](New-Item -ItemType Directory -Path $outside)
      $script:BctParentSwapRan = $false
      $rejected = $false
      try {
        try {
          [void](Invoke-P4tStagingInProcess $itemRoot `
              ([Text.Encoding]::UTF8.GetBytes("original`n")) `
              ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
              'before-staging-directory-create' = {
                param($Context)
                [IO.Directory]::Move($itemRoot, $preserved)
                [void](New-Item -ItemType Junction -Path $itemRoot -Target $outside)
                $script:BctParentSwapRan = $true
              }
            })
        }
        catch { $rejected = $true }
        Assert-CzxtTrue $script:BctParentSwapRan 'parent reparse swap injection did not run'
        Assert-CzxtTrue $rejected 'parent reparse swap was accepted'
        Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $outside -Force).Count `
          'parent reparse swap received a staging write'
      }
      finally {
        if ((Get-Item -LiteralPath $itemRoot -Force -ErrorAction SilentlyContinue).Attributes `
            -band [IO.FileAttributes]::ReparsePoint) {
          Remove-Item -LiteralPath $itemRoot -Force
        }
        if (Test-Path -LiteralPath $preserved -PathType Container) {
          [IO.Directory]::Move($preserved, $itemRoot)
        }
      }
    }

    Invoke-CzxtContract 'staging same-directory reparse race writes zero bytes outside' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-same-directory-reparse'
      $outside = Join-Path $script:P4tFixtureRoot `
        'close-staging-same-directory-reparse-outside'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      [void](New-Item -ItemType Directory -Path $outside)
      $attempted = [pscustomobject]@{ Value = 'none' }
      $script:BctSameDirectoryReparseSet = $false
      $staging = $null
      $rejected = $false
      try {
        try {
          $staging = Invoke-P4tStagingInProcess $itemRoot `
            ([Text.Encoding]::UTF8.GetBytes("original`n")) `
            ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
            'after-staging-directory-verified-before-relative-file-create' = {
              param($Context)
              [Czxt.B.Tests.CloseReparseRaceNative]::SetMountPoint(
                $Context.Path, $outside)
              $script:BctSameDirectoryReparseSet = $true
            }
          } -AttemptedPath $attempted
        }
        catch { $rejected = $true }
        Assert-CzxtTrue $script:BctSameDirectoryReparseSet `
          'real same-directory FSCTL reparse injection did not complete'
        Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $outside -Force).Count `
          'same-directory reparse race received an outside staging write'
        Assert-CzxtTrue $rejected `
          'same-directory reparse mutation was not rejected fail-closed'
      }
      finally {
        if ($null -ne $staging -and $null -ne $staging.Directory) {
          Close-BctOwnedDirectoryLease $staging.Directory
        }
        foreach ($entry in @(Get-ChildItem -LiteralPath $outside -Force `
            -ErrorAction SilentlyContinue)) {
          if (-not $entry.PSIsContainer) { [IO.File]::Delete($entry.FullName) }
        }
        if ($attempted.Value -cne 'none' -and
            (Test-Path -LiteralPath $attempted.Value)) {
          $attributes = (Get-Item -LiteralPath $attempted.Value -Force).Attributes
          if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            [Czxt.B.Tests.CloseReparseRaceNative]::DeleteMountPoint($attempted.Value)
          }
          if ([IO.Directory]::Exists($attempted.Value)) {
            [IO.Directory]::Delete($attempted.Value, $false)
          }
        }
      }
    }

    Invoke-CzxtContract 'staging retained original guard blocks a later reparse mutation' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-original-guard'
      $outside = Join-Path $script:P4tFixtureRoot `
        'close-staging-original-guard-outside'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      [void](New-Item -ItemType Directory -Path $outside)
      $script:BctOriginalGuardAttempted = $false
      $script:BctOriginalGuardBlocked = $false
      $staging = Invoke-P4tStagingInProcess $itemRoot `
        ([Text.Encoding]::UTF8.GetBytes("original`n")) `
        ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
        'after-staging-original-guard-created' = {
          param($Context)
          $script:BctOriginalGuardAttempted = $true
          try {
            [Czxt.B.Tests.CloseReparseRaceNative]::SetMountPoint(
              $Context.Path, $outside)
          }
          catch { $script:BctOriginalGuardBlocked = $true }
        }
      }
      try {
        Assert-CzxtTrue $script:BctOriginalGuardAttempted `
          'retained original guard mutation injection did not run'
        Assert-CzxtTrue $script:BctOriginalGuardBlocked `
          'retained original guard did not block the directory mutation'
        Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $outside -Force).Count `
          'retained original guard allowed an outside staging write'
      }
      finally { Remove-BctStaging $staging }
    }

    Invoke-CzxtContract 'staging atomic directory lease blocks a post-create replacement' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-post-create-swap'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      $script:BctDirectorySwapBlocked = $false
      $script:BctDirectorySwapSucceeded = $false
      $script:BctDisplacedDirectory = $null
      $staging = Invoke-P4tStagingInProcess $itemRoot `
        ([Text.Encoding]::UTF8.GetBytes("original`n")) `
        ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
        'after-staging-directory-created' = {
          param($Context)
          $script:BctDisplacedDirectory = $Context.Path + '.displaced'
          try {
            [IO.Directory]::Move($Context.Path, $script:BctDisplacedDirectory)
            $script:BctDirectorySwapSucceeded = $true
            [void][IO.Directory]::CreateDirectory($Context.Path)
          }
          catch { $script:BctDirectorySwapBlocked = $true }
        }
      }
      Remove-BctStaging $staging
      Assert-CzxtTrue $script:BctDirectorySwapBlocked `
        'post-create staging directory replacement was not blocked'
      Assert-CzxtTrue (-not $script:BctDirectorySwapSucceeded) `
        'post-create staging directory was displaced'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath $script:BctDisplacedDirectory)) `
        'post-create replacement retained a displaced directory'
    }

    Invoke-CzxtContract 'staging compensates a second-file write failure' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-second-write-failure'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      $script:BctOwnedWriteCalls = 0
      $script:BctSecondWriteFailureSeen = $false
      $rejected = $false
      try {
        [void](Invoke-P4tStagingInProcess $itemRoot `
            ([Text.Encoding]::UTF8.GetBytes("original`n")) `
            ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
            'before-staging-owned-file-write' = {
              param($Context)
              $script:BctOwnedWriteCalls++
              if ($script:BctOwnedWriteCalls -eq 2) {
                $script:BctSecondWriteFailureSeen = $true
                throw 'contract injected second staging write failure'
              }
            }
          })
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $script:BctSecondWriteFailureSeen `
        'staging second-write injection did not run'
      Assert-CzxtTrue $rejected 'staging second-write failure was accepted'
      Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $itemRoot -Force).Count `
        'staging second-write failure leaked owned objects'
    }

    Invoke-CzxtContract 'staging compensates a second-file snapshot failure' {
      $itemRoot = Join-Path $script:P4tFixtureRoot 'close-staging-second-snapshot-failure'
      [void](New-Item -ItemType Directory -Path $itemRoot)
      $script:BctStagingSnapshotCalls = 0
      $script:BctSecondSnapshotFailureSeen = $false
      $rejected = $false
      try {
        [void](Invoke-P4tStagingInProcess $itemRoot `
            ([Text.Encoding]::UTF8.GetBytes("original`n")) `
            ([Text.Encoding]::UTF8.GetBytes("candidate`n")) @{
            'before-staging-owned-file-snapshot' = {
              param($Context)
              $script:BctStagingSnapshotCalls++
              if ($script:BctStagingSnapshotCalls -eq 2) {
                $script:BctSecondSnapshotFailureSeen = $true
                throw 'contract injected second staging snapshot failure'
              }
            }
          })
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $script:BctSecondSnapshotFailureSeen `
        'staging second-snapshot injection did not run'
      Assert-CzxtTrue $rejected 'staging second-snapshot failure was accepted'
      Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $itemRoot -Force).Count `
        'staging second-snapshot failure leaked owned objects'
    }

    Invoke-CzxtContract 'close reports the attempted staging path after compensated creation failure' {
      $fixture = New-P4tClosableItem 'staging-report-after-failure'
      $itemRoot = Split-Path -Parent $fixture.Item.CardPath
      $script:BctOwnedWriteCalls = 0
      $result = Invoke-P4tCloseInProcess $fixture @{
        'before-staging-owned-file-write' = {
          param($Context)
          $script:BctOwnedWriteCalls++
          if ($script:BctOwnedWriteCalls -eq 2) {
            throw 'contract injected reported staging failure'
          }
        }
      }
      Assert-CzxtEqual 10 $result.ExitCode 'staging report failure exit code'
      Assert-CzxtTrue ($result.StagingPath -cne 'none（未创建）') `
        'staging creation failure was falsely reported as never created'
      Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $itemRoot -Directory -Force |
        Where-Object { $_.Name -like '.staging-close-*' }).Count `
        'reported staging creation failure leaked a staging directory'
    }

    Invoke-CzxtContract 'formal install succeeds only with an unchanged expected snapshot' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-install-control'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      Write-P4tUtf8 $path "original`n"
      $baseline = Get-BsiStableSnapshot $path
      $candidate = [Text.Encoding]::UTF8.GetBytes("candidate`n")
      [void](Install-BctFormalBytes $path $candidate $baseline)
      Assert-CzxtEqual ([Convert]::ToBase64String($candidate)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path))) `
        'close install control bytes'
    }

    Invoke-CzxtContract 'formal install refuses a concurrent card rewrite before replacement' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-concurrent-install'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      Write-P4tUtf8 $path "original`n"
      $baseline = Get-BsiStableSnapshot $path
      Write-P4tUtf8 $path "modified`n"
      $concurrent = [IO.File]::ReadAllBytes($path)
      $rejected = $false
      try {
        [void](Install-BctFormalBytes $path `
          ([Text.Encoding]::UTF8.GetBytes("candidate`n")) $baseline)
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $rejected 'close install overwrote a concurrent edit'
      Assert-CzxtEqual ([Convert]::ToBase64String($concurrent)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path))) `
        'close install changed concurrent bytes'
      Assert-CzxtTrue ($baseline.Bytes.Length -gt 0) 'close baseline fixture is empty'
    }

    Invoke-CzxtContract 'formal install refuses a replacement identity before replacement' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-concurrent-identity'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      Write-P4tUtf8 $path "original`n"
      $baseline = Get-BsiStableSnapshot $path
      $replacement = Join-Path $directory 'replacement.md'
      Write-P4tUtf8 $replacement "original`n"
      [IO.File]::Delete($path)
      [IO.File]::Move($replacement, $path)
      $rejected = $false
      try {
        [void](Install-BctFormalBytes $path `
          ([Text.Encoding]::UTF8.GetBytes("candidate`n")) $baseline)
      }
      catch { $rejected = $true }
      Assert-CzxtTrue $rejected 'close install accepted a replacement identity'
      Assert-CzxtEqual "original`n" `
        ([IO.File]::ReadAllText($path, $script:P4tUtf8NoBom)) `
        'close install changed replacement identity bytes'
    }

    Invoke-CzxtContract 'formal install preserves a concurrent object swapped after validation' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-cas-after-validation'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      Write-P4tUtf8 $path "original`n"
      $baseline = Get-BsiStableSnapshot $path
      $script:BctCasTarget = $path
      $script:BctCasBytes = [Text.Encoding]::UTF8.GetBytes("concurrent`n")
      $script:BctCasSnapshot = $null
      $script:BctCasInjected = $false
      $script:BctOriginalTemporaryCheck =
        (Get-Item Function:\Assert-BsiTemporaryUnchanged).ScriptBlock
      $rejected = $false
      try {
        Set-Item Function:\Assert-BsiTemporaryUnchanged -Value {
          param($Temporary, [byte[]]$ExpectedBytes)
          & $script:BctOriginalTemporaryCheck $Temporary $ExpectedBytes
          if (-not $script:BctCasInjected) {
            $script:BctCasInjected = $true
            $directory = Split-Path -Parent $script:BctCasTarget
            $replacement = Join-Path $directory `
              ('.contract-concurrent-' + [guid]::NewGuid().ToString('N') + '.tmp')
            [IO.File]::WriteAllBytes($replacement, $script:BctCasBytes)
            [IO.File]::Delete($script:BctCasTarget)
            [IO.File]::Move($replacement, $script:BctCasTarget)
            $script:BctCasSnapshot = Get-BsiStableSnapshot $script:BctCasTarget
          }
        }
        try {
          [void](Install-BctFormalBytes $path `
            ([Text.Encoding]::UTF8.GetBytes("candidate`n")) $baseline)
        }
        catch { $rejected = $true }
      }
      finally {
        Set-Item Function:\Assert-BsiTemporaryUnchanged `
          -Value $script:BctOriginalTemporaryCheck
      }
      Assert-CzxtTrue ($null -ne $script:BctCasSnapshot) `
        'close CAS injection did not run after expected snapshot validation'
      $after = Get-BsiStableSnapshot $path
      Assert-CzxtEqual $script:BctCasSnapshot.IdentityKey $after.IdentityKey `
        'close CAS overwrote the concurrent object identity'
      Assert-CzxtEqual ([Convert]::ToBase64String($script:BctCasBytes)) `
        ([Convert]::ToBase64String($after.Bytes)) `
        'close CAS overwrote the concurrent object bytes'
      $residue = @(Get-ChildItem -LiteralPath $directory -Force |
        Where-Object { $_.Name -like '.staging-replace-*' })
      Assert-CzxtEqual 0 $residue.Count 'close CAS recovery left replacement residue'
      Assert-CzxtTrue $rejected 'close CAS accepted a changed replacement target'
    }

    Invoke-CzxtContract 'final formal lock rejects bytes changed after P4t' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-after-p4t-stability'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      Write-P4tUtf8 $path "sealed-a`n"
      $sealed = Get-BsiStableSnapshot $path
      $controlLock = Open-BctFormalReadLock $path $sealed
      Assert-CzxtTrue ($null -ne $controlLock) 'close final formal lock control is missing'
      $writerRejected = $false
      $writer = $null
      try {
        $writer = New-Object IO.FileStream(
          $path, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
      }
      catch { $writerRejected = $true }
      finally { if ($null -ne $writer) { $writer.Dispose() } }
      Assert-CzxtTrue $writerRejected 'close final formal lock did not exclude a writer'
      $controlLock.Dispose()
      Write-P4tUtf8 $path "sealed-b`n"
      $rejected = $false
      $lock = $null
      try { $lock = Open-BctFormalReadLock $path $sealed }
      catch { $rejected = $true }
      finally { if ($null -ne $lock) { $lock.Dispose() } }
      Assert-CzxtTrue $rejected 'close accepted a post-P4t byte rewrite'
    }

    Invoke-CzxtContract 'final formal lock rejects identity changed after P4t' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-after-p4t-identity'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      Write-P4tUtf8 $path "sealed`n"
      $sealed = Get-BsiStableSnapshot $path
      $replacement = Join-Path $directory 'replacement.md'
      Write-P4tUtf8 $replacement "sealed`n"
      [IO.File]::Delete($path)
      [IO.File]::Move($replacement, $path)
      $rejected = $false
      $lock = $null
      try { $lock = Open-BctFormalReadLock $path $sealed }
      catch { $rejected = $true }
      finally { if ($null -ne $lock) { $lock.Dispose() } }
      Assert-CzxtTrue $rejected 'close accepted a post-P4t identity replacement'
    }

    Invoke-CzxtContract 'final formal lock revalidates hardlink count on the opened handle' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-final-lock-hardlink-window'
      [void](New-Item -ItemType Directory -Path $directory)
      $path = Join-Path $directory '借鉴卡.md'
      $alias = Join-Path $directory '同对象别名.md'
      Write-P4tUtf8 $path "sealed`n"
      $sealed = Get-BsiStableSnapshot $path
      $script:BctFinalLockHardlinkInjected = $false
      $script:BctTestInjections = @{
        'before-final-formal-handle-open' = {
          param($Context)
          [void](New-Item -ItemType HardLink -Path $alias -Target $Context.FormalPath)
          $script:BctFinalLockHardlinkInjected = $true
        }
      }
      $lock = $null
      $rejected = $false
      try { $lock = Open-BctFormalReadLock $path $sealed }
      catch { $rejected = $true }
      finally {
        if ($null -ne $lock) { $lock.Dispose() }
        Remove-Variable BctTestInjections -Scope Script -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $alias -PathType Leaf) {
          [IO.File]::Delete($alias)
        }
      }
      Assert-CzxtTrue $script:BctFinalLockHardlinkInjected `
        'final formal lock internal-window injection did not run'
      Assert-CzxtTrue $rejected `
        'final formal lock accepted a hardlink added inside its open window'
    }

    Invoke-CzxtContract 'post-content-delete cleanup failure does not roll back the sealed formal card' {
      $fixture = New-P4tClosableItem 'cleanup-delete-rollback'
      $before = [IO.File]::ReadAllBytes($fixture.Item.CardPath)
      $script:BctCleanupInjectionSeen = $false
      $result = Invoke-P4tCloseInProcess $fixture @{
        'after-staging-owned-files-deleted' = {
          param($Context)
          $script:BctCleanupInjectionSeen =
            -not (Test-Path -LiteralPath $Context.Staging.Original.Path) -and
            -not (Test-Path -LiteralPath $Context.Staging.Candidate.Path)
          throw 'contract injected directory deletion failure'
        }
      }
      Assert-CzxtTrue $script:BctCleanupInjectionSeen `
        'cleanup injection did not run after both owned files were deleted'
      Assert-CzxtEqual 10 $result.ExitCode 'cleanup deletion failure exit code'
      $formalText = [IO.File]::ReadAllText($fixture.Item.CardPath, $script:P4tUtf8NoBom)
      Assert-CzxtTrue $formalText.Contains('lifecycle_status: closed') `
        'post-delete cleanup failure rolled back the sealed formal card'
      Assert-CzxtEqual cleanup $result.Stage 'post-delete cleanup failure stage'
      Assert-CzxtEqual cleanup-failed $result.ReasonCode `
        'post-delete cleanup failure reason code'
      $entries = @(Get-ChildItem -LiteralPath $result.StagingPath -Force)
      Assert-CzxtEqual 0 $entries.Count `
        'post-delete cleanup failure recreated already deleted staging content'
      Assert-CzxtTrue ($before.Length -gt 0) 'post-delete fixture original card is empty'
    }

    Invoke-CzxtContract 'formal-lock disposer post-release exception does not trigger rollback' {
      $fixture = New-P4tClosableItem 'formal-lock-post-release'
      $script:BctRealFormalLockOpen = (Get-Item Function:\Open-BctFormalReadLock).ScriptBlock
      $script:BctRealRestoreOriginal = (Get-Item Function:\Restore-BctOriginal).ScriptBlock
      $script:BctFormalPostReleaseSeen = $false
      $script:BctRollbackAfterCompleteAttempted = $false
      try {
        Set-Item Function:\Open-BctFormalReadLock -Value {
          param([string]$FormalPath, $ExpectedSnapshot)
          $inner = & $script:BctRealFormalLockOpen $FormalPath $ExpectedSnapshot
          $proxy = [pscustomobject]@{ Inner = $inner }
          Add-Member -InputObject $proxy -MemberType ScriptMethod -Name Dispose -Value {
            $this.Inner.Dispose()
            $script:BctFormalPostReleaseSeen = $true
            throw 'contract injected post-release exception'
          }
          return $proxy
        }
        Set-Item Function:\Restore-BctOriginal -Value {
          param(
            [string]$FormalPath, [byte[]]$OriginalBytes,
            $ExpectedFormalSnapshot, $Staging
          )
          $script:BctRollbackAfterCompleteAttempted = $true
          return & $script:BctRealRestoreOriginal $FormalPath $OriginalBytes `
            $ExpectedFormalSnapshot $Staging
        }
        $result = Invoke-P4tCloseInProcess $fixture @{}
      }
      finally {
        Set-Item Function:\Open-BctFormalReadLock -Value $script:BctRealFormalLockOpen
        Set-Item Function:\Restore-BctOriginal -Value $script:BctRealRestoreOriginal
      }
      Assert-CzxtTrue $script:BctFormalPostReleaseSeen `
        'formal-lock post-release injection did not run'
      Assert-CzxtTrue (-not $script:BctRollbackAfterCompleteAttempted) `
        'formal-lock post-release exception attempted rollback after Complete'
      Assert-CzxtEqual 10 $result.ExitCode 'formal-lock post-release exit code'
      Assert-CzxtEqual cleanup $result.Stage 'formal-lock post-release stage'
      Assert-CzxtEqual cleanup-failed $result.ReasonCode `
        'formal-lock post-release reason code'
      $formalText = [IO.File]::ReadAllText($fixture.Item.CardPath, $script:P4tUtf8NoBom)
      Assert-CzxtTrue $formalText.Contains('lifecycle_status: closed') `
        'formal-lock post-release exception rolled back the formal card'
    }

    Invoke-CzxtContract 'rollback refuses a same-byte replacement identity after P4t' {
      $fixture = New-P4tClosableItem 'rollback-same-bytes-identity'
      $script:BctReplacementIdentity = $null
      $result = Invoke-P4tCloseInProcess $fixture @{
        'before-final-formal-lock' = {
          param($Context)
          $replacement = Join-Path (Split-Path -Parent $Context.FormalPath) `
            ('.contract-replacement-' + [guid]::NewGuid().ToString('N') + '.tmp')
          [IO.File]::WriteAllBytes($replacement, $Context.ExpectedSnapshot.Bytes)
          [IO.File]::Delete($Context.FormalPath)
          [IO.File]::Move($replacement, $Context.FormalPath)
          $script:BctReplacementIdentity =
            (Get-BsiStableSnapshot $Context.FormalPath).IdentityKey
        }
      }
      Assert-CzxtTrue ($null -ne $script:BctReplacementIdentity) `
        'same-byte identity injection did not run before the final lock'
      Assert-CzxtEqual 10 $result.ExitCode 'same-byte replacement exit code'
      $after = Get-BsiStableSnapshot $fixture.Item.CardPath
      Assert-CzxtEqual $script:BctReplacementIdentity $after.IdentityKey `
        'rollback overwrote a same-byte concurrent replacement identity'
      Assert-CzxtEqual rollback $result.Stage 'same-byte replacement failure stage'
      Assert-CzxtEqual rollback-failed $result.ReasonCode `
        'same-byte replacement reason code'
      Assert-CzxtTrue ([IO.File]::ReadAllText(
          $fixture.Item.CardPath, $script:P4tUtf8NoBom).Contains(
          'lifecycle_status: closed')) 'same-byte replacement bytes changed'
    }

    Invoke-CzxtContract 'close refuses a same-byte identity swap after seal helper completion' {
      $fixture = New-P4tClosableItem 'seal-attestation-identity'
      $script:BctSealRaceSnapshot = $null
      $script:BctOriginalSealProcess =
        (Get-Item Function:\Invoke-BctSealProcess).ScriptBlock
      try {
        Set-Item Function:\Invoke-BctSealProcess -Value {
          param([string]$SafeRoot, [string]$FormalPath)
          $result = & $script:BctOriginalSealProcess `
            -SafeRoot $SafeRoot -FormalPath $FormalPath
          if ($result.ExitCode -eq 0) {
            $sealed = Get-BsiStableSnapshot $FormalPath
            $replacement = Join-Path (Split-Path -Parent $FormalPath) `
              ('.contract-post-seal-' + [guid]::NewGuid().ToString('N') + '.tmp')
            [IO.File]::WriteAllBytes($replacement, $sealed.Bytes)
            [IO.File]::Delete($FormalPath)
            [IO.File]::Move($replacement, $FormalPath)
            $script:BctSealRaceSnapshot = Get-BsiStableSnapshot $FormalPath
          }
          return $result
        }
        $result = Invoke-P4tCloseInProcess $fixture @{}
      }
      finally {
        Set-Item Function:\Invoke-BctSealProcess `
          -Value $script:BctOriginalSealProcess
      }
      Assert-CzxtTrue ($null -ne $script:BctSealRaceSnapshot) `
        'post-seal identity injection did not run'
      $after = Get-BsiStableSnapshot $fixture.Item.CardPath
      Assert-CzxtEqual $script:BctSealRaceSnapshot.IdentityKey $after.IdentityKey `
        'close rollback overwrote the post-seal concurrent object identity'
      Assert-CzxtEqual ([Convert]::ToBase64String($script:BctSealRaceSnapshot.Bytes)) `
        ([Convert]::ToBase64String($after.Bytes)) `
        'close changed the post-seal concurrent object bytes'
      Assert-CzxtEqual 10 $result.ExitCode `
        'close accepted a post-seal identity not installed by its helper'
      Assert-CzxtEqual seal $result.Stage 'post-seal identity failure stage'
      Assert-CzxtEqual seal-ownership-unproven $result.ReasonCode `
        'post-seal identity failure reason code'
    }

    Invoke-CzxtContract 'seal exit zero plus first formal snapshot failure preserves ownership evidence' {
      $fixture = New-P4tClosableItem 'seal-snapshot-ownership-unproven'
      $script:BctRealSealProcess = (Get-Item Function:\Invoke-BctSealProcess).ScriptBlock
      $script:BctRealStableSnapshot = (Get-Item Function:\Get-BsiStableSnapshot).ScriptBlock
      $script:BctSealFormalPath = $fixture.Item.CardPath
      $script:BctSealExitedZero = $false
      $script:BctSealSnapshotFailureSeen = $false
      try {
        Set-Item Function:\Invoke-BctSealProcess -Value {
          param([string]$SafeRoot, [string]$FormalPath)
          $result = & $script:BctRealSealProcess $SafeRoot $FormalPath
          if ($result.ExitCode -eq 0) { $script:BctSealExitedZero = $true }
          return $result
        }
        Set-Item Function:\Get-BsiStableSnapshot -Value {
          param([string]$Path)
          if ($script:BctSealExitedZero -and -not $script:BctSealSnapshotFailureSeen -and
              [string]::Equals($Path, $script:BctSealFormalPath,
                [StringComparison]::OrdinalIgnoreCase)) {
            $script:BctSealSnapshotFailureSeen = $true
            throw 'contract injected first post-seal formal snapshot failure'
          }
          return & $script:BctRealStableSnapshot $Path
        }
        $result = Invoke-P4tCloseInProcess $fixture @{}
      }
      finally {
        Set-Item Function:\Invoke-BctSealProcess -Value $script:BctRealSealProcess
        Set-Item Function:\Get-BsiStableSnapshot -Value $script:BctRealStableSnapshot
      }
      Assert-CzxtTrue $script:BctSealSnapshotFailureSeen `
        'first post-seal formal snapshot injection did not run'
      Assert-CzxtEqual 10 $result.ExitCode 'post-seal snapshot failure exit code'
      Assert-CzxtEqual seal $result.Stage 'post-seal snapshot failure stage'
      Assert-CzxtEqual seal-ownership-unproven $result.ReasonCode `
        'post-seal snapshot failure did not report unproven ownership'
      $formalText = [IO.File]::ReadAllText($fixture.Item.CardPath, $script:P4tUtf8NoBom)
      Assert-CzxtTrue $formalText.Contains('lifecycle_status: closed') `
        'post-seal snapshot failure changed the formal object'
      Assert-CzxtTrue (Test-Path -LiteralPath $result.StagingPath -PathType Container) `
        'post-seal snapshot failure removed staging evidence'
      Assert-CzxtEqual 2 @(Get-ChildItem -LiteralPath $result.StagingPath -Force).Count `
        'post-seal snapshot failure changed staging evidence'
    }

    Invoke-CzxtContract 'root isolation failure restores original active bytes and retains failed candidate' {
      $fixture = New-P4tClosableItem 'rollback' -BreakIsolation
      $before = [IO.File]::ReadAllBytes($fixture.Item.CardPath)
      $result = Invoke-P4tCloseFacade $fixture
      Assert-ExitCode $result 10 'close rollback after isolation failure'
      Assert-CzxtTrue $result.StdOut.Contains('stage=p4t-after') `
        ('close failure stage; stdout=' + $result.StdOut + '; stderr=' + $result.StdErr)
      Assert-CzxtEqual ([Convert]::ToBase64String($before)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($fixture.Item.CardPath))) `
        'close rollback original bytes'
      $itemRoot = Split-Path -Parent $fixture.Item.CardPath
      $staging = @(Get-ChildItem -LiteralPath $itemRoot -Directory -Force |
        Where-Object { $_.Name -like '.staging-close-*' })
      Assert-CzxtEqual 1 $staging.Count 'failed close staging count'
      $candidatePath = Join-Path $staging[0].FullName '借鉴卡.md'
      Assert-CzxtTrue (Test-Path -LiteralPath $candidatePath -PathType Leaf) `
        'failed close candidate retained'
      $candidate = [IO.File]::ReadAllText($candidatePath, $script:P4tUtf8NoBom)
      Assert-CzxtTrue $candidate.Contains('lifecycle_status: closed') `
        'failed candidate is not closed'
      Assert-CzxtTrue ([regex]::IsMatch($candidate,
          '(?m)^closure_seal_sha256: [0-9a-f]{64}$')) `
        'failed candidate did not retain seal result'
    }

    Invoke-CzxtContract 'seal post-check failure restores the active card without rollback failure' {
      $fixture = New-P4tClosableItem 'seal-post-check-rollback'
      $invalid = New-P4tItemCard -Root $fixture.Root `
        -BorrowId 'borrow-20260719-close-post-check-invalid' `
        -Bindings @($fixture.Source) -Status draft -Decision pending
      Set-P4tFrontmatterField $invalid.CardPath decision invalid
      $before = [IO.File]::ReadAllBytes($fixture.Item.CardPath)

      $result = Invoke-P4tCloseFacade $fixture

      Assert-ExitCode $result 10 'close rollback after seal post-check failure'
      Assert-CzxtTrue $result.StdOut.Contains('stage=seal') `
        ('seal post-check failure did not retain the seal stage; stdout=' +
          $result.StdOut + '; stderr=' + $result.StdErr)
      Assert-CzxtTrue $result.StdOut.Contains('reason_code=seal-failed') `
        'seal post-check failure degraded into rollback-failed'
      Assert-CzxtEqual ([Convert]::ToBase64String($before)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($fixture.Item.CardPath))) `
        'seal post-check failure left the formal card closed'
      $residue = @(Get-ChildItem -LiteralPath (Split-Path -Parent $fixture.Item.CardPath) `
        -Force | Where-Object { $_.Name -like '.staging-replace-*' })
      Assert-CzxtEqual 0 $residue.Count `
        'close seal post-check rollback left replacement residue'
    }

    Invoke-CzxtContract 'sealed formal card rolls back when staging candidate update fails before commit' {
      $fixture = New-P4tClosableItem 'seal-staging-update-rollback'
      $before = [IO.File]::ReadAllBytes($fixture.Item.CardPath)
      $script:BctStagingCandidateUpdateSeen = $false
      $result = Invoke-P4tCloseInProcess $fixture @{
        'before-staging-candidate-update' = {
          param($Context)
          $script:BctStagingCandidateUpdateSeen = $true
          throw 'contract injected staging candidate update failure'
        }
      }
      Assert-CzxtTrue $script:BctStagingCandidateUpdateSeen `
        'staging candidate update failure injection did not run'
      Assert-CzxtEqual 10 $result.ExitCode 'staging candidate update failure exit code'
      Assert-CzxtEqual seal $result.Stage 'staging candidate update failure stage'
      Assert-CzxtEqual seal-failed $result.ReasonCode `
        'staging candidate update failure reason code'
      Assert-CzxtEqual ([Convert]::ToBase64String($before)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($fixture.Item.CardPath))) `
        'staging candidate update failure did not restore the active card'
      Assert-CzxtTrue (Test-Path -LiteralPath $result.StagingPath -PathType Container) `
        'staging candidate update failure removed staging evidence'
      $candidatePath = Join-Path $result.StagingPath '借鉴卡.md'
      $candidateText = [IO.File]::ReadAllText($candidatePath, $script:P4tUtf8NoBom)
      Assert-CzxtTrue ([regex]::IsMatch(
          $candidateText, '(?m)^closure_seal_sha256: ""$')) `
        'staging candidate update failure changed the pre-update candidate bytes'
    }

    foreach ($attestationCase in @(
        [pscustomobject]@{
          Name = 'malformed'; Mode = 'malformed'; RestoresActive = $false
        },
        [pscustomobject]@{
          Name = 'field-mismatch'; Mode = 'field-mismatch'; RestoresActive = $true
        }
      )) {
      Invoke-CzxtContract ('seal attestation failure has an explicit ownership result: ' +
          $attestationCase.Name) {
        $fixture = New-P4tClosableItem ('seal-attestation-' + $attestationCase.Name)
        $before = [IO.File]::ReadAllBytes($fixture.Item.CardPath)
        Set-P4tCloseSealAttestationOverride $fixture.Root $attestationCase.Mode

        $result = Invoke-P4tCloseFacade $fixture

        Assert-ExitCode $result 10 ('seal attestation ' + $attestationCase.Name)
        Assert-CzxtTrue $result.StdOut.Contains('stage=seal') `
          ('seal attestation stage ' + $attestationCase.Name + '; stdout=' +
            $result.StdOut + '; stderr=' + $result.StdErr)
        if ($attestationCase.RestoresActive) {
          Assert-CzxtTrue $result.StdOut.Contains('reason_code=seal-failed') `
            ('seal attestation rollback reason ' + $attestationCase.Name)
          Assert-CzxtEqual ([Convert]::ToBase64String($before)) `
            ([Convert]::ToBase64String([IO.File]::ReadAllBytes($fixture.Item.CardPath))) `
            ('seal attestation active bytes ' + $attestationCase.Name)
        }
        else {
          Assert-CzxtTrue $result.StdOut.Contains(
            'reason_code=seal-ownership-unproven') `
            'malformed attestation did not report unproven ownership'
          $afterText = [IO.File]::ReadAllText(
            $fixture.Item.CardPath, $script:P4tUtf8NoBom)
          Assert-CzxtTrue $afterText.Contains('lifecycle_status: closed') `
            'malformed attestation overwrote the unproven formal object'
        }
      }
    }

    Invoke-CzxtContract 'malformed attestation preserves a same-byte replacement identity' {
      $fixture = New-P4tClosableItem 'seal-malformed-same-byte-identity'
      $script:BctMalformedReplacement = $null
      $script:BctOriginalSealProcess =
        (Get-Item Function:\Invoke-BctSealProcess).ScriptBlock
      try {
        Set-Item Function:\Invoke-BctSealProcess -Value {
          param([string]$SafeRoot, [string]$FormalPath)
          $result = & $script:BctOriginalSealProcess `
            -SafeRoot $SafeRoot -FormalPath $FormalPath
          if ($result.ExitCode -eq 0) {
            $sealed = Get-BsiStableSnapshot $FormalPath
            $replacement = Join-Path (Split-Path -Parent $FormalPath) `
              ('.contract-malformed-' + [guid]::NewGuid().ToString('N') + '.tmp')
            [IO.File]::WriteAllBytes($replacement, $sealed.Bytes)
            [IO.File]::Delete($FormalPath)
            [IO.File]::Move($replacement, $FormalPath)
            $script:BctMalformedReplacement = Get-BsiStableSnapshot $FormalPath
            return [pscustomobject]@{
              ExitCode = 0; StdOut = 'BROKEN'; StdErr = $result.StdErr
            }
          }
          return $result
        }
        $result = Invoke-P4tCloseInProcess $fixture @{}
      }
      finally {
        Set-Item Function:\Invoke-BctSealProcess `
          -Value $script:BctOriginalSealProcess
      }
      Assert-CzxtTrue ($null -ne $script:BctMalformedReplacement) `
        'malformed same-byte replacement injection did not run'
      Assert-CzxtEqual 10 $result.ExitCode 'malformed same-byte replacement exit code'
      Assert-CzxtEqual seal $result.Stage 'malformed same-byte replacement stage'
      Assert-CzxtEqual seal-ownership-unproven $result.ReasonCode `
        'malformed same-byte replacement reason'
      $after = Get-BsiStableSnapshot $fixture.Item.CardPath
      Assert-CzxtEqual $script:BctMalformedReplacement.IdentityKey $after.IdentityKey `
        'malformed attestation overwrote the replacement identity'
      Assert-CzxtEqual ([Convert]::ToBase64String(
          $script:BctMalformedReplacement.Bytes)) `
        ([Convert]::ToBase64String($after.Bytes)) `
        'malformed attestation changed the replacement bytes'
    }

    Invoke-CzxtContract 'staging file cleanup preserves a replacement at the same path' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-staging-file-bound-delete'
      [void](New-Item -ItemType Directory -Path $directory)
      [byte[]]$originalBytes = [Text.Encoding]::UTF8.GetBytes("original`n")
      [byte[]]$candidateBytes = [Text.Encoding]::UTF8.GetBytes("candidate`n")
      [byte[]]$laterBytes = [Text.Encoding]::UTF8.GetBytes("later`n")
      $staging = New-BctStaging $directory $originalBytes $candidateBytes
      $target = $staging.Candidate.Path
      $preserved = $target + '.preserved'
      $script:BsiOwnedObjectTestInjections = @{
        'before-file-handle-open' = {
          param($Context)
          if ($Context.Path -ceq $target) {
            [IO.File]::Move($target, $preserved)
            [IO.File]::WriteAllBytes($target, $laterBytes)
          }
        }
      }
      $rejected = $false
      try { Remove-BctStaging $staging }
      catch { $rejected = $true }
      finally { Remove-Variable BsiOwnedObjectTestInjections -Scope Script -ErrorAction SilentlyContinue }
      Assert-CzxtTrue $rejected 'staging cleanup accepted a replacement file'
      Assert-CzxtTrue (Test-Path -LiteralPath $target -PathType Leaf) `
        'staging cleanup deleted the replacement file'
      Assert-CzxtEqual ([Convert]::ToBase64String($laterBytes)) `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes($target))) `
        'staging cleanup changed the replacement file'
      Close-BctStagingLeases $staging
    }

    Invoke-CzxtContract 'staging directory cleanup lease blocks a replacement at the same path' {
      $directory = Join-Path $script:P4tFixtureRoot 'close-staging-directory-bound-delete'
      [void](New-Item -ItemType Directory -Path $directory)
      [byte[]]$originalBytes = [Text.Encoding]::UTF8.GetBytes("original`n")
      [byte[]]$candidateBytes = [Text.Encoding]::UTF8.GetBytes("candidate`n")
      $staging = New-BctStaging $directory $originalBytes $candidateBytes
      $preserved = $staging.Path + '.preserved'
      $script:BctDirectoryCleanupSwapBlocked = $false
      $script:BctDirectoryCleanupSwapSucceeded = $false
      $script:BctTestInjections = @{
        'before-staging-directory-delete' = {
          param($Context)
          try {
            [IO.Directory]::Move($staging.Path, $preserved)
            $script:BctDirectoryCleanupSwapSucceeded = $true
            [void][IO.Directory]::CreateDirectory($staging.Path)
          }
          catch { $script:BctDirectoryCleanupSwapBlocked = $true }
        }
      }
      try { Remove-BctStaging $staging }
      finally { Remove-Variable BctTestInjections -Scope Script -ErrorAction SilentlyContinue }
      Assert-CzxtTrue $script:BctDirectoryCleanupSwapBlocked `
        'staging cleanup directory replacement was not blocked'
      Assert-CzxtTrue (-not $script:BctDirectoryCleanupSwapSucceeded) `
        'staging cleanup directory was displaced'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath $staging.Path)) `
        'staging cleanup retained the owned directory'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath $preserved)) `
        'staging cleanup retained a displaced directory'
    }

    Invoke-CzxtContract 'successful close promotes sealed candidate only after full root P4t' {
      $fixture = New-P4tClosableItem 'success'
      $result = Invoke-P4tCloseFacade $fixture
      Assert-ExitCode $result 0 'successful close transaction'
      Assert-CzxtTrue $result.StdOut.Contains('result=CLOSED') 'close success output'
      $text = [IO.File]::ReadAllText($fixture.Item.CardPath, $script:P4tUtf8NoBom)
      Assert-CzxtTrue $text.Contains('lifecycle_status: closed') 'formal item not closed'
      $seal = [regex]::Match(
        $text, '(?m)^closure_seal_sha256: ([0-9a-f]{64})$').Groups[1].Value
      Assert-CzxtEqual (Get-P4tClosureSealFromText $text) $seal 'formal close seal'
      $staging = @(Get-ChildItem -LiteralPath (Split-Path -Parent $fixture.Item.CardPath) `
        -Directory -Force | Where-Object { $_.Name -like '.staging-close-*' })
      Assert-CzxtEqual 0 $staging.Count 'successful close retained staging'
      $p4t = Invoke-P4tFixture $fixture.Root
      Assert-ExitCode $p4t 0 'successful close root P4t'
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
