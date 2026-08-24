[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-local-test-support.ps1')

function New-BorrowingLocalCandidateFixture {
  param([string]$Name)
  $root = New-BorrowingFixtureRoot ($Name + '-root') project
  $source = New-BorrowingLocalSourceFixture ($Name + '-source')
  $staging = Join-Path $root ('借鉴区\来源\safe-source\.staging-' + $Name)
  [void](New-Item -ItemType Directory -Path $staging -Force)
  $ops = New-BorrowingProductionLocalOperations
  $input = New-BorrowingLocalInput $root $source 'safe-source' $ops
  $candidate = New-BorrowingLocalCandidate $input $staging $ops
  return [pscustomobject]@{
    Root = $root; Source = $source; Staging = $staging
    Operations = $ops; Candidate = $candidate
  }
}

Initialize-BorrowingCaptureFixture
try {
  $script:LocalHelperReady = $false
  Invoke-CzxtContract 'capture Local identity helper exists' {
    Import-BorrowingLocalTestModules
    $script:LocalHelperReady = $true
  }
  if ($script:LocalHelperReady) {
    Invoke-CzxtContract 'Local normal copy preserves M0-M1 and separates M0-M2 identities' {
      $fixture = New-BorrowingLocalCandidateFixture 'copy'
      $candidate = $fixture.Candidate
      Assert-CzxtEqual 'borrowing-local-candidate/v1' $candidate.Schema 'Local candidate schema'
      Assert-BorrowingSnapshotIdentityEqual $candidate.SourceBefore $candidate.SourceAfter $true `
        'M0 to M1'
      Assert-BorrowingSnapshotIdentityEqual $candidate.SourceBefore $candidate.StagingContent $false `
        'M0 to M2'
      foreach ($bytes in @(
          $candidate.SourceBefore.ManifestBytes, $candidate.SourceAfter.ManifestBytes,
          $candidate.StagingContent.ManifestBytes,
          [IO.File]::ReadAllBytes((Join-Path $fixture.Staging '快照\manifest.tsv'))
        )) {
        Assert-CzxtEqual $candidate.Fingerprint (Get-BorrowingSha256Hex -Bytes $bytes) `
          'M0-M2 and stored manifest fingerprint'
      }
    }

    Invoke-CzxtContract 'Local same-volume move preserves M2-M3 identity' {
      $fixture = New-BorrowingLocalCandidateFixture 'promote'
      $capture = Join-Path $fixture.Root `
        '借鉴区\来源\safe-source\local-20260719-aaaaaaaaaaaa'
      [IO.Directory]::Move($fixture.Staging, $capture)
      $promoted = Confirm-BorrowingLocalPromotion -Candidate $fixture.Candidate `
        -CapturePath $capture -Operations $fixture.Operations
      Assert-BorrowingSnapshotIdentityEqual $fixture.Candidate.StagingContent $promoted $true `
        'M2 to M3'
      Assert-CzxtEqual $fixture.Candidate.Fingerprint $promoted.Fingerprint 'M3 fingerprint'
    }

    Invoke-CzxtContract 'Local detects same-byte source replacement by identity instead of manifest alone' {
      $root = New-BorrowingFixtureRoot 'local-race-root' project
      $source = New-BorrowingLocalSourceFixture 'race-source'
      $staging = Join-Path $root '借鉴区\来源\safe-source\.staging-race'
      [void](New-Item -ItemType Directory -Path $staging -Force)
      $ops = New-BorrowingProductionLocalOperations
      $originalCopy = $ops.CopyFile
      $script:LocalRaceTriggered = $false
      $ops.CopyFile = ({
        param([string]$SourcePath, [string]$DestinationPath, [byte[]]$ExpectedBytes)
        & $originalCopy $SourcePath $DestinationPath $ExpectedBytes
        if (-not $script:LocalRaceTriggered) {
          $bytes = [IO.File]::ReadAllBytes($SourcePath)
          Remove-Item -LiteralPath $SourcePath -Force
          [IO.File]::WriteAllBytes($SourcePath, $bytes)
          $script:LocalRaceTriggered = $true
        }
      }).GetNewClosure()
      $localInput = New-BorrowingLocalInput $root $source 'safe-source' $ops
      Assert-BorrowingFailureCode {
        New-BorrowingLocalCandidate $localInput $staging $ops
      } 'capture' 'source-unsafe'
      Assert-CzxtTrue (Test-Path -LiteralPath $staging -PathType Container) `
        'race staging was preserved'
    }

    Invoke-CzxtContract 'Local snapshot resists same-length ABA while reading source bytes' {
      $root = New-BorrowingFixtureRoot 'local-read-aba-root' project
      $source = New-BorrowingLocalSourceFixture 'local-read-aba-source' $true
      $target = Join-Path $source 'a.txt'
      $attacker = Join-Path $script:BorrowingCaptureFixtureRoot 'local-read-attacker.txt'
      $parked = Join-Path $script:BorrowingCaptureFixtureRoot 'local-read-parked.txt'
      [byte[]]$safeBytes = [Text.Encoding]::UTF8.GetBytes('A')
      Write-BorrowingFixtureBytes $target $safeBytes
      Write-BorrowingFixtureBytes $attacker ([Text.Encoding]::UTF8.GetBytes('B'))
      $ops = New-BorrowingProductionLocalOperations
      $originalRead = $ops.ReadAllBytes
      $script:BlciLegacyReadRan = $false
      $targetPath = [IO.Path]::GetFullPath($target)
      $ops.ReadAllBytes = ({
        param([string]$Path)
        if (-not $script:BlciLegacyReadRan -and
            [IO.Path]::GetFullPath($Path) -ieq $targetPath) {
          [IO.File]::Move($Path, $parked)
          [IO.File]::Move($attacker, $Path)
          try { [byte[]]$bytes = & $originalRead $Path }
          finally {
            [IO.File]::Move($Path, $attacker)
            [IO.File]::Move($parked, $Path)
          }
          $script:BlciLegacyReadRan = $true
          return ,$bytes
        }
        return ,([byte[]](& $originalRead $Path))
      }).GetNewClosure()
      $input = New-BorrowingLocalInput $root $source 'safe-source' $ops
      Assert-CzxtTrue (-not [bool]$script:BlciLegacyReadRan) `
        'Local snapshot still used the path-based ReadAllBytes seam'
      Assert-CzxtEqual 1 $input.SourceBefore.Entries.Count 'Local ABA entry count'
      Assert-CzxtEqual (Get-BorrowingSha256Hex -Bytes $safeBytes) `
        $input.SourceBefore.Entries[0].Sha256 'Local ABA accepted attacker bytes'
    }

    Invoke-CzxtContract 'Local copy uses source-before bound bytes across an ABA window' {
      $root = New-BorrowingFixtureRoot 'local-copy-aba-root' project
      $source = New-BorrowingLocalSourceFixture 'local-copy-aba-source' $true
      $target = Join-Path $source 'a.txt'
      $attacker = Join-Path $script:BorrowingCaptureFixtureRoot 'local-copy-attacker.txt'
      $parked = Join-Path $script:BorrowingCaptureFixtureRoot 'local-copy-parked.txt'
      [byte[]]$safeBytes = [Text.Encoding]::UTF8.GetBytes('A')
      Write-BorrowingFixtureBytes $target $safeBytes
      Write-BorrowingFixtureBytes $attacker ([Text.Encoding]::UTF8.GetBytes('B'))
      $staging = Join-Path $root '借鉴区\来源\safe-source\.staging-copy-aba'
      [void](New-Item -ItemType Directory -Path $staging -Force)
      $ops = New-BorrowingProductionLocalOperations
      $input = New-BorrowingLocalInput $root $source 'safe-source' $ops
      $originalCopy = $ops.CopyFile
      $script:BlciLegacyCopyRan = $false
      $ops.CopyFile = ({
        param([string]$SourcePath, [string]$DestinationPath, [byte[]]$ExpectedBytes)
        if ($null -eq $ExpectedBytes) {
          [IO.File]::Move($SourcePath, $parked)
          [IO.File]::Move($attacker, $SourcePath)
          try { & $originalCopy $SourcePath $DestinationPath }
          finally {
            [IO.File]::Move($SourcePath, $attacker)
            [IO.File]::Move($parked, $SourcePath)
          }
          $script:BlciLegacyCopyRan = $true
          return
        }
        & $originalCopy $SourcePath $DestinationPath $ExpectedBytes
      }).GetNewClosure()
      $caught = $null
      try { [void](New-BorrowingLocalCandidate $input $staging $ops) }
      catch { $caught = $_.Exception }
      Assert-CzxtTrue (-not [bool]$script:BlciLegacyCopyRan) `
        'Local copy still reopened the source path without bound bytes'
      Assert-CzxtTrue ($null -eq $caught) 'Local bound-byte copy failed'
      $actual = [IO.File]::ReadAllBytes((Join-Path $staging '快照\内容\a.txt'))
      Assert-CzxtEqual ([Convert]::ToBase64String($safeBytes)) `
        ([Convert]::ToBase64String($actual)) 'Local copy exposed ABA bytes'
    }

    Invoke-CzxtContract 'Local promotion rejects same-byte target replacement by identity' {
      $fixture = New-BorrowingLocalCandidateFixture 'replace-after-move'
      $capture = Join-Path $fixture.Root `
        '借鉴区\来源\safe-source\local-20260719-bbbbbbbbbbbb'
      [IO.Directory]::Move($fixture.Staging, $capture)
      $target = Join-Path $capture '快照\内容\a.txt'
      $bytes = [IO.File]::ReadAllBytes($target)
      Remove-Item -LiteralPath $target -Force
      [IO.File]::WriteAllBytes($target, $bytes)
      Assert-BorrowingFailureCode {
        Confirm-BorrowingLocalPromotion $fixture.Candidate $capture $fixture.Operations
      } 'promotion' 'source-unsafe'
      Assert-CzxtTrue (-not (Test-Path -LiteralPath $capture)) `
        'Local rollback removed the promoted path'
      Assert-CzxtTrue (Test-Path -LiteralPath $fixture.Staging -PathType Container) `
        'Local rollback restored the staging path'
    }
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
