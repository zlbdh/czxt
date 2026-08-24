$ErrorActionPreference = 'Stop'

$sourceCandidateCacheLayoutPath = Join-Path `
  ([IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)) `
  'source-candidate-cache-layout.ps1'
if (-not (Get-Command Get-BcvExpectedSnapshotMembers -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . $sourceCandidateCacheLayoutPath
}

function global:Get-BcvExpectedCacheMembers {
  param([string]$SourceType)
  switch -CaseSensitive ($SourceType) {
    'git' {
      return @(
        [pscustomobject]@{ RelativePath = '快照\repository.git'; Kind = 'Directory' },
        [pscustomobject]@{ RelativePath = 'capture.local.json'; Kind = 'File' }
      )
    }
    'local' {
      return @(
        [pscustomobject]@{ RelativePath = '快照\内容'; Kind = 'Directory' },
        [pscustomobject]@{ RelativePath = '快照\manifest.tsv'; Kind = 'File' },
        [pscustomobject]@{ RelativePath = 'capture.local.json'; Kind = 'File' }
      )
    }
    'web' {
      return @(
        [pscustomobject]@{ RelativePath = '快照\response.bin'; Kind = 'File' },
        [pscustomobject]@{ RelativePath = '快照\response.metadata.json'; Kind = 'File' },
        [pscustomobject]@{ RelativePath = 'capture.local.json'; Kind = 'File' }
      )
    }
    default { Throw-BorrowingCandidateFailure 'cache source type is invalid' }
  }
}

function global:Test-BcvSafeCachePath {
  param([string]$Path, [string]$Kind)
  try {
    $pathType = if ($Kind -ceq 'Directory') { 'Container' }
      elseif ($Kind -ceq 'File') { 'Leaf' }
      else { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType $pathType)) { return $false }
    if (-not (Get-Command Get-BorrowingSafePathInfo `
          -CommandType Function -ErrorAction SilentlyContinue)) { return $false }
    [void](Get-BorrowingSafePathInfo $Path $Kind candidate source-unsafe)
    return $true
  }
  catch { return $false }
}

function global:Get-BcvStateNodeValue {
  param($Node, [bool]$Nullable)
  if ($null -eq $Node) { throw 'missing state node' }
  if ($Nullable -and $Node.Kind -ceq 'null') { return $null }
  if ($Node.Kind -cne 'string') { throw 'invalid state node' }
  return [string]$Node.Value
}

function global:Test-BcvCanonicalStatePath {
  param([string]$Value)
  try {
    if ([string]::IsNullOrEmpty($Value) -or
        $Value -cne $Value.Normalize([Text.NormalizationForm]::FormC) -or
        $Value -cnotmatch '\A[A-Z]:\\' -or
        $Value -match '[/\x00-\x1F\x7F-\x9F\u2028\u2029]' -or
        $Value.IndexOf(':', 2) -ge 0 -or
        (Test-BorrowingCredentialPathMaterial $Value)) { return $false }
    $tail = $Value.Substring(3)
    if ($tail.Length -gt 0) {
      foreach ($segment in $tail.Split([char]'\')) {
        if ([string]::IsNullOrEmpty($segment) -or $segment.EndsWith(' ') -or
            $segment.EndsWith('.') -or $segment -match '[<>"|?*]') { return $false }
        $stem = $segment.Split('.')[0]
        if ($stem -match '\A(?:con|prn|aux|nul|com[1-9]|lpt[1-9])\z') { return $false }
      }
    }
    return [IO.Path]::GetFullPath($Value) -ceq $Value
  }
  catch { return $false }
}

function global:Test-BcvCaptureLocalState {
  param([string]$Path, [string]$SourceType)
  try {
    if (-not (Test-BcvSafeCachePath $Path File)) { return $false }
    [byte[]]$bytes = Read-BorrowingStableSafeFileBytes `
      $Path candidate source-unsafe
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { return $false }
    $node = ConvertFrom-BorrowingStrictJson -Bytes $bytes
    $keys = @(
      'schema', 'source_type', 'local_source_path', 'web_raw_bytes_path',
      'web_response_metadata_path'
    )
    if ($node.Kind -cne 'object' -or $node.Value.Count -ne 5) { return $false }
    foreach ($key in $keys) { if (-not $node.Value.ContainsKey($key)) { return $false } }
    $schema = Get-BcvStateNodeValue $node.Value['schema'] $false
    $type = Get-BcvStateNodeValue $node.Value['source_type'] $false
    $local = Get-BcvStateNodeValue $node.Value['local_source_path'] $true
    $raw = Get-BcvStateNodeValue $node.Value['web_raw_bytes_path'] $true
    $metadata = Get-BcvStateNodeValue $node.Value['web_response_metadata_path'] $true
    if ($schema -cne 'borrowing-capture-local-state/v1' -or $type -cne $SourceType -or
        ($SourceType -ceq 'git' -and
          ($null -ne $local -or $null -ne $raw -or $null -ne $metadata)) -or
        ($SourceType -ceq 'local' -and
          ($null -eq $local -or $null -ne $raw -or $null -ne $metadata)) -or
        ($SourceType -ceq 'web' -and
          ($null -ne $local -or $null -eq $raw -or $null -eq $metadata))) {
      return $false
    }
    foreach ($value in @($local, $raw, $metadata)) {
      if ($null -ne $value -and -not (Test-BcvCanonicalStatePath $value)) { return $false }
    }
    $jsonValue = {
      param($value)
      if ($null -eq $value) { return 'null' }
      return ConvertTo-BorrowingCanonicalJsonString $value
    }
    $canonical = '{"schema":"borrowing-capture-local-state/v1","source_type":' +
      (ConvertTo-BorrowingCanonicalJsonString $type) + ',"local_source_path":' +
      (& $jsonValue $local) + ',"web_raw_bytes_path":' + (& $jsonValue $raw) +
      ',"web_response_metadata_path":' + (& $jsonValue $metadata) + "}`n"
    return Test-BcvBytesEqual $bytes ([Text.Encoding]::UTF8.GetBytes($canonical))
  }
  catch { return $false }
}

function global:Get-BorrowingIgnoredCacheState {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)][string]$CaptureDirectory,
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet('git', 'local', 'web')][string]$SourceType
  )
  $capture = [IO.Path]::GetFullPath($CaptureDirectory).TrimEnd('\')
  $members = @(Get-BcvExpectedCacheMembers $SourceType)
  $snapshot = Join-Path $capture '快照'
  $captureSafe = Test-BcvSafeCachePath $capture Directory
  $snapshotPresent = Test-Path -LiteralPath $snapshot
  $present = New-Object 'Collections.Generic.List[string]'
  $missing = New-Object 'Collections.Generic.List[string]'
  foreach ($member in $members) {
    $path = Join-Path $capture $member.RelativePath
    if (Test-Path -LiteralPath $path) { [void]$present.Add($member.RelativePath) }
    else { [void]$missing.Add($member.RelativePath) }
  }
  $cardExists = Test-BcvSafeCachePath (Join-Path $capture '来源版本卡.md') File
  $cardOnly = @([pscustomobject]@{ Name = '来源版本卡.md'; Kind = 'File' })
  $completeCapture = @(
    [pscustomobject]@{ Name = '来源版本卡.md'; Kind = 'File' },
    [pscustomobject]@{ Name = 'capture.local.json'; Kind = 'File' },
    [pscustomobject]@{ Name = '快照'; Kind = 'Directory' }
  )
  if ($captureSafe -and -not $snapshotPresent -and $present.Count -eq 0 -and
      $cardExists -and (Test-BcvExactDirectoryMembers $capture $cardOnly)) {
    $state = 'AllMissing'
  }
  elseif ($captureSafe -and $snapshotPresent -and $missing.Count -eq 0 -and $cardExists) {
    $healthy = (Test-BcvExactDirectoryMembers $capture $completeCapture) -and
      (Test-BcvExactDirectoryMembers $snapshot `
        @(Get-BcvExpectedSnapshotMembers $SourceType))
    foreach ($member in $members) {
      if (-not (Test-BcvSafeCachePath (Join-Path $capture $member.RelativePath) $member.Kind)) {
        $healthy = $false
      }
    }
    if ($healthy -and -not (Test-BcvCaptureLocalState `
          (Join-Path $capture 'capture.local.json') $SourceType)) { $healthy = $false }
    $state = if ($healthy) { 'Healthy' } else { 'Conflict' }
  }
  else { $state = 'Conflict' }
  return [pscustomobject][ordered]@{
    State = $state
    SourceType = $SourceType
    CaptureDirectory = $capture
    ExpectedMembers = @($members | ForEach-Object { $_.RelativePath })
    PresentMembers = @($present)
    MissingMembers = @($missing)
    ParentSnapshotPresent = [bool]$snapshotPresent
  }
}
