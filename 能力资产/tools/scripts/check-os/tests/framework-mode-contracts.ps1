[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$frameworkScope = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\framework-scope.ps1'))
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-gate0-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
$templateMarkerText = "czxt-root-mode=template`nschema=1`n"
$projectMarkerText = "czxt-root-mode=project`nschema=1`n"

[void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
try {
  $roots = @{}
  foreach ($name in @('template-only', 'project-only', 'none', 'both')) {
    $roots[$name] = Join-Path $fixtureRoot $name
    [void](New-Item -ItemType Directory -Path $roots[$name])
  }
  Write-CzxtNoBomText (Join-Path $roots['template-only'] '.czxt-template-root') $templateMarkerText
  Write-CzxtNoBomText (Join-Path $roots['project-only'] '.czxt-project-root') $projectMarkerText
  Write-CzxtNoBomText (Join-Path $roots['both'] '.czxt-template-root') $templateMarkerText
  Write-CzxtNoBomText (Join-Path $roots['both'] '.czxt-project-root') $projectMarkerText

  foreach ($name in @('project-only', 'none')) {
    Write-CzxtNoBomText (Join-Path $roots[$name] 'README.md') "# 操作系统模板`n"
    Write-CzxtNoBomText (Join-Path $roots[$name] '项目配置\_模板.project.json') '{}'
    Write-CzxtNoBomText (Join-Path $roots[$name] '项目区\清单.md') '# legacy scaffold'
  }

  . $frameworkScope

  Invoke-CzxtContract 'Get-CzxtRootMode exposes the four-state marker truth table' {
    Assert-CzxtTrue ($null -ne (Get-Command Get-CzxtRootMode -ErrorAction SilentlyContinue)) `
      'Get-CzxtRootMode is missing'
    $expected = @{
      'template-only' = 'template'; 'project-only' = 'project';
      'none' = 'unknown'; 'both' = 'conflict'
    }
    foreach ($name in $expected.Keys) {
      Assert-CzxtEqual $expected[$name] (Get-CzxtRootMode -Root $roots[$name]) ("mode for {0}" -f $name)
    }
  }

  Invoke-CzxtContract 'Test-IsTemplateRoot is true only for template-only markers' {
    Assert-CzxtEqual $true (Test-IsTemplateRoot -Root $roots['template-only']) 'template-only predicate'
    foreach ($name in @('project-only', 'none', 'both')) {
      Assert-CzxtEqual $false (Test-IsTemplateRoot -Root $roots[$name]) ("predicate for {0}" -f $name)
    }
  }

  Invoke-CzxtContract 'README title and legacy scaffold cannot override markers' {
    Assert-CzxtEqual $false (Test-IsTemplateRoot -Root $roots['project-only']) 'project marker wins over legacy clues'
    Assert-CzxtEqual $false (Test-IsTemplateRoot -Root $roots['none']) 'legacy clues cannot create template mode'
    Assert-CzxtEqual $true (Test-IsTemplateRoot -Root $roots['template-only']) 'template marker needs no legacy clues'
  }
}
finally {
  Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot
}

Complete-CzxtContracts
