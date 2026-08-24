[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function Write-BorrowingProcessFixtureScript {
  param([string]$Name, [string]$Content)
  $path = Join-Path $script:BorrowingCaptureFixtureRoot $Name
  Write-CzxtText $path $Content $script:CzxtUtf8Bom
  return $path
}

function Invoke-BorrowingProcessFixture {
  param(
    [string]$ScriptPath,
    [int]$TimeoutMilliseconds = 10000,
    [int]$StdOutLimitBytes = 1048576,
    [int]$StdErrLimitBytes = 1048576,
    [bool]$AllowStdOutNul = $false
  )
  $environment = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
    -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') -Overrides @{}
  return Invoke-BorrowingBoundedProcess `
    -Executable (Join-Path $PSHOME 'powershell.exe') `
    -ArgumentList @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $ScriptPath) `
    -WorkingDirectory $script:BorrowingCaptureFixtureRoot `
    -EnvironmentVariables $environment `
    -TimeoutMilliseconds $TimeoutMilliseconds `
    -StdOutLimitBytes $StdOutLimitBytes `
    -StdErrLimitBytes $StdErrLimitBytes `
    -AllowStdOutNul:$AllowStdOutNul `
    -Stage 'capture' -TimeoutReasonCode 'resource-limit' `
    -FailureReasonCode 'capture-failed'
}

