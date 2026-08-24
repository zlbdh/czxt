[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-template-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-p4a-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-instance-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-scaffold-path-safety-contracts.ps1')

$templateRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$installerPath = Join-Path $templateRoot '实例化项目.ps1'
$p4aPath = Join-Path $templateRoot '能力资产\tools\scripts\check-os\p4a-basic-integrity.ps1'
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-borrowing-scaffold-tests'))
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
$instanceRoot = Join-Path $fixtureRoot 'instance'
$staticPaths = @(
  '借鉴区/README.md',
  '借鉴区/.gitignore',
  '借鉴区/模板/来源版本卡.md',
  '借鉴区/模板/借鉴卡.md'
)
$skeletonPaths = $staticPaths + @('借鉴区/来源/.gitkeep', '借鉴区/事项/.gitkeep')

[void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
try {
  Invoke-BorrowingTemplateContracts -TemplateRoot $templateRoot `
    -InstallerPath $installerPath -SkeletonPaths $skeletonPaths
  Invoke-BorrowingP4aGuardContracts -TemplateRoot $templateRoot `
    -FixtureRoot $fixtureRoot -SkeletonPaths $skeletonPaths
  Invoke-BorrowingPathSafetyContracts -TemplateRoot $templateRoot -FixtureRoot $fixtureRoot
  Invoke-BorrowingInstanceContracts -TemplateRoot $templateRoot `
    -InstallerPath $installerPath -P4aPath $p4aPath -InstanceRoot $instanceRoot `
    -StaticPaths $staticPaths -SkeletonPaths $skeletonPaths
}
finally {
  Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot
}

Complete-CzxtContracts
