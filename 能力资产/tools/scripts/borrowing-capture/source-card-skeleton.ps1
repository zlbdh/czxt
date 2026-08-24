$ErrorActionPreference = 'Stop'

$sourceCardSkeletonRoot = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
if (-not (Get-Command Read-BorrowingStableSafeFileBytes -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $sourceCardSkeletonRoot 'trusted-file-read.ps1')
}

function global:Throw-BorrowingSourceCardFailure {
  param([string]$Stage, [string]$ReasonCode, [string]$Reason)
  if (Get-Command Throw-BorrowingFailure -CommandType Function -ErrorAction SilentlyContinue) {
    Throw-BorrowingFailure $Stage $ReasonCode $Reason
  }
  $exception = New-Object InvalidOperationException $Reason
  $exception.Data['BorrowingStage'] = $Stage
  $exception.Data['BorrowingReasonCode'] = $ReasonCode
  throw $exception
}

function global:Get-BorrowingSourceCardHash {
  param([byte[]]$Bytes)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}

function global:ConvertTo-BorrowingCardCell {
  param($Value)
  if ($null -eq $Value) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid 'source-card value is missing'
  }
  if ($Value -is [IFormattable]) {
    $text = $Value.ToString($null, [Globalization.CultureInfo]::InvariantCulture)
  }
  else { $text = [string]$Value }
  try { $normalized = $text.Normalize([Text.NormalizationForm]::FormC) }
  catch { Throw-BorrowingSourceCardFailure candidate candidate-invalid 'source-card value is invalid' }
  if ([string]::IsNullOrEmpty($normalized) -or $normalized -cne $text -or
      $normalized -match '[\x00-\x1F\x7F-\x9F\u2028\u2029\|\x60]' -or
      $normalized -match '[ \t]\z') {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid 'source-card value is unsafe'
  }
  return $normalized
}

function global:New-BorrowingCardRow {
  param([object[]]$Cells)
  $safe = @($Cells | ForEach-Object { ConvertTo-BorrowingCardCell $_ })
  return '| ' + ($safe -join ' | ') + ' |'
}

function global:Get-BorrowingValidatedSourceCardSkeleton {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$Root)
  $path = Join-Path ([IO.Path]::GetFullPath($Root)) '借鉴区\模板\来源版本卡.md'
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component 'source-card skeleton is missing'
  }
  try {
    [byte[]]$bytes = Read-BorrowingStableSafeFileBytes $path preflight `
      missing-trusted-component
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw 'BOM is forbidden' }
    $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
  }
  catch {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card skeleton encoding is invalid'
  }
  if ($text.Contains("`r") -or
      -not $text.EndsWith("`n", [StringComparison]::Ordinal) -or
      $text.EndsWith("`n`n", [StringComparison]::Ordinal)) {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card skeleton line endings are invalid'
  }
  $lines = $text.Split(@([char]10), [StringSplitOptions]::None)
  if ($lines.Count -ne 68 -or $lines[67] -cne '') {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card skeleton structure is invalid'
  }
  $prefix = '- 适用项目：`'
  $projectLine = $lines[22]
  if (-not $projectLine.StartsWith($prefix, [StringComparison]::Ordinal) -or
      -not $projectLine.EndsWith('`', [StringComparison]::Ordinal) -or
      $projectLine.Length -le ($prefix.Length + 1)) {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card project line is invalid'
  }
  $projectName = $projectLine.Substring($prefix.Length, $projectLine.Length - $prefix.Length - 1)
  if ($projectName -cne $projectName.Normalize([Text.NormalizationForm]::FormC) -or
      [Text.Encoding]::UTF8.GetByteCount($projectName) -gt 512 -or
      $projectName -match '[\x00-\x1F\x7F-\x9F\u2028\u2029\|\x60]') {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card project line is unsafe'
  }
  $fixed = @($lines[0..66])
  # 运行时构造占位符，避免实例化器改写校验器自身的规范化常量。
  $canonicalProjectToken = '{' + '{PROJECT_NAME}' + '}'
  $fixed[22] = '- 适用项目：`' + $canonicalProjectToken + '`'
  $fixedBytes = [Text.Encoding]::UTF8.GetBytes(($fixed -join "`n") + "`n")
  if ((Get-BorrowingSourceCardHash $fixedBytes) -cne
      'c383093ed2d6903ba91b654605c8e9398fce87b81a20a78b18ce1f652205db13') {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card skeleton content is invalid'
  }
  return [pscustomobject][ordered]@{
    Path = $path
    Lines = @($lines[0..66])
    ProjectLine = $projectLine
    ProjectName = $projectName
  }
}

function global:Get-BorrowingLocalStateProperty {
  param($Object, [string[]]$Names)
  foreach ($name in $Names) {
    $property = $Object.PSObject.Properties[$name]
    if ($null -ne $property -and $null -ne $property.Value) {
      return [string]$property.Value
    }
  }
  return $null
}

function global:ConvertTo-BorrowingLocalStatePathJson {
  param([string]$Path)
  if ([string]::IsNullOrEmpty($Path)) { return 'null' }
  try { $normalized = $Path.Normalize([Text.NormalizationForm]::FormC) }
  catch {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid 'local-state path is invalid'
  }
  if ($normalized -cne $Path -or $normalized -cnotmatch '\A[A-Z]:\\' -or
      $normalized -match '[/\x00-\x1F\x7F-\x9F\u2028\u2029]') {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'local-state path is not canonical'
  }
  if (Test-BorrowingCredentialPathMaterial $normalized) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'local-state path contains credential material'
  }
  return ConvertTo-BorrowingCanonicalJsonString $normalized
}

function global:New-BorrowingCaptureLocalStateBytes {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Alias('Request')]$Input,
    [Parameter(Position = 1)]
    [ValidateSet('git', 'local', 'web')][string]$SourceType
  )
  $captureInput = $PSBoundParameters['Input']
  if (-not $PSBoundParameters.ContainsKey('SourceType')) {
    $SourceType = [string]$captureInput.SourceType
  }
  $SourceType = $SourceType.ToLowerInvariant()
  if (@('git', 'local', 'web') -cnotcontains $SourceType) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'local-state source type is invalid'
  }
  $local = Get-BorrowingLocalStateProperty $captureInput `
    @('LocalSourcePath', 'SourcePath', 'LocalPath')
  $raw = Get-BorrowingLocalStateProperty $captureInput `
    @('WebRawBytesPath', 'RawPath')
  $metadata = Get-BorrowingLocalStateProperty $captureInput `
    @('WebResponseMetadataPath', 'MetadataPath')
  if (($SourceType -eq 'git' -and
        ($null -ne $local -or $null -ne $raw -or $null -ne $metadata)) -or
      ($SourceType -eq 'local' -and
        ($null -eq $local -or $null -ne $raw -or $null -ne $metadata)) -or
      ($SourceType -eq 'web' -and
        ($null -ne $local -or $null -eq $raw -or $null -eq $metadata))) {
    Throw-BorrowingSourceCardFailure candidate candidate-invalid `
      'local-state path combination is invalid'
  }
  $json = '{"schema":"borrowing-capture-local-state/v1","source_type":' +
    (ConvertTo-BorrowingCanonicalJsonString $SourceType) + ',"local_source_path":' +
    (ConvertTo-BorrowingLocalStatePathJson $local) + ',"web_raw_bytes_path":' +
    (ConvertTo-BorrowingLocalStatePathJson $raw) + ',"web_response_metadata_path":' +
    (ConvertTo-BorrowingLocalStatePathJson $metadata) + "}`n"
  return [Text.Encoding]::UTF8.GetBytes($json)
}
