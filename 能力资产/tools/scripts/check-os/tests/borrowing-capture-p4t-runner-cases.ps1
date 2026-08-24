[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function Set-BorrowingFixtureP4tScript {
  param([string]$Root, [string]$Content)
  $path = Join-Path $Root '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1'
  Write-CzxtText $path $Content $script:CzxtUtf8Bom
  return $path
}

function New-BorrowingP4tFixtureRoot {
  param(
    [string]$Name,
    [ValidateSet('project', 'template', 'unknown', 'conflict')]
    [string]$Mode = 'project',
    [int]$P4tExitCode = 0
  )
  $root = New-BorrowingFixtureRoot $Name $Mode $P4tExitCode
  Write-CzxtText (Join-Path $root `
      '能力资产\tools\scripts\check-os\p4t\fixture-helper.ps1') `
    "`$ErrorActionPreference = 'Stop'`n" $script:CzxtUtf8Bom
  Write-CzxtText (Join-Path $root `
      '能力资产\tools\scripts\borrowing-capture\fixture-dependency.ps1') `
    "`$ErrorActionPreference = 'Stop'`n" $script:CzxtUtf8Bom
  return $root
}

function Replace-BorrowingFixtureP4tHelper {
  param([string]$Root)
  $target = Join-Path $Root `
    '能力资产\tools\scripts\check-os\p4t\fixture-helper.ps1'
  $replacement = $target + '.replacement'
  $backup = $target + '.backup'
  Write-CzxtText $replacement "`$ErrorActionPreference = 'Continue'`n" `
    $script:CzxtUtf8Bom
  [IO.File]::Replace($replacement, $target, $backup)
  if (Test-Path -LiteralPath $backup -PathType Leaf) {
    Remove-Item -LiteralPath $backup -Force
  }
}

function Assert-BorrowingP4tProjectionFailure {
  param([scriptblock]$Body, [string]$Stage, [string]$Projection)
  $caught = $null
  try { & $Body }
  catch { $caught = $_.Exception }
  Assert-CzxtTrue ($null -ne $caught) ('expected P4t failure: ' + $Projection)
  Assert-CzxtEqual $Stage ([string]$caught.Data['BorrowingStage']) `
    ($Projection + ' stage')
  Assert-CzxtEqual 'p4t-process-failed' `
    ([string]$caught.Data['BorrowingReasonCode']) ($Projection + ' reason')
  Assert-CzxtEqual $Projection `
    ([string]$caught.Data['BorrowingP4tProjection']) ($Projection + ' projection')
}

Initialize-BorrowingCaptureFixture
try {
  $script:P4tRunnerReady = $false
  Invoke-CzxtContract 'capture P4t runner helper exists' {
    Import-BorrowingCaptureModules @('p4t-runner', 'process', 'file-safety', 'common')
    foreach ($name in @(
        'New-BorrowingP4tProcessSpec', 'Invoke-BorrowingP4tGateCore',
        'Invoke-BorrowingP4tGate'
      )) { Assert-BorrowingCommandExists $name }
    $script:P4tRunnerReady = $true
  }
  if ($script:P4tRunnerReady) {
    Invoke-CzxtContract 'P4t production spec freezes executable argv limits and script path' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-spec-root' project
      $spec = $null
      try {
        $spec = New-BorrowingP4tProcessSpec -Root $root
        Assert-CzxtEqual 'czxt-borrowing-p4t-process/v1' $spec.Schema 'P4t spec schema'
        Assert-CzxtEqual ([IO.Path]::GetFullPath((Join-Path $PSHOME 'powershell.exe'))) `
          $spec.ExecutablePath 'P4t executable'
        Assert-CzxtEqual ([IO.Path]::GetFullPath((Join-Path $root `
              '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1'))) `
          $spec.ScriptPath 'P4t fixed script'
        Assert-CzxtEqual 120000 $spec.TimeoutMilliseconds 'P4t timeout'
        Assert-CzxtEqual 1048576 $spec.StdOutLimitBytes 'P4t stdout limit'
        Assert-CzxtEqual 1048576 $spec.StdErrLimitBytes 'P4t stderr limit'
        $expected = @(
          '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
          '-File', $spec.ScriptPath, '-Root', $spec.Root
        )
        Assert-CzxtEqual ($expected -join [char]0x1F) `
          ($spec.Arguments -join [char]0x1F) 'P4t argv'
        $sealedPaths = @($spec.ComponentSeal.Items | ForEach-Object { $_.Path })
        foreach ($relative in @(
            '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1',
            '能力资产\tools\scripts\check-os\p4t\fixture-helper.ps1',
            '能力资产\tools\scripts\borrowing-capture\fixture-dependency.ps1'
          )) {
          Assert-CzxtTrue ($sealedPaths -contains ([IO.Path]::GetFullPath(
                (Join-Path $root $relative)))) ('sealed P4t component ' + $relative)
        }
      }
      finally {
        if ($null -ne $spec) {
          Close-BorrowingP4tComponentSeal $spec.ComponentSeal
        }
      }
    }


    Invoke-CzxtContract 'P4t component handles span both gates then close' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-seal-lifecycle-root' project
      $spec = New-BorrowingP4tProcessSpec $root
      try {
        $before = Invoke-BorrowingP4tGateCore $spec 'p4t-before'
        Assert-CzxtEqual 0 $before.ExitCode 'P4t seal before exit'
        $blocked = $false
        try { Replace-BorrowingFixtureP4tHelper $root }
        catch [IO.IOException] { $blocked = $true }
        Assert-CzxtEqual $true $blocked 'P4t helper replacement while sealed'
        $after = Invoke-BorrowingP4tGateCore $spec 'p4t-after'
        Assert-CzxtEqual 0 $after.ExitCode 'P4t seal after exit'
        Replace-BorrowingFixtureP4tHelper $root
      }
      finally {
        if (Get-Command Close-BorrowingP4tComponentSeal -CommandType Function `
            -ErrorAction SilentlyContinue) {
          Close-BorrowingP4tComponentSeal $spec.ComponentSeal
        }
      }
    }

    Invoke-CzxtContract 'P4t gate rejects a component replaced after process exit' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-seal-post-root' project
      $spec = New-BorrowingP4tProcessSpec $root
      $helper = Join-Path $root `
        '能力资产\tools\scripts\check-os\p4t\fixture-helper.ps1'
      $item = @($spec.ComponentSeal.Items | Where-Object {
          $_.Path.Equals($helper, [StringComparison]::OrdinalIgnoreCase)
        })[0]
      $script:BorrowingP4tSealTestInjections = @{
        'after-process-exit-before-verify' = {
          $item.Stream.Dispose()
          Replace-BorrowingFixtureP4tHelper $root
        }.GetNewClosure()
      }
      try {
        Assert-BorrowingFailureCode {
          Invoke-BorrowingP4tGateCore $spec 'p4t-before'
        } 'p4t-before' 'trusted-component-changed'
      }
      finally {
        $script:BorrowingP4tSealTestInjections = $null
        if (Get-Command Close-BorrowingP4tComponentSeal -CommandType Function `
            -ErrorAction SilentlyContinue) {
          Close-BorrowingP4tComponentSeal $spec.ComponentSeal
        }
      }
    }

    Invoke-CzxtContract 'P4t standalone wrapper closes its component handles' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-seal-standalone-root' project
      $actual = Invoke-BorrowingP4tGate $root 'p4t-before'
      Assert-CzxtEqual 0 $actual.ExitCode 'P4t standalone exit'
      Replace-BorrowingFixtureP4tHelper $root
    }

    Invoke-CzxtContract 'P4t wrapper preserves every normal integer exit code' {
      foreach ($exitCode in @(0, 5, 10, 37)) {
        $root = New-BorrowingP4tFixtureRoot ('p4t-exit-' + $exitCode) project $exitCode
        $actual = Invoke-BorrowingP4tGate -Root $root -Stage 'p4t-before'
        Assert-CzxtEqual 'exited' $actual.Outcome ('P4t outcome ' + $exitCode)
        Assert-CzxtEqual $exitCode $actual.ExitCode ('P4t exit ' + $exitCode)
        Assert-CzxtEqual ([string]$exitCode) $actual.Projection ('P4t projection ' + $exitCode)
      }
    }

    Invoke-CzxtContract 'P4t core maps byte overflow invalid UTF-8 and NUL to process failure' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-output-root' project
      $scriptPath = Set-BorrowingFixtureP4tScript $root @'
