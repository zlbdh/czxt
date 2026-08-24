$ErrorActionPreference = 'Stop'

function Get-BorrowingTemplatePermissionRows {
  $time = '1970-01-01T00:00:00.000Z'
  $values = @(
    @('rights_status', 'unverified'), @('access_policy', 'local-read-only'),
    @('reuse_scope', 'inspect-and-analyze-only'), @('execution_policy', 'deny'),
    @('network_policy', 'deny'), @('storage_policy', 'local-only'),
    @('distribution_policy', 'deny'), @('upstream_write_policy', 'deny'),
    @('auto_refresh', 'false')
  )
  return @($values | ForEach-Object {
      ,@($_[0], $_[1], $time, 'default-policy', 'current-capture')
    })
}

function Assert-BorrowingCanonicalUtf8File {
  param([string]$Path, [string]$Context)
  $bytes = [IO.File]::ReadAllBytes($Path)
  Assert-CzxtTrue ($bytes.Length -gt 0) ("{0} is empty" -f $Context)
  $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
    $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
  Assert-CzxtTrue (-not $bom) ("{0} has UTF-8 BOM" -f $Context)
  $strict = New-Object System.Text.UTF8Encoding($false, $true)
  try { $text = $strict.GetString($bytes) }
  catch { throw ("{0} is not strict UTF-8" -f $Context) }
  Assert-CzxtTrue (-not $text.Contains("`r")) ("{0} contains CR" -f $Context)
  Assert-CzxtEqual 10 ([int]$bytes[$bytes.Length - 1]) ("{0} final LF" -f $Context)
  if ($bytes.Length -gt 1) {
    Assert-CzxtTrue ($bytes[$bytes.Length - 2] -ne 10) `
      ("{0} has more than one trailing LF" -f $Context)
  }
}

function Invoke-BorrowingSourceCardTemplateCases {
  param([string]$Root)
  Invoke-CzxtContract 'source card template locks canonical projection bytes' {
    $relative = '借鉴区/模板/来源版本卡.md'
    $path = Get-BorrowingDocPath $Root $relative
    Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) 'source card template missing'
    Assert-BorrowingCanonicalUtf8File $path 'source card template'
    $card = Get-BorrowingDocText $Root $relative
    Assert-BorrowingLineSequence $card @(
      'capture_id: local-19700101-placeholder', 'source_type: local',
      'capture_status: ready'
    ) 'template capture identity lines'
    Assert-BorrowingLineSequence $card @(
      'captured_at: 1970-01-01T00:00:00.000Z'
    ) 'template canonical captured_at'
    Assert-BorrowingExactOrderedTable $card @(
      '权限维度', '生效值', '授权时间', '授权来源', '适用范围'
    ) (Get-BorrowingTemplatePermissionRows) 'template permission rows'
    $git = @('ref', 'ref 类型', 'object format', 'commit', 'tree', 'submodule 状态', 'LFS 状态')
    Assert-BorrowingExactOrderedTable (Get-BorrowingMarkdownSection $card 'Git 捕获事实') `
      $git @(,@($git | ForEach-Object { 'not-applicable' })) 'template Git facts'
    Assert-BorrowingExactOrderedTable (Get-BorrowingMarkdownSection $card '本地捕获事实') `
      @('manifest 算法', '文件数', '字节数', '排除项', '失败项') `
      @(,@('sha256-manifest-v1', '0', '0', '无', '无')) 'template Local facts'
    $web = @('原始 URL', '最终 URL', '重定向', '状态码', 'MIME', 'charset',
      'ETag', 'Last-Modified', '响应哈希')
    Assert-BorrowingExactOrderedTable (Get-BorrowingMarkdownSection $card '网页捕获事实') `
      $web @(,@($web | ForEach-Object { 'not-applicable' })) 'template Web facts'
    Assert-BorrowingExactOrderedTable (Get-BorrowingMarkdownSection $card '管理历史') `
      @('时间', '旧状态', '新状态', '原因', '确认') `
      @(,@('1970-01-01T00:00:00.000Z', 'none', 'ready',
          'initial-capture', 'capture-executor')) 'template initial history'
  }
}
