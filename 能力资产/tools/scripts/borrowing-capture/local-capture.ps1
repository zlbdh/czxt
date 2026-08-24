$ErrorActionPreference = 'Stop'

function global:New-BorrowingLocalInput {
  param($Root, $LocalPath, $LocalDisplayName, $Operations)
  try {
    [void](Assert-BorrowingSafeIdentifier ([string]$LocalDisplayName) LocalDisplayName)
    $safe = $Operations.GetSafePathInfo
    $rootInfo = & $safe $Root Directory input source-boundary
    $borrowing = & $safe (Join-Path $rootInfo.CanonicalPath '借鉴区') Directory input source-boundary
    $source = & $safe $LocalPath Directory input source-boundary
    if ((Get-BorrowingPathRelation $rootInfo.CanonicalPath $source.CanonicalPath) -cne 'disjoint' -or
        (Get-BorrowingPathRelation $borrowing.CanonicalPath $source.CanonicalPath) -cne 'disjoint') {
      Throw-BorrowingFailure input source-boundary 'Local source crosses the project boundary'
    }
    $snapshot = Get-BorrowingLocalSnapshot $source.CanonicalPath source-before $Operations
    return [pscustomobject][ordered]@{
      Schema = 'borrowing-local-input/v1'; Root = $rootInfo.CanonicalPath
      BorrowingRoot = $borrowing.CanonicalPath; LocalPath = $source.CanonicalPath
      LocalDisplayName = [string]$LocalDisplayName; CanonicalLocator = 'local:' + [string]$LocalDisplayName
      SourceBefore = $snapshot
    }
  }
  catch {
    if (Test-BlcKnownFailure $_.Exception) { throw }
    Throw-BorrowingFailure input source-boundary 'Local input validation failed'
  }
}

