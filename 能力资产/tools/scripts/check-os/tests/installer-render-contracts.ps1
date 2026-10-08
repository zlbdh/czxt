[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'installer-render-support.ps1')
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../'))
$fixtureParent = Join-Path $env:TEMP 'czxt-installer-render-tests'
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixtureRoot)
try {
  $template = New-InstallerRenderFixture -SourceRoot $sourceRoot -FixtureRoot $fixtureRoot
  $cases = @(
    @{ Id='normal'; Name='普通中文项目' },
    @{ Id='double'; Name='我的"项目' },
    @{ Id='single'; Name="我的'项目" },
    @{ Id='dollar'; Name='我的$(throw "不得执行")$name`项目' },
    @{ Id='token'; Name=('我的{' + '{APP_REPO_DIR}' + '}项目') }
  )
  foreach ($case in $cases) {
    $project = Join-Path $fixtureRoot $case.Id
    $install = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName $case.Name
    Invoke-CzxtContract ($case.Id + ': valid names and nested paths produce parseable files') {
      Assert-CzxtEqual 0 $install.ExitCode ('installer failed: ' + $install.StdErr)
      Assert-InstallerRenderSyntax $project
      $json = [IO.File]::ReadAllText((Join-Path $project '.codex/hooks.json')) | ConvertFrom-Json
      Assert-CzxtEqual ('Loading governance context for ' + $case.Name) $json.hooks.SessionStart[0].hooks[0].statusMessage 'JSON values must be preserved literally'
      $manifest = [IO.File]::ReadAllText((Join-Path $project '能力资产/tools/hooks/manifest.json')) | ConvertFrom-Json
      $hook = $manifest.hooks | Where-Object { $_.id -eq 'hook-install-check' }
      Assert-CzxtTrue ($hook.description.Contains('frontend/app/.git/hooks')) 'Application paths should normalize to forward slashes'
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $project 'frontend/app') -PathType Container) 'Nested application directory was not created'
    }
    Invoke-CzxtContract ($case.Id + ': PowerShell strings retain parameters as plain data at runtime') {
      $run = Invoke-CzxtPowerShell -ScriptPath (Join-Path $project '能力资产/sample.ps1')
      Assert-CzxtEqual 0 $run.ExitCode ('sample execution failed: ' + $run.StdErr)
      $values = $run.StdOut | ConvertFrom-Json
      foreach ($property in @('single', 'double', 'singleHere', 'doubleHere')) {
        Assert-CzxtEqual $case.Name $values.$property ($property + 'Parameters were not preserved literally')
      }
    }
  }
  Invoke-CzxtContract 'P4b groups nested application directories correctly without treating directory names as regex' {
    $path = Join-Path $fixtureRoot 'normal/能力资产/tools/scripts/check-os/p4b-size-classification.ps1'
    . $path
    $meta = Get-AppSrcP4bMeta -Rel 'frontend\app\src\features\editor\large.ts'
    Assert-CzxtEqual 'features/editor' $meta.Domain 'Application-domain detection failed for a nested directory'
  }
  Invoke-CzxtContract 'Six renderer test assets are copied byte-for-byte into the instance' {
    $relativeRoot='能力资产/tools/scripts/check-os/tests'
    $project=Join-Path $fixtureRoot 'double'
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $template $relativeRoot) -Filter 'installer-render-*.ps1') {
      Assert-CzxtTrue (([Convert]::ToBase64String([IO.File]::ReadAllBytes($file.FullName))) -ceq `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $project ($relativeRoot+'/'+$file.Name)))))) `
        ('Project parameters rewrote a test asset: '+$file.Name)
    }
  }
  Invoke-CzxtContract 'Force preserves source, item, and unknown files without parsing their content' {
    $project = Join-Path $fixtureRoot 'normal'
    $protected = @('借鉴区/来源/user/raw.json', '借鉴区/事项/user/raw.ps1', '能力资产/user-owned.json')
    foreach ($relative in $protected) { Write-CzxtNoBomText (Join-Path $project $relative) 'user={{PROJECT_NAME}}; deliberately not JSON or PowerShell {' }
    $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName 'Force"项目' -Force
    Assert-CzxtEqual 0 $result.ExitCode ('Force failed: ' + $result.StdErr)
    foreach ($relative in $protected) {
      Assert-CzxtEqual 'user={{PROJECT_NAME}}; deliberately not JSON or PowerShell {' ([IO.File]::ReadAllText((Join-Path $project $relative))) 'Protected or unknown files were rewritten or included in format validation'
    }
  }
  Invoke-CzxtContract 'Existing managed files still reject overwrite without Force' {
    $project = Join-Path $fixtureRoot 'double'
    $path = Join-Path $project '.codex/hooks.json'
    $before = [IO.File]::ReadAllText($path)
    $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName '不应覆盖'
    Assert-CzxtTrue ($result.ExitCode -ne 0) 'Overwrite was accepted without Force'
    Assert-CzxtEqual $before ([IO.File]::ReadAllText($path)) 'Managed file was overwritten before rejection'
  }
  foreach ($extension in @('json', 'ps1')) {
    Invoke-CzxtContract ('Corrupted managed ' + $extension + ' must prohibit a success marker') {
      $bad = Join-Path $template ('能力资产/broken.' + $extension)
      $content = if ($extension -eq 'json') { '{bad-json' } else { 'function Broken {' }
      Write-CzxtText $bad $content $script:CzxtUtf8Bom
      try {
        $project = Join-Path $fixtureRoot ('invalid-' + $extension)
        $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName '失败测试' -AppRepoDir 'app'
        Assert-CzxtTrue ($result.ExitCode -ne 0) 'Invalid managed file still reported success'
        Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $project '.czxt-project-root'))) 'Success marker was written despite validation failure'
      }
      finally { Remove-Item -LiteralPath $bad -Force }
    }
  }
  Invoke-CzxtContract 'Out-of-bounds paths are still rejected before writing to disk' {
    $project = Join-Path $fixtureRoot 'escape'
    $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName '越界测试' -AppRepoDir '../outside'
    Assert-CzxtTrue ($result.ExitCode -ne 0) 'Out-of-bounds path was accepted'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $project)) 'Project root was created before the out-of-bounds path was rejected'
  }
}
finally { Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot }
Complete-CzxtContracts
