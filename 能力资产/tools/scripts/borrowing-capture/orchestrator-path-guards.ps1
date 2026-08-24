$ErrorActionPreference = 'Stop'

function global:Assert-BorrowingContextPathIdentity {
  param($Context, [string]$Stage, [string]$ReasonCode)
  if ($null -eq $Context.Ownership -or
      $null -eq $Context.Ownership.SourceLease.Native -or
      $null -eq $Context.Ownership.StagingLease.Native) {
    Throw-BorrowingFailure $Stage $ReasonCode `
      'transaction owned leases are missing'
  }
  try {
    $Context.Ownership.SourceLease.Native.Verify()
    $Context.Ownership.StagingLease.Native.Verify()
  }
  catch {
    Throw-BorrowingFailure $Stage $ReasonCode `
      'transaction owned lease changed'
  }
  $source = Get-BorrowingSafePathInfo $Context.SourcePath Directory $Stage $ReasonCode
  $staging = Get-BorrowingSafePathInfo $Context.StagingPath Directory $Stage $ReasonCode
  if ($source.IdentityKey -cne $Context.SourceIdentityKey -or
      $staging.IdentityKey -cne $Context.StagingIdentityKey -or
      -not (Test-BorrowingOwnedSamePath `
        $Context.Ownership.SourceLease.Path $source.CanonicalPath) -or
      -not (Test-BorrowingOwnedSamePath `
        $Context.Ownership.StagingLease.Path $staging.CanonicalPath) -or
      (Get-BorrowingPathRelation $source.CanonicalPath $staging.CanonicalPath) -cne `
        'ancestor') {
    Throw-BorrowingFailure $Stage $ReasonCode 'transaction path identity changed'
  }
  return [pscustomobject]@{ Source = $source; Staging = $staging }
}

function global:Assert-BorrowingContextStagedCandidate {
  param($Context, [string]$Stage, [string]$ReasonCode)
  [void](Assert-BorrowingContextPathIdentity $Context $Stage $ReasonCode)
  try {
    $validated = Get-BorrowingValidatedSourceCandidate `
      -CaptureDirectory $Context.StagingPath
    $envelope = [pscustomobject]@{
      Artifact = $Context.Artifact; Candidate = $Context.Candidate
      LocalStateBytes = $Context.LocalStateBytes
    }
    $staging = [pscustomobject]@{
      SourcePath = $Context.SourcePath; StagingPath = $Context.StagingPath
    }
    Assert-BorrowingStagedEnvelope $Context.Prepared $envelope $staging $validated
    if ($validated.SourceType -cne $Context.SourceType -or
        $validated.CaptureId -cne $Context.Artifact.CaptureId -or
        $validated.Fingerprint -cne $Context.Candidate.Fingerprint -or
        $validated.StableIdentitySha256 -cne $Context.Artifact.StableIdentitySha256) {
      throw 'candidate identity changed'
    }
  }
  catch { Throw-BorrowingFailure $Stage $ReasonCode 'transaction candidate changed' }
}

function global:Assert-BorrowingRepairCleanupStaging {
  param($Context)
  [void](Assert-BorrowingContextPathIdentity $Context cleanup cleanup-failed)
  try { $members = @(Get-ChildItem -LiteralPath $Context.StagingPath -Force) }
  catch { Throw-BorrowingFailure cleanup cleanup-failed 'repair staging is unreadable' }
  if ($members.Count -ne 1 -or $members[0].Name -cne '来源版本卡.md' -or
      $members[0].PSIsContainer) {
    Throw-BorrowingFailure cleanup cleanup-failed 'repair staging contains unknown members'
  }
  [byte[]]$cardBytes = Get-BorrowingOwnedFileBytes $Context.Ownership `
    $members[0].FullName cleanup cleanup-failed
  if (-not (Test-BorrowingExactBytes $cardBytes $Context.Artifact.Bytes)) {
    Throw-BorrowingFailure cleanup cleanup-failed 'repair staging card changed'
  }
}

function global:Assert-BorrowingExistingCandidateState {
  param($Context, [string]$ExpectedCacheState)
  if ($null -eq $Context.ExistingCandidate -or
      $null -eq $Context.ExistingLease -or
      $null -eq $Context.ExistingLease.Native -or
      [string]::IsNullOrEmpty([string]$Context.ExistingIdentityKey) -or
      $Context.ExistingIdentityKey -ceq 'none') {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture baseline is missing'
  }
  try { $Context.ExistingLease.Native.Verify() }
  catch {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture lease changed'
  }
  $directory = Get-BorrowingSafePathInfo $Context.CapturePath Directory `
    idempotency idempotency-conflict
  if ($directory.IdentityKey -cne $Context.ExistingIdentityKey) {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture identity changed'
  }
  if (-not (Test-BorrowingOwnedSamePath `
      $Context.ExistingLease.Path $directory.CanonicalPath)) {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture lease path changed'
  }
  try {
    $validated = Get-BorrowingValidatedSourceCandidate `
      -CaptureDirectory $directory.CanonicalPath
  }
  catch {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture is no longer valid'
  }
  $baseline = $Context.ExistingCandidate
  if ($validated.CaptureStatus -cne 'ready' -or
      $validated.SourceId -cne $baseline.SourceId -or
      $validated.SourceType -cne $baseline.SourceType -or
      $validated.CaptureId -cne $baseline.CaptureId -or
      $validated.FingerprintAlgorithm -cne $baseline.FingerprintAlgorithm -or
      $validated.Fingerprint -cne $baseline.Fingerprint -or
      $validated.StableIdentitySha256 -cne $baseline.StableIdentitySha256) {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing capture facts changed'
  }
  $cache = Get-BorrowingIgnoredCacheState -CaptureDirectory $directory.CanonicalPath `
    -SourceType $validated.SourceType
  if ($cache.State -cne $ExpectedCacheState) {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing cache state changed'
  }
  if ($ExpectedCacheState -ceq 'Healthy' -and
      -not (Test-BorrowingValidatedFingerprint $validated)) {
    Throw-BorrowingFailure idempotency idempotency-conflict `
      'existing cache fingerprint changed'
  }
  return $validated
}

