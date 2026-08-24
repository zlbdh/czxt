$ErrorActionPreference = 'Stop'

$candidateCardRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Read-BorrowingStableSafeFileBytes -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $candidateCardRoot 'trusted-file-read.ps1')
}

function global:Assert-BcvCardStructure {
  param($Card, $Skeleton, [string]$ExpectedFormalLine)
  $expectedCount = if ($Card.capture_status -ceq 'retired') { 68 } else { 67 }
  if ($Card.Lines.Count -ne $expectedCount -or $Skeleton.Lines.Count -ne 67) {
    Throw-BorrowingCandidateFailure 'source card line count is invalid'
  }
  $dynamic = @(
    2..18; 23; 32..40; 46; 52; 58; 66
  )
  for ($index = 0; $index -lt 67; $index++) {
    if ($dynamic -notcontains $index -and
        [string]$Card.Lines[$index] -cne [string]$Skeleton.Lines[$index]) {
      Throw-BorrowingCandidateFailure 'source card static structure is invalid'
    }
  }
  if ($Card.Lines[23] -cne $ExpectedFormalLine) {
    Throw-BorrowingCandidateFailure 'source card formal path is invalid'
  }
}

function global:Assert-BcvCardHistory {
  param($Card)
  [string[]]$initial = ConvertFrom-BcvCardRow $Card.Lines[66] 5
  if ($initial[0] -cne $Card.captured_at -or $initial[1] -cne 'none' -or
      $initial[2] -cne 'ready' -or $initial[3] -cne 'initial-capture' -or
      $initial[4] -cne 'capture-executor') {
    Throw-BorrowingCandidateFailure 'source card initial history is invalid'
  }
  if ($Card.capture_status -ceq 'retired') {
    [string[]]$retirement = ConvertFrom-BcvCardRow $Card.Lines[67] 5
    if (-not (Test-BcvUtcTimestamp $retirement[0]) -or
        $retirement[1] -cne 'ready' -or $retirement[2] -cne 'retired') {
      Throw-BorrowingCandidateFailure 'source card retirement history is invalid'
    }
    $captured = [DateTimeOffset]::ParseExact(
      $Card.captured_at, "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
      [Globalization.CultureInfo]::InvariantCulture,
      [Globalization.DateTimeStyles]::AssumeUniversal
    )
    $retired = [DateTimeOffset]::ParseExact(
      $retirement[0], "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
      [Globalization.CultureInfo]::InvariantCulture,
      [Globalization.DateTimeStyles]::AssumeUniversal
    )
    if ($retired -lt $captured) {
      Throw-BorrowingCandidateFailure 'source card history time moved backwards'
    }
  }
}

