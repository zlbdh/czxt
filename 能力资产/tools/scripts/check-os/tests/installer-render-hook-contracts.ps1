[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot '../../installer-render-text.ps1')
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../'))
$fixtureParent = Join-Path $env:TEMP 'czxt-installer-render-hooks'
$fixtureRoot = Join-Path $fixtureParent ([guid]::NewGuid().ToString('N'))
$tempRoot = Join-Path $fixtureRoot 'temp'
[void][IO.Directory]::CreateDirectory($tempRoot)
try {
  foreach ($relative in @('能力资产/tools/hooks/run-hooks.ps1',
      '能力资产/tools/hooks/chat-output/check-chat-summary.ps1')) {
    $target = Join-Path $fixtureRoot $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy((Join-Path $sourceRoot $relative), $target)
  }
  $manifest = [IO.File]::ReadAllText((Join-Path $sourceRoot '能力资产/tools/hooks/manifest.json')) | ConvertFrom-Json
  $manifest.hooks = @($manifest.hooks | Where-Object { $_.id -eq 'chat-summary-check' })
  Write-CzxtNoBomText (Join-Path $fixtureRoot '能力资产/tools/hooks/manifest.json') ($manifest | ConvertTo-Json -Depth 20)
  foreach ($kind in @('codex', 'claude')) {
    Invoke-CzxtContract ($kind + ': 嵌套业务目录的Stop真实检查和临时文件清理') {
      $relative = '能力资产/tools/hooks/' + $kind + '/stop-chat-summary.ps1'
      $source = [IO.File]::ReadAllText((Join-Path $sourceRoot $relative))
      $text = ConvertTo-CzxtInstallerRenderedText $source '.ps1' @{ PROJECT_NAME='我的"项目'; APP_REPO_DIR='frontend/app' }
      $target = Join-Path $fixtureRoot $relative
      Write-CzxtText $target $text $script:CzxtUtf8Bom
      $start = New-Object Diagnostics.ProcessStartInfo
      $start.FileName = 'powershell.exe'
      $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $target, '-Root', $fixtureRoot)
      $start.Arguments = ($arguments | ForEach-Object { Quote-CzxtProcessArgument $_ }) -join ' '
      $start.UseShellExecute=$false; $start.CreateNoWindow=$true
      $start.RedirectStandardInput=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
      $start.StandardOutputEncoding=$script:CzxtUtf8NoBom
      $start.StandardErrorEncoding=$script:CzxtUtf8NoBom
      $start.EnvironmentVariables['TEMP']=$tempRoot; $start.EnvironmentVariables['TMP']=$tempRoot
      $process = New-Object Diagnostics.Process
      $process.StartInfo=$start
      try {
        $previousInputEncoding = [Console]::InputEncoding
        try {
          [Console]::InputEncoding = $script:CzxtUtf8NoBom
          [void]$process.Start()
        }
        finally { [Console]::InputEncoding = $previousInputEncoding }
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        # WinPS 5.1没有StandardInputEncoding，启动时显式绑定无BOM编码。
        $inputBytes = [Text.Encoding]::ASCII.GetBytes('{"last_assistant_message":"\u5df2\u4fee\u6539\u6587\u4ef6\uff0c\u6d4b\u8bd5\u901a\u8fc7\u3002"}')
        $process.StandardInput.BaseStream.Write($inputBytes, 0, $inputBytes.Length)
        $process.StandardInput.BaseStream.Close()
        if (-not $process.WaitForExit(15000)) {
          $null = Stop-CzxtTimedOutProcessTree $process $stdout $stderr
          throw 'Stop hook超时'
        }
        $output=Receive-CzxtAsyncText $stdout 'stdout'; $errorText=Receive-CzxtAsyncText $stderr 'stderr'
        Assert-CzxtEqual 0 $process.ExitCode ('Stop退出失败: ' + $errorText)
        $result = $output | ConvertFrom-Json
        Assert-CzxtEqual 'block' $result.decision ('未实际检查缺失交接卡: ' + $output + '; stderr=' + $errorText)
        Assert-CzxtTrue ($result.reason.Contains('我的"项目')) 'Stop理由中的名称未逐字保留'
        Assert-CzxtEqual 0 @(Get-ChildItem -LiteralPath $tempRoot -Force).Count 'Stop泄漏了临时文件'
      }
      finally { $process.Dispose() }
    }
  }
}
finally { Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $fixtureRoot }
Complete-CzxtContracts
