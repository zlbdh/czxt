$ErrorActionPreference = 'Stop'

$bcvLocalFingerprintRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Read-BorrowingStableSafeFileSnapshot -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $bcvLocalFingerprintRoot 'trusted-file-read.ps1')
}

function global:Get-BcvLocalStoredSnapshot {
  param([string]$CaptureDirectory, [string]$ExpectedFingerprint)
  try {
    if ($ExpectedFingerprint -cnotmatch '\A[0-9a-f]{64}\z' -or
        (Get-BorrowingIgnoredCacheState $CaptureDirectory local).State -cne 'Healthy') {
      return $null
    }
    $contentPath = Join-Path $CaptureDirectory '快照\内容'
    $manifestPath = Join-Path $CaptureDirectory '快照\manifest.tsv'
    $rootInfo = Get-BorrowingSafePathInfo $contentPath Directory candidate source-unsafe
    $entries = New-Object 'Collections.Generic.Dictionary[string,object]' `
      ([StringComparer]::Ordinal)
    $stack = New-Object 'Collections.Generic.Stack[string]'
    $stack.Push($rootInfo.CanonicalPath)
    [int64]$totalBytes = 0
    while ($stack.Count -gt 0) {
      $directory = $stack.Pop()
      foreach ($item in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return $null }
        $kind = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
        $info = Get-BorrowingSafePathInfo $item.FullName $kind candidate source-unsafe
        if ((Get-BorrowingPathRelation $rootInfo.CanonicalPath $info.CanonicalPath) -cne
            $(if ($info.CanonicalPath -ceq $rootInfo.CanonicalPath) { 'equal' } else { 'ancestor' })) {
          return $null
        }
        if ($kind -eq 'Directory') {
          $stack.Push($info.CanonicalPath)
          continue
        }
        $relative = $info.CanonicalPath.Substring($rootInfo.CanonicalPath.Length + 1).Replace('\', '/')
        if ($relative -cne $relative.Normalize([Text.NormalizationForm]::FormC) -or
            [string]::IsNullOrEmpty($relative) -or $relative -match '[\t\r\n]' -or
            [Text.Encoding]::UTF8.GetByteCount($relative) -gt 1024 -or
            $relative.Split('/').Count -gt 64 -or $entries.ContainsKey($relative)) {
          return $null
        }
        [uint64]$length = $info.Length
        if ($length -gt 67108864 -or $length -gt [uint64][int64]::MaxValue -or
            $totalBytes -gt (536870912 - [int64]$length)) { return $null }
        $snapshot = Read-BorrowingStableSafeFileSnapshot `
          $info.CanonicalPath candidate source-unsafe
        if (-not (Test-BorrowingTrustedSnapshotEqual $info $snapshot)) {
          return $null
        }
        [byte[]]$bytes = $snapshot.Bytes
        $entries.Add($relative, [pscustomobject]@{
            RelativePath = $relative; Length = [int64]$length
            Sha256 = Get-BcvSha256Hex $bytes
          })
        $totalBytes += [int64]$length
        if ($entries.Count -gt 10000) { return $null }
      }
    }
    [string[]]$paths = @($entries.Keys)
    [Array]::Sort($paths, [StringComparer]::Ordinal)
    $builder = New-Object Text.StringBuilder
    foreach ($path in $paths) {
      $entry = $entries[$path]
      [void]$builder.Append($entry.Sha256).Append("`t").Append(
        $entry.Length.ToString([Globalization.CultureInfo]::InvariantCulture)).Append(
        "`t").Append($entry.RelativePath).Append("`n")
    }
    [byte[]]$computedManifest = [Text.Encoding]::UTF8.GetBytes($builder.ToString())
    $manifestBefore = Get-BorrowingSafePathInfo $manifestPath File candidate source-unsafe
    $manifestSnapshot = Read-BorrowingStableSafeFileSnapshot `
      $manifestBefore.CanonicalPath candidate source-unsafe
    [byte[]]$storedManifest = $manifestSnapshot.Bytes
    if (-not (Test-BorrowingTrustedSnapshotEqual $manifestBefore $manifestSnapshot) -or
        -not (Test-BcvBytesEqual $computedManifest $storedManifest)) { return $null }
    $fingerprint = Get-BcvSha256Hex $computedManifest
    if ($fingerprint -cne $ExpectedFingerprint) { return $null }
    return [pscustomobject][ordered]@{
      IsValid = $true; Fingerprint = $fingerprint; ManifestBytes = $computedManifest
      FileCount = $entries.Count; TotalBytes = $totalBytes
    }
  }
  catch { return $null }
}

function global:Test-BorrowingLocalStoredFingerprint {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)][string]$CaptureDirectory,
    [Parameter(Mandatory = $true, Position = 1)][string]$ExpectedFingerprint
  )
  return $null -ne (Get-BcvLocalStoredSnapshot $CaptureDirectory $ExpectedFingerprint)
}
