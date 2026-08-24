$ErrorActionPreference = 'Stop'

function global:Test-BcvCanonicalGitLocator {
  param([string]$Value)
  try {
    if ($Value -cne $Value.Normalize([Text.NormalizationForm]::FormC) -or
        [Text.Encoding]::UTF8.GetByteCount($Value) -gt 1024 -or
        $Value -match '[\\%\s\x00-\x1F\x7F-\x9F\u2028\u2029]') { return $false }
    $uri = New-Object Uri($Value, [UriKind]::Absolute)
    if ($uri.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($uri.UserInfo) -or
        -not [string]::IsNullOrEmpty($uri.Query) -or
        -not [string]::IsNullOrEmpty($uri.Fragment) -or -not $uri.IsDefaultPort -or
        $uri.Port -ne 443 -or $uri.HostNameType -notin @(
          [UriHostNameType]::Dns, [UriHostNameType]::Basic
        ) -or $uri.Host.EndsWith('.')) { return $false }
    $idn = New-Object Globalization.IdnMapping
    $idn.UseStd3AsciiRules = $true
    $canonicalHost = $idn.GetAscii($uri.Host).ToLowerInvariant()
    $path = $uri.AbsolutePath
    if ($path -cnotmatch '\A/(?:[A-Za-z0-9_~-][A-Za-z0-9._~-]*/)*' +
        '[A-Za-z0-9_~-][A-Za-z0-9._~-]*\.git\z' -or $path.Contains('//')) { return $false }
    return $Value -ceq ('https://' + $canonicalHost + $path)
  }
  catch { return $false }
}

function global:Test-BcvGitRef {
  param([string]$Value, [string]$ExpectedType)
  $prefix = if ($ExpectedType -ceq 'branch') { 'refs/heads/' } else { 'refs/tags/' }
  if (-not $Value.StartsWith($prefix, [StringComparison]::Ordinal) -or
      [Text.Encoding]::UTF8.GetByteCount($Value) -gt 1024 -or
      $Value -match '[^\x21-\x7E]|[~^:?*\[\\]|\.\.|@\{|//|/\.|\.$|\.lock(?:/|$)') {
    return $false
  }
  foreach ($segment in $Value.Split('/')) {
    if ([string]::IsNullOrEmpty($segment) -or $segment.StartsWith('.') -or
        $segment.EndsWith('.')) { return $false }
  }
  return $true
}

function global:Test-BcvCanonicalWebFactToken {
  param([string]$Token)
  if ($Token -ceq 'null') { return $true }
  try {
    $node = ConvertFrom-BorrowingStrictJson -Bytes ([Text.Encoding]::UTF8.GetBytes($Token))
    if ($node.Kind -cne 'string' -or $node.Value.Contains("`r") -or $node.Value.Contains("`n")) {
      return $false
    }
    return (ConvertTo-BorrowingCanonicalJsonString $node.Value) -ceq $Token
  }
  catch { return $false }
}

function global:Get-BcvValidatedGitFacts {
  param($Card, [string[]]$Cells)
  if (-not (Test-BcvCanonicalGitLocator $Card.canonical_locator) -or
      $Card.fingerprint_algorithm -cne 'git-object' -or
      $Cells[1] -notin @('branch', 'tag') -or
      $Cells[2] -notin @('sha1', 'sha256') -or
      -not (Test-BcvGitRef $Cells[0] $Cells[1]) -or
      $Cells[5] -notin @('detected', 'not-detected') -or
      $Cells[6] -notin @('detected', 'not-detected')) {
    Throw-BorrowingCandidateFailure 'Git source facts are invalid'
  }
  $length = if ($Cells[2] -ceq 'sha1') { 40 } else { 64 }
  $oidPattern = '\A[0-9a-f]{' + $length + '}\z'
  if ($Cells[3] -cnotmatch $oidPattern -or $Cells[4] -cnotmatch $oidPattern -or
      $Card.fingerprint -cnotmatch $oidPattern -or $Card.fingerprint -cne $Cells[3]) {
    Throw-BorrowingCandidateFailure 'Git object lengths are invalid'
  }
  return [pscustomobject][ordered]@{
    Ref = $Cells[0]; RefType = $Cells[1]; ObjectFormat = $Cells[2]
    Commit = $Cells[3]; Tree = $Cells[4]
    SubmoduleStatus = $Cells[5]; LfsStatus = $Cells[6]
  }
}

function global:Get-BcvValidatedLocalFacts {
  param($Card, [string[]]$Cells)
  $displayName = if ($Card.canonical_locator.StartsWith('local:', [StringComparison]::Ordinal)) {
    $Card.canonical_locator.Substring(6)
  } else { '' }
  [void](Assert-BcvIdentifier $displayName)
  [int64]$count = 0; [int64]$bytes = 0
  if ($Card.fingerprint_algorithm -cne 'sha256-manifest-v1' -or
      $Card.fingerprint -cnotmatch '\A[0-9a-f]{64}\z' -or
      $Cells[0] -cne 'sha256-manifest-v1' -or
      $Cells[1] -cnotmatch '\A(?:0|[1-9][0-9]*)\z' -or
      $Cells[2] -cnotmatch '\A(?:0|[1-9][0-9]*)\z' -or
      -not [int64]::TryParse($Cells[1], [ref]$count) -or
      -not [int64]::TryParse($Cells[2], [ref]$bytes) -or
      $count -gt 10000 -or $bytes -gt 536870912 -or
      $Cells[3] -cne '无' -or $Cells[4] -cne '无') {
    Throw-BorrowingCandidateFailure 'Local source facts are invalid'
  }
  return [pscustomobject][ordered]@{
    ManifestAlgorithm = $Cells[0]; FileCount = $count; TotalBytes = $bytes
    Exclusions = $Cells[3]; Failures = $Cells[4]
  }
}
