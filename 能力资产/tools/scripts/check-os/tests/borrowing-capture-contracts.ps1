[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

foreach ($caseFile in @(
    'borrowing-capture-common-cases.ps1',
    'borrowing-capture-facade-cases.ps1',
    'borrowing-capture-facade-success-cases.ps1',
    'borrowing-capture-file-safety-cases.ps1',
    'borrowing-capture-git-cases.ps1',
    'borrowing-capture-local-cases.ps1',
    'borrowing-capture-web-cases.ps1',
    'borrowing-capture-atomic-cases.ps1'
  )) {
  Invoke-CzxtContract ('capture semantic suite passes: ' + $caseFile) {
    $path = Join-Path $PSScriptRoot $caseFile
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
      ('missing capture semantic case: ' + $caseFile)
    $result = Invoke-CzxtPowerShell -ScriptPath $path -TimeoutMilliseconds 600000
    if (-not [string]::IsNullOrEmpty($result.StdOut)) { Write-Output $result.StdOut.TrimEnd() }
    Assert-CzxtEqual 0 $result.ExitCode ($caseFile + ' stderr: ' + $result.StdErr)
  }
}

Complete-CzxtContracts
