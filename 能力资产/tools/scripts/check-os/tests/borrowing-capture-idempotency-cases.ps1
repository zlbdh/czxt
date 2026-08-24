[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-capture-test-support.ps1')

function New-BorrowingDispositionFixture {
  param([string]$Name, [object[]]$Existing)
  $root = New-BorrowingFixtureRoot ('idempotency-' + $Name) project
  $sourcePath = Join-Path $root '借鉴区\来源\web-source'
  $stagingPath = Join-Path $sourcePath '.staging-current'
  [void](New-Item -ItemType Directory -Path (Join-Path $stagingPath '快照') -Force)
  $cardBytes = [Text.Encoding]::UTF8.GetBytes("candidate`n")
  $stateBytes = [Text.Encoding]::UTF8.GetBytes("{}`n")
  Write-BorrowingFixtureBytes (Join-Path $stagingPath '来源版本卡.md') $cardBytes
  Write-BorrowingFixtureBytes (Join-Path $stagingPath 'capture.local.json') $stateBytes
  Write-BorrowingFixtureBytes (Join-Path $stagingPath '快照\response.bin') ([byte[]](1))
  Write-BorrowingFixtureBytes (Join-Path $stagingPath '快照\response.metadata.json') `
    ([Text.Encoding]::UTF8.GetBytes("{}`n"))

  $script:DispositionCandidates = New-Object `
    'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
  $staged = [pscustomobject]@{
    SourceId = 'web-source'; SourceType = 'web'; CaptureId = 'web-20260719-aaaaaaaaaaaa'
    CaptureStatus = 'ready'; FingerprintAlgorithm = 'sha256-raw-bytes-v1'
    Fingerprint = ('a' * 64); StableIdentitySha256 = ('b' * 64)
    CardBytes = $cardBytes; CardPath = (Join-Path $stagingPath '来源版本卡.md')
  }
  $script:DispositionCandidates[$stagingPath] = $staged
  $index = 0
  foreach ($candidate in $Existing) {
    $index++
    $path = Join-Path $sourcePath ('web-2026071' + $index + '-bbbbbbbbbbbb')
    [void](New-Item -ItemType Directory -Path $path -Force)
    $candidate | Add-Member -NotePropertyName CardPath `
      -NotePropertyValue (Join-Path $path '来源版本卡.md') -Force
    $script:DispositionCandidates[$path] = $candidate
  }
  $prepared = [pscustomobject]@{
    Request = [pscustomobject]@{ SourceId = 'web-source'; SourceType = 'web' }
  }
  $envelope = [pscustomobject]@{
    Artifact = [pscustomobject]@{
      CaptureId = $staged.CaptureId; StableIdentitySha256 = $staged.StableIdentitySha256
      Bytes = $cardBytes
    }
    Candidate = [pscustomobject]@{
      Fingerprint = $staged.Fingerprint
      FingerprintAlgorithm = $staged.FingerprintAlgorithm
    }
    LocalStateBytes = $stateBytes
  }
  return [pscustomobject]@{
    Prepared = $prepared; Envelope = $envelope
    Staging = [pscustomobject]@{ SourcePath = $sourcePath; StagingPath = $stagingPath }
  }
}

function New-BorrowingExistingCandidate {
  param([string]$Status = 'ready', [string]$Fingerprint = ('a' * 64),
    [string]$StableIdentitySha256 = ('b' * 64))
  return [pscustomobject]@{
    SourceId = 'web-source'; SourceType = 'web'; CaptureId = 'web-existing'
    CaptureStatus = $Status; FingerprintAlgorithm = 'sha256-raw-bytes-v1'
    Fingerprint = $Fingerprint; StableIdentitySha256 = $StableIdentitySha256
  }
}

