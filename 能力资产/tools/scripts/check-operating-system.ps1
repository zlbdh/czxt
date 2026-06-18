$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$script:OsCheckRoot = $root
$script:OsCheckScriptRoot = $PSScriptRoot
. (Join-Path $PSScriptRoot "check-os\invoke-subcheck.ps1")
. (Join-Path $PSScriptRoot "check-os\write-summary.ps1")
. (Join-Path $PSScriptRoot "check-os\check-plan.ps1")
. (Join-Path $PSScriptRoot "check-os\check-plan-assert.ps1")

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$p4aPasses = New-Object System.Collections.Generic.List[string]
$stateStale = $false
$staleReason = ""

Write-Host ""
Write-Host "🔬 开发操作系统健康检查 — $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host "项目根：$root" -ForegroundColor Gray

$plan = @(Get-OsCheckPlan)
Assert-OsCheckPlan -Plan $plan

foreach ($section in $plan) {
  Write-Host ""
  Write-Host $section.Title -ForegroundColor Cyan

  foreach ($check in $section.Checks) {
    $invokeArgs = @{
      RelativeScript = $check.Script
      FailureLabel = $check.Failure
    }
    if (-not [string]::IsNullOrWhiteSpace($check.Warning)) {
      $invokeArgs.WarningLabel = $check.Warning
    }
    switch ($check.Args) {
      "P4aPasses" { $invokeArgs.Arguments = @{ Failures = $failures; Warnings = $warnings; Passes = $p4aPasses } }
      "Warnings" { $invokeArgs.Arguments = @{ Warnings = $warnings } }
      "Failures" { $invokeArgs.Arguments = @{ Failures = $failures } }
    }

    Invoke-OsSubcheck @invokeArgs
    if ($check.After -eq "StateStale" -and $script:lastSubcheckExit -eq 5) {
      $stateStale = $true
      $staleReason = "子检查 warning exit 5"
    }
  }
}

$exitCode = Write-OsHealthSummary -Failures $failures -Warnings $warnings -PassCount $p4aPasses.Count -StateStale $stateStale -StaleReason $staleReason
exit $exitCode
