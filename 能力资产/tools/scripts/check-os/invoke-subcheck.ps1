function Invoke-OsSubcheck {
  param(
    [string]$RelativeScript,
    [string]$FailureLabel,
    [string]$WarningLabel = "",
    [int[]]$WarnExitCodes = @(5),
    [int[]]$FailExitCodes = @(10),
    [string]$Root = $script:OsCheckRoot,
    [string]$ScriptRoot = $script:OsCheckScriptRoot,
    [object]$Failures = $script:failures,
    [object]$Warnings = $script:warnings,
    [hashtable]$Arguments = @{}
  )

  $script:lastSubcheckExit = 0
  $scriptPath = Join-Path $ScriptRoot $RelativeScript
  if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Write-Host "  🔴 子检查脚本缺失：$RelativeScript" -ForegroundColor Red
    $Failures.Add("$FailureLabel 子检查脚本缺失")
    $script:lastSubcheckExit = 10
    return
  }

  $invokeArgs = @{ Root = $Root }
  if ($null -ne $Arguments) {
    foreach ($key in $Arguments.Keys) {
      $invokeArgs[$key] = $Arguments[$key]
    }
  }

  & $scriptPath @invokeArgs
  $exitCode = $LASTEXITCODE
  $script:lastSubcheckExit = $exitCode
  if ($exitCode -eq 0) {
    return
  }

  if ($WarnExitCodes -contains $exitCode) {
    $warningText = if ([string]::IsNullOrWhiteSpace($WarningLabel)) {
      "$FailureLabel 子检查 warning exit $exitCode"
    } else {
      "$WarningLabel exit $exitCode"
    }
    $Warnings.Add($warningText)
    return
  }

  if (($FailExitCodes -contains $exitCode) -or ($exitCode -ne 0)) {
    $Failures.Add("$FailureLabel 子检查失败 exit $exitCode")
  }
}
