[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-git-test-support.ps1')

function Invoke-BorrowingFixtureCapture {
  param($Fixture, [string]$FullRef, [string]$RefType, [string]$Name)
  $staging = Join-Path $script:BorrowingCaptureFixtureRoot ('capture-' + $Name)
  [void](New-Item -ItemType Directory -Path $staging)
  $trace = New-Object 'Collections.Generic.List[string]'
  $adapter = New-BorrowingOfflineGitAdapter $Fixture.LogicalLocator $Fixture.Origin $trace
  $candidate = Invoke-BorrowingGitCapture -StagingPath $staging `
    -CanonicalLocator $Fixture.LogicalLocator -FullRef $FullRef `
    -RefType $RefType -RunGit $adapter
  return [pscustomobject]@{ Candidate = $candidate; Staging = $staging; Trace = $trace }
}

Initialize-BorrowingCaptureFixture
try {
  $script:GitCaptureReady = $false
  Invoke-CzxtContract 'capture Git object helper exists' {
    Import-BorrowingGitCaptureTestModules
    $script:GitCaptureReady = $true
  }
  if ($script:GitCaptureReady) {
    Invoke-CzxtContract 'Git SHA-1 branch capture is detached shallow canonical and fsck-clean' {
      $fixture = New-BorrowingGitRepositoryFixture 'sha1-branch' sha1
      $result = Invoke-BorrowingFixtureCapture $fixture 'refs/heads/main' branch 'sha1-main'
      $candidate = $result.Candidate
      Assert-CzxtEqual 'czxt-borrowing-git-candidate/v1' $candidate.Schema 'Git candidate schema'
      Assert-CzxtEqual 'sha1' $candidate.ObjectFormat 'Git object format'
      Assert-CzxtEqual 40 $candidate.AdvertisedOid.Length 'SHA-1 advertised length'
      Assert-CzxtEqual $fixture.MainCommit $candidate.Commit 'SHA-1 commit'
      Assert-CzxtEqual $candidate.Commit $candidate.Fingerprint 'Git fingerprint'
      Assert-CzxtEqual 'git-object' $candidate.FingerprintAlgorithm 'Git fingerprint algorithm'
      Assert-CzxtEqual 'not-detected' $candidate.SubmoduleStatus 'clean submodule status'
      Assert-CzxtEqual 'not-detected' $candidate.LfsStatus 'clean LFS status'
      $repository = Join-Path $result.Staging '快照\repository.git'
      Assert-CzxtEqual ($candidate.Commit + "`n") `
        ([IO.File]::ReadAllText((Join-Path $repository 'HEAD')).Replace("`r`n", "`n")) `
        'detached HEAD bytes'
      Assert-CzxtEqual 0 @(Invoke-BorrowingFixtureGit @(
          '-C', $repository, 'fsck', '--full', '--strict', '--no-reflogs',
          '--unreachable', '--no-progress'
        )).Count 'Git fsck output'
      Test-BorrowingGitCache -RepositoryPath $repository `
        -ObjectFormat $candidate.ObjectFormat -AdvertisedOid $candidate.AdvertisedOid `
        -CommitOid $candidate.Commit -TreeOid $candidate.Tree -RunGit `
        (New-BorrowingOfflineGitAdapter $fixture.LogicalLocator $fixture.Origin `
          (New-Object 'Collections.Generic.List[string]'))
      $logical = $result.Trace -join "`n"
      Assert-CzxtTrue $logical.Contains($fixture.LogicalLocator) 'logical HTTPS locator was not recorded'
      Assert-CzxtTrue ($logical -notmatch '(?i)checkout|submodule\s+(update|init)|lfs\s+(pull|fetch)') `
        'Git capture executed forbidden command'
    }

    Invoke-CzxtContract 'Git annotated tag keeps advertised tag OID but fingerprints peeled commit' {
      $fixture = New-BorrowingGitRepositoryFixture 'sha1-tag' sha1
      $result = Invoke-BorrowingFixtureCapture $fixture 'refs/tags/v1.0.0' tag 'sha1-tag'
      $candidate = $result.Candidate
      Assert-CzxtEqual 'tag' $candidate.RefType 'tag ref type'
      Assert-CzxtTrue ($candidate.AdvertisedOid -cne $candidate.Commit) `
        'annotated tag was not peeled'
      Assert-CzxtEqual $fixture.MainCommit $candidate.Commit 'tag peeled commit'
      Assert-CzxtEqual $candidate.Commit $candidate.Fingerprint 'tag fingerprint'
      $repository = Join-Path $result.Staging '快照\repository.git'
      Assert-CzxtEqual ($candidate.AdvertisedOid + "`n") `
        ([IO.File]::ReadAllText((Join-Path $repository 'refs\czxt\capture')).Replace("`r`n", "`n")) `
        'tag capture ref bytes'
      Assert-CzxtEqual ($candidate.Commit + "`n") `
        ([IO.File]::ReadAllText((Join-Path $repository 'HEAD')).Replace("`r`n", "`n")) `
        'tag detached HEAD bytes'
    }

    Invoke-CzxtContract 'Git SHA-256 branch capture preserves 64-hex object format' {
      $fixture = New-BorrowingGitRepositoryFixture 'sha256-branch' sha256
      $result = Invoke-BorrowingFixtureCapture $fixture 'refs/heads/main' branch 'sha256-main'
      $candidate = $result.Candidate
      Assert-CzxtEqual 'sha256' $candidate.ObjectFormat 'SHA-256 object format'
      Assert-CzxtEqual 64 $candidate.AdvertisedOid.Length 'SHA-256 advertised length'
      Assert-CzxtEqual 64 $candidate.Commit.Length 'SHA-256 commit length'
      Assert-CzxtEqual $candidate.Commit $candidate.Fingerprint 'SHA-256 fingerprint'
    }

    Invoke-CzxtContract 'Git detects submodule and LFS without initializing downloading or executing' {
      $fixture = New-BorrowingGitRepositoryFixture 'detected-source' sha1
      $result = Invoke-BorrowingFixtureCapture $fixture 'refs/heads/detected' branch 'detected'
      Assert-CzxtEqual 'detected' $result.Candidate.SubmoduleStatus 'submodule detection'
      Assert-CzxtEqual 'detected' $result.Candidate.LfsStatus 'LFS detection'
      Assert-CzxtEqual $false `
        (Test-Path -LiteralPath (Join-Path $result.Staging '快照\repository.git\modules')) `
        'Git modules directory created'
    }

    Invoke-CzxtContract 'Git rejects tree mode 120000 before producing a candidate' {
      $fixture = New-BorrowingGitRepositoryFixture 'unsafe-source' sha1
      Assert-BorrowingFailureCode {
        Invoke-BorrowingFixtureCapture $fixture 'refs/heads/unsafe' branch 'unsafe'
      } 'capture' 'source-unsafe'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
