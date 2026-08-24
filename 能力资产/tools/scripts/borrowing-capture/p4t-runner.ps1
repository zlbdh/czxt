$ErrorActionPreference = 'Stop'

$p4tRunnerModuleRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command New-BorrowingP4tComponentSeal -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $p4tRunnerModuleRoot 'p4t-component-seal.ps1')
}

function global:Throw-BorrowingP4tFailure {
  param([string]$Stage, [string]$ReasonCode, [string]$Message)
  $exception = New-Object InvalidOperationException($Message)
  $exception.Data['BorrowingStage'] = $Stage
  $exception.Data['BorrowingReasonCode'] = $ReasonCode
  throw $exception
}

function global:New-BorrowingP4tProcessSpec {
  param([string]$Root)
  try {
    $rootInfo = Get-BorrowingSafePathInfo $Root Directory preflight invalid-root
    $scriptPath = Join-Path $rootInfo.CanonicalPath `
      '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1'
    $scriptInfo = Get-BorrowingSafePathInfo $scriptPath File preflight missing-trusted-component
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Throw-BorrowingP4tFailure preflight missing-trusted-component `
      'the fixed P4t component is unavailable'
  }
  if ((Get-BorrowingPathRelation $rootInfo.CanonicalPath $scriptInfo.CanonicalPath) -cne `
      'ancestor') {
    Throw-BorrowingP4tFailure preflight missing-trusted-component `
      'the fixed P4t component crosses the project boundary'
  }
  $executablePath = [IO.Path]::GetFullPath((Join-Path $PSHOME 'powershell.exe'))
  try {
    $executableInfo = Get-BorrowingSafePathInfo $executablePath File `
      preflight missing-trusted-component $true $true
    $executable = $executableInfo.CanonicalPath
  }
  catch {
    if ($_.Exception.Data['BorrowingStage']) { throw }
    Throw-BorrowingP4tFailure preflight missing-trusted-component `
      'Windows PowerShell is unavailable'
  }
  $arguments = @(
    '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
    '-File', $scriptInfo.CanonicalPath, '-Root', $rootInfo.CanonicalPath
  )
  $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
    -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') -Overrides @{}
  $componentSeal = New-BorrowingP4tComponentSeal -Root $rootInfo.CanonicalPath
  return [pscustomobject]@{
    Schema = 'czxt-borrowing-p4t-process/v1'
    Root = $rootInfo.CanonicalPath
    ScriptPath = $scriptInfo.CanonicalPath
    ExecutablePath = $executable
    Arguments = $arguments
    EnvironmentVariables = $environment
    TimeoutMilliseconds = 120000
    StdOutLimitBytes = 1048576
    StdErrLimitBytes = 1048576
    ComponentSeal = $componentSeal
  }
}

function global:Invoke-BorrowingP4tGateCore {
  param($Spec, [string]$Stage)
  if ($Stage -notin @('p4t-before', 'p4t-after')) {
    Throw-BorrowingP4tFailure preflight invalid-parameters 'invalid P4t stage'
  }
  $completed = $false
  try {
    Assert-BorrowingP4tComponentSeal $Spec.ComponentSeal $Stage
    try {
      $result = Invoke-BorrowingBoundedProcess `
        -Executable $Spec.ExecutablePath -ArgumentList $Spec.Arguments `
        -WorkingDirectory $Spec.Root -EnvironmentVariables $Spec.EnvironmentVariables `
        -TimeoutMilliseconds $Spec.TimeoutMilliseconds `
        -StdOutLimitBytes $Spec.StdOutLimitBytes -StdErrLimitBytes $Spec.StdErrLimitBytes `
        -Stage $Stage -TimeoutReasonCode p4t-process-failed `
        -FailureReasonCode p4t-process-failed
    }
    catch {
      if ($_.Exception.Data['BorrowingStage']) {
        $projection = [string]$_.Exception.Data['BorrowingProcessProjection']
        if ($projection -notin @('start-failed', 'timeout')) {
          $projection = 'start-failed'
        }
        $_.Exception.Data['BorrowingP4tProjection'] = $projection
        throw
      }
      Throw-BorrowingP4tFailure $Stage p4t-process-failed 'P4t process failed'
    }
    Invoke-BorrowingP4tSealTestInjection `
      'after-process-exit-before-verify' $Spec.ComponentSeal
    Assert-BorrowingP4tComponentSeal $Spec.ComponentSeal $Stage
    $completed = $true
    return [pscustomobject]@{
      Schema = 'czxt-borrowing-p4t-result/v1'
      Outcome = 'exited'
      ExitCode = [int]$result.ExitCode
      Projection = ([string]$result.ExitCode)
    }
  }
  finally {
    if (-not $completed -or $Stage -ceq 'p4t-after') {
      Close-BorrowingP4tComponentSeal $Spec.ComponentSeal
    }
  }
}

function global:Invoke-BorrowingP4tGate {
  param([string]$Root, [string]$Stage)
  $spec = $null
  try {
    $spec = New-BorrowingP4tProcessSpec -Root $Root
    return Invoke-BorrowingP4tGateCore -Spec $spec -Stage $Stage
  }
  finally {
    if ($null -ne $spec) {
      Close-BorrowingP4tComponentSeal $spec.ComponentSeal
    }
  }
}
