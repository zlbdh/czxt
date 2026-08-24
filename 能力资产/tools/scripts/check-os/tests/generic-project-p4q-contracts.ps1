[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$templateRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$installer = Join-Path $templateRoot '实例化项目.ps1'
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-generic-p4q-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
$instanceRoot = Join-Path $fixtureRoot 'instance'
$legacySignatures = @(
  'Docs\1-需求文档\PRD-v3.md',
  'Docs\4-测试文档\测试策略.md',
  '确认改动\已审批\已完成\PROP-040-2026-05-22-Sprint-8-W-1-F-F1-AI餐食推荐.md'
)

[void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
try {
  $install = Invoke-CzxtPowerShell -ScriptPath $installer -ScriptArguments @(
    '-ProjectRoot', $instanceRoot, '-ProjectName', 'Generic P4q 契约实例', '-AppRepoDir', 'app'
  )
  Invoke-CzxtContract 'real installer creates the generic project fixture' {
    Assert-CzxtEqual 0 $install.ExitCode ('installer stderr: {0}' -f $install.StdErr)
  }

  $scope = Join-Path $instanceRoot '能力资产\tools\scripts\check-os\framework-scope.ps1'
  $p4q = Join-Path $instanceRoot '能力资产\tools\scripts\check-os\p4q-governance-semantics.ps1'
  . $scope

  Invoke-CzxtContract 'project-only root without legacy signatures is generic' {
    Assert-CzxtEqual $false (Test-IsCzxtLegacyProjectProfile -Root $instanceRoot) `
      'fresh instance must not inherit the legacy source profile'
  }

  $generic = Invoke-CzxtPowerShell -ScriptPath $p4q -ScriptArguments @('-Root', $instanceRoot)
  Invoke-CzxtContract 'P4q skips legacy-only helpers for a generic project' {
    Assert-CzxtEqual 0 $generic.ExitCode ('generic P4q stderr: {0}' -f $generic.StdErr)
    Assert-CzxtTrue ($generic.StdOut -match 'generic project.*PROP.*edge-doc') `
      'generic P4q did not disclose the legacy-helper skip'
  }

  Write-CzxtNoBomText (Join-Path $instanceRoot $legacySignatures[0]) "# decoy legacy file`n"
  Invoke-CzxtContract 'one legacy-looking file cannot activate the legacy profile' {
    Assert-CzxtEqual $false (Test-IsCzxtLegacyProjectProfile -Root $instanceRoot) `
      'partial legacy signature must fail closed as generic'
  }
  $partial = Invoke-CzxtPowerShell -ScriptPath $p4q -ScriptArguments @('-Root', $instanceRoot)
  Invoke-CzxtContract 'P4q still skips legacy-only helpers for a partial signature' {
    Assert-CzxtEqual 0 $partial.ExitCode ('partial-signature P4q stderr: {0}' -f $partial.StdErr)
  }

  foreach ($relativePath in $legacySignatures[1..($legacySignatures.Count - 1)]) {
    Write-CzxtNoBomText (Join-Path $instanceRoot $relativePath) "# legacy signature fixture`n"
  }
  Invoke-CzxtContract 'complete legacy signature activates the legacy profile' {
    Assert-CzxtEqual $true (Test-IsCzxtLegacyProjectProfile -Root $instanceRoot) `
      'complete high-confidence signature must activate legacy checks'
  }
  $legacy = Invoke-CzxtPowerShell -ScriptPath $p4q -ScriptArguments @('-Root', $instanceRoot)
  Invoke-CzxtContract 'P4q runs legacy-only helpers for a signed legacy project' {
    Assert-CzxtEqual 10 $legacy.ExitCode 'empty legacy fixture content must be rejected'
    Assert-CzxtTrue ($legacy.StdOut -match 'TASKS\.md') `
      'legacy requirements helper did not run'
  }
}
finally {
  Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot
}

Complete-CzxtContracts
