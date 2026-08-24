$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'json-parser.ps1')
if (-not (Get-Command Test-BorrowingCredentialMaterial -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . (Join-Path $PSScriptRoot 'credential-safety.ps1')
}

function global:Throw-BorrowingWebMetadataFailure {
  param([string]$ReasonCode = 'source-boundary')
  $exception = New-Object InvalidOperationException('invalid Web response metadata')
  $exception.Data['BorrowingStage'] = 'input'
  $exception.Data['BorrowingReasonCode'] = $ReasonCode
  throw $exception
}

function global:Assert-BorrowingJsonObjectShape {
  param($Node, [string[]]$Keys)
  if ($null -eq $Node -or $Node.Kind -cne 'object' -or $Node.Value.Count -ne $Keys.Count) {
    Throw-BorrowingWebMetadataFailure
  }
  foreach ($key in $Keys) {
    if (-not $Node.Value.ContainsKey($key)) { Throw-BorrowingWebMetadataFailure }
  }
}

function global:Get-BorrowingJsonStringValue {
  param($Node)
  if ($null -eq $Node -or $Node.Kind -cne 'string') { Throw-BorrowingWebMetadataFailure }
  try { return $Node.Value.Normalize([Text.NormalizationForm]::FormC) }
  catch { Throw-BorrowingWebMetadataFailure }
}

function global:Get-BorrowingJsonNullableStringValue {
  param($Node)
  if ($null -ne $Node -and $Node.Kind -ceq 'null') { return $null }
  $value = Get-BorrowingJsonStringValue $Node
  if ($value.IndexOf("`r", [StringComparison]::Ordinal) -ge 0 -or `
      $value.IndexOf("`n", [StringComparison]::Ordinal) -ge 0) {
    Throw-BorrowingWebMetadataFailure
  }
  return $value
}

function global:Get-BorrowingJsonIntegerValue {
  param($Node, [int]$Minimum, [int]$Maximum, [int[]]$Excluded = @())
  if ($null -eq $Node -or $Node.Kind -cne 'number' -or `
      $Node.Lexeme -notmatch '^(?:0|[1-9][0-9]*)$') {
    Throw-BorrowingWebMetadataFailure
  }
  $value = 0
  if (-not [int]::TryParse($Node.Lexeme, [Globalization.NumberStyles]::None, `
      [Globalization.CultureInfo]::InvariantCulture, [ref]$value) -or `
      $value -lt $Minimum -or $value -gt $Maximum -or $Excluded -contains $value) {
    Throw-BorrowingWebMetadataFailure
  }
  return $value
}

function global:Assert-BorrowingWebMetadataCredentialSafe {
  param([AllowNull()][string]$Value)
  if ($null -ne $Value -and (Test-BorrowingCredentialMaterial $Value)) {
    Throw-BorrowingWebMetadataFailure
  }
}

function global:ConvertTo-BorrowingUpperPercentEscapes {
  param([string]$Value)
  return [regex]::Replace($Value, '%[0-9A-Fa-f]{2}', {
      param($match)
      $match.Value.ToUpperInvariant()
    })
}

function global:ConvertTo-BorrowingCanonicalHttpsUrl {
  param([string]$Value)
  try { $normalized = $Value.Normalize([Text.NormalizationForm]::FormC) }
  catch { Throw-BorrowingWebMetadataFailure }
  Assert-BorrowingWebMetadataCredentialSafe $normalized
  if ([string]::IsNullOrEmpty($normalized) -or $normalized -match '[\\\r\n?#]' -or `
      $normalized -match '(?i)%0d|%0a' -or `
      [regex]::IsMatch($normalized, '%(?![0-9A-Fa-f]{2})')) {
    Throw-BorrowingWebMetadataFailure
  }
  $uri = $null
  if (-not [Uri]::TryCreate($normalized, [UriKind]::Absolute, [ref]$uri) -or `
      -not $uri.Scheme.Equals('https', [StringComparison]::OrdinalIgnoreCase) -or `
      -not [string]::IsNullOrEmpty($uri.UserInfo) -or -not $uri.IsDefaultPort -or `
      $uri.Port -ne 443 -or [string]::IsNullOrEmpty($uri.Host) -or `
      $uri.Host.EndsWith('.', [StringComparison]::Ordinal)) {
    Throw-BorrowingWebMetadataFailure
  }
  try { $canonicalHost = $uri.IdnHost.ToLowerInvariant() }
  catch { Throw-BorrowingWebMetadataFailure }
  if ($uri.HostNameType -eq [UriHostNameType]::IPv6) {
    $canonicalHost = '[' + $canonicalHost + ']'
  }
  $path = $uri.GetComponents([UriComponents]::Path, [UriFormat]::UriEscaped)
  $path = ConvertTo-BorrowingUpperPercentEscapes $path
  if ([string]::IsNullOrEmpty($path)) { $path = '/' } else { $path = '/' + $path }
  return 'https://' + $canonicalHost + $path
}

function global:Assert-BorrowingMimeValue {
  param([string]$Value)
  $pattern = '^[a-z0-9][a-z0-9!#$%&''*+.^_~-]*/[a-z0-9][a-z0-9!#$%&''*+.^_~-]*$'
  if ([string]::IsNullOrEmpty($Value) -or `
      -not $Value.Equals($Value.ToLowerInvariant(), [StringComparison]::Ordinal) -or `
      $Value.IndexOf('|') -ge 0 -or $Value.IndexOf('`') -ge 0 -or `
      $Value.IndexOf(';') -ge 0) {
    Throw-BorrowingWebMetadataFailure
  }
  $match = [regex]::Match($Value, $pattern, [Text.RegularExpressions.RegexOptions]::CultureInvariant)
  if (-not $match.Success -or $match.Index -ne 0 -or $match.Length -ne $Value.Length) {
    Throw-BorrowingWebMetadataFailure
  }
}