function global:Get-BcvCandidateLayout {
  param([string]$CaptureDirectory, [string]$SourceId, [string]$CaptureId)
  $capture = [IO.Path]::GetFullPath($CaptureDirectory).TrimEnd('\')
  if (-not (Test-BcvSafeCachePath $capture Directory)) {
    Throw-BorrowingCandidateFailure 'source candidate directory is unsafe' 'source-unsafe'
  }
  $leaf = Split-Path -Leaf $capture
  $sourcePath = Split-Path -Parent $capture
  $sourceLeaf = Split-Path -Leaf $sourcePath
  $sourcesPath = Split-Path -Parent $sourcePath
  $borrowingPath = Split-Path -Parent $sourcesPath
  $root = Split-Path -Parent $borrowingPath
  if ($sourceLeaf -cne $SourceId -or (Split-Path -Leaf $sourcesPath) -cne '来源' -or
      (Split-Path -Leaf $borrowingPath) -cne '借鉴区' -or
      [string]::IsNullOrEmpty($root)) {
    Throw-BorrowingCandidateFailure 'source candidate directory does not match source_id'
  }
  $isStaging = $leaf.StartsWith('.staging-', [StringComparison]::Ordinal)
  if (($isStaging -and $leaf -cnotmatch '\A\.staging-[A-Za-z0-9][A-Za-z0-9._-]*\z') -or
      (-not $isStaging -and $leaf -cne $CaptureId)) {
    Throw-BorrowingCandidateFailure 'source candidate directory does not match capture_id'
  }
  return [pscustomobject][ordered]@{
    CaptureDirectory = $capture; SourceDirectory = $sourcePath; Root = $root
    IsStaging = $isStaging
  }
}

function global:Assert-BcvFrontmatterSemantics {
  param($Card)
  if ($Card.schema -cne 'borrowing-source/v1' -or
      $Card.source_type -notin @('git', 'local', 'web') -or
      $Card.capture_status -notin @('ready', 'retired')) {
    Throw-BorrowingCandidateFailure 'source card public fields are invalid'
  }
  [void](Assert-BcvIdentifier $Card.source_id)
  if (-not (Test-BcvUtcTimestamp $Card.captured_at) -or
      $Card.fingerprint -cnotmatch '\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z') {
    Throw-BorrowingCandidateFailure 'source card fingerprint or timestamp is invalid'
  }
  $pattern = '\A' + [regex]::Escape($Card.source_type) +
    '-([0-9]{8})-([0-9a-f]{12})\z'
  if ($Card.capture_id -cnotmatch $pattern -or
      $Matches[2] -cne $Card.fingerprint.Substring(0, 12) -or
      $Matches[1] -cne $Card.captured_at.Substring(0, 10).Replace('-', '')) {
    Throw-BorrowingCandidateFailure 'source card capture_id is invalid'
  }
}

function global:Get-BorrowingValidatedSourceCandidate {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$CaptureDirectory)
  try {
    $cardPath = Join-Path ([IO.Path]::GetFullPath($CaptureDirectory)) '来源版本卡.md'
    $card = Read-BorrowingFrontmatter -Path $cardPath
    Assert-BcvFrontmatterSemantics $card
    $layout = Get-BcvCandidateLayout $CaptureDirectory $card.source_id $card.capture_id
    $skeleton = Get-BorrowingValidatedSourceCardSkeleton -Root $layout.Root
    $formalLine = '- 正式路径：`借鉴区/来源/' + $card.source_id + '/' +
      $card.capture_id + '/来源版本卡.md`'
    Assert-BcvCardStructure $card $skeleton $formalLine
    $permissionData = Get-BcvValidatedPermissions $card
    $factData = Get-BcvValidatedFacts $card
    Assert-BcvCardHistory $card
    $candidate = [pscustomobject][ordered]@{
      CardPath = $card.Path; CardBytes = $card.Bytes
      CaptureDirectory = $layout.CaptureDirectory; IsStaging = $layout.IsStaging
      SourceId = $card.source_id; CaptureId = $card.capture_id
      SourceType = $card.source_type; CaptureStatus = $card.capture_status
      CanonicalLocator = $card.canonical_locator
      FingerprintAlgorithm = $card.fingerprint_algorithm
      Fingerprint = $card.fingerprint; CapturedAt = $card.captured_at
      Permissions = $permissionData.Permissions
      PermissionAuthorizations = $permissionData.PermissionAuthorizations
      TypeFacts = $factData.TypeFacts; FactNames = $factData.FactNames
      FactValues = $factData.FactValues
    }
    $identity = Get-BorrowingSourceStableIdentity $candidate
    Add-Member -InputObject $candidate -NotePropertyName StableIdentity `
      -NotePropertyValue $identity.StableIdentity
    Add-Member -InputObject $candidate -NotePropertyName StableIdentitySha256 `
      -NotePropertyValue $identity.StableIdentitySha256
    $cache = Get-BorrowingIgnoredCacheState $layout.CaptureDirectory $candidate.SourceType
    Add-Member -InputObject $candidate -NotePropertyName IgnoredCacheState `
      -NotePropertyValue $cache
    if (($layout.IsStaging -and $cache.State -cne 'Healthy') -or
        $cache.State -ceq 'Conflict') {
      Throw-BorrowingCandidateFailure 'source candidate cache set is incomplete'
    }
    if ($cache.State -ceq 'Healthy' -and $candidate.SourceType -ne 'git') {
      $stored = Test-BorrowingStoredCaptureFingerprint $candidate
      if (-not $stored.IsValid) {
        Throw-BorrowingCandidateFailure 'stored source fingerprint is invalid'
      }
    }
    return $candidate
  }
  catch {
    if (Test-BcvKnownFailure $_.Exception) { throw }
    Throw-BorrowingCandidateFailure 'source candidate validation failed'
  }
}
