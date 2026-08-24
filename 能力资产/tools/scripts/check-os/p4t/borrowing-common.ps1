$ErrorActionPreference = 'Stop'

$borrowingP4tCaptureRoot = [IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..\..\borrowing-capture'))
foreach ($dependency in @('common.ps1', 'file-safety.ps1', 'trusted-file-read.ps1')) {
  $dependencyPath = Join-Path $borrowingP4tCaptureRoot $dependency
  if (-not (Test-Path -LiteralPath $dependencyPath -PathType Leaf)) {
    throw ('P4t 缺少捕获公共依赖：{0}' -f $dependencyPath)
  }
  $null = . $dependencyPath
}

function global:Resolve-BorrowingP4tSafeRoot {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$Root)

  try {
    if ([string]::IsNullOrWhiteSpace($Root)) { throw 'Root 为空' }
    $fullPath = [IO.Path]::GetFullPath($Root)
    $pathInfo = Get-BorrowingSafePathInfo -Path $fullPath -ExpectedKind Directory `
      -Stage 'p4t-root' -ReasonCode 'unsafe-root'
    return [string]$pathInfo.CanonicalPath
  }
  catch {
    Throw-BorrowingFailure -Stage 'p4t-root' -ReasonCode 'unsafe-root' `
      -Reason 'P4t Root 不存在或未通过安全路径校验'
  }
}

function global:Get-BorrowingP4tRootMode {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$Root)

  $hasTemplateMarker = Test-Path -LiteralPath (Join-Path $Root '.czxt-template-root') -PathType Leaf
  $hasProjectMarker = Test-Path -LiteralPath (Join-Path $Root '.czxt-project-root') -PathType Leaf
  if ($hasTemplateMarker -and $hasProjectMarker) { return 'conflict' }
  if ($hasTemplateMarker) { return 'template' }
  if ($hasProjectMarker) { return 'project' }
  return 'unknown'
}

function global:New-BorrowingP4tCheckResult {
  [CmdletBinding()]
  param(
    [ValidateSet('template', 'project', 'unknown', 'conflict')][string]$Mode,
    [object]$Warnings,
    [object]$Failures
  )

  $warningItems = @($Warnings | ForEach-Object { [string]$_ })
  $failureItems = @($Failures | ForEach-Object { [string]$_ })
  $exitCode = 0
  if ($failureItems.Count -gt 0) {
    $exitCode = 10
  }
  elseif ($warningItems.Count -gt 0) {
    $exitCode = 5
  }

  return [pscustomobject][ordered]@{
    Mode = $Mode
    Warnings = [string[]]$warningItems
    Failures = [string[]]$failureItems
    ExitCode = $exitCode
  }
}
