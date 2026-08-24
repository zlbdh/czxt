$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

$script:P4tUtf8NoBom = New-Object Text.UTF8Encoding($false)
$script:P4tUtf8Bom = New-Object Text.UTF8Encoding($true)
$script:P4tTemplateRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
$script:P4tModuleRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\p4t'))
$script:P4tFacadePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\p4t-borrowing-consistency.ps1'))
$script:P4tSealPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\seal-borrowing-item.ps1'))
$script:P4tFixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-p4t-tests'))
$script:P4tFixtureRoot = $null
$script:P4tReparsePaths = New-Object Collections.Generic.List[string]
. (Join-Path $PSScriptRoot 'p4t-borrowing-safety-test-support.ps1')

function Initialize-P4tTestFixture {
  if ($null -ne $script:P4tFixtureRoot) { throw 'P4t fixture is already initialized' }
  [void](New-Item -ItemType Directory -Path $script:P4tFixtureParent -Force)
  $script:P4tFixtureRoot = Join-Path $script:P4tFixtureParent ([guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Path $script:P4tFixtureRoot)
}

function Write-Utf8Bom {
  param([string]$Path, [string]$Content)
  Write-CzxtText -Path $Path -Content $Content -Encoding $script:P4tUtf8Bom
}

function Write-P4tUtf8 {
  param([string]$Path, [string]$Content)
  Write-CzxtText -Path $Path -Content $Content -Encoding $script:P4tUtf8NoBom
}

function Copy-P4tTemplateFile {
  param([string]$RelativePath, [string]$Root)
  $source = Join-Path $script:P4tTemplateRoot $RelativePath
  Assert-CzxtTrue (Test-Path -LiteralPath $source -PathType Leaf) `
    ('fixture source is missing: ' + $RelativePath)
  $target = Join-Path $Root $RelativePath
  $parent = Split-Path -Parent $target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllBytes($target, [IO.File]::ReadAllBytes($source))
}

function New-TestRoot {
  param([string]$Name)
  Assert-CzxtTrue ($null -ne $script:P4tFixtureRoot) 'P4t fixture is not initialized'
  Assert-CzxtTrue ($Name -cmatch '\A[a-z0-9][a-z0-9-]{0,63}\z') ('unsafe test root name: ' + $Name)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $rawDigest = [BitConverter]::ToString(
      $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Name)))
    $digest = $rawDigest.Replace('-', '').ToLowerInvariant().Substring(0, 12)
  }
  finally { $sha.Dispose() }
  $root = Assert-P4tPathInside -Path (Join-Path $script:P4tFixtureRoot ('r-' + $digest)) `
    -Parent $script:P4tFixtureRoot -Context 'test root'
  Assert-CzxtTrue (-not (Test-Path -LiteralPath $root)) ('duplicate test root: ' + $Name)
  [void](New-Item -ItemType Directory -Path $root)
  return $root
}

function Add-P4tBorrowingSkeleton {
  param([string]$Root)
  foreach ($relative in @(
      '借鉴区\README.md', '借鉴区\.gitignore',
      '借鉴区\模板\来源版本卡.md', '借鉴区\模板\借鉴卡.md')) {
    Copy-P4tTemplateFile -RelativePath $relative -Root $Root
  }
  foreach ($relative in @('借鉴区\来源', '借鉴区\事项')) {
    [void](New-Item -ItemType Directory -Path (Join-Path $Root $relative) -Force)
  }
}

function New-TemplateSkeleton {
  param([string]$Name)
  $root = New-TestRoot -Name $Name
  Write-P4tUtf8 (Join-Path $root '.czxt-template-root') "czxt-root-mode=template`nschema=1`n"
  Add-P4tBorrowingSkeleton -Root $root
  foreach ($relative in @('借鉴区\来源\.gitkeep', '借鉴区\事项\.gitkeep')) {
    Write-P4tUtf8 (Join-Path $root $relative) ''
  }
  foreach ($relative in @(
      '实例化项目.ps1', '能力资产\tools\scripts\installer-borrowing-zone.ps1',
      '能力资产\tools\scripts\installer-borrowing-skeleton.ps1',
      '能力资产\tools\scripts\installer-path-safety.ps1',
      '能力资产\tools\scripts\installer-file-safety.ps1',
      '能力资产\tools\scripts\installer-source-copy.ps1',
      '能力资产\tools\scripts\installer-handle-lease.ps1',
      '能力资产\tools\scripts\installer-replace-transaction.ps1',
      '能力资产\tools\scripts\installer-output-manifest.ps1',
      '能力资产\tools\scripts\installer-tree-plan.ps1',
      '能力资产\tools\scripts\installer-copy-expectation.ps1')) {
    Copy-P4tTemplateFile -RelativePath $relative -Root $root
  }
  return $root
}

function New-ProjectSkeleton {
  param([string]$Name)
  $root = New-TestRoot -Name $Name
  Write-P4tUtf8 (Join-Path $root '.czxt-project-root') "czxt-root-mode=project`nschema=1`n"
  Add-P4tBorrowingSkeleton -Root $root
  foreach ($relative in @('借鉴区\模板\来源版本卡.md', '借鉴区\模板\借鉴卡.md')) {
    $templatePath = Join-Path $root $relative
    $text = [IO.File]::ReadAllText($templatePath, $script:P4tUtf8NoBom)
    Write-P4tUtf8 $templatePath ($text.Replace('{{PROJECT_NAME}}', 'P4t fixture'))
  }
  [void](New-Item -ItemType Directory -Path (Join-Path $root 'app') -Force)
  [void](New-Item -ItemType Directory -Path (Join-Path $root 'Docs') -Force)
  Write-P4tUtf8 (Join-Path $root '项目配置\fixture.project.json') @'
{
  "projectName": "P4t fixture",
  "projectRoot": "fixture-only",
  "appRepoDir": "app",
  "currentVersion": "v0.0.0",
  "currentSprint": "test"
}
'@
  return $root
}

function Import-P4tHelper {
  param([string]$FileName, [string]$CommandName)
  $path = Join-Path $script:P4tModuleRoot $FileName
  Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) `
    ('missing P4t {0} helper: {1}' -f $FileName, $path)
  . $path
  Assert-CzxtTrue ($null -ne (Get-Command $CommandName -CommandType Function -ErrorAction SilentlyContinue)) `
    ('missing P4t function {0} in {1}' -f $CommandName, $FileName)
}

