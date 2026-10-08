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


# Canonicalize only the two exact trusted source-card presentations. Raw bytes
# remain unchanged for identity, fingerprints, and sealing.
function global:ConvertTo-BorrowingLegacySourceCardLines {
  param([string[]]$Lines)
  [string[]]$copy = @($Lines)
  if ($copy.Count -lt 67 -or $copy[20] -cne '# Source Capture Card') { return ,$copy }
  $fixed = @(
    @{ Index = 20; English = '# Source Capture Card'; Legacy = '# 来源版本卡' },
    @{ Index = 24; English = '- Record only sanitized stable identity and audit facts. Absolute paths belong only in the ignored `capture.local.json` in the same directory. Never write credentials.'; Legacy = '- 卡片只记录净化后的稳定身份与审计事实；绝对路径只进入同目录下被忽略的 `capture.local.json`，凭据不得写入。' },
    @{ Index = 26; English = '## Permission authorization'; Legacy = '## 权限授权' },
    @{ Index = 28; English = 'Use `default-policy` as the authorization source for default rows. For every effective value that deviates from the default, record an ISO 8601 authorization time, auditable source, and limited scope for that permission dimension.'; Legacy = '默认行的授权来源写 `default-policy`。任何偏离默认策略的生效值，都必须逐维填写 ISO 8601 授权时间、可审计来源和有限适用范围。' },
    @{ Index = 30; English = '| Permission dimension | Effective value | Authorization time | Authorization source | Scope |'; Legacy = '| 权限维度 | 生效值 | 授权时间 | 授权来源 | 适用范围 |' },
    @{ Index = 42; English = '## Git capture facts'; Legacy = '## Git 捕获事实' },
    @{ Index = 44; English = '| ref | Ref type | Object format | commit | tree | Submodule status | LFS status |'; Legacy = '| ref | ref 类型 | object format | commit | tree | submodule 状态 | LFS 状态 |' },
    @{ Index = 48; English = '## Local capture facts'; Legacy = '## 本地捕获事实' },
    @{ Index = 50; English = '| Manifest algorithm | File count | Byte count | Exclusions | Failures |'; Legacy = '| manifest 算法 | 文件数 | 字节数 | 排除项 | 失败项 |' },
    @{ Index = 54; English = '## Web capture facts'; Legacy = '## 网页捕获事实' },
    @{ Index = 56; English = '| Original URL | Final URL | Redirects | Status code | MIME | charset | ETag | Last-Modified | Response hash |'; Legacy = '| 原始 URL | 最终 URL | 重定向 | 状态码 | MIME | charset | ETag | Last-Modified | 响应哈希 |' },
    @{ Index = 60; English = '## Management history'; Legacy = '## 管理历史' },
    @{ Index = 62; English = 'Formal cards allow only `ready` or `retired`. Identity and fingerprint fields are immutable after becoming ready. Retirement may only append history and must first confirm that no active item references the capture.'; Legacy = '正式卡只允许 `ready` 或 `retired`；ready 后身份与指纹字段不可改写。退役只能追加历史，且必须先确认没有活动事项引用。' },
    @{ Index = 64; English = '| Time | Previous status | New status | Reason | Confirmation |'; Legacy = '| 时间 | 旧状态 | 新状态 | 原因 | 确认 |' }
  )
  foreach ($entry in $fixed) {
    if ($copy[$entry.Index] -cne $entry.English) {
      throw 'source card English static structure is invalid'
    }
    $copy[$entry.Index] = $entry.Legacy
  }
  foreach ($entry in @(
    @{ Index = 22; English = '- Project: `'; Legacy = '- 适用项目：`' },
    @{ Index = 23; English = '- Formal path: `'; Legacy = '- 正式路径：`' }
  )) {
    $line = $copy[$entry.Index]
    if (-not $line.StartsWith($entry.English, [StringComparison]::Ordinal) -or
        -not $line.EndsWith('`.', [StringComparison]::Ordinal)) {
      throw 'source card English identity line is invalid'
    }
    $copy[$entry.Index] = $entry.Legacy +
      $line.Substring($entry.English.Length, $line.Length - $entry.English.Length - 1)
  }
  return ,$copy
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
  $isEnglish = $lines[20] -ceq '# Source Capture Card'
  $prefix = if ($isEnglish) { '- Project: `' } else { '- 适用项目：`' }
  $suffix = if ($isEnglish) { '`.' } else { '`' }
  $projectLine = $lines[22]
  if (-not $projectLine.StartsWith($prefix, [StringComparison]::Ordinal) -or
      -not $projectLine.EndsWith($suffix, [StringComparison]::Ordinal) -or
      $projectLine.Length -le ($prefix.Length + $suffix.Length)) {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card project line is invalid'
  }
  $projectName = $projectLine.Substring($prefix.Length, $projectLine.Length - $prefix.Length - $suffix.Length)
  if ($projectName -cne $projectName.Normalize([Text.NormalizationForm]::FormC) -or
      [Text.Encoding]::UTF8.GetByteCount($projectName) -gt 512 -or
      $projectName -match '[\x00-\x1F\x7F-\x9F\u2028\u2029\|\x60]') {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card project line is unsafe'
  }
  $fixed = @($lines[0..66])
  # 运行时构造占位符，避免实例化器改写校验器自身的规范化常量。
  $canonicalProjectToken = '{' + '{PROJECT_NAME}' + '}'
  $fixed[22] = $prefix + $canonicalProjectToken + $suffix
  $fixedBytes = [Text.Encoding]::UTF8.GetBytes(($fixed -join "`n") + "`n")
  $expectedHash = if ($isEnglish) { '75398a27a98f0cb67a83b0471624508e01035247e785bcec0f2695dc4966b554' }
    else { 'c383093ed2d6903ba91b654605c8e9398fce87b81a20a78b18ce1f652205db13' }
  if ((Get-BorrowingSourceCardHash $fixedBytes) -cne $expectedHash) {
    Throw-BorrowingSourceCardFailure preflight missing-trusted-component `
      'source-card skeleton content is invalid'
  }
  return [pscustomobject][ordered]@{
    Path = $path
    Lines = @($lines[0..66])
    ProjectLine = $projectLine
    ProjectName = $projectName
    IsEnglish = $isEnglish
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
