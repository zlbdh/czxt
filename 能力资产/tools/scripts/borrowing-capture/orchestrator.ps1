$ErrorActionPreference = 'Stop'

$orchestratorModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $orchestratorModuleRoot 'orchestrator-preparation.ps1')
. (Join-Path $orchestratorModuleRoot 'orchestrator-validation.ps1')
. (Join-Path $orchestratorModuleRoot 'orchestrator-transaction.ps1')

function global:Invoke-BorrowingCaptureOrchestration {
  param($Request)
  $prepared = $null
  $staging = $null
  $candidate = $null
  $envelope = $null
  $existingLease = $null
  $stagingSeal = $null
  $existingSeal = $null
  $context = $null
  try {
    $prepared = Initialize-BorrowingPreparedInput $Request
    $staging = New-BorrowingStagingDirectory $prepared
    $candidateOperations = New-BorrowingOwnedCandidateOperations `
      $prepared.Operations $staging
    $candidate = New-BorrowingTypedCandidate $prepared $staging $candidateOperations
    $envelope = Write-BorrowingCandidateMetadata $prepared $candidate `
      $staging.StagingPath $candidateOperations
    $stagingSeal = New-BorrowingOwnedTreeSeal $staging `
      $staging.StagingPath candidate candidate-invalid
    $decision = Get-BorrowingCaptureDisposition $prepared $envelope $staging
    if ($null -ne $decision.Existing) {
      $capturePath = Split-Path -Parent $decision.Existing.CardPath
      $existingIdentityKey = [string]$decision.Existing.CaptureIdentityKey
      if ([string]::IsNullOrEmpty($existingIdentityKey)) {
        Throw-BorrowingFailure idempotency idempotency-conflict `
          'existing capture baseline identity is missing'
      }
      if ($decision.Disposition -in @('HealthyReuse', 'RepairMissingCache')) {
        $existingLease = Open-BorrowingOwnedExistingCapture `
          $capturePath $existingIdentityKey
        $existingSeal = New-BorrowingOwnedTreeSeal $staging $capturePath `
          idempotency idempotency-conflict $existingLease
      }
    }
    else {
      $capturePath = Join-Path $staging.SourcePath $envelope.Artifact.CaptureId
      $existingIdentityKey = 'none'
    }
    $context = [pscustomobject]@{
      Root = $prepared.Root
      SourceType = $Request.SourceType
      SourcePath = $staging.SourcePath
      StagingPath = $staging.StagingPath
      CapturePath = $capturePath
      SourceIdentityKey = $staging.SourceIdentityKey
      StagingIdentityKey = $staging.StagingIdentityKey
      ExistingIdentityKey = $existingIdentityKey
      Disposition = $decision.Disposition
      Prepared = $prepared
      Candidate = $candidate
      Artifact = $envelope.Artifact
      LocalStateBytes = $envelope.LocalStateBytes
      ExistingCandidate = $decision.Existing
      ExistingLease = $existingLease
      Ownership = $staging
      CandidateOperations = $candidateOperations
      StagingSeal = $stagingSeal
      CaptureSeal = $null
      ExistingSeal = $existingSeal
    }
    $operations = New-BorrowingProductionTransactionOperations $context
    $result = Invoke-BorrowingCaptureTransactionCore $context $operations
    $result | Add-Member -NotePropertyName SourceId `
      -NotePropertyValue $Request.SourceId -Force
    $result | Add-Member -NotePropertyName CaptureId `
      -NotePropertyValue $envelope.Artifact.CaptureId -Force
    $result | Add-Member -NotePropertyName Fingerprint `
      -NotePropertyValue $candidate.Fingerprint -Force
    return $result
  }
  catch {
    if ($null -ne $staging) {
      $_.Exception.Data['BorrowingStagingPath'] = $staging.StagingPath
    }
    if ($null -ne $Request) {
      $_.Exception.Data['BorrowingSourceId'] = $Request.SourceId
    }
    if ($null -ne $candidate) {
      $_.Exception.Data['BorrowingFingerprint'] = $candidate.Fingerprint
    }
    if ($null -ne $envelope) {
      $_.Exception.Data['BorrowingCaptureId'] = $envelope.Artifact.CaptureId
    }
    throw
  }
  finally {
    if ($null -ne $context) {
      try { Close-BorrowingContextTreeSeals $context } catch { }
    }
    else {
      try { Close-BorrowingOwnedTreeSeal $existingSeal } catch { }
      try { Close-BorrowingOwnedTreeSeal $stagingSeal } catch { }
    }
    if ($null -ne $prepared -and $null -ne $prepared.P4tSpec) {
      try { Close-BorrowingP4tComponentSeal $prepared.P4tSpec.ComponentSeal } catch { }
    }
    try { Close-BorrowingOwnedDirectoryState $existingLease } catch { }
    try { Close-BorrowingOwnedStagingLeases $staging } catch { }
  }
}
