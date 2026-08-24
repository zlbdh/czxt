$ErrorActionPreference = 'Stop'

$ownedTreeSealRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $ownedTreeSealRoot 'owned-tree-seal-native.ps1')

function global:Stop-BorrowingOwnedTreeSeal {
  param([string]$Stage, [string]$ReasonCode, [string]$Reason)
  Throw-BorrowingFailure $Stage $ReasonCode $Reason
}

. (Join-Path $ownedTreeSealRoot 'owned-tree-seal-inventory.ps1')

function global:Close-BorrowingOwnedTreeSealHandles {
  param($Seal)
  if ($null -eq $Seal) { return }
  foreach ($entry in @($Seal.Files.Values)) {
    if ($null -ne $entry.Native) {
      try { $entry.Native.Dispose() } catch { }
      $entry.Native = $null
    }
  }
  foreach ($entry in @($Seal.Directories.Values)) {
    if ($null -ne $entry.Handle) {
      try { $entry.Handle.Dispose() } catch { }
      $entry.Handle = $null
    }
  }
}

function global:Get-BorrowingOwnedTreeSealDirectoryHandleSnapshot {
  param($Handle, [string]$Stage, [string]$ReasonCode)
  try {
    $information = New-Object Czxt.B.FI
    if (-not [Czxt.B.NP]::GetFileInformationByHandle(
        $Handle, [ref]$information) -or
        ($information.FileAttributes -band 0x10) -eq 0 -or
        ($information.FileAttributes -band 0x400) -ne 0) {
      throw 'directory identity'
    }
    $buffer = New-Object Text.StringBuilder 32768
    $count = [Czxt.B.NP]::GetFinalPathNameByHandleW(
      $Handle, $buffer, [uint32]$buffer.Capacity, 0)
    if ($count -eq 0 -or $count -ge $buffer.Capacity) { throw 'directory path' }
    $path = ConvertFrom-BorrowingOwnedNativePath `
      $buffer.ToString() $Stage $ReasonCode
    return [pscustomobject]@{
      Path = $path
      IdentityKey = '{0:x8}:{1:x8}:{2:x8}' -f `
        $information.VolumeSerialNumber, $information.FileIndexHigh,
        $information.FileIndexLow
    }
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal directory handle is unsafe'
  }
}

function global:Open-BorrowingOwnedTreeSealDirectory {
  param($Member, [string]$Stage, [string]$ReasonCode)
  $handle = $null
  try {
    # DELETE access is required for later same-handle disposition; omitting it
    # turns an otherwise valid empty-directory cleanup into ERROR_ACCESS_DENIED.
    $handle = [Czxt.B.NP]::CreateFileW(
      $Member.Path, [uint32]0x001100A1, 3, [IntPtr]::Zero, 3,
      [uint32]0x02200000, [IntPtr]::Zero)
    if ($null -eq $handle -or $handle.IsInvalid) {
      throw 'directory open'
    }
    $snapshot = Get-BorrowingOwnedTreeSealDirectoryHandleSnapshot `
      $handle $Stage $ReasonCode
    if (-not (Test-BorrowingOwnedSamePath $snapshot.Path $Member.Path) -or
        $snapshot.IdentityKey -cne $Member.IdentityKey) {
      Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
        'owned tree seal directory changed while opening'
    }
    $entry = [pscustomobject]@{
      Key = $Member.Key; Kind = 'Directory'; Path = $snapshot.Path
      IdentityKey = $snapshot.IdentityKey; Handle = $handle
    }
    $handle = $null
    return $entry
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal directory open failed'
  }
  finally { if ($null -ne $handle) { $handle.Dispose() } }
}

function global:Open-BorrowingOwnedTreeSealFile {
  param($Member, [string]$Stage, [string]$ReasonCode)
  $native = $null
  try {
    # FILE_SHARE_READ keeps harmless readers compatible while denying writes,
    # rename and delete for the entire seal window.
    $native = [Czxt.B.BorrowingTreeFileLease]::OpenReadLocked($Member.Path)
    $path = ConvertFrom-BorrowingOwnedNativePath `
      $native.FinalPath $Stage $ReasonCode
    $identity = Get-BorrowingOwnedNativeIdentity $native
    if (-not (Test-BorrowingOwnedSamePath $path $Member.Path) -or
        $identity -cne $Member.IdentityKey -or
        [uint64]$native.Length -ne [uint64]$Member.Length) {
      Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
        'owned tree seal file changed while opening'
    }
    $entry = [pscustomobject]@{
      Key = $Member.Key; Kind = 'File'; Path = $path
      IdentityKey = $identity; Length = [uint64]$native.Length
      Sha256 = ([BitConverter]::ToString(
          ([byte[]]$native.Digest))).Replace('-', '').ToLowerInvariant()
      Native = $native
    }
    $native = $null
    return $entry
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal file open failed'
  }
  finally { if ($null -ne $native) { $native.Dispose() } }
}

