[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-git-test-support.ps1')

function Assert-BorrowingStringArrayEqual {
  param([string[]]$Expected, [string[]]$Actual, [string]$Context)
  Assert-CzxtEqual $Expected.Count $Actual.Count ($Context + ' count')
  for ($index = 0; $index -lt $Expected.Count; $index++) {
    Assert-CzxtEqual $Expected[$index] $Actual[$index] ($Context + ' item ' + $index)
  }
}

Initialize-BorrowingCaptureFixture
try {
  $script:GitRunnerReady = $false
  Invoke-CzxtContract 'capture Git runner helper exists' {
    Import-BorrowingGitRunnerTestModules
    $script:GitRunnerReady = $true
  }
  if ($script:GitRunnerReady) {
    Invoke-CzxtContract 'Git runner freezes executable directories environment and argv prefix' {
      $staging = Join-Path $script:BorrowingCaptureFixtureRoot 'runner-staging'
      [void](New-Item -ItemType Directory -Path $staging)
      $resolved = Resolve-BorrowingGitExecutable
      Assert-CzxtTrue ([IO.Path]::IsPathRooted($resolved.Path)) 'Git executable absolute path'
      Assert-CzxtTrue ($resolved.Version -ge [Version]'2.43.0') 'Git minimum version'
      $runner = New-BorrowingGitRunner -ExecutablePath $resolved.Path -StagingPath $staging
      Assert-CzxtEqual 'czxt-borrowing-git-runner/v1' $runner.Schema 'Git runner schema'
      Assert-CzxtTrue $runner.WorkingDirectory.StartsWith($runner.RunnerRoot + '\') `
        'Git runner cwd boundary'
      Assert-CzxtTrue $runner.Home.StartsWith($staging + '\') 'Git runner HOME boundary'
      Assert-CzxtTrue $runner.TrustedEmptyDirectory.StartsWith($staging + '\') `
        'Git trusted empty boundary'
      Assert-CzxtEqual 300000 $runner.TimeoutMilliseconds 'Git timeout'
      Assert-CzxtEqual 67108864 $runner.StdOutLimitBytes 'Git stdout limit'
      Assert-CzxtEqual 67108864 $runner.StdErrLimitBytes 'Git stderr limit'
      $expectedEnvironment = @{
        GIT_TERMINAL_PROMPT = '0'; GIT_CONFIG_NOSYSTEM = '1'; GIT_CONFIG_GLOBAL = 'NUL'
        GIT_CONFIG_SYSTEM = 'NUL'; GIT_LFS_SKIP_SMUDGE = '1'; GIT_PROTOCOL_FROM_USER = '0'
        GIT_ALLOW_PROTOCOL = 'https'; GIT_NO_REPLACE_OBJECTS = '1'; GIT_OPTIONAL_LOCKS = '0'
        LC_ALL = 'C'; LANG = 'C'
      }
      foreach ($key in $expectedEnvironment.Keys) {
        Assert-CzxtEqual $expectedEnvironment[$key] $runner.Environment[$key] `
          ('Git environment ' + $key)
      }
      Assert-CzxtEqual $runner.RunnerRoot $runner.Environment['GIT_CEILING_DIRECTORIES'] `
        'Git ceiling directory'
      foreach ($key in @('HOME', 'USERPROFILE', 'XDG_CONFIG_HOME')) {
        Assert-CzxtEqual $runner.Home $runner.Environment[$key] ('Git isolated ' + $key)
      }
      $expectedPrefix = @(
        '--no-pager', '-c', 'credential.helper=', '-c', 'core.askPass=',
        '-c', ('core.hooksPath=' + $runner.TrustedEmptyDirectory),
        '-c', 'filter.lfs.clean=', '-c', 'filter.lfs.smudge=',
        '-c', 'filter.lfs.process=', '-c', 'filter.lfs.required=false',
        '-c', 'submodule.recurse=false', '-c', 'fetch.recurseSubmodules=false',
        '-c', 'protocol.file.allow=never', '-c', 'protocol.ext.allow=never',
        '-c', 'maintenance.auto=false', '-c', 'gc.auto=0',
        '-c', 'http.sslVerify=true', '-c', 'http.followRedirects=false',
        '-c', 'http.extraHeader='
      )
      Assert-BorrowingStringArrayEqual $expectedPrefix $runner.ArgvPrefix 'Git argv prefix'
    }

    Invoke-CzxtContract 'Git runner ignores parent local global and inherited askpass configuration' {
      $staging = Join-Path $script:BorrowingCaptureFixtureRoot 'isolation-staging'
      [void](New-Item -ItemType Directory -Path $staging)
      $askpassMarker = Join-Path $staging 'askpass.marker'
      $askpass = Join-Path $staging 'askpass.cmd'
      Write-CzxtNoBomText $askpass (('@echo marker>"{0}"' -f $askpassMarker) + "`r`n")
      $hostileGlobal = Join-Path $staging 'hostile.gitconfig'
      Write-CzxtNoBomText $hostileGlobal "[czxt]`n`tglobal = visible`n[http]`n`tsslVerify = false`n"
      $oldGlobal = $env:GIT_CONFIG_GLOBAL
      $oldAskpass = $env:SSH_ASKPASS
      $oldMixed = $env:GiT_CZXT_INHERITED
      try {
        $env:GIT_CONFIG_GLOBAL = $hostileGlobal
        $env:SSH_ASKPASS = $askpass
        $env:GiT_CZXT_INHERITED = 'must-not-survive'
        $resolved = Resolve-BorrowingGitExecutable
        $runner = New-BorrowingGitRunner $resolved.Path $staging
      }
      finally {
        $env:GIT_CONFIG_GLOBAL = $oldGlobal
        $env:SSH_ASKPASS = $oldAskpass
        $env:GiT_CZXT_INHERITED = $oldMixed
      }
      [void](New-Item -ItemType Directory -Path (Join-Path $runner.RunnerRoot '.git') -Force)
      Write-CzxtNoBomText (Join-Path $runner.RunnerRoot '.git\config') `
        "[czxt]`n`tparent = visible`n[http]`n`tsslVerify = false`n"
      $parent = Invoke-BorrowingGitRunner $runner @('config', '--get', 'czxt.parent') text
      Assert-CzxtEqual 1 $parent.ExitCode 'parent config discovery exit'
      Assert-CzxtEqual '' $parent.StdOut 'parent config discovery output'
      $global = Invoke-BorrowingGitRunner $runner @('config', '--get', 'czxt.global') text
      Assert-CzxtEqual 1 $global.ExitCode 'global config discovery exit'
      $ssl = Invoke-BorrowingGitRunner $runner @('config', '--get', 'http.sslVerify') text
      Assert-CzxtEqual 0 $ssl.ExitCode 'fixed HTTP config exit'
      Assert-CzxtEqual 'true' $ssl.StdOut.Trim() 'fixed HTTP config value'
      $blocked = Invoke-BorrowingGitRunner $runner `
        @('ls-remote', 'ssh://fixture.invalid/repo.git') text
      Assert-CzxtTrue ($blocked.ExitCode -ne 0) 'SSH protocol unexpectedly allowed'
      Assert-CzxtEqual $false (Test-Path -LiteralPath $askpassMarker) 'askpass marker executed'
      Assert-CzxtEqual 0 @($runner.Environment.Keys | Where-Object {
          $_ -ieq 'GiT_CZXT_INHERITED' -or $_ -ieq 'SSH_ASKPASS'
        }).Count 'hostile inherited environment survived'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
