$ErrorActionPreference = 'Stop'

function global:Get-P4tIsolationFileDigestSnapshot {
  param($ExpectedFile, $Budget)

  $sha = $null
  try {
    $fullDigestLimit = [uint64](8MB)
    if ([uint64]$ExpectedFile.Length -le $fullDigestLimit) {
      $digestBytes = [uint64]$ExpectedFile.Length
      Use-P4tIsolationResourceBudget $Budget 1 0 $digestBytes
      $read = Read-P4tIsolationExpectedFullSnapshot `
        -ExpectedFile $ExpectedFile -MaximumBytes $digestBytes
      [byte[]]$content = $read.Bytes
      $snapshot = [pscustomobject]@{
        CanonicalPath = $read.CanonicalPath
        IdentityKey = $read.IdentityKey
        Kind = 'File'
        Length = [uint64]$read.Length
      }
      $digestKind = 'full-sha256'
    }
    else {
      $prefixLength = 65536
      Use-P4tIsolationResourceBudget $Budget 1 0 ([uint64]$prefixLength)
      $read = Read-P4tIsolationStablePrefixSnapshot `
        -ExpectedFile $ExpectedFile -PrefixLength $prefixLength
      [byte[]]$content = $read.Bytes
      $digestBytes = [uint64]$read.BytesRead
      $snapshot = $read.File
      $digestKind = 'prefix-64k-sha256'
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($content, 0, [int]$digestBytes)
    $digest = ([BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant()
    return [pscustomobject]@{
      Snapshot = $snapshot
      Sha256 = [string]$digest
      DigestKind = $digestKind
      DigestBytes = [uint64]$digestBytes
    }
  }
  finally { if ($null -ne $sha) { $sha.Dispose() } }
}

function global:Get-P4tIsolationTreeSnapshot {
  param(
    $ExpectedRoot,
    [string[]]$ExcludedNames,
    $Budget
  )

  $root = Get-BorrowingSafePathInfo -Path $ExpectedRoot.CanonicalPath `
    -ExpectedKind Directory -Stage 'p4t-isolation' -ReasonCode 'unsafe-business-path'
  if (-not (Test-P4tIsolationSnapshotEqual $ExpectedRoot $root)) {
    throw 'business root changed before tree snapshot'
  }
  $records = New-Object Collections.Generic.List[object]
  [void]$records.Add([pscustomobject]@{
      RelativePath = '.'; Kind = 'Directory'; Snapshot = $root; Sha256 = $null
    })
  $pending = New-Object Collections.Generic.Queue[object]
  $pending.Enqueue([pscustomobject]@{ RelativePath = ''; Snapshot = $root })
  while ($pending.Count -gt 0) {
    $directory = $pending.Dequeue()
    $inventory = Get-P4tIsolationDirectoryInventory $directory.Snapshot $Budget
    foreach ($entry in @($inventory.Entries)) {
      $relative = if ([string]::IsNullOrEmpty([string]$directory.RelativePath)) {
        [string]$entry.Name
      }
      else { [string]$directory.RelativePath + '/' + [string]$entry.Name }
      if ($entry.IsContainer) {
        [void]$records.Add([pscustomobject]@{
            RelativePath = $relative; Kind = 'Directory'
            Snapshot = $entry.Snapshot; Sha256 = $null
          })
        if ($ExcludedNames -notcontains ([string]$entry.Name).ToLowerInvariant()) {
          $pending.Enqueue([pscustomobject]@{
              RelativePath = $relative; Snapshot = $entry.Snapshot
            })
        }
      }
      else {
        $digest = Get-P4tIsolationFileDigestSnapshot $entry.Snapshot $Budget
        [void]$records.Add([pscustomobject]@{
            RelativePath = $relative; Kind = 'File'
            Snapshot = $digest.Snapshot; Sha256 = $digest.Sha256
            DigestKind = $digest.DigestKind; DigestBytes = $digest.DigestBytes
          })
      }
    }
  }
  return [pscustomobject]@{
    Root = $root
    Records = [object[]]$records.ToArray()
  }
}

function global:Test-P4tIsolationTreeSnapshotEqual {
  param($Expected, $Actual)

  $expectedRecords = @($Expected.Records | Sort-Object RelativePath -CaseSensitive)
  $actualRecords = @($Actual.Records | Sort-Object RelativePath -CaseSensitive)
  if ($expectedRecords.Count -ne $actualRecords.Count) { return $false }
  for ($index = 0; $index -lt $expectedRecords.Count; $index++) {
    $left = $expectedRecords[$index]
    $right = $actualRecords[$index]
    if ([string]$left.RelativePath -cne [string]$right.RelativePath -or
        [string]$left.Kind -cne [string]$right.Kind -or
        -not (Test-P4tIsolationSnapshotEqual $left.Snapshot $right.Snapshot) -or
        [string]$left.Sha256 -cne [string]$right.Sha256 -or
        [string]$left.DigestKind -cne [string]$right.DigestKind -or
        [uint64]$left.DigestBytes -ne [uint64]$right.DigestBytes) {
      return $false
    }
  }
  return $true
}