function Assert-P4tResult {
  param($Result, [int]$ExpectedExitCode, [string]$Context)
  Assert-CzxtTrue ($null -ne $Result) ($Context + ' returned null')
  Assert-CzxtTrue ($null -ne $Result.PSObject.Properties['ExitCode']) `
    ($Context + ' result has no ExitCode')
  Assert-CzxtEqual $ExpectedExitCode ([int]$Result.ExitCode) ($Context + ' exit code')
  foreach ($name in @('Warnings', 'Failures')) {
    Assert-CzxtTrue ($null -ne $Result.PSObject.Properties[$name]) `
      ($Context + ' result has no ' + $name)
  }
  if ($ExpectedExitCode -eq 10) {
    Assert-CzxtTrue (@($Result.Failures).Count -gt 0) ($Context + ' lacks failure detail')
  }
  elseif ($ExpectedExitCode -eq 5) {
    Assert-CzxtEqual 0 @($Result.Failures).Count ($Context + ' warning has failures')
    Assert-CzxtTrue (@($Result.Warnings).Count -gt 0) ($Context + ' lacks warning detail')
  }
  else {
    Assert-CzxtEqual 0 @($Result.Failures).Count ($Context + ' has failures')
    Assert-CzxtEqual 0 @($Result.Warnings).Count ($Context + ' has warnings')
  }
}

function Invoke-P4tFixture {
  param([string]$Root)
  Assert-CzxtTrue (Test-Path -LiteralPath $script:P4tFacadePath -PathType Leaf) `
    ('missing P4t façade: ' + $script:P4tFacadePath)
  return Invoke-CzxtPowerShell -ScriptPath $script:P4tFacadePath `
    -ScriptArguments @('-Root', [IO.Path]::GetFullPath($Root)) -TimeoutMilliseconds 180000
}

function Assert-ExitCode {
  param($ProcessResult, [int]$Expected, [string]$Context)
  Assert-CzxtEqual $Expected $ProcessResult.ExitCode `
    ('{0}; stdout=<{1}> stderr=<{2}>' -f $Context, $ProcessResult.StdOut, $ProcessResult.StdErr)
}
