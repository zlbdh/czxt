$ErrorActionPreference = 'Stop'

function global:ConvertFrom-BorrowingCredentialJsonUnicodeEscapes {
  param([AllowNull()][string]$Value)
  if ([string]::IsNullOrEmpty($Value) -or
      $Value.IndexOf('\u', [StringComparison]::Ordinal) -lt 0) { return $Value }
  $builder = New-Object Text.StringBuilder
  for ($index = 0; $index -lt $Value.Length; $index++) {
    if ($Value[$index] -cne [char]'\' -or $index + 1 -ge $Value.Length -or
        $Value[$index + 1] -cne [char]'u') {
      [void]$builder.Append($Value[$index])
      continue
    }
    if ($index + 5 -ge $Value.Length) { throw 'credential JSON Unicode escape is truncated' }
    [int]$codeUnit = 0
    $hex = $Value.Substring($index + 2, 4)
    if (-not [int]::TryParse(
        $hex, [Globalization.NumberStyles]::AllowHexSpecifier,
        [Globalization.CultureInfo]::InvariantCulture, [ref]$codeUnit)) {
      throw 'credential JSON Unicode escape is invalid'
    }
    $index += 5
    if ([char]::IsHighSurrogate([char]$codeUnit)) {
      if ($index + 6 -ge $Value.Length -or $Value[$index + 1] -cne [char]'\' -or
          $Value[$index + 2] -cne [char]'u') {
        throw 'credential JSON Unicode surrogate pair is truncated'
      }
      [int]$lowUnit = 0
      $lowHex = $Value.Substring($index + 3, 4)
      if (-not [int]::TryParse(
          $lowHex, [Globalization.NumberStyles]::AllowHexSpecifier,
          [Globalization.CultureInfo]::InvariantCulture, [ref]$lowUnit) -or
          -not [char]::IsLowSurrogate([char]$lowUnit)) {
        throw 'credential JSON Unicode surrogate pair is invalid'
      }
      [void]$builder.Append([char]$codeUnit).Append([char]$lowUnit)
      $index += 6
    }
    elseif ([char]::IsLowSurrogate([char]$codeUnit)) {
      throw 'credential JSON Unicode low surrogate is unpaired'
    }
    else { [void]$builder.Append([char]$codeUnit) }
  }
  return $builder.ToString()
}

function global:Get-BorrowingCredentialInspectionVariants {
  param([AllowNull()][string]$Value)
  if ([string]::IsNullOrEmpty($Value)) { return @() }
  $variants = New-Object 'Collections.Generic.List[string]'
  $seen = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
  $current = $Value
  # 最多允许四次内容变化，第五轮只用于确认解码已经稳定。
  $maximumDecodePasses = 5
  for ($depth = 0; $depth -lt $maximumDecodePasses; $depth++) {
    $formDecoded = $current.Replace('+', ' ')
    $jsonDecoded = ConvertFrom-BorrowingCredentialJsonUnicodeEscapes $current
    $jsonQuoteDecoded = $jsonDecoded.Replace('\/', '/').Replace('\"', '"')
    $jsonFormDecoded = ConvertFrom-BorrowingCredentialJsonUnicodeEscapes $formDecoded
    $jsonFormDecoded = $jsonFormDecoded.Replace('\/', '/').Replace('\"', '"')
    try { $decoded = [Uri]::UnescapeDataString($current) }
    catch { throw 'credential inspection URL decode failed' }
    $urlJsonDecoded = ConvertFrom-BorrowingCredentialJsonUnicodeEscapes $decoded
    $urlJsonDecoded = $urlJsonDecoded.Replace('\/', '/').Replace('\"', '"')
    $urlFormDecoded = $decoded.Replace('+', ' ')
    $next = ConvertFrom-BorrowingCredentialJsonUnicodeEscapes $urlFormDecoded
    $next = $next.Replace('\/', '/').Replace('\"', '"')
    foreach ($candidate in @(
        $current, $formDecoded, $jsonDecoded, $jsonQuoteDecoded,
        $jsonFormDecoded, $decoded, $urlJsonDecoded, $urlFormDecoded, $next)) {
      if ($seen.Add($candidate)) { [void]$variants.Add($candidate) }
    }
    if ($next -ceq $current) { return $variants.ToArray() }
    $current = $next
  }
  # 只有检测到稳定点才可放行；达到上限仍变化视为潜在隐藏凭据。
  throw 'credential inspection URL decode did not stabilize'
}

