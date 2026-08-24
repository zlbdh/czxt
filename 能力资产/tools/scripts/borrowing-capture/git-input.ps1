$ErrorActionPreference = 'Stop'

function global:Stop-Bg {
  param($Stage, $Code, $Reason = 'Git capture failed')
  Throw-BorrowingFailure -Stage $Stage -ReasonCode $Code -Reason $Reason
}

function global:ConvertTo-BorrowingGitLocator {
  param([string]$Value)
  try { $v = $Value.Normalize([Text.NormalizationForm]::FormC) }
  catch { Stop-Bg input invalid-parameters }
  if ([string]::IsNullOrWhiteSpace($v) -or
      [Text.Encoding]::UTF8.GetByteCount($v) -gt 1024 -or
      $v -match '[\\%\s\x00-\x1F\x7F-\x9F\u2028\u2029]') {
    Stop-Bg input invalid-parameters
  }
  $u = $null
  if (-not [Uri]::TryCreate($v, [UriKind]::Absolute, [ref]$u) -or
      $u.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($u.UserInfo) -or
      -not [string]::IsNullOrEmpty($u.Query) -or
      -not [string]::IsNullOrEmpty($u.Fragment) -or $u.Port -ne 443 -or
      $u.Host.EndsWith('.')) { Stop-Bg input invalid-parameters }
  try {
    $idn = New-Object Globalization.IdnMapping
    $idn.UseStd3AsciiRules = $true
    $asciiHost = $idn.GetAscii($u.Host).ToLowerInvariant()
  }
  catch { Stop-Bg input invalid-parameters }
  $ip = $null
  if ([Net.IPAddress]::TryParse($asciiHost, [ref]$ip) -or
      $asciiHost.Length -gt 253) { Stop-Bg input invalid-parameters }
  foreach ($label in $asciiHost.Split('.')) {
    if ($label.Length -gt 63 -or
        $label -cnotmatch '\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z') {
      Stop-Bg input invalid-parameters
    }
  }
  $m = [regex]::Match($v, '\Ahttps://(?<a>[^/]+)(?<p>/.*)\z',
    [Text.RegularExpressions.RegexOptions]'IgnoreCase,CultureInvariant')
  if (-not $m.Success) { Stop-Bg input invalid-parameters }
  $authority = $m.Groups['a'].Value
  if ($authority.Contains(':') -and -not $authority.EndsWith(':443')) {
    Stop-Bg input invalid-parameters
  }
  $path = $m.Groups['p'].Value
  if ($path.EndsWith('/') -or $path -match '//') {
    Stop-Bg input invalid-parameters
  }
  $parts = @($path.Substring(1).Split('/'))
  foreach ($part in $parts) {
    if ($part -cnotmatch '\A[A-Za-z0-9_~-][A-Za-z0-9._~-]*\z') {
      Stop-Bg input invalid-parameters
    }
  }
  if ($parts[-1] -cnotmatch '\A[A-Za-z0-9_~-][A-Za-z0-9._~-]*\.git\z') {
    Stop-Bg input invalid-parameters
  }
  return 'https://{0}{1}' -f $asciiHost, $path
}

function global:ConvertTo-BorrowingGitRef {
  param([string]$Value)
  try { $v = $Value.Normalize([Text.NormalizationForm]::FormC) }
  catch { Stop-Bg input invalid-parameters }
  if ([string]::IsNullOrWhiteSpace($v) -or
      [Text.Encoding]::UTF8.GetByteCount($v) -gt 1024 -or
      $v -cnotmatch '\A[\x21-\x7E]+\z' -or $v.Contains('|') -or
      $v.Contains('`')) { Stop-Bg input invalid-parameters }
  if ($v.StartsWith('refs/heads/', [StringComparison]::Ordinal)) {
    $type = 'branch'
  }
  elseif ($v.StartsWith('refs/tags/', [StringComparison]::Ordinal)) {
    $type = 'tag'
  }
  else { Stop-Bg input invalid-parameters }
  try {
    $gitCommand = Get-Command git.exe -CommandType Application -ErrorAction Stop |
      Select-Object -First 1
    $output = @(& $gitCommand.Source check-ref-format $v 2>&1)
    $exitCode = $LASTEXITCODE
  }
  catch {
    Stop-Bg preflight missing-trusted-component `
      'trusted Git capability is unavailable'
  }
  if ($exitCode -ne 0 -or $output.Count -ne 0) {
    Stop-Bg input invalid-parameters
  }
  return [pscustomobject][ordered]@{ FullRef = $v; RefType = $type }
}