function global:Assert-BorrowingRollbackPathIdentities {
  param($Context)
  $source = Get-BorrowingSafePathInfo $Context.SourcePath Directory rollback rollback-failed
  if ($source.IdentityKey -cne $Context.SourceIdentityKey) {
    Throw-BorrowingFailure rollback rollback-failed 'rollback source identity changed'
  }
  try { $Context.Ownership.SourceLease.Native.Verify() }
  catch { Throw-BorrowingFailure rollback rollback-failed 'rollback source lease changed' }
  if ($Context.Disposition -ceq 'New') {
    if (Test-Path -LiteralPath $Context.StagingPath) {
      Throw-BorrowingFailure rollback rollback-failed 'rollback staging already exists'
    }
    $capture = Get-BorrowingSafePathInfo $Context.CapturePath Directory `
      rollback rollback-failed
    if ($capture.IdentityKey -cne $Context.StagingIdentityKey -or
        $null -eq $Context.Ownership.StagingLease.Native -or
        -not (Test-BorrowingOwnedSamePath `
          $Context.Ownership.StagingLease.Path $capture.CanonicalPath) -or
        (Get-BorrowingPathRelation $source.CanonicalPath $capture.CanonicalPath) -cne `
          'ancestor') {
      Throw-BorrowingFailure rollback rollback-failed 'promoted identity changed'
    }
    return
  }
  if ($Context.Disposition -ceq 'RepairMissingCache') {
    $staging = Get-BorrowingSafePathInfo $Context.StagingPath Directory `
      rollback rollback-failed
    $capture = Get-BorrowingSafePathInfo $Context.CapturePath Directory `
      rollback rollback-failed
    if ($staging.IdentityKey -cne $Context.StagingIdentityKey -or
        $capture.IdentityKey -cne $Context.ExistingIdentityKey) {
      Throw-BorrowingFailure rollback rollback-failed 'repair rollback identity changed'
    }
    try {
      $Context.Ownership.StagingLease.Native.Verify()
      $Context.ExistingLease.Native.Verify()
    }
    catch {
      Throw-BorrowingFailure rollback rollback-failed `
        'repair rollback lease changed'
    }
  }
}

function global:Assert-BorrowingPromotedPathIdentity {
  param($Context)
  $source = Get-BorrowingSafePathInfo $Context.SourcePath Directory promotion source-unsafe
  $capture = Get-BorrowingSafePathInfo $Context.CapturePath Directory promotion source-unsafe
  $expectedIdentity = if ($Context.Disposition -ceq 'New') {
    $Context.StagingIdentityKey
  } else { $Context.ExistingIdentityKey }
  if ($source.IdentityKey -cne $Context.SourceIdentityKey -or
      $capture.IdentityKey -cne $expectedIdentity -or
      (Get-BorrowingPathRelation $source.CanonicalPath $capture.CanonicalPath) -cne `
        'ancestor') {
    Throw-BorrowingFailure promotion source-unsafe 'promoted path identity changed'
  }
  try {
    $Context.Ownership.SourceLease.Native.Verify()
    if ($Context.Disposition -ceq 'New') {
      $Context.Ownership.StagingLease.Native.Verify()
      if (-not (Test-BorrowingOwnedSamePath `
          $Context.Ownership.StagingLease.Path $capture.CanonicalPath)) {
        throw 'new capture lease path changed'
      }
    }
    else {
      $Context.ExistingLease.Native.Verify()
      if (-not (Test-BorrowingOwnedSamePath `
          $Context.ExistingLease.Path $capture.CanonicalPath)) {
        throw 'existing capture lease path changed'
      }
    }
  }
  catch {
    Throw-BorrowingFailure promotion source-unsafe `
      'promoted capture lease changed'
  }
  if ($Context.Disposition -ceq 'RepairMissingCache') {
    $staging = Get-BorrowingSafePathInfo $Context.StagingPath Directory promotion source-unsafe
    if ($staging.IdentityKey -cne $Context.StagingIdentityKey) {
      Throw-BorrowingFailure promotion source-unsafe 'repair staging identity changed'
    }
  }
}
