$ErrorActionPreference = 'Stop'

$closeStagingPath = Join-Path $PSScriptRoot 'borrowing-close-staging.ps1'
if (-not (Test-Path -LiteralPath $closeStagingPath -PathType Leaf)) {
  throw 'close requires the staging lifecycle helper'
}
. $closeStagingPath

function New-BctResult {
  param(
    [int]$ExitCode, [string]$Result, [string]$Stage,
    [string]$BorrowId, [string]$CardPath, [string]$StagingPath,
    [string]$P4t, [string]$ReasonCode
  )
  return [pscustomobject][ordered]@{
    ExitCode = $ExitCode; Result = $Result; Stage = $Stage
    BorrowId = $BorrowId; CardPath = $CardPath; StagingPath = $StagingPath
    P4t = $P4t; ReasonCode = $ReasonCode
  }
}

function Install-BctFormalBytes {
  param([string]$FormalPath, [byte[]]$Bytes, $ExpectedSnapshot)
  Assert-BciCondition ($null -ne $ExpectedSnapshot) 'formal item card is missing its pre-replacement snapshot'
  $current = Get-BsiStableSnapshot $FormalPath
  Assert-BsiSnapshotUnchanged $ExpectedSnapshot $current
  $temporary = New-BsiTemporaryFile (Split-Path -Parent $FormalPath) $Bytes
  try {
    $installed = Invoke-BsiConditionalReplace $temporary $FormalPath $current $Bytes
    $temporary = $null
  }
  finally { Remove-BsiOwnedTemporaryFile $temporary }
  Assert-BciCondition (Test-BcvBytesEqual $installed.Bytes $Bytes) `
    'formal item card bytes do not match after atomic replacement'
  return $installed
}

function Open-BctFormalReadLock {
  param([string]$FormalPath, $ExpectedSnapshot)
  Assert-BciCondition ($null -ne $ExpectedSnapshot) 'formal item card is missing its final stable snapshot'
  Assert-BciCondition (Test-BsiSamePath $FormalPath $ExpectedSnapshot.Path) `
    'formal item card final canonical path changed'
  Invoke-BctStagingTestInjection 'before-final-formal-handle-open' `
    ([pscustomobject]@{
        FormalPath = $ExpectedSnapshot.Path
        ExpectedSnapshot = $ExpectedSnapshot
      })
  # After a single OPEN_REPARSE_POINT open, verify the canonical path, type,
  # link count, identity, length, and bytes on the same handle; retain the exclusive lease until staging cleanup finishes.
  $lock = Open-BsiOwnedFileLock $ExpectedSnapshot 'formal item card final lock '
  return $lock.Stream
}

function Restore-BctOriginal {
  param(
    [string]$FormalPath, [byte[]]$OriginalBytes,
    $ExpectedFormalSnapshot, $Staging
  )
  Assert-BciCondition ($null -ne $ExpectedFormalSnapshot) `
    'rollback is missing the formal card snapshot for this transaction'
  Assert-BciCondition ($null -ne $Staging -and $null -ne $Staging.Candidate -and
      $null -ne $Staging.Candidate.Bytes) 'rollback is missing the current staging candidate snapshot'
  [byte[]]$stagingCandidateBytes = $Staging.Candidate.Bytes
  Restore-BctStagingFiles $Staging $OriginalBytes $stagingCandidateBytes
  $current = Get-BsiStableSnapshot $FormalPath
  Assert-BsiSnapshotUnchanged $ExpectedFormalSnapshot $current
  [void](Install-BctFormalBytes $FormalPath $OriginalBytes $current)
  $restored = Get-BsiStableSnapshot $FormalPath
  Assert-BciCondition (Test-BcvBytesEqual $restored.Bytes $OriginalBytes) `
    'original active card bytes do not match after restoration'
  Assert-BctOwnedFileLease $Staging.Original
  Assert-BciCondition (Test-BcvBytesEqual `
      $Staging.Original.Bytes $OriginalBytes) 'rollback original active card guard bytes changed'
  Assert-BsiSnapshotUnchanged $Staging.Candidate `
    (Get-BsiStableSnapshot $Staging.Candidate.Path)
}

function Invoke-BctSealProcess {
  param([string]$SafeRoot, [string]$FormalPath)
  $scriptPath = Join-Path $SafeRoot '能力资产\tools\scripts\seal-borrowing-item.ps1'
  $scriptInfo = Get-BorrowingSafePathInfo $scriptPath File close missing-trusted-component
  Assert-BciCondition ((Get-BorrowingPathRelation $SafeRoot $scriptInfo.CanonicalPath) -ceq `
      'ancestor') 'seal helper escapes the project root'
  $executableInfo = Get-BorrowingSafePathInfo (Join-Path $PSHOME 'powershell.exe') `
    File close missing-trusted-component $true $true
  $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
    -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') -Overrides @{}
  return Invoke-BorrowingBoundedProcess -Executable $executableInfo.CanonicalPath `
    -ArgumentList @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy',
      'Bypass', '-File', $scriptInfo.CanonicalPath, '-Root', $SafeRoot,
      '-CardPath', $FormalPath) -WorkingDirectory $SafeRoot `
    -EnvironmentVariables $environment -TimeoutMilliseconds 120000 `
    -StdOutLimitBytes 1048576 -StdErrLimitBytes 1048576 `
    -Stage seal -TimeoutReasonCode seal-failed -FailureReasonCode seal-failed
}

function Invoke-BorrowingCloseTransaction {
  param(
    [string]$Root, [string]$CardPath, [string]$ClosedAt,
    [string]$Reason, [string]$Confirmation
  )
  $stage = 'preflight'
  $reasonCode = 'preflight-failed'
  $borrowId = 'none'
  $formalPath = 'none'
  $staging = $null
  $formalInstalled = $false
  $candidate = $null
  $p4t = 'not-run'
  $originalBytes = $null
  $ownedFormalSnapshot = $null
  $formalOwnershipUnproven = $false
  $formalLock = $null
  $stagingAttempt = [pscustomobject]@{ Value = 'none(not-created)' }
  $completeReached = $false
  try {
    $mode = Invoke-BorrowingP4tModeCheck -Root $Root
    Assert-BciCondition ($mode.ExitCode -eq 0 -and $mode.Mode -ceq 'project') `
      'close permits only a project-only Root'
    $safeRoot = Resolve-BorrowingP4tSafeRoot $Root
    $formal = Get-BciFormalTarget $safeRoot $CardPath
    $borrowId = $formal.Card.BorrowId
    $formalPath = $formal.Path
    $sourceState = Invoke-BorrowingP4tSourceCheck -Root $safeRoot -Mode project
    Assert-BciCondition ($sourceState.ExitCode -eq 0) 'close source checks failed'
    $active = Invoke-BpiSingleItemValidation -Root $safeRoot `
      -CardPath $formal.Path -SourceState $sourceState
    Assert-BciCondition $active.IsValid 'original active item card contract is invalid'
    Assert-BciCondition ($active.Card.Status -cne 'closed') 'item card is already closed'
    $itemRoot = Get-BorrowingSafePathInfo (Split-Path -Parent $formal.Path) `
      Directory close source-unsafe
    Assert-BciCondition ((Get-BorrowingPathRelation `
        $itemRoot.CanonicalPath $formal.Path) -ceq 'ancestor') `
      'formal item card is not a direct child of the trusted item directory'
    $baseline = Get-BsiStableSnapshot $formal.Path
    Assert-BciCondition (Test-BcvBytesEqual $active.Card.Bytes $baseline.Bytes) `
      'original active item card changed after validation'
    $originalBytes = $baseline.Bytes

    $stage = 'candidate'
    $reasonCode = 'candidate-invalid'
    $candidate = New-BciClosedCandidate $active.Card $ClosedAt $Reason $Confirmation
    $staging = New-BctStaging $itemRoot `
      $originalBytes $candidate.Bytes -AttemptedPath $stagingAttempt
    $context = New-BpiValidationContext $safeRoot $sourceState
    Assert-BciCondition ($context.Failures.Count -eq 0) 'closure candidate context is invalid'
    [void](Assert-BciClosedCandidate $staging.Candidate.Path $formal.Path `
      $context $candidate.Bytes)

    $stage = 'install-candidate'
    $ownedFormalSnapshot = Install-BctFormalBytes $formal.Path $candidate.Bytes $baseline
    $formalInstalled = $true

    $stage = 'seal'
    $reasonCode = 'seal-failed'
    $sealResult = Invoke-BctSealProcess $safeRoot $formal.Path
    Assert-BciCondition ($sealResult.ExitCode -eq 0) 'seal helper failed'
    try { $sealed = Get-BsiStableSnapshot $formal.Path }
    catch {
      $formalOwnershipUnproven = $true
      $reasonCode = 'seal-ownership-unproven'
      throw
    }
    try { $attestation = ConvertFrom-BsiSealAttestation $sealResult.StdOut }
    catch {
      $formalOwnershipUnproven = $true
      $reasonCode = 'seal-ownership-unproven'
      throw
    }
    if ($attestation.IdentityKey -cne $sealed.IdentityKey -or
        [uint64]$attestation.Length -ne [uint64]$sealed.Length -or
        $attestation.Sha256 -cne (Get-BorrowingSha256Hex -Bytes $sealed.Bytes)) {
      $formalOwnershipUnproven = $true
      $reasonCode = 'seal-ownership-unproven'
      throw 'seal helper attestation is not bound to the current formal card'
    }
    $ownedFormalSnapshot = $sealed
    Set-BctCandidateBytes $staging $sealed.Bytes
    Assert-BciCondition ($attestation.BorrowId -ceq $borrowId) `
      'seal helper attestation borrow_id does not match'
    Assert-BciCondition (Test-BcvBytesEqual $sealed.Bytes $candidate.SealedBytes) `
      'seal helper result does not match the closure candidate'

    $stage = 'p4t-after'
    $reasonCode = 'p4t-failed'
    $p4tResult = Invoke-BorrowingP4tGate -Root $safeRoot -Stage p4t-after
    $p4t = [string]$p4tResult.ExitCode
    Assert-BciCondition ($p4tResult.ExitCode -eq 0) 'full-root P4t checks failed'

    $stage = 'stability-after-p4t'
    $reasonCode = 'concurrent-change'
    if ($script:BctTestInjections -is [Collections.IDictionary] -and
        $script:BctTestInjections.Contains('before-final-formal-lock')) {
      & $script:BctTestInjections['before-final-formal-lock'] `
        ([pscustomobject]@{ FormalPath = $formalPath; ExpectedSnapshot = $sealed })
    }
    $formalLock = Open-BctFormalReadLock $formalPath $sealed

    $stage = 'cleanup'
    $reasonCode = 'cleanup-failed'
    Remove-BctStaging $staging
    $completeReached = $staging.State -cin @('content-deleted', 'removed')
    $formalLock.Dispose()
    $formalLock = $null
    $staging = $null
    return New-BctResult 0 CLOSED complete $borrowId $formalPath `
      'none(cleaned)' $p4t none
  }
  catch {
    if ($null -ne $staging -and
        $staging.State -cin @('content-deleted', 'removed')) {
      # 2026-07-21 by Codex — Once all staging evidence is deleted, the transaction is irreversibly complete; never roll back the formal card.
      $completeReached = $true
    }
    if ($null -ne $formalLock) {
      try { $formalLock.Dispose() }
      catch { }
      $formalLock = $null
    }
    if (-not $completeReached -and $formalInstalled -and
        -not $formalOwnershipUnproven -and
        $null -ne $candidate -and $null -ne $staging) {
      try {
        Restore-BctOriginal $formalPath $originalBytes `
          $ownedFormalSnapshot $staging
      }
      catch {
        $stage = 'rollback'
        $reasonCode = 'rollback-failed'
      }
    }
    if ($null -ne $staging -and $null -ne $staging.Directory) {
      Close-BctStagingLeases $staging
    }
    $stagingPath = if ($null -ne $staging -and
        (Test-Path -LiteralPath $staging.Path -PathType Container)) {
      $staging.Path
    }
    elseif ($null -ne $staging -and $staging.State -ceq 'removed') {
      'none(cleaned)'
    }
    elseif ($stagingAttempt.Value -cne 'none(not-created)') { $stagingAttempt.Value }
    else { 'none(not-created)' }
    return New-BctResult 10 FAIL $stage $borrowId $formalPath `
      $stagingPath $p4t $reasonCode
  }
}
