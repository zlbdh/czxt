[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')

$groups = @(
  'p4t-borrowing-mode-cases.ps1',
  'p4t-borrowing-source-cases.ps1',
  'p4t-borrowing-item-cases.ps1',
  'borrowing-item-seal-contracts.ps1',
  'borrowing-item-close-transaction-contracts.ps1',
  'p4t-borrowing-isolation-cases.ps1',
  'p4t-borrowing-isolation-race-cases.ps1',
  'p4t-borrowing-isolation-window-cases.ps1',
  'p4t-borrowing-isolation-budget-cases.ps1',
  'p4t-borrowing-facade-cases.ps1'
)
foreach ($caseFile in $groups) {
  Invoke-CzxtContract ('P4t borrowing group passes: ' + $caseFile) {
    $path = Join-Path $PSScriptRoot $caseFile
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
      ('missing P4t group: ' + $caseFile)
    $result = Invoke-CzxtPowerShell -ScriptPath $path -TimeoutMilliseconds 900000
    if (-not [string]::IsNullOrEmpty($result.StdOut)) { Write-Output $result.StdOut.TrimEnd() }
    Assert-CzxtEqual 0 $result.ExitCode ($caseFile + ' stderr: ' + $result.StdErr)
  }
}

Write-Output ('P4T_BORROWING_CONTRACT_GROUPS={0}' -f $groups.Count)
Complete-CzxtContracts
