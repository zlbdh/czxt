[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-test-support.ps1')

Initialize-P4tTestFixture
try {
  $cases = @()
  $cases += [pscustomobject]@{ Name = 'empty template'; Root = New-TemplateSkeleton 'facade-template'; Exit = 0 }
  $cases += [pscustomobject]@{ Name = 'empty project'; Root = New-ProjectSkeleton 'facade-project'; Exit = 0 }
  $unknown = New-ProjectSkeleton 'facade-unknown'
  Remove-Item -LiteralPath (Join-Path $unknown '.czxt-project-root') -Force
  $cases += [pscustomobject]@{ Name = 'unknown mode'; Root = $unknown; Exit = 10 }
  $conflict = New-ProjectSkeleton 'facade-conflict'
  Write-P4tUtf8 (Join-Path $conflict '.czxt-template-root') "czxt-root-mode=template`nschema=1`n"
  $cases += [pscustomobject]@{ Name = 'conflict mode'; Root = $conflict; Exit = 10 }
  $warning = New-ProjectSkeleton 'facade-cache-warning'
  $warningSource = New-P4tSourceCapture $warning local
  Remove-Item -LiteralPath (Join-Path $warningSource.CapturePath '快照') -Recurse -Force
  Remove-Item -LiteralPath (Join-Path $warningSource.CapturePath 'capture.local.json') -Force
  $cases += [pscustomobject]@{ Name = 'ignored local cache absent'; Root = $warning; Exit = 5 }
  $isolated = New-ProjectSkeleton 'facade-isolation-failure'
  Write-P4tUtf8 (Join-Path $isolated 'app\bad.js') "import '../借鉴区/模板/借鉴卡.md';`n"
  $cases += [pscustomobject]@{ Name = 'business dependency'; Root = $isolated; Exit = 10 }
  $untrusted = New-ProjectSkeleton 'facade-untrusted-data'
  $sentinel = Join-Path $untrusted 'sentinel-must-not-exist.txt'
  $payload = "[IO.File]::WriteAllText('$($sentinel.Replace("'", "''"))','executed')"
  [void](New-P4tSourceCapture -Root $untrusted -SourceType web -PayloadText $payload)
  $cases += [pscustomobject]@{ Name = 'untrusted response remains data'; Root = $untrusted; Exit = 0; Sentinel = $sentinel }

  Invoke-CzxtContract 'façade fixtures cover 0 5 10 aggregation without external execution' {
    Assert-CzxtEqual 7 $cases.Count 'façade fixture count'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath $sentinel)) 'façade sentinel exists before audit'
  }

  $script:FacadeReady = $false
  Invoke-CzxtContract 'P4t public façade exists' {
    Assert-CzxtTrue (Test-Path -LiteralPath $script:P4tFacadePath -PathType Leaf) `
      ('missing P4t façade: ' + $script:P4tFacadePath)
    $script:FacadeReady = $true
  }
  if ($script:FacadeReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('façade: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-P4tFixture $case.Root
        Assert-ExitCode $result $case.Exit $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
        if ($null -ne $case.PSObject.Properties['Sentinel']) {
          Assert-CzxtTrue (-not (Test-Path -LiteralPath $case.Sentinel)) `
            'P4t façade executed untrusted response bytes'
        }
      }
    }

    Invoke-CzxtContract 'two P4t audits run concurrently without fixture or result leakage' {
      $rootA = New-ProjectSkeleton 'facade-concurrent-a'
      $rootB = New-ProjectSkeleton 'facade-concurrent-b'
      $processes = @()
      $index = 0
      foreach ($root in @($rootA, $rootB)) {
        $out = Join-Path $script:P4tFixtureRoot ('concurrent-' + $index + '.out')
        $err = Join-Path $script:P4tFixtureRoot ('concurrent-' + $index + '.err')
        $process = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') `
          -ArgumentList @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', $script:P4tFacadePath, '-Root', $root) -WindowStyle Hidden -PassThru `
          -RedirectStandardOutput $out -RedirectStandardError $err
        # WinPS 5.1 需先物化 Handle，否则重定向进程结束后 ExitCode 可能保持 null。
        [void]$process.Handle
        $processes += $process
        $index++
      }
      foreach ($process in $processes) {
        $completed = $process.WaitForExit(120000)
        if (-not $completed) {
          Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
          throw ('concurrent P4t process timed out: ' + $process.Id)
        }
        Assert-CzxtEqual 0 $process.ExitCode ('concurrent P4t process ' + $process.Id)
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
