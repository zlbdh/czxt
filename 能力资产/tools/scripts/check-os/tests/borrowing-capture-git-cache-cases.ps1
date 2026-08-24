[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-git-test-support.ps1')

function New-BorrowingValidGitCacheFixture {
  $script:BorrowingGitCacheFixtureIndex++
  $suffix = [string]$script:BorrowingGitCacheFixtureIndex
  $fixture = New-BorrowingGitRepositoryFixture ('cache-source-' + $suffix) sha1
  $staging = Join-Path $script:BorrowingCaptureFixtureRoot ('cache-candidate-' + $suffix)
  [void](New-Item -ItemType Directory -Path $staging)
  $trace = New-Object 'Collections.Generic.List[string]'
  $adapter = New-BorrowingOfflineGitAdapter $fixture.LogicalLocator $fixture.Origin $trace
  $candidate = Invoke-BorrowingGitCapture -StagingPath $staging `
    -CanonicalLocator $fixture.LogicalLocator -FullRef 'refs/heads/main' `
    -RefType branch -RunGit $adapter
  return [pscustomobject]@{
    Fixture = $fixture; Candidate = $candidate; Adapter = $adapter
    Repository = (Join-Path $staging '快照\repository.git')
  }
}

function Copy-BorrowingGitCacheFixture {
  param([string]$Source, [string]$Name)
  $destination = Join-Path $script:BorrowingCaptureFixtureRoot $Name
  Copy-Item -LiteralPath $Source -Destination $destination -Recurse
  return $destination
}

function Assert-BorrowingGitCacheFailure {
  param($Fixture, [string]$Repository, [string]$ReasonCode)
  Assert-BorrowingFailureCode {
    Test-BorrowingGitCache -RepositoryPath $Repository `
      -ObjectFormat $Fixture.Candidate.ObjectFormat `
      -AdvertisedOid $Fixture.Candidate.AdvertisedOid `
      -CommitOid $Fixture.Candidate.Commit -TreeOid $Fixture.Candidate.Tree `
      -RunGit $Fixture.Adapter
  } 'candidate' $ReasonCode
}

Initialize-BorrowingCaptureFixture
try {
  $script:GitCacheReady = $false
  Invoke-CzxtContract 'capture Git cache validator exists' {
    Import-BorrowingGitCaptureTestModules
    $script:GitCacheReady = $true
  }
  if ($script:GitCacheReady) {
    Invoke-CzxtContract 'Git cache validator accepts only canonical detached cache bytes' {
      $fixture = New-BorrowingValidGitCacheFixture
      Test-BorrowingGitCache -RepositoryPath $fixture.Repository `
        -ObjectFormat $fixture.Candidate.ObjectFormat `
        -AdvertisedOid $fixture.Candidate.AdvertisedOid `
        -CommitOid $fixture.Candidate.Commit -TreeOid $fixture.Candidate.Tree `
        -RunGit $fixture.Adapter
      $config = [IO.File]::ReadAllBytes((Join-Path $fixture.Repository 'config'))
      Assert-CzxtTrue (-not ($config.Length -ge 3 -and $config[0] -eq 0xEF -and `
            $config[1] -eq 0xBB -and $config[2] -eq 0xBF)) 'Git config BOM'
      Assert-CzxtTrue (-not ([Text.Encoding]::UTF8.GetString($config)).Contains("`r")) `
        'Git config CRLF'
    }

    Invoke-CzxtContract 'Git cache rejects symbolic HEAD config drift and forbidden top-level files' {
      $fixture = New-BorrowingValidGitCacheFixture
      $symbolic = Copy-BorrowingGitCacheFixture $fixture.Repository 'cache-symbolic'
      Write-CzxtNoBomText (Join-Path $symbolic 'HEAD') "ref: refs/czxt/capture`n"
      Assert-BorrowingGitCacheFailure $fixture $symbolic 'candidate-invalid'

      $configDrift = Copy-BorrowingGitCacheFixture $fixture.Repository 'cache-config-drift'
      $configPath = Join-Path $configDrift 'config'
      $bytes = [IO.File]::ReadAllBytes($configPath)
      Write-BorrowingFixtureBytes $configPath ([byte[]](0xEF, 0xBB, 0xBF) + $bytes)
      Assert-BorrowingGitCacheFailure $fixture $configDrift 'candidate-invalid'

      $forbidden = Copy-BorrowingGitCacheFixture $fixture.Repository 'cache-fetch-head'
      Write-CzxtNoBomText (Join-Path $forbidden 'FETCH_HEAD') "forbidden`n"
      Assert-BorrowingGitCacheFailure $fixture $forbidden 'candidate-invalid'
    }

    Invoke-CzxtContract 'Git cache rejects unreachable objects and single-file hardlink aliases' {
      $fixture = New-BorrowingValidGitCacheFixture
      $unreachable = Copy-BorrowingGitCacheFixture $fixture.Repository 'cache-unreachable'
      $blob = Join-Path $script:BorrowingCaptureFixtureRoot 'unreachable.bin'
      Write-CzxtNoBomText $blob 'unreachable'
      Invoke-BorrowingFixtureGit @('-C', $unreachable, 'hash-object', '-w', $blob) | Out-Null
      Assert-BorrowingGitCacheFailure $fixture $unreachable 'candidate-invalid'

      $hardlink = Copy-BorrowingGitCacheFixture $fixture.Repository 'cache-hardlink'
      $alias = Join-Path $script:BorrowingCaptureFixtureRoot 'config-hardlink-alias'
      [void](New-Item -ItemType HardLink -Path $alias -Target (Join-Path $hardlink 'config') -Force)
      Assert-BorrowingGitCacheFailure $fixture $hardlink 'source-unsafe'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
