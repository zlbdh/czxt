$ErrorActionPreference = 'Stop'

function global:Get-BorrowingExpectedCacheMembers {
  param([string]$SourceType)
  switch ($SourceType.ToLowerInvariant()) {
    'git' { return @('快照/repository.git/', 'capture.local.json') }
    'local' { return @('快照/内容/', '快照/manifest.tsv', 'capture.local.json') }
    'web' {
      return @('快照/response.bin', '快照/response.metadata.json', 'capture.local.json')
    }
    default { return @() }
  }
}

$transactionModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
. (Join-Path $transactionModuleRoot 'transaction-result.ps1')

function global:Invoke-BorrowingTransactionGate {
  param($Context, $Operations, [string]$Gate)
  $runOperation = $Operations.RunP4t
  $result = & $runOperation $Context $Gate
  if ($null -eq $result -or $result.Outcome -cne 'exited') {
    $exception = New-Object InvalidOperationException('P4t process did not exit normally')
    $exception.Data['BorrowingStage'] = $Gate
    $exception.Data['BorrowingReasonCode'] = 'p4t-process-failed'
    throw $exception
  }
  return $result
}

function global:Invoke-BorrowingTransactionFinalCheck {
  param($Context, $Operations)
  if ($null -eq $Operations.FinalCheck) {
    Throw-BorrowingFailure promotion source-unsafe `
      'final bound transaction check is missing'
  }
  $finalCheck = $Operations.FinalCheck
  & $finalCheck $Context
}

function global:Invoke-BorrowingTransactionRollback {
  param(
    $Context, $Operations, [Collections.Generic.List[string]]$Trace,
    [string]$FailureStage, [string]$FailureReason,
    [string]$P4tBefore, [string]$P4tAfter
  )
  [void]$Trace.Add('rollback')
  try {
    $rollbackOperation = $Operations.Rollback
    & $rollbackOperation $Context
  }
  catch {
    return New-BorrowingTransactionResult FAIL rollback rollback-failed `
      $P4tBefore $P4tAfter $Trace $Context $Operations
  }
  return New-BorrowingTransactionResult FAIL $FailureStage $FailureReason `
    $P4tBefore $P4tAfter $Trace $Context $Operations
}

function global:Invoke-BorrowingCaptureTransactionCore {
  param($Context, $Operations)
  $trace = New-Object 'Collections.Generic.List[string]'
  foreach ($stage in @(
      'preflight', 'input', 'staging-created', 'capture',
      'candidate-validator', 'idempotency'
    )) { [void]$trace.Add($stage) }
  $p4tBefore = 'not-run'
  $p4tAfter = 'not-run'
  if ($null -eq $Context -or $null -eq $Operations) {
    return New-BorrowingTransactionResult FAIL preflight invalid-parameters `
      $p4tBefore $p4tAfter $trace $Context $Operations
  }
  switch ($Context.Disposition) {
    'Conflict' {
      [void]$trace.Add('idempotency-conflict')
      return New-BorrowingTransactionResult FAIL idempotency idempotency-conflict `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    'HealthyReuse' { $branch = 'reuse' }
    'RepairMissingCache' { $branch = 'repair-missing-cache' }
    'New' { $branch = 'new' }
    default {
      [void]$trace.Add('idempotency-conflict')
      return New-BorrowingTransactionResult FAIL idempotency idempotency-conflict `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
  }
  [void]$trace.Add($branch)

  if ($Context.Disposition -in @('HealthyReuse', 'New')) {
    [void]$trace.Add('p4t-before')
    try { $gate = Invoke-BorrowingTransactionGate $Context $Operations p4t-before }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ p4t-before p4t-process-failed
      $projection = [string]$_.Exception.Data['BorrowingP4tProjection']
      if ($projection -in @('start-failed', 'timeout')) { $p4tBefore = $projection }
      return New-BorrowingTransactionResult FAIL $failure.Stage $failure.ReasonCode `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    $p4tBefore = $gate.Projection
    if ($gate.ExitCode -ne 0) {
      return New-BorrowingTransactionResult FAIL p4t-before p4t-not-zero `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
  }

  if ($Context.Disposition -eq 'HealthyReuse') {
    [void]$trace.Add('final-check')
    try { Invoke-BorrowingTransactionFinalCheck $Context $Operations }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ promotion source-unsafe
      return New-BorrowingTransactionResult FAIL $failure.Stage $failure.ReasonCode `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    [void]$trace.Add('cleanup')
    try {
      $cleanupOperation = $Operations.Cleanup
      & $cleanupOperation $Context
    }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ cleanup cleanup-failed
      return New-BorrowingTransactionResult FAIL $failure.Stage $failure.ReasonCode `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    [void]$trace.Add('final-check-after-cleanup')
    try { Invoke-BorrowingTransactionFinalCheck $Context $Operations }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ promotion source-unsafe
      return New-BorrowingTransactionResult FAIL $failure.Stage $failure.ReasonCode `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    [void]$trace.Add('complete')
    return New-BorrowingTransactionResult REUSED complete none `
      $p4tBefore $p4tAfter $trace $Context $Operations
  }

  if ($Context.Disposition -eq 'RepairMissingCache') {
    [void]$trace.Add('install-missing-cache')
    try {
      $installOperation = $Operations.InstallMissingCache
      & $installOperation $Context
    }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ promotion promotion-failed
      return Invoke-BorrowingTransactionRollback $Context $Operations $trace `
        $failure.Stage $failure.ReasonCode $p4tBefore $p4tAfter
    }
  }
  else {
    [void]$trace.Add('atomic-move')
    try {
      $moveOperation = $Operations.AtomicMove
      & $moveOperation $Context
    }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ promotion promotion-failed
      $stateOperation = $Operations.ProbePathState
      $state = & $stateOperation $Context
      if ($state.CaptureExists -and -not $state.StagingExists) {
        return Invoke-BorrowingTransactionRollback $Context $Operations $trace `
          $failure.Stage $failure.ReasonCode $p4tBefore $p4tAfter
      }
      return New-BorrowingTransactionResult FAIL $failure.Stage $failure.ReasonCode `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
  }

  [void]$trace.Add('post-link-check')
  try {
    $postLinkOperation = $Operations.PostLinkCheck
    & $postLinkOperation $Context
  }
  catch {
    $failure = Get-BorrowingTransactionFailureData $_ promotion source-unsafe
    return Invoke-BorrowingTransactionRollback $Context $Operations $trace `
      $failure.Stage $failure.ReasonCode $p4tBefore $p4tAfter
  }

  [void]$trace.Add('p4t-after')
  try { $gate = Invoke-BorrowingTransactionGate $Context $Operations p4t-after }
  catch {
    $failure = Get-BorrowingTransactionFailureData $_ p4t-after p4t-process-failed
    $projection = [string]$_.Exception.Data['BorrowingP4tProjection']
    if ($projection -in @('start-failed', 'timeout')) { $p4tAfter = $projection }
    return Invoke-BorrowingTransactionRollback $Context $Operations $trace `
      $failure.Stage $failure.ReasonCode $p4tBefore $p4tAfter
  }
  $p4tAfter = $gate.Projection
  if ($gate.ExitCode -ne 0) {
    return Invoke-BorrowingTransactionRollback $Context $Operations $trace `
      p4t-after p4t-not-zero $p4tBefore $p4tAfter
  }

  [void]$trace.Add('final-check')
  try { Invoke-BorrowingTransactionFinalCheck $Context $Operations }
  catch {
    $failure = Get-BorrowingTransactionFailureData $_ promotion source-unsafe
    return Invoke-BorrowingTransactionRollback $Context $Operations $trace `
      $failure.Stage $failure.ReasonCode $p4tBefore $p4tAfter
  }

  if ($Context.Disposition -eq 'RepairMissingCache') {
    [void]$trace.Add('cleanup')
    try {
      $cleanupOperation = $Operations.Cleanup
      & $cleanupOperation $Context
    }
    catch {
      return New-BorrowingTransactionResult FAIL cleanup cleanup-failed `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    [void]$trace.Add('final-check-after-cleanup')
    try { Invoke-BorrowingTransactionFinalCheck $Context $Operations }
    catch {
      $failure = Get-BorrowingTransactionFailureData $_ promotion source-unsafe
      return New-BorrowingTransactionResult FAIL $failure.Stage $failure.ReasonCode `
        $p4tBefore $p4tAfter $trace $Context $Operations
    }
    [void]$trace.Add('complete')
    return New-BorrowingTransactionResult REUSED complete none `
      $p4tBefore $p4tAfter $trace $Context $Operations
  }
  [void]$trace.Add('complete')
  return New-BorrowingTransactionResult READY complete none `
    $p4tBefore $p4tAfter $trace $Context $Operations
}
