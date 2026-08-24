$ErrorActionPreference = 'Stop'

function global:Throw-BorrowingWebFailure {
  param([string]$Stage, [string]$ReasonCode, [string]$Message)
  $exception = New-Object InvalidOperationException($Message)
  $exception.Data['BorrowingStage'] = $Stage
  $exception.Data['BorrowingReasonCode'] = $ReasonCode
  throw $exception
}

function global:New-BorrowingProductionWebOperations {
  return [pscustomobject]@{
    GetSafePathInfo = {
      param([string]$Path, [string]$Kind, [string]$Stage, [string]$ReasonCode)
      Get-BorrowingSafePathInfo $Path $Kind $Stage $ReasonCode
    }
    GetPathRelation = {
      param([string]$Left, [string]$Right)
      Get-BorrowingPathRelation $Left $Right
    }
    ReadAllBytes = { param([string]$Path) [IO.File]::ReadAllBytes($Path) }
    CreateDirectory = { param([string]$Path) [void][IO.Directory]::CreateDirectory($Path) }
    WriteAllBytes = { param([string]$Path, [byte[]]$Bytes) [IO.File]::WriteAllBytes($Path, $Bytes) }
  }
}

function global:Assert-BorrowingWebDisjointPath {
  param($Operations, [string]$Left, [string]$Right)
  $relationOperation = $Operations.GetPathRelation
  if ((& $relationOperation $Left $Right) -cne 'disjoint') {
    Throw-BorrowingWebFailure input source-boundary 'Web input crosses the project boundary'
  }
}

function global:Open-BorrowingWebInput {
  param(
    [string]$Root,
    [string]$WebRawBytesPath,
    [string]$WebResponseMetadataPath,
    $Operations
  )
  if ($null -eq $Operations) { Throw-BorrowingWebFailure input source-boundary 'missing Web operations' }
  $getInfo = $Operations.GetSafePathInfo
  $rootInfo = & $getInfo $Root Directory input source-boundary
  $zoneInfo = & $getInfo (Join-Path $rootInfo.CanonicalPath '借鉴区') `
    Directory input source-boundary
  $rawBefore = & $getInfo $WebRawBytesPath File input source-boundary
  $metadataBefore = & $getInfo $WebResponseMetadataPath File input source-boundary
  foreach ($fileInfo in @($rawBefore, $metadataBefore)) {
    Assert-BorrowingWebDisjointPath $Operations $rootInfo.CanonicalPath $fileInfo.CanonicalPath
    Assert-BorrowingWebDisjointPath $Operations $zoneInfo.CanonicalPath $fileInfo.CanonicalPath
  }
  Assert-BorrowingWebDisjointPath $Operations `
    $rawBefore.CanonicalPath $metadataBefore.CanonicalPath
  if ($rawBefore.IdentityKey -ceq $metadataBefore.IdentityKey) {
    Throw-BorrowingWebFailure input source-boundary 'Web input files share one physical identity'
  }
  if ($rawBefore.Length -gt 67108864 -or $rawBefore.Length -gt 536870912 -or `
      $metadataBefore.Length -gt 65536) {
    Throw-BorrowingWebFailure input resource-limit 'Web input exceeds the fixed resource limits'
  }
  try {
    $rawSnapshot = Read-BorrowingStableSafeFileSnapshot `
      $rawBefore.CanonicalPath input source-boundary
    $metadataSnapshot = Read-BorrowingStableSafeFileSnapshot `
      $metadataBefore.CanonicalPath input source-boundary
  }
  catch { Throw-BorrowingWebFailure input source-boundary 'Web input could not be read safely' }
  if (-not (Test-BorrowingTrustedSnapshotEqual $rawBefore $rawSnapshot) -or `
      -not (Test-BorrowingTrustedSnapshotEqual $metadataBefore $metadataSnapshot)) {
    Throw-BorrowingWebFailure input source-boundary 'Web input changed while it was being opened'
  }
  [byte[]]$rawBytes = $rawSnapshot.Bytes
  [byte[]]$metadataBytes = $metadataSnapshot.Bytes
  $metadata = Read-BorrowingStrictWebMetadata -Bytes $metadataBytes
  [byte[]]$canonicalMetadata = ConvertTo-BorrowingCanonicalWebMetadataBytes -Metadata $metadata
  if ($canonicalMetadata.LongLength -gt 65536) {
    Throw-BorrowingWebFailure input resource-limit 'canonical Web metadata exceeds 65536 bytes'
  }
  return [pscustomobject]@{
    Schema = 'borrowing-web-input/v1'
    RootPath = $rootInfo.CanonicalPath
    RawPath = $rawSnapshot.CanonicalPath
    MetadataPath = $metadataSnapshot.CanonicalPath
    RawIdentityKey = $rawSnapshot.IdentityKey
    MetadataIdentityKey = $metadataSnapshot.IdentityKey
    RawBytes = $rawBytes
    MetadataBytes = $metadataBytes
    Metadata = $metadata
    CanonicalMetadataBytes = $canonicalMetadata
  }
}

