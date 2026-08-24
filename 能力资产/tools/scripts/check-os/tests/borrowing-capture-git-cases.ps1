[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

foreach ($caseFile in @(
    'borrowing-capture-git-input-cases.ps1',
    'borrowing-capture-git-runner-cases.ps1',
    'borrowing-capture-process-cases.ps1',
    'borrowing-capture-git-capture-cases.ps1',
    'borrowing-capture-git-cache-cases.ps1'
  )) {
  Invoke-CzxtContract ('Git semantic case passes: ' + $caseFile) {
    $path = Join-Path $PSScriptRoot $caseFile
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) ('missing Git case: ' + $caseFile)
    $result = Invoke-CzxtPowerShell -ScriptPath $path -TimeoutMilliseconds 300000
    if (-not [string]::IsNullOrEmpty($result.StdOut)) { Write-Output $result.StdOut.TrimEnd() }
    Assert-CzxtEqual 0 $result.ExitCode ($caseFile + ' stderr: ' + $result.StdErr)
  }
}

Complete-CzxtContracts
