$ErrorActionPreference = 'Stop'

function global:Invoke-P4tIsolationTestInjection {
  param([string]$Name, $Context)
  if ($script:P4tIsolationTestInjections -is [Collections.IDictionary] -and
      $script:P4tIsolationTestInjections.Contains($Name)) {
    & $script:P4tIsolationTestInjections[$Name] $Context
  }
}

function global:Read-P4tIsolationExpectedFullSnapshot {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]$ExpectedFile,
    [Parameter(Mandatory = $true)][uint64]$MaximumBytes,
    [string]$ReasonCode = 'unsafe-business-path'
  )

  $stream = $null
  try {
    $before = Get-BorrowingSafePathInfo -Path $ExpectedFile.CanonicalPath `
      -ExpectedKind File -Stage 'p4t-isolation' -ReasonCode $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $ExpectedFile $before) -or
        [uint64]$before.Length -gt $MaximumBytes) {
      throw 'expected file changed before full read'
    }
    Invoke-P4tIsolationTestInjection 'before-expected-full-handle-open' `
      ([pscustomobject]@{
          Path = [string]$before.CanonicalPath; MaximumBytes = $MaximumBytes
        })
    $stream = New-Object IO.FileStream(
      $before.CanonicalPath, [IO.FileMode]::Open, [IO.FileAccess]::Read,
      [IO.FileShare]::Read)
    $opened = Get-BorrowingTrustedHandleSnapshot $stream.SafeFileHandle `
      'p4t-isolation' $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $ExpectedFile $opened) -or
        [uint64]$opened.Length -gt $MaximumBytes -or
        [uint64]$opened.Length -gt [uint64][int]::MaxValue) {
      throw 'expected file changed before full handle open'
    }
    Invoke-P4tIsolationTestInjection 'before-expected-full-content-read' `
      ([pscustomobject]@{
          Path = [string]$opened.CanonicalPath; Length = [uint64]$opened.Length
        })
    [byte[]]$bytes = New-Object byte[] ([int]$opened.Length)
    $offset = 0
    while ($offset -lt $bytes.Length) {
      $read = $stream.Read($bytes, $offset, $bytes.Length - $offset)
      if ($read -le 0) { throw 'expected file read ended early' }
      $offset += $read
    }
    $handleAfter = Get-BorrowingTrustedHandleSnapshot $stream.SafeFileHandle `
      'p4t-isolation' $ReasonCode
    $pathAfter = Get-BorrowingSafePathInfo -Path $opened.CanonicalPath `
      -ExpectedKind File -Stage 'p4t-isolation' -ReasonCode $ReasonCode
    if (-not (Test-BorrowingTrustedSnapshotEqual $opened $handleAfter) -or
        -not (Test-BorrowingTrustedSnapshotEqual $opened $pathAfter) -or
        -not (Test-BorrowingTrustedSnapshotEqual $ExpectedFile $pathAfter) -or
        [uint64]$opened.Length -ne [uint64]$bytes.LongLength) {
      throw 'expected file changed while reading'
    }
    return [pscustomobject]@{
      Path = $opened.CanonicalPath
      CanonicalPath = $opened.CanonicalPath
      IdentityKey = $opened.IdentityKey
      Length = [uint64]$opened.Length
      Bytes = $bytes
    }
  }
  finally { if ($null -ne $stream) { $stream.Dispose() } }
}