function global:New-BorrowingOwnedTreeSeal {
  param($Ownership, [string]$RootPath,
    [string]$Stage = 'capture', [string]$ReasonCode = 'source-unsafe',
    $RootOwned = $null)
  if ($null -eq $Ownership) {
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal ownership is missing'
  }
  $rootOwned = $RootOwned
  if ($null -eq $rootOwned) {
    $rootOwned = Find-BorrowingOwnedDirectoryState $Ownership `
      ([IO.Path]::GetFullPath($RootPath))
  }
  if ($null -eq $rootOwned -or $null -eq $rootOwned.Native) {
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal root lease is missing'
  }
  $seal = $null
  try {
    # Old candidate leases can permit readers only or carry stale paths; the
    # seal replaces them with one uniform, read-locked ledger.
    Close-BorrowingOwnedDescendantFiles $Ownership $rootOwned.Path
    Close-BorrowingOwnedDescendantDirectories $Ownership $rootOwned.Path -KeepRoot
    $rootOwned.Native.Verify()
    $first = Get-BorrowingOwnedTreeSealInventory `
      $rootOwned.Path $Stage $ReasonCode
    if ($first.Root.IdentityKey -cne $rootOwned.IdentityKey) {
      Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
        'owned tree seal root identity changed'
    }
    $directories = New-Object `
      'Collections.Generic.Dictionary[string,object]' `
      ([StringComparer]::OrdinalIgnoreCase)
    $files = New-Object `
      'Collections.Generic.Dictionary[string,object]' `
      ([StringComparer]::OrdinalIgnoreCase)
    $seal = [pscustomobject]@{
      Schema = 'borrowing-owned-tree-seal/v1'
      RootPath = $first.Root.CanonicalPath; RootIdentityKey = $first.Root.IdentityKey
      RootOwned = $rootOwned; Directories = $directories; Files = $files
      Stage = $Stage; ReasonCode = $ReasonCode
      Closed = $false; Removed = $false
    }
    $directoryMembers = @($first.Members.Values | Where-Object {
        $_.Kind -ceq 'Directory'
      } | Sort-Object { ([string]$_.Path).Length })
    foreach ($member in $directoryMembers) {
      $entry = Open-BorrowingOwnedTreeSealDirectory $member $Stage $ReasonCode
      $directories.Add($entry.Key, $entry)
    }
    foreach ($member in @($first.Members.Values | Where-Object {
          $_.Kind -ceq 'File'
        } | Sort-Object Path)) {
      $entry = Open-BorrowingOwnedTreeSealFile $member $Stage $ReasonCode
      $files.Add($entry.Key, $entry)
    }
    # Enumeration is not a snapshot on Windows. A complete second pass closes
    # the enumerate/open race before this ledger is accepted.
    Invoke-BorrowingOwnedTreeSealInjection `
      'after-seal-handles-open-before-reconcile' $seal
    Assert-BorrowingOwnedTreeSeal $seal
    return $seal
  }
  catch {
    if ($null -ne $seal) { Close-BorrowingOwnedTreeSealHandles $seal }
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-BorrowingOwnedTreeSeal $Stage $ReasonCode `
      'owned tree seal creation failed'
  }
}

function global:Assert-BorrowingOwnedTreeSeal {
  param($Seal)
  if ($null -eq $Seal -or [bool]$Seal.Closed -or [bool]$Seal.Removed) {
    Stop-BorrowingOwnedTreeSeal capture source-unsafe `
      'owned tree seal is not active'
  }
  $stage = [string]$Seal.Stage; $reasonCode = [string]$Seal.ReasonCode
  try {
    $Seal.RootOwned.Native.Verify()
    $current = Get-BorrowingOwnedTreeSealInventory `
      $Seal.RootPath $stage $reasonCode
    if ($current.Root.IdentityKey -cne $Seal.RootIdentityKey -or
        $current.Members.Count -ne
          ($Seal.Directories.Count + $Seal.Files.Count)) {
      Stop-BorrowingOwnedTreeSeal $stage $reasonCode `
        'owned tree seal membership changed'
    }
    foreach ($member in @($current.Members.Values)) {
      $ledger = if ($member.Kind -ceq 'Directory') { $Seal.Directories }
        else { $Seal.Files }
      if (-not $ledger.ContainsKey($member.Key)) {
        Stop-BorrowingOwnedTreeSeal $stage $reasonCode `
          'owned tree seal contains an unknown member'
      }
      $entry = $ledger[$member.Key]
      if ($entry.IdentityKey -cne $member.IdentityKey -or
          ($member.Kind -ceq 'File' -and
            [uint64]$entry.Length -ne [uint64]$member.Length)) {
        Stop-BorrowingOwnedTreeSeal $stage $reasonCode `
          'owned tree seal member identity changed'
      }
      if ($member.Kind -ceq 'Directory') {
        $opened = Get-BorrowingOwnedTreeSealDirectoryHandleSnapshot `
          $entry.Handle $stage $reasonCode
        if (-not (Test-BorrowingOwnedSamePath $opened.Path $entry.Path) -or
            $opened.IdentityKey -cne $entry.IdentityKey) {
          Stop-BorrowingOwnedTreeSeal $stage $reasonCode `
            'owned tree seal directory lease changed'
        }
      }
      else { $entry.Native.Verify() }
    }
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Stop-BorrowingOwnedTreeSeal $stage $reasonCode `
      'owned tree seal assertion failed'
  }
}

function global:Close-BorrowingOwnedTreeSeal {
  param($Seal)
  if ($null -eq $Seal -or [bool]$Seal.Closed) { return }
  Close-BorrowingOwnedTreeSealHandles $Seal
  $Seal.Closed = $true
}

. (Join-Path $ownedTreeSealRoot 'owned-tree-seal-remove.ps1')
