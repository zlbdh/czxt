$ErrorActionPreference = 'Stop'

function global:Test-BorrowingStoredCaptureFingerprint {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true, Position = 0)]$Candidate)
  $valid = $false
  $applicable = $true
  $reason = 'stored fingerprint does not match the source card'
  if ($null -eq $Candidate -or
      [string]::IsNullOrEmpty([string]$Candidate.CaptureDirectory)) {
    return [pscustomobject]@{ Applicable = $true; IsValid = $false; Reason = $reason }
  }
  if ($Candidate.SourceType -ceq 'git') {
    $applicable = $false
    $valid = $true
    $reason = 'Git cache validation is delegated to the offline Git validator'
  }
  elseif ($Candidate.SourceType -ceq 'local') {
    $snapshot = Get-BcvLocalStoredSnapshot `
      $Candidate.CaptureDirectory $Candidate.Fingerprint
    $valid = $null -ne $snapshot -and
      [int64]$Candidate.TypeFacts.FileCount -eq [int64]$snapshot.FileCount -and
      [int64]$Candidate.TypeFacts.TotalBytes -eq [int64]$snapshot.TotalBytes -and
      [string]$Candidate.TypeFacts.ManifestAlgorithm -ceq 'sha256-manifest-v1'
  }
  elseif ($Candidate.SourceType -ceq 'web') {
    $snapshot = Get-BcvWebStoredSnapshot `
      $Candidate.CaptureDirectory $Candidate.Fingerprint
    if ($null -ne $snapshot) {
      $projection = Get-BcvWebFactProjection $snapshot.Metadata $snapshot.Fingerprint
      $valid = $true
      foreach ($property in @(
          'OriginalUrl', 'FinalUrl', 'RedirectChain', 'StatusCode', 'Mime',
          'Charset', 'Etag', 'LastModified', 'ResponseHash'
        )) {
        if ([string]$projection.$property -cne [string]$Candidate.TypeFacts.$property) {
          $valid = $false
        }
      }
      if ([string]$Candidate.CanonicalLocator -cne [string]$projection.FinalUrl) {
        $valid = $false
      }
    }
  }
  return [pscustomobject][ordered]@{
    Applicable = $applicable
    IsValid = [bool]$valid
    Reason = $(if ($valid) { 'none' } else { $reason })
  }
}
