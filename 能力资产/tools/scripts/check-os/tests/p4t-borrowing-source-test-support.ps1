$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'p4t-borrowing-source-cache-test-support.ps1')

function New-P4tPermissionRows {
  param([string]$SourceType)
  $captured = '2026-07-19T01:02:03.456Z'
  $remote = $SourceType -in @('git', 'web')
  $values = [ordered]@{
    rights_status = 'unverified'
    access_policy = $(if ($remote) { 'source-read-only' } else { 'local-read-only' })
    reuse_scope = 'inspect-and-analyze-only'
    execution_policy = 'deny'
    network_policy = $(if ($remote) { 'source-read-only' } else { 'deny' })
    storage_policy = 'local-only'
    distribution_policy = 'deny'
    upstream_write_policy = 'deny'
    auto_refresh = 'false'
  }
  $rows = @()
  foreach ($entry in $values.GetEnumerator()) {
    $deviated = $remote -and $entry.Key -in @('access_policy', 'network_policy')
    $time = if ($deviated) { '2026-07-19T01:00:00.000Z' } else { $captured }
    $source = if ($deviated) { 'approved-fixture' } else { 'default-policy' }
    $rows += ('| {0} | {1} | {2} | {3} | current-capture |' -f
      $entry.Key, $entry.Value, $time, $source)
  }
  return [pscustomobject]@{ Values = $values; Rows = [string[]]$rows }
}

function New-P4tSourceCardText {
  param($Record, $Facts)
  $permissions = New-P4tPermissionRows -SourceType $Record.SourceType
  $p = $permissions.Values
  $na7 = '| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |'
  $na5 = '| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |'
  $na9 = '| not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |'
  $gitRow = $na7
  $localRow = $na5
  $webRow = $na9
  if ($Record.SourceType -eq 'git') {
    $gitRow = '| refs/heads/main | branch | {0} | {1} | {2} | not-detected | not-detected |' -f
      $Facts.ObjectFormat, $Record.Fingerprint, $Facts.Tree
  }
  elseif ($Record.SourceType -eq 'local') {
    $localRow = '| sha256-manifest-v1 | {0} | {1} | 无 | 无 |' -f
      $Facts.FileCount, $Facts.TotalBytes
  }
  else {
    $webRow = '| https://example.invalid/start | https://example.invalid/final | [{{"status_code":301,"location_url":"https://example.invalid/final"}}] | 200 | text/plain | "utf-8" | null | null | {0} |' -f
      $Record.Fingerprint
  }
  $history = @('| 2026-07-19T01:02:03.456Z | none | ready | initial-capture | capture-executor |')
  if ($Record.Status -eq 'retired') {
    $history += '| 2026-07-20T01:02:03.456Z | ready | retired | no-active-reference | operating-system-pm |'
  }
  $lines = @(
    '---',
    'schema: borrowing-source/v1',
    ('source_id: ' + $Record.SourceId),
    ('capture_id: ' + $Record.CaptureId),
    ('source_type: ' + $Record.SourceType),
    ('capture_status: ' + $Record.Status),
    ('canonical_locator: ' + $Record.CanonicalLocator),
    ('fingerprint_algorithm: ' + $Record.FingerprintAlgorithm),
    ('fingerprint: ' + $Record.Fingerprint),
    'captured_at: 2026-07-19T01:02:03.456Z',
    ('rights_status: ' + $p.rights_status),
    ('access_policy: ' + $p.access_policy),
    ('reuse_scope: ' + $p.reuse_scope),
    ('execution_policy: ' + $p.execution_policy),
    ('network_policy: ' + $p.network_policy),
    ('storage_policy: ' + $p.storage_policy),
    ('distribution_policy: ' + $p.distribution_policy),
    ('upstream_write_policy: ' + $p.upstream_write_policy),
    ('auto_refresh: ' + $p.auto_refresh),
    '---',
    '# 来源版本卡',
    '',
    '- 适用项目：`P4t fixture`',
    ('- 正式路径：`借鉴区/来源/{0}/{1}/来源版本卡.md`' -f $Record.SourceId, $Record.CaptureId),
    '- 卡片只记录净化后的稳定身份与审计事实；绝对路径只进入同目录下被忽略的 `capture.local.json`，凭据不得写入。',
    '',
    '## 权限授权',
    '',
    '默认行的授权来源写 `default-policy`。任何偏离默认策略的生效值，都必须逐维填写 ISO 8601 授权时间、可审计来源和有限适用范围。',
    '',
    '| 权限维度 | 生效值 | 授权时间 | 授权来源 | 适用范围 |',
    '|---|---|---|---|---|'
  ) + $permissions.Rows + @(
    '', '## Git 捕获事实', '',
    '| ref | ref 类型 | object format | commit | tree | submodule 状态 | LFS 状态 |',
    '|---|---|---|---|---|---|---|', $gitRow,
    '', '## 本地捕获事实', '',
    '| manifest 算法 | 文件数 | 字节数 | 排除项 | 失败项 |',
    '|---|---:|---:|---|---|', $localRow,
    '', '## 网页捕获事实', '',
    '| 原始 URL | 最终 URL | 重定向 | 状态码 | MIME | charset | ETag | Last-Modified | 响应哈希 |',
    '|---|---|---|---:|---|---|---|---|---|', $webRow,
    '', '## 管理历史', '',
    '正式卡只允许 `ready` 或 `retired`；ready 后身份与指纹字段不可改写。退役只能追加历史，且必须先确认没有活动事项引用。',
    '', '| 时间 | 旧状态 | 新状态 | 原因 | 确认 |', '|---|---|---|---|---|'
  ) + $history
  return ($lines -join "`n") + "`n"
}

