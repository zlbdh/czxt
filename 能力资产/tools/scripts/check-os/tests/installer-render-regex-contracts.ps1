[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'installer-render-support.ps1')
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../'))
$fixtureParent = Join-Path $env:TEMP 'czxt-installer-render-regex'
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixtureRoot)
try {
  $template = New-InstallerRenderFixture $sourceRoot $fixtureRoot
  $checkSource = Join-Path $sourceRoot '能力资产/tools/scripts/check-os'
  $checkTarget = Join-Path $template '能力资产/tools/scripts/check-os'
  foreach ($file in Get-ChildItem -LiteralPath $checkSource -File | Where-Object {
      $_.Name -like 'p4k-*.ps1' -or $_.Name -like 'p4m-*.ps1' -or
      $_.Name -in @('p4b-file-size.ps1', 'framework-scope.ps1') }) {
    [IO.File]::Copy($file.FullName, (Join-Path $checkTarget $file.Name))
  }
  $project = Join-Path $fixtureRoot 'instance'
  $install = Invoke-InstallerRenderFixture $template $project '演示§$()[x]' 'frontend.v2/app'
  Assert-CzxtEqual 0 $install.ExitCode ('正则回归实例化失败: ' + $install.StdErr)
  $scripts = Join-Path $project '能力资产/tools/scripts/check-os'
  . (Join-Path $project '能力资产/tools/scripts/installer-render-text.ps1')
  $gitDoc = Join-Path $project '操作系统/07_完整工作流/git流程.md'
  Write-CzxtNoBomText $gitDoc ('```bash' + "`n" + 'cd D:\WGKJ\演示§$()[x]\frontend.v2/app')
  Invoke-CzxtContract '实例P4k按字面名称识别含美元括号方括号的旧路径' {
    $result = Invoke-CzxtPowerShell (Join-Path $scripts 'p4k-entry-anchor-legacy.ps1') @('-Root', $project)
    Assert-CzxtEqual 10 $result.ExitCode '名称元字符导致P4k漏检真实旧路径'
  }
  Write-CzxtNoBomText $gitDoc ('```bash' + "`n" + 'cd D:\WGKJ\演示OTHER\frontend.v2/app')
  Invoke-CzxtContract '项目名分隔符不能截短P4k行协议中的正则' {
    $result=Invoke-CzxtPowerShell (Join-Path $scripts 'p4k-entry-anchor-legacy.ps1') @('-Root',$project)
    Assert-CzxtEqual 0 $result.ExitCode '项目名中的§截短正则并误命中另一个项目'
  }
  Write-CzxtNoBomText $gitDoc '正常内容'
  $rulesDoc = Join-Path $project '能力资产/skills/项目体检-检查项-5-6.md'
  Write-CzxtNoBomText $rulesDoc 'Windows/Codex 为 D:\WGKJ\演示§$()[x]，Cowork'
  Invoke-CzxtContract '实例P4m按字面名称识别真实旧说明' {
    $result = Invoke-CzxtPowerShell (Join-Path $scripts 'p4m-rules-command.ps1') @('-Root', $project)
    Assert-CzxtEqual 10 $result.ExitCode '名称元字符导致P4m漏检真实旧说明'
  }
  Write-CzxtNoBomText $rulesDoc '正常内容'
  foreach ($relative in @('状态推断.md', '状态推断-推断项.md', '状态推断-跨session监控.md', '状态推断-跨session监控-附录.md')) {
    Write-CzxtNoBomText (Join-Path $project ('能力资产/skills/' + $relative)) '正常内容'
  }
  $skillsDoc = Join-Path $project '能力资产/skills/项目体检-检查项-1-4-附录.md'
  $productDoc = Join-Path $project '操作系统/02_智能体/产品PM-需求拆解者.md'
  foreach ($case in @(@{ App='frontendXv2/app'; Want=0 }, @{ App='frontend.v2/app'; Want=10 })) {
    Write-CzxtNoBomText $skillsDoc ('find ' + $case.App + '/src 操作系统 能力资产 -type f -exec wc -c')
    Write-CzxtNoBomText $productDoc ($case.App + '/__tests__')
    Invoke-CzxtContract ('实例P4m目录点号为字面量: ' + $case.App) {
      $result = Invoke-CzxtPowerShell (Join-Path $scripts 'p4m-skills-command.ps1') @('-Root', $project)
      Assert-CzxtEqual $case.Want $result.ExitCode ('P4m业务目录正则语义改变: ' + $result.StdErr)
    }
    Invoke-CzxtContract ('实例P4k目录点号为字面量: ' + $case.App) {
      $result = Invoke-CzxtPowerShell (Join-Path $scripts 'p4k-tool-subject-legacy.ps1') @('-Root', $project)
      Assert-CzxtEqual $case.Want $result.ExitCode ('P4k业务目录正则语义改变: ' + $result.StdErr)
    }
  }
  Invoke-CzxtContract '实例P4b对带点多层目录真实扫描并归类' {
    Write-CzxtNoBomText (Join-Path $project 'frontend.v2/app/src/features/editor/large.ts') ('x' * 8000)
    $result = Invoke-CzxtPowerShell (Join-Path $scripts 'p4b-file-size.ps1') @('-Root', $project)
    Assert-CzxtEqual 0 $result.ExitCode ('P4b扫描失败: ' + $result.StdErr)
    Assert-CzxtTrue ($result.StdOut.Contains('features/editor: 1')) 'P4b未把真实业务文件归到editor域'
  }
  foreach ($appDir in @('frontend/app{0}', 'frontend/app{1}')) {
    Invoke-CzxtContract ('实例P4b格式输出逐字保留业务路径: ' + $appDir) {
      $source=[IO.File]::ReadAllText((Join-Path $template '能力资产/tools/scripts/check-os/p4b-file-size.ps1'))
      $rendered=ConvertTo-CzxtInstallerRenderedText $source '.ps1' @{APP_REPO_DIR=$appDir}
      Write-CzxtText (Join-Path $scripts 'p4b-file-size.ps1') $rendered $script:CzxtUtf8Bom
      $result=Invoke-CzxtPowerShell (Join-Path $scripts 'p4b-file-size.ps1') @('-Root',$project)
      Assert-CzxtEqual 0 $result.ExitCode ('P4b格式输出异常: '+$result.StdErr)
      Assert-CzxtTrue ($result.StdOut.Contains('文件 ('+$appDir+'/src + 操作系统 + 能力资产)')) 'P4b再次解释了路径中的格式占位符'
    }
  }
}
finally { Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot }
Complete-CzxtContracts
