[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$templateRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$installer = Join-Path $templateRoot '实例化项目.ps1'
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-gate0-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
$instanceRoot = Join-Path $fixtureRoot 'instance'
$conflictingRoot = Join-Path $fixtureRoot 'conflicting-target'
$templateMarkerText = "czxt-root-mode=template`nschema=1`n"
$projectMarkerText = "czxt-root-mode=project`nschema=1`n"

[void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
try {
  Invoke-CzxtContract 'template root is template-only with schema 1' {
    $templateMarker = Join-Path $templateRoot '.czxt-template-root'
    Assert-CzxtTrue (Test-Path -LiteralPath $templateMarker -PathType Leaf) 'template marker is missing'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $templateRoot '.czxt-project-root'))) `
      'template root must not have project marker'
    $actual = [IO.File]::ReadAllText($templateMarker).Replace("`r`n", "`n")
    Assert-CzxtEqual $templateMarkerText $actual 'template marker content'
  }

  $install = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
    '-ProjectRoot', $instanceRoot, '-ProjectName', 'Gate0 集成实例', '-AppRepoDir', 'app'
  )
  Invoke-CzxtContract 'real installer succeeds for an empty target' {
    Assert-CzxtEqual 0 $install.ExitCode ('installer stderr: {0}' -f $install.StdErr)
  }

  Invoke-CzxtContract 'instance is project-only with schema 1' {
    $projectMarker = Join-Path $instanceRoot '.czxt-project-root'
    Assert-CzxtTrue (Test-Path -LiteralPath $projectMarker -PathType Leaf) 'project marker is missing'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $instanceRoot '.czxt-template-root'))) `
      'template marker leaked into instance'
    $actual = [IO.File]::ReadAllText($projectMarker).Replace("`r`n", "`n")
    Assert-CzxtEqual $projectMarkerText $actual 'project marker content'
  }

  $instanceGate = Join-Path $instanceRoot '能力资产\tools\scripts\check-winps-encoding.ps1'
  Invoke-CzxtContract 'instance official PowerShell scope keeps UTF-8 BOM' {
    Assert-CzxtOfficialPowerShellScope -GatePath $instanceGate -InstanceRoot $instanceRoot
  }

  Invoke-CzxtContract 'instance encoding gate succeeds' {
    $result = Invoke-CzxtPowerShell -ScriptPath $instanceGate -ScriptArguments @('-Root', $instanceRoot)
    Assert-CzxtEqual 0 $result.ExitCode ('encoding gate stderr: {0}' -f $result.StdErr)
  }

  $instanceP4a = Join-Path $instanceRoot '能力资产\tools\scripts\check-os\p4a-basic-integrity.ps1'
  Invoke-CzxtContract 'instance P4a succeeds in project-only mode' {
    $result = Invoke-CzxtPowerShell -ScriptPath $instanceP4a -ScriptArguments @('-Root', $instanceRoot)
    Assert-CzxtEqual 0 $result.ExitCode ('P4a stderr: {0}' -f $result.StdErr)
  }

  Invoke-CzxtContract 'P4a rejects unknown root mode' {
    $projectMarker = Join-Path $instanceRoot '.czxt-project-root'
    if (Test-Path -LiteralPath $projectMarker) { Remove-Item -LiteralPath $projectMarker -Force }
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $instanceP4a -ScriptArguments @('-Root', $instanceRoot)
      Assert-CzxtEqual 10 $result.ExitCode 'P4a must reject a missing project marker'
    }
    finally { Write-CzxtNoBomText $projectMarker $projectMarkerText }
  }

  $sinkHarness = Join-Path $fixtureRoot 'p4a-external-sink-harness.ps1'
  Invoke-CzxtContract 'P4a external empty sink receives unknown-mode failure and exit 10' {
    $projectMarker = Join-Path $instanceRoot '.czxt-project-root'
    if (Test-Path -LiteralPath $projectMarker) { Remove-Item -LiteralPath $projectMarker -Force }
    try {
      $result = Invoke-CzxtP4aSinkContract -HarnessPath $sinkHarness -P4aPath $instanceP4a `
        -RootPath $instanceRoot -ExpectedP4aExit 10 -ExpectedFailureCount 1
      Assert-CzxtEqual 0 $result.ExitCode ('negative sink contract stderr: {0}' -f $result.StdErr)
    }
    finally { Write-CzxtNoBomText $projectMarker $projectMarkerText }
  }

  Invoke-CzxtContract 'P4a valid project preserves a pre-existing external failure and exits 0' {
    $seed = 'existing failure sentinel'
    $result = Invoke-CzxtP4aSinkContract -HarnessPath $sinkHarness -P4aPath $instanceP4a `
      -RootPath $instanceRoot -ExpectedP4aExit 0 -ExpectedFailureCount 1 -SeedFailure $seed
    Assert-CzxtEqual 0 $result.ExitCode ('positive sink contract stderr: {0}' -f $result.StdErr)
  }

  Invoke-CzxtContract 'P4a rejects conflicting root markers' {
    $templateMarker = Join-Path $instanceRoot '.czxt-template-root'
    Write-CzxtNoBomText $templateMarker $templateMarkerText
    try {
      $result = Invoke-CzxtPowerShell -ScriptPath $instanceP4a -ScriptArguments @('-Root', $instanceRoot)
      Assert-CzxtEqual 10 $result.ExitCode 'P4a must reject conflicting markers'
    }
    finally { if (Test-Path -LiteralPath $templateMarker) { Remove-Item -LiteralPath $templateMarker -Force } }
  }

  Invoke-CzxtContract 'P4a propagates the public encoding gate failure' {
    $target = Join-Path $instanceRoot '能力资产\tools\scripts\check-os\framework-scope.ps1'
    $bytes = [IO.File]::ReadAllBytes($target)
    Assert-CzxtTrue (Test-CzxtUtf8Bom $target) 'chosen official PS1 does not start with BOM'
    [IO.File]::WriteAllBytes($target, $bytes[3..($bytes.Length - 1)])
    $result = Invoke-CzxtPowerShell -ScriptPath $instanceP4a -ScriptArguments @('-Root', $instanceRoot)
    Assert-CzxtEqual 10 $result.ExitCode 'P4a must propagate encoding gate exit 10'
  }

  [void](New-Item -ItemType Directory -Path $conflictingRoot)
  Write-CzxtNoBomText (Join-Path $conflictingRoot '.czxt-template-root') $templateMarkerText
  $refused = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
    '-ProjectRoot', $conflictingRoot, '-ProjectName', 'refused', '-AppRepoDir', 'app', '-Force'
  )
  Invoke-CzxtContract 'installer safely rejects a target carrying template marker' {
    Assert-CzxtTrue ($refused.ExitCode -ne 0) 'installer accepted a conflicting target'
    Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $conflictingRoot '.czxt-template-root')) `
      'installer deleted the pre-existing template marker'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $conflictingRoot '.czxt-project-root'))) `
      'installer wrote project marker after refusal'
  }
}
finally {
  Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot
}

Complete-CzxtContracts
