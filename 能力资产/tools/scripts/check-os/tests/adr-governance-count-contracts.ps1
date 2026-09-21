[CmdletBinding()]
param([switch]$CleanupProbe, [switch]$CleanupIsolationOnly)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'adr-governance-count-test-support.ps1')

$p4iPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\p4i-governance-count-anchor.ps1'))
$p4sPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\p4s-template-cleanliness.ps1'))
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $env:TEMP 'czxt-adr-governance-count-tests'))
$script:AdrOwnedFixtureRoots = New-Object System.Collections.Generic.List[string]

if (-not $CleanupProbe) {
  Invoke-CzxtContract 'ADR fixture cleanup preserves same-parent history and other-run sentinels' {
    Assert-AdrCleanupIsolation -ContractPath $PSCommandPath
  }
  if ($CleanupIsolationOnly) { Complete-CzxtContracts }
}

try {
  if ($CleanupProbe) {
    Write-Output (New-AdrFixtureRoot)
    return
  }

  Invoke-CzxtContract 'P4s and P4i accept ADR truth 39 total / 36 current / 3 replaced when the main entry matches' {
    $root = New-AdrFixtureRoot
    $p4s = Invoke-AdrGate $p4sPath $root
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 0 $p4s.ExitCode ('P4s rejected matching ADR truth; stdout={0}; stderr={1}' -f $p4s.StdOut, $p4s.StdErr)
    Assert-CzxtEqual 0 $p4i.ExitCode ('P4i rejected matching ADR truth; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
    Assert-CzxtTrue ($p4i.StdOut -like '*39/36/3*') ('P4i did not print readable ADR truth; stdout={0}' -f $p4i.StdOut)
  }

  Invoke-CzxtContract 'P4i fails when the main entry ADR total drifts from index truth' {
    $root = New-AdrFixtureRoot -EntryTotal 38
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed total drift; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails when the main entry current count drifts from index truth' {
    $root = New-AdrFixtureRoot -EntryCurrent 35
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed current-count drift; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails when the main entry replaced count drifts from index truth' {
    $root = New-AdrFixtureRoot -EntryReplaced 2
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed replaced-count drift; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails when ADR index has a row without a file' {
    $root = New-AdrFixtureRoot -OmitFiles @(39)
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed index extra row; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails when ADR directory has a file missing from the index' {
    $root = New-AdrFixtureRoot -OmitRows @(39)
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed index missing row; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails on duplicate ADR file numbers' {
    $root = New-AdrFixtureRoot -DuplicateFileNumber
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed duplicate file number; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails on duplicate ADR index numbers' {
    $root = New-AdrFixtureRoot -DuplicateIndexRow
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed duplicate index row; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4i fails on unknown ADR status values' {
    $root = New-AdrFixtureRoot -UnknownStatusNumbers @(5)
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 10 $p4i.ExitCode ('P4i missed unknown ADR status; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
  }

  Invoke-CzxtContract 'P4s and P4i follow ADR status changes without changing the file set' {
    $replaced = @(3, 7, 11, 12)
    $oldEntryRoot = New-AdrFixtureRoot -ReplacedNumbers $replaced -EntryTotal 39 -EntryCurrent 36 -EntryReplaced 3
    $oldP4s = Invoke-AdrGate $p4sPath $oldEntryRoot
    $oldP4i = Invoke-AdrGate $p4iPath $oldEntryRoot
    Assert-CzxtEqual 10 $oldP4s.ExitCode ('P4s missed status-count drift for old 39/36/3 entry; stdout={0}; stderr={1}' -f $oldP4s.StdOut, $oldP4s.StdErr)
    Assert-CzxtEqual 10 $oldP4i.ExitCode ('P4i missed status-count drift for old 39/36/3 entry; stdout={0}; stderr={1}' -f $oldP4i.StdOut, $oldP4i.StdErr)

    $newEntryRoot = New-AdrFixtureRoot -ReplacedNumbers $replaced -EntryTotal 39 -EntryCurrent 35 -EntryReplaced 4
    $newP4s = Invoke-AdrGate $p4sPath $newEntryRoot
    $newP4i = Invoke-AdrGate $p4iPath $newEntryRoot
    Assert-CzxtEqual 0 $newP4s.ExitCode ('P4s rejected updated 39/35/4 status truth; stdout={0}; stderr={1}' -f $newP4s.StdOut, $newP4s.StdErr)
    Assert-CzxtEqual 0 $newP4i.ExitCode ('P4i rejected updated 39/35/4 status truth; stdout={0}; stderr={1}' -f $newP4i.StdOut, $newP4i.StdErr)
    Assert-CzxtTrue ($newP4i.StdOut -like '*39/35/4*') ('P4i did not print updated status truth; stdout={0}' -f $newP4i.StdOut)
  }

  Invoke-CzxtContract 'P4i accepts a new ADR when file, index status, and main entry all move to the new truth' {
    $root = New-AdrFixtureRoot -Total 40 -EntryTotal 40 -EntryCurrent 37 -EntryReplaced 3
    $p4i = Invoke-AdrGate $p4iPath $root
    Assert-CzxtEqual 0 $p4i.ExitCode ('P4i rejected updated 40/37/3 truth; stdout={0}; stderr={1}' -f $p4i.StdOut, $p4i.StdErr)
    Assert-CzxtTrue ($p4i.StdOut -like '*40/37/3*') ('P4i did not print updated ADR truth; stdout={0}' -f $p4i.StdOut)
  }
}
finally {
  foreach ($ownedRoot in $script:AdrOwnedFixtureRoots) {
    $rootFull = [IO.Path]::GetFullPath($ownedRoot)
    Assert-CzxtTrue ((Split-Path -Parent $rootFull).Equals($fixtureParent, [StringComparison]::OrdinalIgnoreCase)) `
      ('refuse cleanup outside the registered fixture parent: {0}' -f $rootFull)
    if (Test-Path -LiteralPath $rootFull) {
      Assert-CzxtTrue (-not ((Get-Item -LiteralPath $rootFull -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) `
        ('refuse cleanup of a replaced fixture link: {0}' -f $rootFull)
      Remove-CzxtFixture -FixtureParent $fixtureParent -FixtureRoot $rootFull
    }
  }
}

Complete-CzxtContracts
