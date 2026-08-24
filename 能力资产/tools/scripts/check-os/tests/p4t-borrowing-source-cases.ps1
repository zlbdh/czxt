[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')

foreach ($caseFile in @(
    'p4t-borrowing-source-valid-cases.ps1',
    'p4t-borrowing-source-schema-cases.ps1',
    'p4t-borrowing-source-permission-cases.ps1',
    'p4t-borrowing-source-cache-cases.ps1',
    'p4t-borrowing-source-retirement-cases.ps1'
  )) {
  Invoke-CzxtContract ('P4t source group passes: ' + $caseFile) {
    $path = Join-Path $PSScriptRoot $caseFile
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
      ('missing source group: ' + $caseFile)
    $result = Invoke-CzxtPowerShell -ScriptPath $path -TimeoutMilliseconds 600000
    if (-not [string]::IsNullOrEmpty($result.StdOut)) { Write-Output $result.StdOut.TrimEnd() }
    Assert-CzxtEqual 0 $result.ExitCode ($caseFile + ' stderr: ' + $result.StdErr)
  }
}

Complete-CzxtContracts