function global:Read-BorrowingStrictWebMetadata {
  param([byte[]]$Bytes)
  $root = ConvertFrom-BorrowingStrictJson -Bytes $Bytes
  $keys = @(
    'schema', 'original_url', 'final_url', 'redirect_chain', 'status_code',
    'mime', 'charset', 'etag', 'last_modified'
  )
  Assert-BorrowingJsonObjectShape $root $keys
  $schema = Get-BorrowingJsonStringValue $root.Value['schema']
  if ($schema -cne 'borrowing-web-response/v1') { Throw-BorrowingWebMetadataFailure }
  $originalUrl = ConvertTo-BorrowingCanonicalHttpsUrl `
    (Get-BorrowingJsonStringValue $root.Value['original_url'])
  $finalUrl = ConvertTo-BorrowingCanonicalHttpsUrl `
    (Get-BorrowingJsonStringValue $root.Value['final_url'])
  $chainNode = $root.Value['redirect_chain']
  if ($null -eq $chainNode -or $chainNode.Kind -cne 'array') {
    Throw-BorrowingWebMetadataFailure
  }
  if ($chainNode.Value.Count -gt 10) { Throw-BorrowingWebMetadataFailure 'resource-limit' }
  $redirects = New-Object 'Collections.Generic.List[object]'
  foreach ($item in $chainNode.Value) {
    Assert-BorrowingJsonObjectShape $item @('status_code', 'location_url')
    [void]$redirects.Add([pscustomobject]@{
        StatusCode = Get-BorrowingJsonIntegerValue $item.Value['status_code'] 300 399 @(304)
        LocationUrl = ConvertTo-BorrowingCanonicalHttpsUrl `
          (Get-BorrowingJsonStringValue $item.Value['location_url'])
      })
  }
  if (($redirects.Count -eq 0 -and $originalUrl -cne $finalUrl) -or `
      ($redirects.Count -gt 0 -and $redirects[$redirects.Count - 1].LocationUrl -cne $finalUrl)) {
    Throw-BorrowingWebMetadataFailure
  }
  $mime = Get-BorrowingJsonStringValue $root.Value['mime']
  Assert-BorrowingMimeValue $mime
  $charset = Get-BorrowingJsonNullableStringValue $root.Value['charset']
  $etag = Get-BorrowingJsonNullableStringValue $root.Value['etag']
  $lastModified = Get-BorrowingJsonNullableStringValue $root.Value['last_modified']
  foreach ($value in @($mime, $charset, $etag, $lastModified)) {
    Assert-BorrowingWebMetadataCredentialSafe $value
  }
  return [pscustomobject]@{
    Schema = $schema
    OriginalUrl = $originalUrl
    FinalUrl = $finalUrl
    RedirectChain = $redirects
    StatusCode = Get-BorrowingJsonIntegerValue $root.Value['status_code'] 100 599
    Mime = $mime
    Charset = $charset
    Etag = $etag
    LastModified = $lastModified
  }
}

function global:ConvertTo-BorrowingJsonNullableString {
  param($Value)
  if ($null -eq $Value) { return 'null' }
  return ConvertTo-BorrowingCanonicalJsonString ([string]$Value)
}

function global:ConvertTo-BorrowingCanonicalWebMetadataBytes {
  param($Metadata)
  $redirectItems = @($Metadata.RedirectChain | ForEach-Object {
      '{"status_code":' + ([string]$_.StatusCode) + ',"location_url":' +
        (ConvertTo-BorrowingCanonicalJsonString ([string]$_.LocationUrl)) + '}'
    })
  $json = '{"schema":' + (ConvertTo-BorrowingCanonicalJsonString $Metadata.Schema) +
    ',"original_url":' + (ConvertTo-BorrowingCanonicalJsonString $Metadata.OriginalUrl) +
    ',"final_url":' + (ConvertTo-BorrowingCanonicalJsonString $Metadata.FinalUrl) +
    ',"redirect_chain":[' + ($redirectItems -join ',') + ']' +
    ',"status_code":' + ([string]$Metadata.StatusCode) +
    ',"mime":' + (ConvertTo-BorrowingCanonicalJsonString $Metadata.Mime) +
    ',"charset":' + (ConvertTo-BorrowingJsonNullableString $Metadata.Charset) +
    ',"etag":' + (ConvertTo-BorrowingJsonNullableString $Metadata.Etag) +
    ',"last_modified":' + (ConvertTo-BorrowingJsonNullableString $Metadata.LastModified) + "}`n"
  return [Text.Encoding]::UTF8.GetBytes($json)
}
