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
    Invoke-CzxtContract ($case.Id + ': 合法名称和嵌套路径生成可解析文件') {
      Assert-CzxtEqual 0 $install.ExitCode ('installer failed: ' + $install.StdErr)
      Assert-InstallerRenderSyntax $project
      $json = [IO.File]::ReadAllText((Join-Path $project '.codex/hooks.json')) | ConvertFrom-Json
      Assert-CzxtEqual ('加载' + $case.Name + '项目治理上下文') $json.hooks.SessionStart[0].hooks[0].statusMessage 'JSON值必须逐字保留'
      $manifest = [IO.File]::ReadAllText((Join-Path $project '能力资产/tools/hooks/manifest.json')) | ConvertFrom-Json
      $hook = $manifest.hooks | Where-Object { $_.id -eq 'hook-install-check' }
      Assert-CzxtTrue ($hook.description.Contains('frontend/app/.git/hooks')) '业务路径应规范化为正斜杠'
      Assert-CzxtTrue (Test-Path -LiteralPath (Join-Path $project 'frontend/app') -PathType Container) '多层业务目录未创建'
    }
    Invoke-CzxtContract ($case.Id + ': PowerShell字符串运行时保持参数为纯数据') {
      $run = Invoke-CzxtPowerShell -ScriptPath (Join-Path $project '能力资产/sample.ps1')
      Assert-CzxtEqual 0 $run.ExitCode ('sample执行失败: ' + $run.StdErr)
      $values = $run.StdOut | ConvertFrom-Json
      foreach ($property in @('single', 'double', 'singleHere', 'doubleHere')) {
        Assert-CzxtEqual $case.Name $values.$property ($property + '没有逐字保留参数')
      }
    }
  }
  Invoke-CzxtContract 'P4b对嵌套业务目录正确分组且不把目录名当正则' {
    $path = Join-Path $fixtureRoot 'normal/能力资产/tools/scripts/check-os/p4b-size-classification.ps1'
    . $path
    $meta = Get-AppSrcP4bMeta -Rel 'frontend\app\src\features\editor\large.ts'
    Assert-CzxtEqual 'features/editor' $meta.Domain '嵌套目录的业务域识别失败'
  }
  Invoke-CzxtContract '六个renderer自测资产在实例中逐字节复制' {
    $relativeRoot='能力资产/tools/scripts/check-os/tests'
    $project=Join-Path $fixtureRoot 'double'
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $template $relativeRoot) -Filter 'installer-render-*.ps1') {
      Assert-CzxtTrue (([Convert]::ToBase64String([IO.File]::ReadAllBytes($file.FullName))) -ceq `
        ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $project ($relativeRoot+'/'+$file.Name)))))) `
        ('自测资产被项目参数改写: '+$file.Name)
    }
  }
  Invoke-CzxtContract 'Force保留来源事项和未知文件且不解析其内容' {
    $project = Join-Path $fixtureRoot 'normal'
    $protected = @('借鉴区/来源/user/raw.json', '借鉴区/事项/user/raw.ps1', '能力资产/user-owned.json')
    foreach ($relative in $protected) { Write-CzxtNoBomText (Join-Path $project $relative) 'user={{PROJECT_NAME}}; deliberately not JSON or PowerShell {' }
    $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName 'Force"项目' -Force
    Assert-CzxtEqual 0 $result.ExitCode ('Force失败: ' + $result.StdErr)
    foreach ($relative in $protected) {
      Assert-CzxtEqual 'user={{PROJECT_NAME}}; deliberately not JSON or PowerShell {' ([IO.File]::ReadAllText((Join-Path $project $relative))) '受保护/未知文件被改写或纳入格式校验'
    }
  }
  Invoke-CzxtContract '未指定Force时仍拒绝覆盖既有受管文件' {
    $project = Join-Path $fixtureRoot 'double'
    $path = Join-Path $project '.codex/hooks.json'
    $before = [IO.File]::ReadAllText($path)
    $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName '不应覆盖'
    Assert-CzxtTrue ($result.ExitCode -ne 0) '未指定Force仍接受覆盖'
    Assert-CzxtEqual $before ([IO.File]::ReadAllText($path)) '拒绝前覆盖了受管文件'
  }
  foreach ($extension in @('json', 'ps1')) {
    Invoke-CzxtContract ('损坏的受管' + $extension + '禁止成功标记') {
      $bad = Join-Path $template ('能力资产/broken.' + $extension)
      $content = if ($extension -eq 'json') { '{bad-json' } else { 'function Broken {' }
      Write-CzxtText $bad $content $script:CzxtUtf8Bom
      try {
        $project = Join-Path $fixtureRoot ('invalid-' + $extension)
        $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName '失败测试' -AppRepoDir 'app'
        Assert-CzxtTrue ($result.ExitCode -ne 0) '非法受管文件仍报告成功'
        Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $project '.czxt-project-root'))) '验证失败仍写入成功marker'
      }
      finally { Remove-Item -LiteralPath $bad -Force }
    }
  }
  Invoke-CzxtContract '路径越界仍在落盘前拒绝' {
    $project = Join-Path $fixtureRoot 'escape'
    $result = Invoke-InstallerRenderFixture -TemplateRoot $template -ProjectRoot $project -ProjectName '越界测试' -AppRepoDir '../outside'
    Assert-CzxtTrue ($result.ExitCode -ne 0) '接受了越界路径'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $project)) '越界拒绝前已创建项目根'
  }
}
finally { Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot }
Complete-CzxtContracts