param([string]$Root)
$stream = [Console]::OpenStandardOutput()
$bytes = [Text.Encoding]::UTF8.GetBytes(('x' * 1025))
$stream.Write($bytes, 0, $bytes.Length)
'@
      $spec = New-BorrowingP4tProcessSpec $root
      $spec.StdOutLimitBytes = 1024
      Assert-BorrowingFailureCode {
        Invoke-BorrowingP4tGateCore -Spec $spec -Stage 'p4t-before'
      } 'p4t-before' 'p4t-process-failed'

      [void](Set-BorrowingFixtureP4tScript $root @'
param([string]$Root)
$stream = [Console]::OpenStandardOutput()
$bytes = [byte[]](0xFF)
$stream.Write($bytes, 0, 1)
'@)
      $spec = New-BorrowingP4tProcessSpec $root
      Assert-BorrowingFailureCode {
        Invoke-BorrowingP4tGateCore $spec 'p4t-before'
      } 'p4t-before' 'p4t-process-failed'

      [void](Set-BorrowingFixtureP4tScript $root @'
param([string]$Root)
$stream = [Console]::OpenStandardOutput()
$bytes = [byte[]](0x61,0x00,0x62)
$stream.Write($bytes, 0, $bytes.Length)
'@)
      $spec = New-BorrowingP4tProcessSpec $root
      Assert-BorrowingFailureCode {
        Invoke-BorrowingP4tGateCore $spec 'p4t-after'
      } 'p4t-after' 'p4t-process-failed'
    }

    Invoke-CzxtContract 'P4t core projects a process start failure explicitly' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-start-failure-root' project
      $spec = New-BorrowingP4tProcessSpec $root
      $spec.ExecutablePath = Join-Path $root 'missing-powershell.exe'
      Assert-BorrowingP4tProjectionFailure {
        Invoke-BorrowingP4tGateCore $spec 'p4t-before'
      } 'p4t-before' 'start-failed'
    }

    Invoke-CzxtContract 'P4t core timeout kills its process tree and returns no child detail' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-timeout-root' project
      $parentPid = Join-Path $root 'parent.pid'
      $childPid = Join-Path $root 'child.pid'
      [void](Set-BorrowingFixtureP4tScript $root @"
param([string]`$Root)
[IO.File]::WriteAllText('$($parentPid.Replace("'", "''"))', [string]`$PID)
`$child = Start-Process -FilePath (Join-Path `$PSHOME 'powershell.exe') -ArgumentList @(
  '-NoLogo','-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 30'
) -WindowStyle Hidden -PassThru
[IO.File]::WriteAllText('$($childPid.Replace("'", "''"))', [string]`$child.Id)
Start-Sleep -Seconds 30
"@)
      $spec = New-BorrowingP4tProcessSpec $root
      $spec.TimeoutMilliseconds = 1000
      Assert-BorrowingP4tProjectionFailure {
        Invoke-BorrowingP4tGateCore $spec 'p4t-after'
      } 'p4t-after' 'timeout'
      foreach ($path in @($parentPid, $childPid)) {
        Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) 'P4t timeout pid file'
        $processId = [int][IO.File]::ReadAllText($path)
        $deadline = [DateTime]::UtcNow.AddSeconds(5)
        do {
          $running = $null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)
          if ($running) { Start-Sleep -Milliseconds 100 }
        } while ($running -and [DateTime]::UtcNow -lt $deadline)
        Assert-CzxtEqual $false $running ('P4t process survived ' + $processId)
      }
    }

    Invoke-CzxtContract 'P4t wrapper rejects a missing fixed trusted script before starting' {
      $root = New-BorrowingP4tFixtureRoot 'p4t-missing-root' project
      Remove-Item -LiteralPath (Join-Path $root `
          '能力资产\tools\scripts\check-os\p4t-borrowing-consistency.ps1') -Force
      Assert-BorrowingFailureCode {
        Invoke-BorrowingP4tGate $root 'p4t-before'
      } 'preflight' 'missing-trusted-component'
    }

    Invoke-CzxtContract 'failed input preflight does not create a P4t component seal' {
      . (Join-Path $script:BorrowingCaptureModuleRoot `
        'orchestrator-preparation.ps1')
      $root = New-BorrowingP4tFixtureRoot 'p4t-preflight-order-root' project
      $script:P4tPreflightSpecCalls = 0
      function global:New-BorrowingP4tProcessSpec {
        param([string]$Root)
        $script:P4tPreflightSpecCalls++
        return [pscustomobject]@{ ComponentSeal = [pscustomobject]@{} }
      }
      function global:Assert-BorrowingCaptureIgnoreContract {
        param([string]$Root)
        Throw-BorrowingFailure preflight missing-trusted-component `
          'injected ignore preflight failure'
      }
      $caught = $null
      try {
        [void](Initialize-BorrowingPreparedInput ([pscustomobject]@{
              Root = $root; SourceType = 'local'
            }))
      }
      catch { $caught = $_.Exception }
      Assert-CzxtTrue ($null -ne $caught) 'injected preflight did not fail'
      Assert-CzxtEqual 0 $script:P4tPreflightSpecCalls `
        'P4t component seal was created before fallible input preflight'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
