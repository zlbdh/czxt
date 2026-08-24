$ErrorActionPreference = 'Stop'

if (-not (Get-Command Test-BorrowingCredentialMaterial -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path ([IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)) `
      'credential-safety.ps1')
}

function global:Assert-BorrowingSourceCardCredentialSafe {
  param([AllowNull()][object[]]$Values)
  foreach ($value in @($Values)) {
    if ($null -ne $value -and (Test-BorrowingCredentialMaterial ([string]$value))) {
      Throw-BorrowingSourceCardFailure candidate candidate-invalid `
        'source-card value contains credential material'
    }
  }
}

function global:New-BorrowingSourceCardArtifactCore {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]$Skeleton,
    [Parameter(Mandatory = $true)]$Candidate,
    [Parameter(Mandatory = $true)]$Permissions,
    [DateTimeOffset]$UtcNow = [DateTimeOffset]::UtcNow
  )
  $type = ([string]$Candidate.SourceType).ToLowerInvariant()
  if (@('git', 'local', 'web') -cnotcontains $type -or
      $type -cne [string]$Permissions.SourceType) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'source-card source type is invalid'
  }
  $sourceId = Assert-BorrowingSafeIdentifier ([string]$Permissions.SourceId) SourceId
  $fingerprint = [string]$Candidate.Fingerprint
  $algorithm = [string]$Candidate.FingerprintAlgorithm
  if ($fingerprint -cnotmatch '\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z' -or
      $algorithm -cnotmatch '\A[a-z0-9][a-z0-9-]*\z') {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'source-card fingerprint is invalid'
  }
  $utc = $UtcNow.ToUniversalTime()
  $clock = $utc.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", [Globalization.CultureInfo]::InvariantCulture)
  $captureId = '{0}-{1}-{2}' -f $type, $utc.ToString('yyyyMMdd'), $fingerprint.Substring(0, 12)
  Assert-BorrowingSourceCardCredentialSafe @($sourceId, $Candidate.CanonicalLocator)
  $locator = ConvertTo-BorrowingCardCell ([string]$Candidate.CanonicalLocator)
  $propertyNames = @(
    'RightsStatus', 'AccessPolicy', 'ReuseScope', 'ExecutionPolicy', 'NetworkPolicy',
    'StoragePolicy', 'DistributionPolicy', 'UpstreamWritePolicy', 'AutoRefresh'
  )
  $dimensions = @(
    'rights_status', 'access_policy', 'reuse_scope', 'execution_policy', 'network_policy',
    'storage_policy', 'distribution_policy', 'upstream_write_policy', 'auto_refresh'
  )
  $lines = @($Skeleton.Lines | ForEach-Object { [string]$_ })
  if ($lines.Count -ne 67) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'source-card skeleton object is invalid'
  }
  $lines[2] = 'source_id: ' + $sourceId
  $lines[3] = 'capture_id: ' + $captureId
  $lines[4] = 'source_type: ' + $type
  $lines[6] = 'canonical_locator: ' + $locator
  $lines[7] = 'fingerprint_algorithm: ' + $algorithm
  $lines[8] = 'fingerprint: ' + $fingerprint
  $lines[9] = 'captured_at: ' + $clock
  $stablePermissionParts = @()
  $stableOverrideParts = @()
  for ($index = 0; $index -lt 9; $index++) {
    $value = ConvertTo-BorrowingCardCell $Permissions.($propertyNames[$index])
    $lines[10 + $index] = $dimensions[$index] + ': ' + $value
    $stablePermissionParts += (ConvertTo-BorrowingCanonicalJsonString $dimensions[$index]) +
      ':' + (ConvertTo-BorrowingCanonicalJsonString $value)
  }
  $lines[23] = '- 正式路径：`借鉴区/来源/' + $sourceId + '/' +
    $captureId + '/来源版本卡.md`'
  $authorizations = @($Permissions.PermissionAuthorizations)
  if ($authorizations.Count -ne 9) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'permission authorization rows are invalid'
  }
  for ($index = 0; $index -lt 9; $index++) {
    $authorization = $authorizations[$index]
    $value = ConvertTo-BorrowingCardCell $Permissions.($propertyNames[$index])
    if ([string]$authorization.Dimension -cne $dimensions[$index] -or
        [string]$authorization.Value -cne $value) {
      Throw-BorrowingSourceCardFailure candidate candidate-invalid `
        'permission authorization order is invalid'
    }
    if ([bool]$authorization.IsDefault) {
      $time = $clock
      $authorizationSource = 'default-policy'
      $scope = 'current-capture'
    }
    else {
      $time = ConvertTo-BorrowingCardCell $authorization.AuthorizationTime
      $authorizationSource = ConvertTo-BorrowingCardCell $authorization.AuthorizationSource
      $scope = ConvertTo-BorrowingCardCell $authorization.AuthorizationScope
      if ($time -cnotmatch
          '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z\z') {
        Throw-BorrowingSourceCardFailure candidate candidate-invalid `
          'permission authorization time is invalid'
      }
      $stableOverrideParts += '{"dimension":' +
        (ConvertTo-BorrowingCanonicalJsonString $dimensions[$index]) + ',"time":' +
        (ConvertTo-BorrowingCanonicalJsonString $time) + ',"source":' +
        (ConvertTo-BorrowingCanonicalJsonString $authorizationSource) + ',"scope":' +
        (ConvertTo-BorrowingCanonicalJsonString $scope) + '}'
    }
    Assert-BorrowingSourceCardCredentialSafe @($authorizationSource, $scope)
    $lines[32 + $index] = New-BorrowingCardRow @(
      $dimensions[$index], $value, $time, $authorizationSource, $scope
    )
  }
  $notApplicable = 'not-applicable'
  $lines[46] = New-BorrowingCardRow @(1..7 | ForEach-Object { $notApplicable })
  $lines[52] = New-BorrowingCardRow @(1..5 | ForEach-Object { $notApplicable })
  $lines[58] = New-BorrowingCardRow @(1..9 | ForEach-Object { $notApplicable })
  if ($type -eq 'git') {
    $facts = $Candidate.GitFacts
    if (@('branch', 'tag') -cnotcontains [string]$facts.RefType -or
        @('sha1', 'sha256') -cnotcontains [string]$facts.ObjectFormat -or
        @('detected', 'not-detected') -cnotcontains [string]$facts.SubmoduleStatus -or
        @('detected', 'not-detected') -cnotcontains [string]$facts.LfsStatus) {
      Throw-BorrowingSourceCardFailure candidate candidate-invalid 'Git source-card facts are invalid'
    }
    $lines[46] = New-BorrowingCardRow @(
      $facts.Ref, $facts.RefType, $facts.ObjectFormat, $facts.Commit,
      $facts.Tree, $facts.SubmoduleStatus, $facts.LfsStatus
    )
    $factNames = @('ref', 'ref_type', 'object_format', 'commit', 'tree',
      'submodule_status', 'lfs_status')
    $factValues = @($facts.Ref, $facts.RefType, $facts.ObjectFormat, $facts.Commit,
      $facts.Tree, $facts.SubmoduleStatus, $facts.LfsStatus)
  }
  elseif ($type -eq 'local') {
    $facts = $Candidate.LocalFacts
    $lines[52] = New-BorrowingCardRow @(
      $facts.ManifestAlgorithm, $facts.FileCount, $facts.TotalBytes,
      $facts.Exclusions, $facts.Failures
    )
    $factNames = @('manifest_algorithm', 'file_count', 'total_bytes', 'exclusions', 'failures')
    $factValues = @($facts.ManifestAlgorithm, $facts.FileCount, $facts.TotalBytes,
      $facts.Exclusions, $facts.Failures)
  }
  else {
    $facts = $Candidate.WebFacts
    $lines[58] = New-BorrowingCardRow @(
      $facts.OriginalUrl, $facts.FinalUrl, $facts.RedirectChain, $facts.StatusCode,
      $facts.Mime, $facts.Charset, $facts.Etag, $facts.LastModified, $facts.ResponseHash
    )
    $factNames = @('original_url', 'final_url', 'redirect_chain', 'status_code', 'mime',
      'charset', 'etag', 'last_modified', 'response_hash')
    $factValues = @($facts.OriginalUrl, $facts.FinalUrl, $facts.RedirectChain,
      $facts.StatusCode, $facts.Mime, $facts.Charset, $facts.Etag,
      $facts.LastModified, $facts.ResponseHash)
  }
  Assert-BorrowingSourceCardCredentialSafe $factValues
  $lines[66] = New-BorrowingCardRow @(
    $clock, 'none', 'ready', 'initial-capture', 'capture-executor'
  )
  $bytes = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n") + "`n")
  Assert-BorrowingSourceCardCredentialSafe @([Text.Encoding]::UTF8.GetString($bytes))
  $stableFactParts = @()
  for ($index = 0; $index -lt $factNames.Count; $index++) {
    $factValue = ConvertTo-BorrowingCardCell $factValues[$index]
    $stableFactParts += (ConvertTo-BorrowingCanonicalJsonString $factNames[$index]) +
      ':' + (ConvertTo-BorrowingCanonicalJsonString $factValue)
  }
  $stableIdentity = '{"canonical_locator":' +
    (ConvertTo-BorrowingCanonicalJsonString $locator) + ',"facts":{' +
    ($stableFactParts -join ',') + '},"permissions":{' +
    ($stablePermissionParts -join ',') + '},"authorization_overrides":[' +
    ($stableOverrideParts -join ',') + ']}'
  $stableIdentityBytes = [Text.Encoding]::UTF8.GetBytes($stableIdentity)
  return [pscustomobject][ordered]@{
    Bytes = $bytes
    SourceId = $sourceId
    CaptureId = $captureId
    SourceType = $type
    Fingerprint = $fingerprint
    CapturedAt = $clock
    CanonicalLocator = $locator
    StableIdentity = $stableIdentity
    StableIdentitySha256 = Get-BorrowingSourceCardHash $stableIdentityBytes
  }
}
