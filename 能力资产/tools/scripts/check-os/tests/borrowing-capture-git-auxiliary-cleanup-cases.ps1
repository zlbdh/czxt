[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

Initialize-BorrowingCaptureFixture
try {
  Import-BorrowingCaptureModules @(
    'common', 'file-safety', 'process', 'git-runner', 'git', 'local',
    'web-json', 'web', 'source-card', 'source-candidate-validator',
    'p4t-runner', 'transaction', 'owned-staging', 'orchestrator'
  )

  Invoke-CzxtContract 'initial Git runner cleanup retains unregistered members' {
    $root = New-BorrowingFixtureRoot git-runner-unknown project
    $ownership = New-BorrowingStagingDirectory ([pscustomobject]@{
        Root = $root; Request = [pscustomobject]@{ SourceId = 'git-source' }
      })
    Initialize-BorrowingOwnedGitRunnerDirectories $ownership
    $runner = [pscustomobject]@{
      RunnerRoot = (Join-Path $ownership.StagingPath 'git-runner-root')
      Home = (Join-Path $ownership.StagingPath 'git-runner-home')
      TrustedEmptyDirectory = (Join-Path $ownership.StagingPath `
        'git-trusted-empty')
    }
    $unknown = Join-Path $runner.RunnerRoot 'unregistered.bin'
    [IO.File]::WriteAllBytes($unknown, ([byte[]](3, 4, 5)))
    $caught = $null
    try { Remove-BorrowingOwnedGitRunnerArtifacts $ownership $runner }
    catch { $caught = $_.Exception }
    finally { Close-BorrowingOwnedStagingLeases $ownership }
    Assert-CzxtTrue ($null -ne $caught) `
      'unregistered initial Git runner member did not fail cleanup'
    Assert-CzxtTrue (Test-Path -LiteralPath $unknown -PathType Leaf) `
      'initial Git runner cleanup deleted an unregistered member'
    Assert-CzxtTrue (Test-Path -LiteralPath $runner.RunnerRoot `
        -PathType Container) 'initial Git runner root was deleted around unknown data'
  }

  Invoke-CzxtContract 'Git auxiliary cleanup retains every unregistered member' {
    $root = New-BorrowingFixtureRoot git-auxiliary-unknown project
    $ownership = New-BorrowingStagingDirectory ([pscustomobject]@{
        Root = $root; Request = [pscustomobject]@{ SourceId = 'git-source' }
      })
    $script:AuxiliaryUnknownPath = $null
    $script:AuxiliaryUnknownRoot = $null
    function global:New-BorrowingGitRunner {
      param($ExecutablePath, $StagingPath)
      $script:AuxiliaryUnknownRoot = $StagingPath
      return [pscustomobject]@{
        RunnerRoot = (Join-Path $StagingPath 'git-runner-root')
        WorkingDirectory = (Join-Path $StagingPath 'git-runner-root\cwd')
        Home = (Join-Path $StagingPath 'git-runner-home')
        TrustedEmptyDirectory = (Join-Path $StagingPath 'git-trusted-empty')
      }
    }
    function global:Test-BorrowingGitCache {
      param($RepositoryPath, $ObjectFormat, $AdvertisedOid, $CommitOid,
        $TreeOid, $RunGit)
      $script:AuxiliaryUnknownPath = Join-Path `
        $script:AuxiliaryUnknownRoot 'unregistered.bin'
      [IO.File]::WriteAllBytes($script:AuxiliaryUnknownPath,
        ([byte[]](8, 9, 10)))
    }
    $caught = $null
    try {
      Test-BorrowingPostMoveGitCache ([pscustomobject]@{
          Ownership = $ownership; CapturePath = 'C:\fixture-capture'
          Candidate = [pscustomobject]@{
            GitExecutablePath = 'C:\git.exe'; ObjectFormat = 'sha1'
            AdvertisedOid = ('a' * 40); Commit = ('b' * 40); Tree = ('c' * 40)
          }
        })
    }
    catch { $caught = $_.Exception }
    finally { Close-BorrowingOwnedStagingLeases $ownership }
    Assert-CzxtTrue ($null -ne $caught) `
      'unregistered Git auxiliary member did not fail cleanup'
    Assert-CzxtTrue (Test-Path -LiteralPath $script:AuxiliaryUnknownPath `
        -PathType Leaf) 'unregistered Git auxiliary member was deleted'
    Assert-CzxtTrue (Test-Path -LiteralPath $script:AuxiliaryUnknownRoot `
        -PathType Container) 'Git auxiliary root was deleted around unknown data'
  }

  Invoke-CzxtContract 'Git post-move validation always closes auxiliary leases' {
    $script:AuxiliaryCloseCalled = $false
    $auxiliaryFixture = New-BorrowingFixtureRoot git-auxiliary-close project
    $script:AuxiliaryCloseFixturePath = Join-Path $auxiliaryFixture `
      '.staging-git-validation-fixture'
    [void][IO.Directory]::CreateDirectory($script:AuxiliaryCloseFixturePath)
    function global:New-BorrowingOwnedAuxiliaryStaging {
      param($Ownership, [string]$Prefix)
      return [pscustomobject]@{
        StagingPath = $script:AuxiliaryCloseFixturePath
      }
    }
    function global:Initialize-BorrowingOwnedGitRunnerDirectories { param($Ownership) }
    function global:New-BorrowingGitRunner {
      param($ExecutablePath, $StagingPath)
      return [pscustomobject]@{
        RunnerRoot = 'C:\fixture-runner'; Home = 'C:\fixture-home'
        TrustedEmptyDirectory = 'C:\fixture-empty'
      }
    }
    function global:Test-BorrowingGitCache { param($RepositoryPath, $ObjectFormat,
        $AdvertisedOid, $CommitOid, $TreeOid, $RunGit) }
    function global:Remove-BorrowingOwnedAuxiliaryExactTree {
      param($Ownership)
      throw 'injected auxiliary cleanup failure'
    }
    function global:Close-BorrowingOwnedStagingLeases {
      param($Ownership)
      $script:AuxiliaryCloseCalled = $true
    }

    $caught = $null
    try {
      Test-BorrowingPostMoveGitCache ([pscustomobject]@{
          Ownership = [pscustomobject]@{}
          CapturePath = 'C:\fixture-capture'
          Candidate = [pscustomobject]@{
            GitExecutablePath = 'C:\git.exe'; ObjectFormat = 'sha1'
            AdvertisedOid = ('a' * 40); Commit = ('b' * 40); Tree = ('c' * 40)
          }
        })
    }
    catch { $caught = $_.Exception }
    Assert-CzxtTrue ($null -ne $caught) 'auxiliary cleanup injection must fail'
    Assert-CzxtTrue $script:AuxiliaryCloseCalled `
      'auxiliary leases were not closed after cleanup failure'
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