function global:Read-P4tIsolationStablePrefixSnapshot {
  param(
    $ExpectedFile,
    [int]$PrefixLength = 65536
  )

  $stream = $null
  try {
    $before = Get-BorrowingSafePathInfo -Path $ExpectedFile.CanonicalPath `
      -ExpectedKind File -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
    if (-not (Test-P4tIsolationSnapshotEqual $ExpectedFile $before)) {
      throw 'business file changed before prefix read'
    }
    Invoke-P4tIsolationTestInjection 'before-oversized-handle-open' `
      ([pscustomobject]@{ Path = [string]$before.CanonicalPath })
    $stream = New-Object IO.FileStream(
      $before.CanonicalPath, [IO.FileMode]::Open, [IO.FileAccess]::Read,
      [IO.FileShare]::Read)
    $opened = Get-BorrowingTrustedHandleSnapshot $stream.SafeFileHandle `
      'p4t-isolation' 'unsafe-business-path'
    if (-not (Test-BorrowingTrustedSnapshotEqual $before $opened)) {
      throw 'business file changed before prefix handle open'
    }
    $prefix = New-Object byte[] $PrefixLength
    $read = $stream.Read($prefix, 0, $prefix.Length)
    $handleAfter = Get-BorrowingTrustedHandleSnapshot $stream.SafeFileHandle `
      'p4t-isolation' 'unsafe-business-path'
    if (-not (Test-BorrowingTrustedSnapshotEqual $opened $handleAfter)) {
      throw 'business file changed while reading prefix'
    }
    Invoke-P4tIsolationTestInjection 'after-oversized-prefix-read' `
      ([pscustomobject]@{ Path = [string]$opened.CanonicalPath })
    # 路径复核必须发生在句柄释放前；FileShare.Read 同时封住删除与改名窗口。
    $pathAfter = Get-BorrowingSafePathInfo -Path $opened.CanonicalPath `
      -ExpectedKind File -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
    if (-not (Test-BorrowingTrustedSnapshotEqual $opened $pathAfter) -or
        -not (Test-BorrowingTrustedSnapshotEqual $ExpectedFile $pathAfter)) {
      throw 'business file changed while validating prefix path'
    }
    return [pscustomobject]@{
      Bytes = [byte[]]$prefix
      BytesRead = [int]$read
      File = $pathAfter
    }
  }
  finally { if ($null -ne $stream) { $stream.Dispose() } }
}

function global:Get-P4tIsolationDirectoryInventory {
  param($ExpectedDirectory, $Budget = $null)

  $before = Get-BorrowingSafePathInfo -Path $ExpectedDirectory.CanonicalPath `
    -ExpectedKind Directory -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
  if (-not (Test-P4tIsolationSnapshotEqual $ExpectedDirectory $before)) {
    throw 'business directory changed before inventory'
  }
  $inventory = New-Object Collections.Generic.List[object]
  $directory = New-Object IO.DirectoryInfo($before.CanonicalPath)
  foreach ($entry in $directory.EnumerateFileSystemInfos()) {
    if ($null -ne $Budget) {
      Use-P4tIsolationResourceBudget -Budget $Budget -DirectoryEntries 1
    }
    if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw ('business directory contains a reparse entry: ' + $entry.Name)
    }
    $isContainer = ($entry.Attributes -band [IO.FileAttributes]::Directory) -ne 0
    $kind = if ($isContainer) { 'Directory' } else { 'File' }
    $snapshot = Get-BorrowingSafePathInfo -Path $entry.FullName -ExpectedKind $kind `
      -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
    [void]$inventory.Add([pscustomobject]@{
        Name = [string]$entry.Name
        IsContainer = [bool]$isContainer
        Snapshot = $snapshot
      })
  }
  $after = Get-BorrowingSafePathInfo -Path $before.CanonicalPath `
    -ExpectedKind Directory -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
  if (-not (Test-P4tIsolationSnapshotEqual $before $after)) {
    throw 'business directory changed while building inventory'
  }
  return [pscustomobject]@{
    Directory = $after
    Entries = [object[]]$inventory.ToArray()
  }
}

function global:Test-P4tIsolationDirectoryInventoryEqual {
  param($Expected, $Actual)

  $expectedEntries = @($Expected.Entries)
  $actualEntries = @($Actual.Entries)
  if ($expectedEntries.Count -ne $actualEntries.Count) { return $false }
  foreach ($expectedEntry in $expectedEntries) {
    $matches = @($actualEntries | Where-Object {
        ([string]$_.Name).Equals([string]$expectedEntry.Name, [StringComparison]::Ordinal)
      })
    if ($matches.Count -ne 1 -or
        [bool]$matches[0].IsContainer -ne [bool]$expectedEntry.IsContainer -or
        -not (Test-P4tIsolationSnapshotEqual `
          $expectedEntry.Snapshot $matches[0].Snapshot)) {
      return $false
    }
  }
  return $true
}

function global:Test-P4tIsolationBytesEqual {
  param([byte[]]$Expected, [byte[]]$Actual)
  if ($null -eq $Expected -or $null -eq $Actual -or
      $Expected.Length -ne $Actual.Length) { return $false }
  for ($index = 0; $index -lt $Expected.Length; $index++) {
    if ($Expected[$index] -ne $Actual[$index]) { return $false }
  }
  return $true
}

function global:Test-P4tIsolationHasNulEvidence {
  param([byte[]]$Bytes, [int]$Length)
  for ($index = 0; $index -lt $Length; $index++) {
    if ($Bytes[$index] -eq 0) { return $true }
  }
  return $false
}
