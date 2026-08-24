$ErrorActionPreference = 'Stop'

function global:Throw-BorrowingCandidateFailure {
  param(
    [string]$Reason = 'source candidate is invalid',
    [string]$ReasonCode = 'candidate-invalid'
  )
  if (Get-Command Throw-BorrowingFailure -CommandType Function -ErrorAction SilentlyContinue) {
    Throw-BorrowingFailure candidate $ReasonCode $Reason
  }
  $exception = New-Object InvalidOperationException $Reason
  $exception.Data['BorrowingStage'] = 'candidate'
  $exception.Data['BorrowingReasonCode'] = $ReasonCode
  throw $exception
}

function global:Test-BcvKnownFailure {
  param($Exception)
  return $null -ne $Exception -and
    -not [string]::IsNullOrEmpty([string]$Exception.Data['BorrowingStage']) -and
    -not [string]::IsNullOrEmpty([string]$Exception.Data['BorrowingReasonCode'])
}

function global:Get-BcvSha256Hex {
  param([byte[]]$Bytes)
  if (Get-Command Get-BorrowingSha256Hex -CommandType Function -ErrorAction SilentlyContinue) {
    return Get-BorrowingSha256Hex -Bytes $Bytes
  }
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}

function global:Test-BcvBytesEqual {
  param([byte[]]$Left, [byte[]]$Right)
  if ($null -eq $Left -or $null -eq $Right -or $Left.Length -ne $Right.Length) {
    return $false
  }
  for ($index = 0; $index -lt $Left.Length; $index++) {
    if ($Left[$index] -ne $Right[$index]) { return $false }
  }
  return $true
}

function global:Read-BcvStrictUtf8Card {
  param([string]$Path)
  try {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
      Throw-BorrowingCandidateFailure 'source card is missing'
    }
    [byte[]]$bytes = Read-BorrowingStableSafeFileBytes $Path candidate source-unsafe
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      Throw-BorrowingCandidateFailure 'source card BOM is forbidden'
    }
    $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
  }
  catch {
    if (Test-BcvKnownFailure $_.Exception) { throw }
    Throw-BorrowingCandidateFailure 'source card encoding is invalid'
  }
  if ($text.Contains("`r") -or
      -not $text.EndsWith("`n", [StringComparison]::Ordinal) -or
      $text.EndsWith("`n`n", [StringComparison]::Ordinal)) {
    Throw-BorrowingCandidateFailure 'source card line endings are invalid'
  }
  $allLines = $text.Split(@([char]10), [StringSplitOptions]::None)
  if ($allLines.Count -lt 21 -or $allLines[$allLines.Count - 1] -cne '') {
    Throw-BorrowingCandidateFailure 'source card structure is invalid'
  }
  [string[]]$lines = @($allLines[0..($allLines.Count - 2)])
  foreach ($line in $lines) {
    if ($line -match '[ \t]\z') {
      Throw-BorrowingCandidateFailure 'source card has trailing whitespace'
    }
  }
  return [pscustomobject][ordered]@{
    Path = [IO.Path]::GetFullPath($Path)
    Bytes = $bytes
    Text = $text
    Lines = $lines
  }
}

function global:Read-BorrowingFrontmatter {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$Path)
  $document = Read-BcvStrictUtf8Card $Path
  $keys = @(
    'schema', 'source_id', 'capture_id', 'source_type', 'capture_status',
    'canonical_locator', 'fingerprint_algorithm', 'fingerprint', 'captured_at',
    'rights_status', 'access_policy', 'reuse_scope', 'execution_policy',
    'network_policy', 'storage_policy', 'distribution_policy',
    'upstream_write_policy', 'auto_refresh'
  )
  if ($document.Lines.Count -lt 20 -or $document.Lines[0] -cne '---' -or
      $document.Lines[19] -cne '---') {
    Throw-BorrowingCandidateFailure 'source card frontmatter delimiters are invalid'
  }
  $values = [ordered]@{}
  for ($index = 0; $index -lt $keys.Count; $index++) {
    $prefix = $keys[$index] + ': '
    $line = $document.Lines[$index + 1]
    if (-not $line.StartsWith($prefix, [StringComparison]::Ordinal)) {
      Throw-BorrowingCandidateFailure 'source card frontmatter keys are invalid'
    }
    $value = $line.Substring($prefix.Length)
    try { $normalized = $value.Normalize([Text.NormalizationForm]::FormC) }
    catch { Throw-BorrowingCandidateFailure 'source card frontmatter value is invalid' }
    if ([string]::IsNullOrEmpty($value) -or $normalized -cne $value -or
        $value -match '[\x00-\x1F\x7F-\x9F\u2028\u2029\|\x60]') {
      Throw-BorrowingCandidateFailure 'source card frontmatter value is unsafe'
    }
    $values[$keys[$index]] = $value
  }
  $result = [ordered]@{
    Path = $document.Path; Bytes = $document.Bytes; Text = $document.Text
    Lines = $document.Lines; FieldOrder = [string[]]$keys
  }
  foreach ($key in $keys) { $result[$key] = $values[$key] }
  return [pscustomobject]$result
}

function global:ConvertFrom-BcvCardRow {
  param([string]$Line, [int]$CellCount)
  if (-not $Line.StartsWith('| ', [StringComparison]::Ordinal) -or
      -not $Line.EndsWith(' |', [StringComparison]::Ordinal)) {
    Throw-BorrowingCandidateFailure 'source card table row is invalid'
  }
  [string[]]$cells = @($Line.Substring(2, $Line.Length - 4).Split(
      @(' | '), [StringSplitOptions]::None
    ))
  if ($cells.Count -ne $CellCount -or
      ('| ' + ($cells -join ' | ') + ' |') -cne $Line) {
    Throw-BorrowingCandidateFailure 'source card table cells are invalid'
  }
  foreach ($cell in $cells) {
    try { $normalized = $cell.Normalize([Text.NormalizationForm]::FormC) }
    catch { Throw-BorrowingCandidateFailure 'source card table cell is invalid' }
    if ([string]::IsNullOrEmpty($cell) -or $normalized -cne $cell -or
        $cell -match '[\x00-\x1F\x7F-\x9F\u2028\u2029\|\x60]' -or
        $cell -match '[ \t]\z') {
      Throw-BorrowingCandidateFailure 'source card table cell is unsafe'
    }
  }
  return ,$cells
}

function global:Test-BcvUtcTimestamp {
  param([string]$Value)
  if ($Value -cnotmatch
      '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z\z') {
    return $false
  }
  $parsed = [DateTimeOffset]::MinValue
  return [DateTimeOffset]::TryParseExact(
    $Value, "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$parsed
  )
}

function global:Assert-BcvIdentifier {
  param([string]$Value)
  if ($Value -cnotmatch '\A[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?\z') {
    Throw-BorrowingCandidateFailure 'source identifier is invalid'
  }
  $stem = $Value.Split('.')[0]
  if ($stem -match '\A(?:con|prn|aux|nul|com[1-9]|lpt[1-9])\z') {
    Throw-BorrowingCandidateFailure 'source identifier is reserved'
  }
  return $Value
}
