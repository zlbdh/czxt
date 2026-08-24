[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$p4cPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\p4c-framework-references.ps1'))
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-p4c-reference-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))

[void](New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '操作系统') -Force)
try {
  Write-CzxtNoBomText (Join-Path $fixtureRoot '操作系统\中文规则.md') "# 中文规则`n"
  Write-CzxtNoBomText (Join-Path $fixtureRoot 'README.md') @'
# P4c UTF-8 fixture

[中文规则](操作系统/中文规则.md)
'@

  Invoke-CzxtContract 'P4c counts a Chinese filename referenced by UTF-8 no-BOM Markdown' {
    $result = Invoke-CzxtPowerShell -ScriptPath $p4cPath -ScriptArguments @('-Root', $fixtureRoot)
    Assert-CzxtEqual 0 $result.ExitCode (
      'P4c treated the referenced Chinese filename as dead; stdout={0}; stderr={1}' -f
        $result.StdOut, $result.StdErr)
  }
}
finally {
  Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot
}

Complete-CzxtContracts
