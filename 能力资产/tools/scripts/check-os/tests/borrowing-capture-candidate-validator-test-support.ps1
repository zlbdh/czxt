$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'borrowing-capture-source-card-test-support.ps1')

function Import-BorrowingCandidateValidatorModules {
  Import-BorrowingCaptureModules @(
    'common', 'file-safety', 'source-card', 'web-json', 'source-candidate-validator'
  )
  foreach ($name in @(
      'Read-BorrowingFrontmatter', 'Get-BorrowingValidatedSourceCandidate',
      'Get-BorrowingSourceStableIdentity', 'Get-BorrowingIgnoredCacheState',
      'Test-BorrowingLocalStoredFingerprint', 'Test-BorrowingWebStoredFingerprint',
      'Test-BorrowingStoredCaptureFingerprint'
    )) { Assert-BorrowingCommandExists $name }
}

function New-BcvRoot {
  param([string]$Name)
  return New-BorrowingGoldenRoot ('candidate-' + $Name)
}

function Get-BcvLocalFixtureData {
  param([int]$Variant = 1)
  [byte[]]$content = if ($Variant -eq 1) {
    [Text.Encoding]::UTF8.GetBytes('abc')
  }
  else { [Text.Encoding]::UTF8.GetBytes('abcdef') }
  $fileHash = Get-BorrowingSha256Hex -Bytes $content
  [byte[]]$manifest = [Text.Encoding]::UTF8.GetBytes(
    $fileHash + "`t" + $content.Length + "`ta.txt`n"
  )
  return [pscustomobject]@{
    Content = $content
    Manifest = $manifest
    Fingerprint = Get-BorrowingSha256Hex -Bytes $manifest
  }
}

function Get-BcvWebFixtureData {
  param([int]$Variant = 1)
  [byte[]]$raw = [Text.Encoding]::UTF8.GetBytes(
    $(if ($Variant -eq 1) { 'web-payload' } else { 'web-payload-v2' })
  )
  $metadataText = '{"schema":"borrowing-web-response/v1","original_url":' +
    '"https://example.invalid/","final_url":"https://example.invalid/",' +
    '"redirect_chain":[],"status_code":200,"mime":"text/plain",' +
    '"charset":null,"etag":null,"last_modified":null}' + "`n"
  return [pscustomobject]@{
    Raw = $raw
    Metadata = [Text.Encoding]::UTF8.GetBytes($metadataText)
    Fingerprint = Get-BorrowingSha256Hex -Bytes $raw
  }
}

function New-BcvCandidateData {
  param([ValidateSet('git', 'local', 'web')][string]$SourceType, [int]$Variant = 1)
  if ($SourceType -eq 'git') {
    $length = $(if ($Variant -eq 1) { 40 } else { 64 })
    $format = $(if ($Variant -eq 1) { 'sha1' } else { 'sha256' })
    $commit = $(if ($Variant -eq 1) { 'a' * $length } else { 'b' * $length })
    return [pscustomobject]@{
      SourceType = 'git'; CanonicalLocator = 'https://example.invalid/owner/repo.git'
      FingerprintAlgorithm = 'git-object'; Fingerprint = $commit
      GitFacts = [pscustomobject]@{
        Ref = 'refs/heads/main'; RefType = 'branch'; ObjectFormat = $format
        Commit = $commit; Tree = ('d' * $length)
        SubmoduleStatus = 'not-detected'; LfsStatus = 'not-detected'
      }
    }
  }
  if ($SourceType -eq 'local') {
    $data = Get-BcvLocalFixtureData $Variant
    return [pscustomobject]@{
      SourceType = 'local'; CanonicalLocator = 'local:fixture-local'
      FingerprintAlgorithm = 'sha256-manifest-v1'; Fingerprint = $data.Fingerprint
      LocalData = $data
      LocalFacts = [pscustomobject]@{
        ManifestAlgorithm = 'sha256-manifest-v1'; FileCount = 1
        TotalBytes = $data.Content.Length; Exclusions = '无'; Failures = '无'
      }
    }
  }
  $data = Get-BcvWebFixtureData $Variant
  return [pscustomobject]@{
    SourceType = 'web'; CanonicalLocator = 'https://example.invalid/'
    FingerprintAlgorithm = 'sha256-raw-bytes-v1'; Fingerprint = $data.Fingerprint
    WebData = $data
    WebFacts = [pscustomobject]@{
      OriginalUrl = 'https://example.invalid/'; FinalUrl = 'https://example.invalid/'
      RedirectChain = '[]'; StatusCode = 200; Mime = 'text/plain'
      Charset = 'null'; Etag = 'null'; LastModified = 'null'
      ResponseHash = $data.Fingerprint
    }
  }
}

