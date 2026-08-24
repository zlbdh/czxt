[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$templateRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$installer = Join-Path $templateRoot '实例化项目.ps1'
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-generic-p4r-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
$instanceRoot = Join-Path $fixtureRoot 'instance'

[void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
try {
  $install = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
    '-ProjectRoot', $instanceRoot, '-ProjectName', 'Generic P4r 契约实例', '-AppRepoDir', 'app'
  )
  Invoke-CzxtContract 'real installer creates the generic hooks fixture' {
    Assert-CzxtEqual 0 $install.ExitCode ('installer stderr: {0}' -f $install.StdErr)
  }

  $p4r = Join-Path $instanceRoot '能力资产\tools\scripts\check-os\p4r-hooks-config.ps1'
  $noRepository = Invoke-CzxtPowerShell -ScriptPath $p4r -ScriptArguments @('-Root', $instanceRoot)
  Invoke-CzxtContract 'P4r skips an unbound business repository with exit zero' {
    Assert-CzxtEqual 0 $noRepository.ExitCode ('unbound P4r stderr: {0}' -f $noRepository.StdErr)
    Assert-CzxtTrue ($noRepository.StdOut -match 'generic project.*git hooks') `
      'P4r did not disclose the unbound repository skip'
  }

  $gitDir = Join-Path $instanceRoot 'app\.git'
  [void](New-Item -ItemType Directory -Path $gitDir -Force)
  $missingHooks = Invoke-CzxtPowerShell -ScriptPath $p4r -ScriptArguments @('-Root', $instanceRoot)
  Invoke-CzxtContract 'P4r converts child stderr into the documented failure exit' {
    Assert-CzxtEqual 10 $missingHooks.ExitCode `
      ('missing hooks must be exit 10, not NativeCommandError exit 1; stderr: {0}' -f $missingHooks.StdErr)
    Assert-CzxtTrue ((($missingHooks.StdOut + "`n" + $missingHooks.StdErr) -match '(?i)\.git[\\/]hooks')) `
      'missing hooks diagnostic was lost'
  }

  [void](New-Item -ItemType Directory -Path (Join-Path $gitDir 'hooks') -Force)
  $emptyHooks = Invoke-CzxtPowerShell -ScriptPath $p4r -ScriptArguments @('-Root', $instanceRoot)
  Invoke-CzxtContract 'P4r still rejects an initialized repository with missing wrappers' {
    Assert-CzxtEqual 10 $emptyHooks.ExitCode 'initialized repository must keep hooks drift enforcement'
    Assert-CzxtTrue ($emptyHooks.StdOut -match 'pre-commit wrapper') `
      'install-hooks drift check did not run'
  }
}
finally {
  Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot
}

Complete-CzxtContracts
