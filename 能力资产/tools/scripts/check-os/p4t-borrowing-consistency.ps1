[CmdletBinding()]
param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)

function Add-BorrowingP4tFacadeMessages {
  param($Target, $Values)
  foreach ($value in @($Values)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
      [void]$Target.Add([string]$value)
    }
  }
}

function Write-BorrowingP4tFacadeResult {
  param($Result)
  $status = if ($Result.ExitCode -eq 0) { 'PASS' }
    elseif ($Result.ExitCode -eq 5) { 'WARN' }
    else { 'FAIL' }
  @(
    'CZXT_P4T_BORROWING_V1'
    ('result=' + $status)
    ('mode=' + $Result.Mode)
    ('warnings=' + @($Result.Warnings).Count)
    ('failures=' + @($Result.Failures).Count)
  ) | ForEach-Object { [Console]::Out.WriteLine($_) }
  foreach ($warning in @($Result.Warnings)) {
    [Console]::Out.WriteLine('warning=' + [string]$warning)
  }
  foreach ($failure in @($Result.Failures)) {
    [Console]::Out.WriteLine('failure=' + [string]$failure)
  }
}

$warnings = New-Object 'Collections.Generic.List[string]'
$failures = New-Object 'Collections.Generic.List[string]'
$mode = 'unknown'
$exitCode = 10
try {
  $moduleRoot = Join-Path $PSScriptRoot 'p4t'
  foreach ($module in @(
      'borrowing-mode.ps1', 'borrowing-source-cards.ps1',
      'borrowing-item-cards.ps1', 'borrowing-isolation.ps1')) {
    $path = Join-Path $moduleRoot $module
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw 'P4t helper is missing'
    }
    . $path
  }

  $modeResult = Invoke-BorrowingP4tModeCheck -Root $Root
  $mode = [string]$modeResult.Mode
  Add-BorrowingP4tFacadeMessages $warnings $modeResult.Warnings
  Add-BorrowingP4tFacadeMessages $failures $modeResult.Failures
  if ($modeResult.ExitCode -eq 0) {
    $sourceResult = Invoke-BorrowingP4tSourceCheck -Root $Root -Mode $mode
    Add-BorrowingP4tFacadeMessages $warnings $sourceResult.Warnings
    Add-BorrowingP4tFacadeMessages $failures $sourceResult.Failures

    $itemResult = Invoke-BorrowingP4tItemCheck -Root $Root -SourceState $sourceResult
    Add-BorrowingP4tFacadeMessages $warnings $itemResult.Warnings
    Add-BorrowingP4tFacadeMessages $failures $itemResult.Failures

    $isolationResult = Invoke-BorrowingP4tIsolationCheck -Root $Root -Mode $mode
    Add-BorrowingP4tFacadeMessages $warnings $isolationResult.Warnings
    Add-BorrowingP4tFacadeMessages $failures $isolationResult.Failures
  }
  $result = New-BorrowingP4tCheckResult -Mode $mode `
    -Warnings $warnings -Failures $failures
  $exitCode = [int]$result.ExitCode
}
catch {
  [void]$failures.Add('P4t 借鉴闭环检查未完成')
  $result = [pscustomobject][ordered]@{
    Mode = $mode; Warnings = [string[]]$warnings.ToArray()
    Failures = [string[]]$failures.ToArray(); ExitCode = 10
  }
  $exitCode = 10
}

Write-BorrowingP4tFacadeResult $result
exit $exitCode