Initialize-BorrowingCaptureFixture
try {
  $script:ProcessHelperReady = $false
  Invoke-CzxtContract 'capture process helper exists with bounded-process primitives' {
    Import-BorrowingCaptureModules @('process', 'common')
    foreach ($name in @(
        'ConvertTo-BorrowingWindowsArgument', 'New-BorrowingProcessEnvironment',
        'Invoke-BorrowingBoundedProcess'
      )) { Assert-BorrowingCommandExists $name }
    $script:ProcessHelperReady = $true
  }

  if ($script:ProcessHelperReady) {
    Invoke-CzxtContract 'Windows argv quoting preserves empty quote and trailing-backslash arguments' {
      $cases = @(
        @('', '""'),
        @('plain', 'plain'),
        @('two words', '"two words"'),
        @('a"b', '"a\"b"'),
        @('C:\space dir\', '"C:\space dir\\"'),
        @('x\\"y', '"x\\\\\"y"')
      )
      foreach ($case in $cases) {
        Assert-CzxtEqual $case[1] (ConvertTo-BorrowingWindowsArgument $case[0]) `
          ('argv quote for <{0}>' -f $case[0])
      }
    }

    Invoke-CzxtContract 'process environment removes Git and askpass variables case-insensitively' {
      $oldGit = $env:GiT_CZXT_MARKER
      $oldAsk = $env:SSH_ASKPASS
      try {
        $env:GiT_CZXT_MARKER = 'must-not-survive'
        $env:SSH_ASKPASS = 'must-not-survive'
        $actual = New-BorrowingProcessEnvironment -RemovePrefixes @('GIT_') `
          -RemoveNames @('SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE') `
          -Overrides @{ GIT_TERMINAL_PROMPT = '0'; CZXT_SAFE = 'yes' }
        $gitMarker = @($actual.Keys | Where-Object {
            $_ -ieq 'GiT_CZXT_MARKER'
          })
        Assert-CzxtEqual 0 $gitMarker.Count 'inherited mixed-case Git variable'
        Assert-CzxtEqual $false $actual.ContainsKey('SSH_ASKPASS') 'inherited askpass'
        Assert-CzxtEqual '0' $actual['GIT_TERMINAL_PROMPT'] 'fixed Git override'
        Assert-CzxtEqual 'yes' $actual['CZXT_SAFE'] 'safe override'
      }
      finally {
        $env:GiT_CZXT_MARKER = $oldGit
        $env:SSH_ASKPASS = $oldAsk
      }
    }

    Invoke-CzxtContract 'bounded process drains stdout and stderr concurrently as strict UTF-8' {
      $scriptPath = Write-BorrowingProcessFixtureScript 'dual-stream.ps1' @'
$stderr = [Console]::OpenStandardError()
$stdout = [Console]::OpenStandardOutput()
$left = [Text.Encoding]::UTF8.GetBytes(('e' * 524288))
$right = [Text.Encoding]::UTF8.GetBytes(('o' * 524288))
$stderr.Write($left, 0, $left.Length)
$stdout.Write($right, 0, $right.Length)
'@
      $result = Invoke-BorrowingProcessFixture $scriptPath
      Assert-CzxtEqual 0 $result.ExitCode 'dual stream exit'
      Assert-CzxtEqual 524288 $result.StdOutBytes.Length 'stdout bytes'
      Assert-CzxtEqual 524288 $result.StdErrBytes.Length 'stderr bytes'
      Assert-CzxtEqual 524288 $result.StdOut.Length 'stdout text'
      Assert-CzxtEqual 524288 $result.StdErr.Length 'stderr text'
    }

    Invoke-CzxtContract 'bounded process rejects overflow invalid UTF-8 and NUL' {
      $overflow = Write-BorrowingProcessFixtureScript 'overflow.ps1' @'
$bytes = [Text.Encoding]::UTF8.GetBytes(('x' * 4097))
$stream = [Console]::OpenStandardOutput()
$stream.Write($bytes, 0, $bytes.Length)
'@
      Assert-BorrowingFailureCode {
        Invoke-BorrowingProcessFixture $overflow 10000 4096 4096
      } 'capture' 'resource-limit'

      $invalid = Write-BorrowingProcessFixtureScript 'invalid-utf8.ps1' @'
$stream = [Console]::OpenStandardOutput()
$bytes = [byte[]](0xFF)
$stream.Write($bytes, 0, 1)
'@
      Assert-BorrowingFailureCode {
        Invoke-BorrowingProcessFixture $invalid
      } 'capture' 'capture-failed'

      $nul = Write-BorrowingProcessFixtureScript 'nul.ps1' @'
$stream = [Console]::OpenStandardOutput()
$bytes = [byte[]](0x61, 0x00, 0x62)
$stream.Write($bytes, 0, $bytes.Length)
'@
      Assert-BorrowingFailureCode {
        Invoke-BorrowingProcessFixture $nul
      } 'capture' 'capture-failed'
    }

    Invoke-CzxtContract 'bounded process timeout kills the spawned process tree' {
      $parentPid = Join-Path $script:BorrowingCaptureFixtureRoot 'parent.pid'
      $childPid = Join-Path $script:BorrowingCaptureFixtureRoot 'child.pid'
      $scriptPath = Write-BorrowingProcessFixtureScript 'timeout-tree.ps1' @"
[IO.File]::WriteAllText('$($parentPid.Replace("'", "''"))', [string]`$PID)
`$child = Start-Process -FilePath (Join-Path `$PSHOME 'powershell.exe') -ArgumentList @(
  '-NoLogo','-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 30'
) -WindowStyle Hidden -PassThru
[IO.File]::WriteAllText('$($childPid.Replace("'", "''"))', [string]`$child.Id)
Start-Sleep -Seconds 30
"@
      Assert-BorrowingFailureCode {
        Invoke-BorrowingProcessFixture $scriptPath 1000 4096 4096
      } 'capture' 'resource-limit'
      foreach ($path in @($parentPid, $childPid)) {
        Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) ('missing pid file ' + $path)
        $processId = [int][IO.File]::ReadAllText($path)
        $deadline = [DateTime]::UtcNow.AddSeconds(5)
        do {
          $running = $null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)
          if ($running) { Start-Sleep -Milliseconds 100 }
        } while ($running -and [DateTime]::UtcNow -lt $deadline)
        Assert-CzxtEqual $false $running ('process survived timeout: ' + $processId)
      }
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
