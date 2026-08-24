$ErrorActionPreference = 'Stop'

function global:Get-BorrowingTransactionFailureData {
  param($ErrorRecord, [string]$DefaultStage, [string]$DefaultReason)
  $stage = [string]$ErrorRecord.Exception.Data['BorrowingStage']
  $reason = [string]$ErrorRecord.Exception.Data['BorrowingReasonCode']
  if ([string]::IsNullOrEmpty($stage)) { $stage = $DefaultStage }
  if ([string]::IsNullOrEmpty($reason)) { $reason = $DefaultReason }
  return [pscustomobject]@{ Stage = $stage; ReasonCode = $reason }
}

function global:New-BorrowingTransactionResult {
  param(
    [string]$Result, [string]$Stage, [string]$ReasonCode,
    [string]$P4tBefore, [string]$P4tAfter,
    [Collections.Generic.List[string]]$Trace, $Context, $Operations
  )
  $captureExists = Test-Path -LiteralPath $Context.CapturePath -PathType Container
  $stagingExists = Test-Path -LiteralPath $Context.StagingPath -PathType Container
  if ($null -ne $Operations.ProbePathState) {
    try {
      $probeOperation = $Operations.ProbePathState
      $state = & $probeOperation $Context
      $captureExists = [bool]$state.CaptureExists
      $stagingExists = [bool]$state.StagingExists
    }
    catch { }
  }
  return [pscustomobject]@{
    Schema = 'czxt-borrowing-transaction-result/v1'
    Result = $Result
    Stage = $Stage
    ReasonCode = $ReasonCode
    Reason = if ($Result -ceq 'FAIL') { $Stage + '/' + $ReasonCode } else { 'none' }
    P4tBefore = $P4tBefore
    P4tAfter = $P4tAfter
    CapturePath = if ($captureExists) { $Context.CapturePath } else { 'none' }
    StagingPath = if ($stagingExists) { $Context.StagingPath } else { 'none' }
    Trace = @($Trace)
  }
}
