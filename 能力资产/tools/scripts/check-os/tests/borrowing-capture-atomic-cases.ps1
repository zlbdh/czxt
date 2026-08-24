[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

foreach ($caseFile in @(
    'borrowing-capture-p4t-runner-cases.ps1',
    'borrowing-capture-transaction-cases.ps1',
    'borrowing-capture-source-card-cases.ps1',
    'borrowing-capture-candidate-validator-cases.ps1',
    'borrowing-capture-idempotency-cases.ps1',
    'borrowing-capture-orchestrator-safety-cases.ps1',
    'borrowing-capture-trusted-read-safety-cases.ps1',
    'borrowing-capture-git-auxiliary-cleanup-cases.ps1',
    'borrowing-owned-rename-contracts.ps1',
    'borrowing-owned-tree-seal-contracts.ps1'
  )) {
  Invoke-CzxtContract ('atomic semantic case passes: ' + $caseFile) {
    $path = Join-Path $PSScriptRoot $caseFile
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
      ('missing atomic case: ' + $caseFile)
    $result = Invoke-CzxtPowerShell -ScriptPath $path -TimeoutMilliseconds 300000
    if (-not [string]::IsNullOrEmpty($result.StdOut)) { Write-Output $result.StdOut.TrimEnd() }
    Assert-CzxtEqual 0 $result.ExitCode ($caseFile + ' stderr: ' + $result.StdErr)
  }
}

Complete-CzxtContracts
