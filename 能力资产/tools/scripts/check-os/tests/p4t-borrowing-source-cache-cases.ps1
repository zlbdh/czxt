[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-test-support.ps1')
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-test-support.ps1')

function New-P4tCacheCase {
  param([string]$Name, [string]$Type = 'local', [int]$Exit = 10)
  $root = New-ProjectSkeleton ('source-cache-' + $Name)
  $record = New-P4tSourceCapture $root $Type
  return [pscustomobject]@{ Name = $Name; Root = $root; Record = $record; Exit = $Exit }
}

Initialize-P4tTestFixture
try {
  $cases = @()
  $case = New-P4tCacheCase 'local-cache-absent' local 5
  Remove-Item -LiteralPath (Join-Path $case.Record.CapturePath '快照') -Recurse -Force
  Remove-Item -LiteralPath (Join-Path $case.Record.CapturePath 'capture.local.json') -Force
  $cases += $case
  $case = New-P4tCacheCase 'local-cache-partial'
  Remove-Item -LiteralPath (Join-Path $case.Record.CapturePath '快照\manifest.tsv') -Force
  $cases += $case
  $case = New-P4tCacheCase 'local-content-mismatch'
  Write-P4tUtf8 (Join-Path $case.Record.CapturePath '快照\内容\payload.txt') "changed`n"
  $cases += $case
  $case = New-P4tCacheCase 'web-raw-mismatch' web
  [IO.File]::WriteAllBytes((Join-Path $case.Record.CapturePath '快照\response.bin'),
    [Text.Encoding]::UTF8.GetBytes('changed'))
  $cases += $case
  $case = New-P4tCacheCase 'git-cache-partial' git
  Remove-Item -LiteralPath (Join-Path $case.Record.CapturePath 'capture.local.json') -Force
  $cases += $case
  $case = New-P4tCacheCase 'git-cache-config-drift' git
  $configPath = Join-Path $case.Record.CapturePath '快照\repository.git\config'
  $configText = [IO.File]::ReadAllText($configPath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $configPath ($configText + "[gc]`n`tauto = 1`n")
  $cases += $case

  foreach ($fixture in @(
      @{ Name = 'local-extra-file'; Type = 'local'; Relative = '快照\unexpected.bin';
        Directory = $false },
      @{ Name = 'local-extra-directory'; Type = 'local'; Relative = '快照\unexpected';
        Directory = $true },
      @{ Name = 'web-extra-file'; Type = 'web'; Relative = '快照\unexpected.bin';
        Directory = $false },
      @{ Name = 'web-extra-directory'; Type = 'web'; Relative = '快照\unexpected';
        Directory = $true }
    )) {
    $case = New-P4tCacheCase $fixture.Name $fixture.Type
    $extraPath = Join-Path $case.Record.CapturePath $fixture.Relative
    if ($fixture.Directory) {
      [void](New-Item -ItemType Directory -Path $extraPath)
    }
    else { [IO.File]::WriteAllBytes($extraPath, [byte[]](0x78)) }
    $cases += $case
  }

  $case = New-P4tCacheCase 'snapshot-reparse'
  $snapshot = Join-Path $case.Record.CapturePath '快照'
  $outside = Join-Path $script:P4tFixtureRoot 'reparse-cache-target'
  Copy-Item -LiteralPath $snapshot -Destination $outside -Recurse
  Remove-Item -LiteralPath $snapshot -Recurse -Force
  [void](New-P4tJunction $snapshot $outside)
  $cases += $case

  $case = New-P4tCacheCase 'capture-path-reparse'
  $outsideCapture = Join-Path $script:P4tFixtureRoot 'escaped-capture-target'
  Move-Item -LiteralPath $case.Record.CapturePath -Destination $outsideCapture
  [void](New-P4tJunction $case.Record.CapturePath $outsideCapture)
  $cases += $case

  $case = New-P4tCacheCase 'cache-force-tracked'
  [void](Invoke-P4tFixtureGit @('init', '--quiet', $case.Root) 'tracked root init')
  $trackedRelative = $case.Record.CardPath.Substring($case.Root.Length + 1)
  [void](Invoke-P4tFixtureGit @('-C', $case.Root, 'add', '--', $trackedRelative) 'tracked card')
  $cacheRelative = (Join-Path $case.Record.CapturePath 'capture.local.json').Substring($case.Root.Length + 1)
  [void](Invoke-P4tFixtureGit @('-C', $case.Root, 'add', '-f', '--', $cacheRelative) 'force cache')
  $cases += $case

  $case = New-P4tCacheCase 'non-git-ignore-rule-missing'
  $ignorePath = Join-Path $case.Root '借鉴区\.gitignore'
  $ignoreText = [IO.File]::ReadAllText($ignorePath, $script:P4tUtf8NoBom)
  Write-P4tUtf8 $ignorePath ($ignoreText.Replace('/来源/*/*/快照/**', '# removed snapshot rule'))
  $cases += $case
  $case = New-P4tCacheCase 'cache-hardlink'
  $payloadPath = Join-Path $case.Record.CapturePath '快照\内容\payload.txt'
  $linkedCopy = Join-Path $script:P4tFixtureRoot 'hardlink-target.txt'
  [IO.File]::WriteAllBytes($linkedCopy, [IO.File]::ReadAllBytes($payloadPath))
  Remove-Item -LiteralPath $payloadPath -Force
  [void](New-Item -ItemType HardLink -Path $payloadPath -Target $linkedCopy)
  $cases += $case

  Invoke-CzxtContract 'source cache fixtures cover absence mismatch reparse escape tracking and ignore rules' {
    Assert-CzxtEqual 15 $cases.Count 'source cache case count'
    Assert-CzxtTrue (-not (Test-Path -LiteralPath (Join-Path $cases[0].Record.CapturePath '快照'))) `
      'absent cache fixture still has snapshot'
    Assert-CzxtTrue ((Get-Item -LiteralPath (Join-Path $cases[10].Record.CapturePath '快照') `
          -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) 'snapshot reparse fixture'
  }

  $script:SourceHelperReady = $false
  Invoke-CzxtContract 'P4t source helper exists for cache cases' {
    Import-P4tHelper 'borrowing-source-cards.ps1' 'Invoke-BorrowingP4tSourceCheck'
    $script:SourceHelperReady = $true
  }
  if ($script:SourceHelperReady) {
    foreach ($case in $cases) {
      Invoke-CzxtContract ('source cache: ' + $case.Name) {
        $before = Get-P4tTreeState $case.Root
        $result = Invoke-BorrowingP4tSourceCheck $case.Root project
        Assert-P4tResult $result $case.Exit $case.Name
        Assert-P4tTreeUnchanged $before (Get-P4tTreeState $case.Root) ($case.Name + ' read-only')
      }
    }
  }
}
finally { Remove-P4tTestFixture }

Complete-CzxtContracts
