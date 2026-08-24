$ErrorActionPreference = 'Stop'

function global:Test-BorrowingValidatedFingerprint {
  param($Validated)
  $result = Test-BorrowingStoredCaptureFingerprint -Candidate $Validated
  if (-not $result.Applicable) { return $true }
  return [bool]$result.IsValid
}

function global:Get-BorrowingCaptureDisposition {
  param($Prepared, $Envelope, $Staging)
  $staged = Get-BorrowingValidatedSourceCandidate -CaptureDirectory $Staging.StagingPath
  Assert-BorrowingStagedEnvelope $Prepared $Envelope $Staging $staged
  if ($staged.SourceId -cne $Prepared.Request.SourceId -or
      $staged.SourceType -cne $Prepared.Request.SourceType -or
      $staged.CaptureId -cne $Envelope.Artifact.CaptureId -or
      $staged.Fingerprint -cne $Envelope.Candidate.Fingerprint -or
      $staged.StableIdentitySha256 -cne $Envelope.Artifact.StableIdentitySha256) {
    Throw-BorrowingFailure candidate candidate-invalid 'staged source card does not match candidate'
  }
  $stagedCache = Get-BorrowingIgnoredCacheState -CaptureDirectory $Staging.StagingPath `
    -SourceType $Prepared.Request.SourceType
  if ($stagedCache.State -cne 'Healthy' -or
      -not (Test-BorrowingValidatedFingerprint $staged)) {
    Throw-BorrowingFailure candidate candidate-invalid 'staged source cache is invalid'
  }

  $reuseKeyMatches = New-Object 'Collections.Generic.List[object]'
  $conflict = $false
  foreach ($directory in @(Get-ChildItem -LiteralPath $Staging.SourcePath -Directory -Force)) {
    if ($directory.Name.StartsWith('.staging-', [StringComparison]::Ordinal)) { continue }
    try {
      $existingDirectory = Get-BorrowingSafePathInfo $directory.FullName Directory `
        idempotency idempotency-conflict
      $existing = Get-BorrowingValidatedSourceCandidate -CaptureDirectory $directory.FullName
      $existing | Add-Member -NotePropertyName CaptureIdentityKey `
        -NotePropertyValue $existingDirectory.IdentityKey -Force
      if ($existing.SourceId -ceq $staged.SourceId -and
          $existing.SourceType -ceq $staged.SourceType -and
          $existing.FingerprintAlgorithm -ceq $staged.FingerprintAlgorithm -and
          $existing.Fingerprint -ceq $staged.Fingerprint) {
        [void]$reuseKeyMatches.Add($existing)
      }
    }
    catch { $conflict = $true }
  }
  if ($conflict -or $reuseKeyMatches.Count -gt 1) {
    return [pscustomobject]@{ Disposition = 'Conflict'; Existing = $null }
  }
  if ($reuseKeyMatches.Count -eq 1) {
    $existing = $reuseKeyMatches[0]
    if ($existing.CaptureStatus -cne 'ready' -or
        $existing.StableIdentitySha256 -cne $staged.StableIdentitySha256) {
      return [pscustomobject]@{ Disposition = 'Conflict'; Existing = $existing }
    }
    $cache = Get-BorrowingIgnoredCacheState -CaptureDirectory `
      (Split-Path -Parent $existing.CardPath) -SourceType $existing.SourceType
    if ($cache.State -ceq 'Healthy') {
      if (-not (Test-BorrowingValidatedFingerprint $existing)) {
        return [pscustomobject]@{ Disposition = 'Conflict'; Existing = $existing }
      }
      return [pscustomobject]@{ Disposition = 'HealthyReuse'; Existing = $existing }
    }
    if ($cache.State -ceq 'AllMissing') {
      return [pscustomobject]@{ Disposition = 'RepairMissingCache'; Existing = $existing }
    }
    return [pscustomobject]@{ Disposition = 'Conflict'; Existing = $existing }
  }
  $capturePath = Join-Path $Staging.SourcePath $Envelope.Artifact.CaptureId
  if (Test-Path -LiteralPath $capturePath) {
    return [pscustomobject]@{ Disposition = 'Conflict'; Existing = $null }
  }
  return [pscustomobject]@{ Disposition = 'New'; Existing = $null }
}

function global:Test-BorrowingPostMoveGitCache {
  param($Context)
  $auxiliary = $null
  $runner = $null
  $operationFailure = $null
  try {
    $auxiliary = New-BorrowingOwnedAuxiliaryStaging `
      $Context.Ownership '.staging-git-validation-'
    Initialize-BorrowingOwnedGitRunnerDirectories $auxiliary
    $runner = New-BorrowingGitRunner $Context.Candidate.GitExecutablePath `
      $auxiliary.StagingPath
    $runnerForClosure = $runner
    $runGit = {
      param([string[]]$Arguments, [string]$StdOutMode)
      Invoke-BorrowingGitRunner $runnerForClosure $Arguments $StdOutMode
    }.GetNewClosure()
    Test-BorrowingGitCache `
      -RepositoryPath (Join-Path $Context.CapturePath '快照\repository.git') `
      -ObjectFormat $Context.Candidate.ObjectFormat `
      -AdvertisedOid $Context.Candidate.AdvertisedOid `
      -CommitOid $Context.Candidate.Commit -TreeOid $Context.Candidate.Tree `
      -RunGit $runGit
  }
  catch { $operationFailure = $_ }

  $cleanupFailure = $null
  if ($null -ne $auxiliary) {
    try {
      if (Test-Path -LiteralPath $auxiliary.StagingPath -PathType Container) {
        Remove-BorrowingOwnedAuxiliaryExactTree $auxiliary
      }
    }
    catch { if ($null -eq $cleanupFailure) { $cleanupFailure = $_ } }
    try { Close-BorrowingOwnedStagingLeases $auxiliary }
    catch { if ($null -eq $cleanupFailure) { $cleanupFailure = $_ } }
  }
  if ($null -ne $operationFailure) {
    if ($null -ne $cleanupFailure) {
      $operationFailure.Exception.Data['BorrowingAuxiliaryCleanupFailure'] = `
        $cleanupFailure.Exception.Message
    }
    throw $operationFailure
  }
  if ($null -ne $cleanupFailure) { throw $cleanupFailure }
}

function global:Test-BorrowingPostMoveWebCache {
  param($Context)
  $metadataPath = Join-Path $Context.CapturePath '快照\response.metadata.json'
  [byte[]]$actual = Read-BorrowingStableSafeFileBytes `
    $metadataPath promotion source-unsafe
  if ((Get-BorrowingSha256Hex $actual) -cne
      (Get-BorrowingSha256Hex ([byte[]]$Context.Candidate.CanonicalMetadataBytes))) {
    Throw-BorrowingFailure promotion source-unsafe 'promoted Web metadata differs'
  }
  $metadata = Read-BorrowingStrictWebMetadata -Bytes $actual
  [byte[]]$canonical = ConvertTo-BorrowingCanonicalWebMetadataBytes $metadata
  if ((Get-BorrowingSha256Hex $canonical) -cne (Get-BorrowingSha256Hex $actual)) {
    Throw-BorrowingFailure promotion source-unsafe 'promoted Web metadata is not canonical'
  }
}

$orchestratorTransactionRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $orchestratorTransactionRoot 'orchestrator-operations.ps1')
