$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')

function New-InstallerRenderFixture {
  param([string]$SourceRoot, [string]$FixtureRoot)
  $template = Join-Path $FixtureRoot 'template'
  foreach ($dir in @('.codex', '.claude', '操作系统', '能力资产/tools/scripts',
      'PM工作区', '交接区', '确认改动', '项目配置', 'Docs', '项目区/本地实例',
      '借鉴区/模板', '借鉴区/来源', '借鉴区/事项')) {
    [void][IO.Directory]::CreateDirectory((Join-Path $template $dir))
  }
  foreach ($relative in @('实例化项目.ps1', '.codex/hooks.json', '.claude/settings.json',
      '能力资产/tools/hooks/manifest.json', '能力资产/tools/hooks/codex/stop-chat-summary.ps1',
      '能力资产/tools/hooks/claude/stop-chat-summary.ps1',
      '能力资产/tools/scripts/check-os/p4b-size-classification.ps1')) {
    $target = Join-Path $template $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy((Join-Path $SourceRoot $relative), $target)
  }
  Get-ChildItem -LiteralPath (Join-Path $SourceRoot '能力资产/tools/scripts') -Filter 'installer-*.ps1' |
    ForEach-Object { [IO.File]::Copy($_.FullName, (Join-Path $template ('能力资产/tools/scripts/' + $_.Name))) }
  $selfTestTarget = Join-Path $template '能力资产/tools/scripts/check-os/tests'
  [void][IO.Directory]::CreateDirectory($selfTestTarget)
  Get-ChildItem -LiteralPath (Join-Path $SourceRoot '能力资产/tools/scripts/check-os/tests') -Filter 'installer-render-*.ps1' |
    ForEach-Object { [IO.File]::Copy($_.FullName, (Join-Path $selfTestTarget $_.Name)) }
  foreach ($relative in @('.gitignore', 'AGENTS.md', 'README.md', '状态.md',
      '项目区/README.md', '项目区/清单.md', '项目区/.gitignore', '项目区/本地实例/.gitkeep',
      '借鉴区/README.md', '借鉴区/.gitignore', '借鉴区/模板/来源版本卡.md',
      '借鉴区/模板/借鉴卡.md', '借鉴区/来源/.gitkeep', '借鉴区/事项/.gitkeep')) {
    Write-CzxtNoBomText (Join-Path $template $relative) ''
  }
  $token = '{' + '{PROJECT_NAME}' + '}'
  $sample = @(
    '[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)',
    '$single = ''TOKEN''', '$double = "TOKEN"', '$singleHere = @''', 'TOKEN', '''@',
    '$doubleHere = @"', 'TOKEN', '"@', '# TOKEN',
    '[ordered]@{ single=$single; double=$double; singleHere=$singleHere; doubleHere=$doubleHere } |',
    '  ConvertTo-Json -Compress'
  ) -join "`n"
  Write-CzxtText (Join-Path $template '能力资产/sample.ps1') ($sample.Replace('TOKEN', $token)) $script:CzxtUtf8Bom
  return $template
}

function Invoke-InstallerRenderFixture {
  param([string]$TemplateRoot, [string]$ProjectRoot, [string]$ProjectName,
    [string]$AppRepoDir = 'frontend\app', [switch]$Force)
  $parent = Split-Path -Parent $TemplateRoot
  $inputPath = Join-Path $parent ('input-' + [guid]::NewGuid().ToString('N') + '.json')
  [ordered]@{ Installer=(Join-Path $TemplateRoot '实例化项目.ps1'); ProjectRoot=$ProjectRoot;
    ProjectName=$ProjectName; AppRepoDir=$AppRepoDir; Force=$Force.IsPresent } |
    ConvertTo-Json -Depth 5 | ForEach-Object { Write-CzxtNoBomText $inputPath $_ }
  $runner = Join-Path $parent 'install-runner.ps1'
  Write-CzxtText $runner @'
param([string]$InputPath)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$inputData = [IO.File]::ReadAllText($InputPath) | ConvertFrom-Json
$arguments = @{ ProjectRoot=$inputData.ProjectRoot; ProjectName=$inputData.ProjectName;
  AppRepoDir=$inputData.AppRepoDir; Force=[bool]$inputData.Force }
& $inputData.Installer @arguments
'@ $script:CzxtUtf8Bom
  return Invoke-CzxtPowerShell -ScriptPath $runner -ScriptArguments @('-InputPath', $inputPath)
}

function Assert-InstallerRenderSyntax {
  param([string]$Root)
  foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File) {
    if ($file.Extension -eq '.json') {
      try { $null = [IO.File]::ReadAllText($file.FullName) | ConvertFrom-Json -ErrorAction Stop }
      catch { throw ('JSON无效: ' + $file.Name) }
    }
    if ($file.Extension -eq '.ps1') {
      $tokens=$null; $errors=$null
      $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
      Assert-CzxtEqual 0 @($errors).Count ('PS1语法无效: ' + $file.Name)
      Assert-CzxtTrue (Test-CzxtUtf8Bom $file.FullName) ('BOM缺失: ' + $file.Name)
    }
  }
}