function global:Test-BorrowingCredentialUriUserInfo {
  param([string]$Value)
  if ([string]::IsNullOrEmpty($Value)) { return $false }
  if ([regex]::IsMatch($Value,
      '(?i)(?:[a-z][a-z0-9+.-]*:)?//[^\s/?#@"''<>\\]+@')) { return $true }
  $uri = $null
  if ([Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -and
      -not [string]::IsNullOrEmpty($uri.UserInfo)) { return $true }
  if ($Value.StartsWith('//', [StringComparison]::Ordinal)) {
    $networkUri = $null
    if ([Uri]::TryCreate(('https:' + $Value), [UriKind]::Absolute, [ref]$networkUri) -and
        -not [string]::IsNullOrEmpty($networkUri.UserInfo)) { return $true }
  }
  return $false
}

function global:Test-BorrowingAuthorizationCredential {
  param([string]$Value)
  $pattern = '(?i)(?:\A|[^A-Za-z0-9])(?<scheme>Bearer|Basic)\s+' +
    '(?<token>[A-Za-z0-9._~+/-]+={0,})(?=\z|[^A-Za-z0-9._~+/=-])'
  $proseTokens = @(
    'authentication', 'authorization',
    'authentication-enabled', 'authorization-enabled',
    'authentication-disabled', 'authorization-disabled',
    'authentication-based', 'authorization-based'
  )
  foreach ($match in @([regex]::Matches($Value, $pattern))) {
    $token = $match.Groups['token'].Value.ToLowerInvariant()
    $proseToken = $token.TrimEnd([char[]]@('.'))
    if ($proseTokens -notcontains $proseToken) { return $true }
  }
  return $false
}

function global:Test-BorrowingCredentialMaterial {
  [CmdletBinding()]
  param([AllowNull()][string]$Value)
  try {
    foreach ($variant in @(Get-BorrowingCredentialInspectionVariants $Value)) {
      if (Test-BorrowingCredentialUriUserInfo $variant) { return $true }
      $separator = '(?:[_.-]|[ \t]+)?'
      $sensitiveKey = '(?:(?:aws' + $separator + ')?(?:access' + $separator +
        'key(?:' + $separator + 'id)?|secret' + $separator + 'access' +
        $separator + 'key)|access' + $separator + 'token|refresh' + $separator +
        'token|id' + $separator + 'token|bearer' + $separator + 'token|x' +
        $separator + 'api' + $separator + 'key|api' + $separator + 'key|client' +
        $separator + 'secret|authorization|password|passwd|secret|credential|' +
        'credentials|token)'
      if ($variant -match ('(?i)(?:\A|[^A-Za-z0-9_.-])["'']?' + $sensitiveKey +
          '["'']?\s*[:=]\s*["'']?[^\s\}\]"'']+')) {
        return $true
      }
      if (Test-BorrowingAuthorizationCredential $variant) { return $true }
      if ($variant -match
          '(?i)(?:\A|[^A-Za-z0-9])(?:sk-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|(?:AKIA|ASIA)[A-Z0-9]{16})(?:\z|[^A-Za-z0-9])') {
        return $true
      }
      if ($variant -match '(?i)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----') {
        return $true
      }
    }
    return $false
  }
  catch { return $true }
}

function global:Test-BorrowingCredentialPathMaterial {
  param([AllowNull()][string]$Value)
  try {
    if ([string]::IsNullOrEmpty($Value)) { return $false }
    return Test-BorrowingCredentialMaterial $Value.Replace('\', ' ')
  }
  catch { return $true }
}