function Write-BcvCache {
  param([string]$CaptureDirectory, $Candidate)
  $snapshot = Join-Path $CaptureDirectory '快照'
  [void](New-Item -ItemType Directory -Path $snapshot -Force)
  if ($Candidate.SourceType -eq 'git') {
    [void](New-Item -ItemType Directory -Path (Join-Path $snapshot 'repository.git') -Force)
    $stateInput = [pscustomobject]@{ SourceType = 'git' }
  }
  elseif ($Candidate.SourceType -eq 'local') {
    $content = Join-Path $snapshot '内容'
    [void](New-Item -ItemType Directory -Path $content -Force)
    Write-BorrowingFixtureBytes (Join-Path $content 'a.txt') $Candidate.LocalData.Content
    Write-BorrowingFixtureBytes (Join-Path $snapshot 'manifest.tsv') $Candidate.LocalData.Manifest
    $stateInput = [pscustomobject]@{
      SourceType = 'local'; LocalSourcePath = 'C:\fixture-local'
    }
  }
  else {
    Write-BorrowingFixtureBytes (Join-Path $snapshot 'response.bin') $Candidate.WebData.Raw
    Write-BorrowingFixtureBytes (Join-Path $snapshot 'response.metadata.json') `
      $Candidate.WebData.Metadata
    $stateInput = [pscustomobject]@{
      SourceType = 'web'; WebRawBytesPath = 'C:\fixture-response.bin'
      WebResponseMetadataPath = 'C:\fixture-response.json'
    }
  }
  Write-BorrowingFixtureBytes (Join-Path $CaptureDirectory 'capture.local.json') `
    (New-BorrowingCaptureLocalStateBytes -Input $stateInput)
}

function New-BcvCapture {
  param(
    [string]$Root,
    [ValidateSet('git', 'local', 'web')][string]$SourceType,
    [DateTimeOffset]$Clock = [DateTimeOffset]::Parse('2026-07-19T01:02:03.456Z'),
    [int]$Variant = 1,
    [switch]$WithCache,
    [string]$DirectoryName,
    [string]$SourceDirectoryName
  )
  $candidate = New-BcvCandidateData $SourceType $Variant
  $permissions = New-BorrowingGoldenPermissions $SourceType
  $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $Root
  $artifact = New-BorrowingSourceCardArtifactCore -Skeleton $skeleton `
    -Candidate $candidate -Permissions $permissions -UtcNow $Clock
  if ([string]::IsNullOrEmpty($SourceDirectoryName)) {
    $SourceDirectoryName = $artifact.SourceId
  }
  if ([string]::IsNullOrEmpty($DirectoryName)) { $DirectoryName = $artifact.CaptureId }
  $capture = Join-Path $Root ('借鉴区\来源\' + $SourceDirectoryName + '\' + $DirectoryName)
  [void](New-Item -ItemType Directory -Path $capture -Force)
  Write-BorrowingFixtureBytes (Join-Path $capture '来源版本卡.md') $artifact.Bytes
  if ($WithCache) { Write-BcvCache $capture $candidate }
  return [pscustomobject]@{
    Root = $Root; CaptureDirectory = $capture; Artifact = $artifact
    Candidate = $candidate; Permissions = $permissions
  }
}

function Set-BcvCardText {
  param($Capture, [scriptblock]$Transform)
  $path = Join-Path $Capture.CaptureDirectory '来源版本卡.md'
  $text = (New-Object Text.UTF8Encoding($false, $true)).GetString(
    [IO.File]::ReadAllBytes($path)
  )
  $changed = & $Transform $text
  [IO.File]::WriteAllBytes($path, [Text.Encoding]::UTF8.GetBytes($changed))
}

function Assert-BcvCandidateInvalid {
  param($Capture)
  Assert-BorrowingFailureCode {
    Get-BorrowingValidatedSourceCandidate -CaptureDirectory $Capture.CaptureDirectory
  } candidate candidate-invalid
}