function Assert-BorrowingDispositionFailure {
  param($Fixture, [string]$Context)
  $caught = $null
  try {
    [void](Get-BorrowingCaptureDisposition $Fixture.Prepared $Fixture.Envelope `
        $Fixture.Staging)
  }
  catch { $caught = $_.Exception }
  Assert-CzxtTrue ($null -ne $caught) ($Context + ' expected failure')
  Assert-CzxtEqual 'candidate' ([string]$caught.Data['BorrowingStage']) `
    ($Context + ' stage')
  Assert-CzxtEqual 'candidate-invalid' `
    ([string]$caught.Data['BorrowingReasonCode']) ($Context + ' reason')
}

Initialize-BorrowingCaptureFixture
try {
  Invoke-CzxtContract 'capture idempotency helper is available' {
    Import-BorrowingCaptureModules @(
      'common', 'file-safety', 'transaction', 'orchestrator'
    )
    Assert-BorrowingCommandExists 'Get-BorrowingCaptureDisposition'
  }

  function global:Get-BorrowingValidatedSourceCandidate {
    param([string]$CaptureDirectory)
    if (-not $script:DispositionCandidates.ContainsKey($CaptureDirectory)) {
      throw ('unexpected candidate path: ' + $CaptureDirectory)
    }
    return $script:DispositionCandidates[$CaptureDirectory]
  }
  function global:Get-BorrowingIgnoredCacheState {
    param([string]$CaptureDirectory, [string]$SourceType)
    return [pscustomobject]@{ State = 'Healthy' }
  }
  function global:Test-BorrowingStoredCaptureFingerprint {
    param($Candidate)
    return [pscustomobject]@{ Applicable = $false; IsValid = $true }
  }

  Invoke-CzxtContract 'same reuse key with different stable facts is a conflict' {
    $fixture = New-BorrowingDispositionFixture stable-drift @(
      (New-BorrowingExistingCandidate -StableIdentitySha256 ('c' * 64))
    )
    $actual = Get-BorrowingCaptureDisposition $fixture.Prepared $fixture.Envelope `
      $fixture.Staging
    Assert-CzxtEqual 'Conflict' $actual.Disposition 'stable drift disposition'
  }

  Invoke-CzxtContract 'same reuse key with any retired capture is a conflict' {
    $fixture = New-BorrowingDispositionFixture retired @(
      (New-BorrowingExistingCandidate -Status retired)
    )
    $actual = Get-BorrowingCaptureDisposition $fixture.Prepared $fixture.Envelope `
      $fixture.Staging
    Assert-CzxtEqual 'Conflict' $actual.Disposition 'retired disposition'
  }

  Invoke-CzxtContract 'same reuse key with two ready captures is a conflict' {
    $fixture = New-BorrowingDispositionFixture duplicate-ready @(
      (New-BorrowingExistingCandidate),
      (New-BorrowingExistingCandidate -StableIdentitySha256 ('c' * 64))
    )
    $actual = Get-BorrowingCaptureDisposition $fixture.Prepared $fixture.Envelope `
      $fixture.Staging
    Assert-CzxtEqual 'Conflict' $actual.Disposition 'duplicate ready disposition'
  }

  Invoke-CzxtContract 'a different full fingerprint remains eligible for a new capture' {
    $fixture = New-BorrowingDispositionFixture new-fingerprint @(
      (New-BorrowingExistingCandidate -Fingerprint ('d' * 64))
    )
    $actual = Get-BorrowingCaptureDisposition $fixture.Prepared $fixture.Envelope `
      $fixture.Staging
    Assert-CzxtEqual 'New' $actual.Disposition 'different fingerprint disposition'
  }

  Invoke-CzxtContract 'staging must be the exact ready renderer and local-state bytes' {
    $retired = New-BorrowingDispositionFixture staging-retired @()
    $script:DispositionCandidates[$retired.Staging.StagingPath].CaptureStatus = 'retired'
    Assert-BorrowingDispositionFailure $retired 'retired staging'

    $cardDrift = New-BorrowingDispositionFixture staging-card-drift @()
    $driftBytes = [Text.Encoding]::UTF8.GetBytes("changed-card`n")
    $script:DispositionCandidates[$cardDrift.Staging.StagingPath].CardBytes = $driftBytes
    Write-BorrowingFixtureBytes `
      (Join-Path $cardDrift.Staging.StagingPath '来源版本卡.md') $driftBytes
    Assert-BorrowingDispositionFailure $cardDrift 'staging card drift'

    $stateDrift = New-BorrowingDispositionFixture staging-state-drift @()
    Write-BorrowingFixtureBytes `
      (Join-Path $stateDrift.Staging.StagingPath 'capture.local.json') `
      ([Text.Encoding]::UTF8.GetBytes("{`"changed`":true}`n"))
    Assert-BorrowingDispositionFailure $stateDrift 'staging local-state drift'
  }

  Invoke-CzxtContract 'staging rejects every unknown top-level member' {
    $fixture = New-BorrowingDispositionFixture staging-extra @()
    Write-BorrowingFixtureBytes (Join-Path $fixture.Staging.StagingPath 'unexpected.bin') `
      ([byte[]](9))
    Assert-BorrowingDispositionFailure $fixture 'staging extra member'
  }
}
finally { Remove-BorrowingCaptureFixture }

Complete-CzxtContracts