function global:New-BorrowingLocalCandidate {
  param([Alias('Input')]$LocalInput, $StagingPath, $Operations)
  try {
    if ($null -eq $LocalInput -or $LocalInput.Schema -cne 'borrowing-local-input/v1') {
      Throw-BorrowingFailure capture capture-failed 'Local input is invalid'
    }
    $safe = $Operations.GetSafePathInfo
    $children = $Operations.GetChildren
    $mkdir = $Operations.CreateDirectory
    $copy = $Operations.CopyFile
    $write = $Operations.WriteAllBytes
    $read = $Operations.ReadAllBytes
    $staging = & $safe $StagingPath Directory capture source-unsafe
    if ((Get-BorrowingPathRelation $LocalInput.BorrowingRoot $staging.CanonicalPath) -cne 'ancestor' -or
        @(& $children $staging.CanonicalPath).Count -ne 0) {
      Throw-BorrowingFailure capture source-unsafe 'Local staging is unsafe'
    }
    $snapshotDir = Join-Path $staging.CanonicalPath '快照'
    $content = Join-Path $snapshotDir '内容'
    & $mkdir $snapshotDir
    & $mkdir $content
    foreach ($entry in $LocalInput.SourceBefore.Entries) {
      $destination = Join-Path $content ($entry.RelativePath.Replace('/', '\'))
      & $mkdir (Split-Path -Parent $destination)
      & $copy $entry.CanonicalPath $destination ([byte[]]$entry.Bytes)
    }
    $sourceAfter = Get-BorrowingLocalSnapshot $LocalInput.LocalPath source-after $Operations
    $stagingContent = Get-BorrowingLocalSnapshot $content staging-content $Operations
    Assert-BlcContentEqual $LocalInput.SourceBefore $sourceAfter capture
    Assert-BlcContentEqual $LocalInput.SourceBefore $stagingContent capture
    Assert-BlcIdentityRelation $LocalInput.SourceBefore $sourceAfter $true capture
    Assert-BlcIdentityRelation $LocalInput.SourceBefore $stagingContent $false capture
    $manifestPath = Join-Path $snapshotDir 'manifest.tsv'
    & $write $manifestPath $LocalInput.SourceBefore.ManifestBytes
    [byte[]]$stored = & $read $manifestPath
    if (-not (Test-BlcBytesEqual $stored $LocalInput.SourceBefore.ManifestBytes)) {
      Throw-BorrowingFailure capture source-unsafe 'Stored Local manifest differs'
    }
    return [pscustomobject][ordered]@{
      Schema = 'borrowing-local-candidate/v1'; SourceType = 'local'
      Input = $LocalInput; StagingPath = $staging.CanonicalPath
      ContentPath = $content; ManifestPath = $manifestPath; SourceBefore = $LocalInput.SourceBefore
      SourceAfter = $sourceAfter; StagingContent = $stagingContent
      ManifestBytes = $LocalInput.SourceBefore.ManifestBytes; Fingerprint = $LocalInput.SourceBefore.Fingerprint
      FingerprintAlgorithm = 'sha256-manifest-v1'
      FileCount = $LocalInput.SourceBefore.FileCount; TotalBytes = $LocalInput.SourceBefore.TotalBytes
      CanonicalLocator = $LocalInput.CanonicalLocator; LocalPath = $LocalInput.LocalPath
      LocalDisplayName = $LocalInput.LocalDisplayName
      LocalFacts = [pscustomobject][ordered]@{
        ManifestAlgorithm = 'sha256-manifest-v1'; FileCount = $LocalInput.SourceBefore.FileCount
        TotalBytes = $LocalInput.SourceBefore.TotalBytes; Exclusions = '无'; Failures = '无'
      }
    }
  }
  catch {
    if (Test-BlcKnownFailure $_.Exception) { throw }
    Throw-BorrowingFailure capture capture-failed 'Local capture failed'
  }
}

function global:Test-BorrowingLocalPromotedContent {
  param($Candidate, $CapturePath, $Operations)
  try {
    if ($null -eq $Candidate -or $Candidate.Schema -cne 'borrowing-local-candidate/v1') {
      Throw-BorrowingFailure promotion promotion-failed 'Local candidate is invalid'
    }
    $safe = $Operations.GetSafePathInfo
    $capture = & $safe $CapturePath Directory promotion source-unsafe
    if ((Get-BorrowingPathRelation $Candidate.Input.BorrowingRoot $capture.CanonicalPath) -cne 'ancestor') {
      Throw-BorrowingFailure promotion source-unsafe 'Local promotion path is unsafe'
    }
    $promoted = Get-BorrowingLocalSnapshot (Join-Path $capture.CanonicalPath '快照\内容') promoted-content $Operations
    Assert-BlcContentEqual $Candidate.SourceBefore $promoted promotion
    Assert-BlcContentEqual $Candidate.SourceAfter $promoted promotion
    Assert-BlcContentEqual $Candidate.StagingContent $promoted promotion
    Assert-BlcIdentityRelation $Candidate.StagingContent $promoted $true promotion
    [byte[]]$stored = Read-BorrowingStableSafeFileBytes `
      (Join-Path $capture.CanonicalPath '快照\manifest.tsv') promotion source-unsafe
    if (-not (Test-BlcBytesEqual $stored $promoted.ManifestBytes)) {
      Throw-BorrowingFailure promotion source-unsafe 'Promoted Local manifest differs'
    }
    return $promoted
  }
  catch {
    if (Test-BlcKnownFailure $_.Exception) { throw }
    Throw-BorrowingFailure promotion promotion-failed 'Local promotion failed'
  }
}

function global:Confirm-BorrowingLocalPromotion {
  param($Candidate, $CapturePath, $Operations)
  try { return Test-BorrowingLocalPromotedContent $Candidate $CapturePath $Operations }
  catch { $failure = $_.Exception }
  Move-BlcPromotionBack $Candidate $CapturePath $Operations
  throw $failure
}
