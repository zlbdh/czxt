$ErrorActionPreference = 'Stop'

$bcvWebFingerprintRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Read-BorrowingStableSafeFileSnapshot -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $bcvWebFingerprintRoot 'trusted-file-read.ps1')
}

function global:Read-BcvStableCacheFile {
  param([string]$Path, [uint64]$MaximumBytes)
  $before = Get-BorrowingSafePathInfo $Path File candidate source-unsafe
  if ([uint64]$before.Length -gt $MaximumBytes) { return $null }
  $snapshot = Read-BorrowingStableSafeFileSnapshot `
    $before.CanonicalPath candidate source-unsafe
  if (-not (Test-BorrowingTrustedSnapshotEqual $before $snapshot)) {
    return $null
  }
  return [pscustomobject]@{ Bytes = $snapshot.Bytes; PathInfo = $snapshot }
}

function global:Get-BcvWebStoredSnapshot {
  param([string]$CaptureDirectory, [string]$ExpectedFingerprint)
  try {
    if ($ExpectedFingerprint -cnotmatch '\A[0-9a-f]{64}\z' -or
        (Get-BorrowingIgnoredCacheState $CaptureDirectory web).State -cne 'Healthy') {
      return $null
    }
    $raw = Read-BcvStableCacheFile `
      (Join-Path $CaptureDirectory '快照\response.bin') 67108864
    $metadataFile = Read-BcvStableCacheFile `
      (Join-Path $CaptureDirectory '快照\response.metadata.json') 65536
    if ($null -eq $raw -or $null -eq $metadataFile -or
        (Get-BcvSha256Hex $raw.Bytes) -cne $ExpectedFingerprint) { return $null }
    $metadata = Read-BorrowingStrictWebMetadata -Bytes $metadataFile.Bytes
    [byte[]]$canonical = ConvertTo-BorrowingCanonicalWebMetadataBytes $metadata
    if (-not (Test-BcvBytesEqual $canonical $metadataFile.Bytes)) { return $null }
    return [pscustomobject][ordered]@{
      IsValid = $true; Fingerprint = $ExpectedFingerprint; Metadata = $metadata
      RawBytes = $raw.Bytes; CanonicalMetadataBytes = $canonical
    }
  }
  catch { return $null }
}

function global:Test-BorrowingWebStoredFingerprint {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)][string]$CaptureDirectory,
    [Parameter(Mandatory = $true, Position = 1)][string]$ExpectedFingerprint
  )
  return $null -ne (Get-BcvWebStoredSnapshot $CaptureDirectory $ExpectedFingerprint)
}

function global:Get-BcvWebFactProjection {
  param($Metadata, [string]$Fingerprint)
  $redirects = @($Metadata.RedirectChain | ForEach-Object {
      '{"status_code":' + ([string]$_.StatusCode) + ',"location_url":' +
        (ConvertTo-BorrowingCanonicalJsonString ([string]$_.LocationUrl)) + '}'
    })
  $nullable = {
    param($value)
    if ($null -eq $value) { return 'null' }
    return ConvertTo-BorrowingCanonicalJsonString ([string]$value)
  }
  return [pscustomobject][ordered]@{
    OriginalUrl = [string]$Metadata.OriginalUrl
    FinalUrl = [string]$Metadata.FinalUrl
    RedirectChain = '[' + ($redirects -join ',') + ']'
    StatusCode = [int]$Metadata.StatusCode
    Mime = [string]$Metadata.Mime
    Charset = & $nullable $Metadata.Charset
    Etag = & $nullable $Metadata.Etag
    LastModified = & $nullable $Metadata.LastModified
    ResponseHash = $Fingerprint
  }
}