function New-P4tSourceCapture {
  param(
    [string]$Root,
    [ValidateSet('git', 'local', 'web')][string]$SourceType,
    [string]$SourceId = '',
    [ValidateSet('ready', 'retired')][string]$Status = 'ready',
    [string]$PayloadText = 'fixture-payload'
  )
  if ([string]::IsNullOrEmpty($SourceId)) { $SourceId = 'source-' + $SourceType }
  $sourceRoot = Join-Path $Root ('借鉴区\来源\' + $SourceId)
  [void](New-Item -ItemType Directory -Path $sourceRoot -Force)
  $staging = Join-Path $sourceRoot ('.staging-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
  [void](New-Item -ItemType Directory -Path $staging)
  if ($SourceType -eq 'git') {
    $facts = New-P4tGitCacheFacts -CapturePath $staging -PayloadText $PayloadText
    $algorithm = 'git-object'
    $locator = 'https://example.invalid/' + $SourceId + '.git'
  }
  elseif ($SourceType -eq 'local') {
    $facts = New-P4tLocalCacheFacts -CapturePath $staging -PayloadText $PayloadText
    $algorithm = 'sha256-manifest-v1'
    $locator = 'local:' + $SourceId
  }
  else {
    $facts = New-P4tWebCacheFacts -CapturePath $staging -PayloadText $PayloadText
    $algorithm = 'sha256-raw-bytes-v1'
    $locator = 'https://example.invalid/final'
  }
  $captureId = '{0}-20260719-{1}' -f $SourceType, $facts.Fingerprint.Substring(0, 12)
  $capturePath = Join-Path $sourceRoot $captureId
  Assert-CzxtTrue (-not (Test-Path -LiteralPath $capturePath)) ('fixture capture collision: ' + $captureId)
  Move-Item -LiteralPath $staging -Destination $capturePath
  $record = [pscustomobject]@{
    SourceId = $SourceId
    CaptureId = $captureId
    SourceType = $SourceType
    Status = $Status
    FingerprintAlgorithm = $algorithm
    Fingerprint = $facts.Fingerprint
    CanonicalLocator = $locator
    CapturePath = $capturePath
    CardPath = Join-Path $capturePath '来源版本卡.md'
  }
  Write-P4tUtf8 $record.CardPath (New-P4tSourceCardText -Record $record -Facts $facts)
  return $record
}

function Set-P4tFrontmatterField {
  param([string]$Path, [string]$Name, [string]$Value)
  $text = [IO.File]::ReadAllText($Path, $script:P4tUtf8NoBom)
  $pattern = '(?m)^' + [regex]::Escape($Name) + ':.*$'
  $matches = [regex]::Matches($text, $pattern)
  Assert-CzxtEqual 1 $matches.Count ('fixture field count: ' + $Name)
  $updated = [regex]::Replace($text, $pattern, ($Name + ': ' + $Value), 1)
  Write-P4tUtf8 $Path $updated
}

function New-P4tSourceState {
  param([object[]]$Records)
  return [pscustomobject]@{
    ReadyCaptures = @($Records | Where-Object { $_.Status -eq 'ready' })
    RetiredCaptures = @($Records | Where-Object { $_.Status -eq 'retired' })
    Warnings = @()
    Failures = @()
    ExitCode = 0
  }
}
