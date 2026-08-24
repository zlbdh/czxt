[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')

foreach ($caseFile in @(
    'p4t-borrowing-item-valid-cases.ps1',
    'p4t-borrowing-item-reference-cases.ps1',
    'p4t-borrowing-item-permission-cases.ps1',
    'p4t-borrowing-item-state-cases.ps1',
    'p4t-borrowing-item-closure-cases.ps1'
  )) {
  Invoke-CzxtContract ('P4t item group passes: ' + $caseFile) {
    $path = Join-Path $PSScriptRoot $caseFile
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) ('missing item group: ' + $caseFile)
    $result = Invoke-CzxtPowerShell -ScriptPath $path -TimeoutMilliseconds 600000
    if (-not [string]::IsNullOrEmpty($result.StdOut)) { Write-Output $result.StdOut.TrimEnd() }
    Assert-CzxtEqual 0 $result.ExitCode ($caseFile + ' stderr: ' + $result.StdErr)
  }
}

Complete-CzxtContracts
