[CmdletBinding(PositionalBinding=$false)]
param(
  [string]$Root,
  [string]$SourceType,
  [string]$SourceId,
  [string]$GitLocator,
  [string]$GitRef,
  [string]$LocalPath,
  [string]$LocalDisplayName,
  [string]$WebRawBytesPath,
  [string]$WebResponseMetadataPath,
  [string]$RightsStatus,
  [string]$AccessPolicy,
  [string]$ReuseScope,
  [string]$ExecutionPolicy,
  [string]$NetworkPolicy,
  [string]$StoragePolicy,
  [string]$DistributionPolicy,
  [string]$UpstreamWritePolicy,
  [string]$AutoRefresh,
  [string]$AuthorizationTime,
  [string]$AuthorizationSource,
  [string]$AuthorizationScope
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)

function New-BorrowingFacadeException {
  param([string]$Stage, [string]$ReasonCode)
  $exception = New-Object InvalidOperationException('borrowing capture request failed')
  $exception.Data['BorrowingStage'] = $Stage
  $exception.Data['BorrowingReasonCode'] = $ReasonCode
  return $exception
}

function Write-BorrowingFacadeResult {
  param(
    [string]$Result, [string]$Stage, [string]$SafeSourceId,
    [string]$CaptureId, [string]$Fingerprint,
    [string]$CapturePath, [string]$StagingPath,
    [string]$P4tBefore, [string]$P4tAfter,
    [string]$ReasonCode, [string]$Reason
  )
  @(
    'CZXT_BORROWING_CAPTURE_V1'
    'result=' + $Result
    'stage=' + $Stage
    'source_id=' + $SafeSourceId
    'capture_id=' + $CaptureId
    'fingerprint=' + $Fingerprint
    'capture_path=' + $CapturePath
    'staging_path=' + $StagingPath
    'p4t_before=' + $P4tBefore
    'p4t_after=' + $P4tAfter
    'reason_code=' + $ReasonCode
    'reason=' + $Reason
  ) | ForEach-Object { [Console]::Out.WriteLine($_) }
}

$output = @{
  Result = 'FAIL'; Stage = 'preflight'; SafeSourceId = 'none'
  CaptureId = 'none'; Fingerprint = 'none'; CapturePath = 'none'; StagingPath = 'none'
  P4tBefore = 'not-run'; P4tAfter = 'not-run'; ReasonCode = 'capture-failed'
  Reason = 'capture request failed'
}
$exitCode = 10

try {
  $frameworkScopePath = Join-Path $PSScriptRoot 'check-os\framework-scope.ps1'
  $moduleRoot = Join-Path $PSScriptRoot 'borrowing-capture'
  $commonPath = Join-Path $moduleRoot 'common.ps1'
  foreach ($trustedPath in @($frameworkScopePath, $commonPath)) {
    if (-not (Test-Path -LiteralPath $trustedPath -PathType Leaf)) {
      throw (New-BorrowingFacadeException preflight missing-trusted-component)
    }
  }
  . $frameworkScopePath
  . $commonPath
  if ([string]::IsNullOrEmpty($Root) -or -not [IO.Path]::IsPathRooted($Root)) {
    throw (New-BorrowingFacadeException preflight invalid-root)
  }
  try { $canonicalRoot = [IO.Path]::GetFullPath($Root) }
  catch { throw (New-BorrowingFacadeException preflight invalid-root) }
  if (-not (Test-Path -LiteralPath $canonicalRoot -PathType Container)) {
    throw (New-BorrowingFacadeException preflight invalid-root)
  }
  if ((Get-CzxtRootMode -Root $canonicalRoot) -cne 'project') {
    throw (New-BorrowingFacadeException preflight invalid-mode)
  }
  $requestMap = @{}
  foreach ($key in $PSBoundParameters.Keys) { $requestMap[$key] = $PSBoundParameters[$key] }
  $requestMap['Root'] = $canonicalRoot
  $request = Resolve-BorrowingCaptureRequest -BoundParameters $requestMap
  $output.SafeSourceId = $request.SourceId
  $modules = @(
    'process', 'file-safety', 'git-runner', 'git', 'local', 'web-json', 'web',
    'source-card', 'source-candidate-validator', 'p4t-runner', 'transaction',
    'owned-staging', 'orchestrator'
  )
  foreach ($module in $modules) {
    $modulePath = Join-Path $moduleRoot ($module + '.ps1')
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
      throw (New-BorrowingFacadeException preflight missing-trusted-component)
    }
    . $modulePath
  }
  $result = Invoke-BorrowingCaptureOrchestration $request
  $output.Result = $result.Result
  $output.Stage = $result.Stage
  $output.CaptureId = $result.CaptureId
  $output.Fingerprint = $result.Fingerprint
  $output.CapturePath = $result.CapturePath
  $output.StagingPath = $result.StagingPath
  $output.P4tBefore = $result.P4tBefore
  $output.P4tAfter = $result.P4tAfter
  $output.ReasonCode = $result.ReasonCode
  $output.Reason = $result.Reason
  if ($result.Result -in @('READY', 'REUSED')) { $exitCode = 0 }
}
catch {
  $stage = [string]$_.Exception.Data['BorrowingStage']
  $reasonCode = [string]$_.Exception.Data['BorrowingReasonCode']
  if ([string]::IsNullOrEmpty($stage)) { $stage = 'capture' }
  if ([string]::IsNullOrEmpty($reasonCode)) { $reasonCode = 'capture-failed' }
  $output.Stage = $stage
  $output.ReasonCode = $reasonCode
  $output.Reason = $stage + '/' + $reasonCode
  foreach ($entry in @(
      @('SafeSourceId', 'BorrowingSourceId'),
      @('CaptureId', 'BorrowingCaptureId'),
      @('Fingerprint', 'BorrowingFingerprint'),
      @('StagingPath', 'BorrowingStagingPath')
    )) {
    $value = [string]$_.Exception.Data[$entry[1]]
    if (-not [string]::IsNullOrEmpty($value)) { $output[$entry[0]] = $value }
  }
}

Write-BorrowingFacadeResult @output
exit $exitCode