function global:Write-BorrowingWebCandidate {
  param($Input, [string]$StagingPath, $Operations)
  $captureInput = $PSBoundParameters['Input']
  if ($null -eq $captureInput -or $null -eq $Operations) {
    Throw-BorrowingWebFailure capture capture-failed 'missing Web candidate input'
  }
  $getInfo = $Operations.GetSafePathInfo
  $stagingInfo = & $getInfo $StagingPath Directory capture capture-failed
  $relationOperation = $Operations.GetPathRelation
  if ((& $relationOperation $captureInput.RootPath $stagingInfo.CanonicalPath) -cne 'ancestor') {
    Throw-BorrowingWebFailure capture capture-failed 'Web staging is outside the project root'
  }
  $snapshotPath = Join-Path $stagingInfo.CanonicalPath '快照'
  $rawTarget = Join-Path $snapshotPath 'response.bin'
  $metadataTarget = Join-Path $snapshotPath 'response.metadata.json'
  if (Test-Path -LiteralPath $snapshotPath) {
    Throw-BorrowingWebFailure capture capture-failed 'Web snapshot target already exists'
  }
  $createDirectory = $Operations.CreateDirectory
  $writeBytes = $Operations.WriteAllBytes
  $readBytes = $Operations.ReadAllBytes
  try {
    & $createDirectory $snapshotPath
    & $writeBytes $rawTarget ([byte[]]$captureInput.RawBytes)
    & $writeBytes $metadataTarget ([byte[]]$captureInput.CanonicalMetadataBytes)
    [byte[]]$actualRaw = & $readBytes $rawTarget
    [byte[]]$actualMetadata = & $readBytes $metadataTarget
  }
  catch { Throw-BorrowingWebFailure capture capture-failed 'Web candidate could not be written' }
  $fingerprint = Get-BorrowingSha256Hex -Bytes ([byte[]]$captureInput.RawBytes)
  if ((Get-BorrowingSha256Hex $actualRaw) -cne $fingerprint -or `
      (Get-BorrowingSha256Hex $actualMetadata) -cne `
        (Get-BorrowingSha256Hex ([byte[]]$captureInput.CanonicalMetadataBytes))) {
    Throw-BorrowingWebFailure capture capture-failed 'Web candidate verification failed'
  }
  $redirectItems = @($captureInput.Metadata.RedirectChain | ForEach-Object {
      '{"status_code":' + ([string]$_.StatusCode) + ',"location_url":' +
        (ConvertTo-BorrowingCanonicalJsonString ([string]$_.LocationUrl)) + '}'
    })
  $webFacts = [pscustomobject]@{
    OriginalUrl = $captureInput.Metadata.OriginalUrl
    FinalUrl = $captureInput.Metadata.FinalUrl
    RedirectChain = '[' + ($redirectItems -join ',') + ']'
    StatusCode = $captureInput.Metadata.StatusCode
    Mime = $captureInput.Metadata.Mime
    Charset = ConvertTo-BorrowingJsonNullableString $captureInput.Metadata.Charset
    Etag = ConvertTo-BorrowingJsonNullableString $captureInput.Metadata.Etag
    LastModified = ConvertTo-BorrowingJsonNullableString $captureInput.Metadata.LastModified
    ResponseHash = $fingerprint
  }
  return [pscustomobject]@{
    Schema = 'borrowing-web-candidate/v1'
    SourceType = 'web'
    CanonicalLocator = $captureInput.Metadata.FinalUrl
    FingerprintAlgorithm = 'sha256-raw-bytes-v1'
    Fingerprint = $fingerprint
    Metadata = $captureInput.Metadata
    WebFacts = $webFacts
    CanonicalMetadataBytes = [byte[]]$captureInput.CanonicalMetadataBytes
    RawLength = [long]$captureInput.RawBytes.LongLength
    MetadataInputLength = [long]$captureInput.MetadataBytes.LongLength
    CanonicalMetadataLength = [long]$captureInput.CanonicalMetadataBytes.LongLength
    SnapshotPath = $snapshotPath
  }
}
