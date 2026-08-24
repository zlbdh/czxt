$ErrorActionPreference = 'Stop'

function Get-BorrowingWebMetadataContractRows {
  return @(
    @('容器', 'UTF-8 无 BOM JSON 对象'),
    @(
      '固定且仅有键',
      'schema, original_url, final_url, redirect_chain, status_code, mime, charset, etag, last_modified'
    ),
    @('schema', 'borrowing-web-response/v1'),
    @('original_url / final_url', '净化绝对 HTTPS；禁止 userinfo、query、fragment、CR、LF'),
    @('redirect_chain', '有序 JSON 数组；空数组表示无重定向；数组顺序等于访问顺序'),
    @('redirect_chain 每项固定且仅有键', 'status_code, location_url'),
    @('redirect_chain[].status_code', '300..399 且不等于 304'),
    @(
      'redirect_chain[].location_url',
      '解析后的净化绝对 HTTPS；禁止 userinfo、query、fragment、CR、LF'
    ),
    @('redirect_chain 非空', '末项 location_url 必须等于 final_url'),
    @('redirect_chain 为空', 'original_url 必须等于 final_url'),
    @('status_code', '100..599'),
    @('mime', '非空媒体类型'),
    @('charset / etag / last_modified', '无 CR/LF 字符串或 null'),
    @(
      '键校验',
      '键名先按 JSON escape 解码再判重；顶层及 redirect_chain 每项均拒绝未知键、重复键、缺失键；a 与 \u0061 视为重复'
    ),
    @(
      'JSON 实现',
      '严格 tokenizer/parser；拒绝孤立 surrogate 与 trailing JSON；禁止用 ConvertFrom-Json/ConvertTo-Json 充当机器合同实现'
    ),
    @('redirect_count', '仅由 redirect_chain 数组长度派生；不得作为输入键'),
    @('canonical_locator 投影', '卡片 canonical_locator=规范化 final_url'),
    @(
      'redirect_chain 投影',
      '按输入顺序投影为无空白 JSON；每项键序 status_code,location_url；空链为 []'
    ),
    @(
      'nullable 投影',
      'charset / etag / last_modified 的 JSON null 投影为字面量 null'
    ),
    @('响应哈希', '响应哈希=fingerprint=raw SHA-256；不得信任 metadata 提供的 hash')
  )
}

. (Join-Path $PSScriptRoot 'borrowing-doc-command-machine-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-resource-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-output-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-web-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-parameter-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-artifact-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-git-plan-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-input-path-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-transaction-cases.ps1')

function Invoke-BorrowingCommandAppendixCases {
  param([string]$Text)

  Invoke-BorrowingCommandMachineCases -Text $Text
  Invoke-BorrowingCommandResourceCases -Text $Text
  Invoke-BorrowingCommandOutputCases -Text $Text
  Invoke-BorrowingCommandWebCases -Text $Text
  Invoke-BorrowingCommandParameterCases -Text $Text
  Invoke-BorrowingCommandArtifactCases -Text $Text
  Invoke-BorrowingCommandGitPlanCases -Text $Text
  Invoke-BorrowingCommandInputPathCases -Text $Text
  Invoke-BorrowingCommandTransactionCases -Text $Text

  Invoke-CzxtContract 'command appendix publishes exactly the three facade source calls' {
    Assert-BorrowingDocContainsAll $Text @(
      'name: borrowing-command-appendix', 'type: procedural'
    ) 'command appendix frontmatter'
    $sections = @{
      Git = Get-BorrowingMarkdownSection $Text 'Git 接入'
      Local = Get-BorrowingMarkdownSection $Text '本地接入'
      Web = Get-BorrowingMarkdownSection $Text 'Web 接入'
    }
    foreach ($sourceType in @('Git', 'Local', 'Web')) {
      Assert-BorrowingOrderedText $sections[$sourceType] @(
        'capture-borrowing-source.ps1', ("-SourceType {0}" -f $sourceType)
      ) ("facade call for {0}" -f $sourceType)
    }
  }

  Invoke-CzxtContract 'command appendix explains encapsulated capture guarantees' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 接入'
    Assert-BorrowingDocContainsAll $git @('Git 安全参数', '由执行器') 'Git encapsulation'
    $local = Get-BorrowingMarkdownSection $Text '本地接入'
    Assert-BorrowingOrderedText $local @(
      'source-before', 'source-after', 'staging-content', 'promoted-content',
      'stored manifest.tsv', '逐字节相等'
    ) 'Local manifest order'
    Assert-BorrowingDocContainsAll $local @('同卷') 'Local staging boundary'
    $web = Get-BorrowingMarkdownSection $Text 'Web 接入'
    Assert-BorrowingDocContainsAll $web @('原始响应字节', '响应元数据', 'SHA-256') 'Web raw-byte boundary'
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    Assert-BorrowingDocContainsAll $usage @('staging', '原子晋升', 'P4t', '不联网') 'atomic and offline P4t boundary'
  }

  Invoke-CzxtContract 'command appendix locks the WebResponseMetadataPath input contract' {
    $web = Get-BorrowingMarkdownSection $Text 'Web 接入'
    $contract = Get-BorrowingMarkdownSection $web 'WebResponseMetadataPath 输入合同' 3
    Assert-BorrowingExactOrderedTable $contract @('metadata 项', '精确合同') `
      (Get-BorrowingWebMetadataContractRows) 'Web response metadata machine table'
  }

  Invoke-CzxtContract 'command appendix covers authorization recovery and diagnosis' {
    $authorization = Get-BorrowingMarkdownSection $Text '授权参数'
    Assert-BorrowingDocContainsAll $authorization @(
      '授权时间', '授权来源', '适用范围', '偏离默认值', '缺一不可'
    ) 'command authorization'
    $recovery = Get-BorrowingMarkdownSection $Text '失败恢复'
    Assert-BorrowingDocContainsAll $recovery @(
      '失败阶段', 'staging 路径', '重试', '不得生成 ready'
    ) 'command recovery'
    $diagnosis = Get-BorrowingMarkdownSection $Text '诊断'
    Assert-BorrowingDocContainsAll $diagnosis @('P4t', '只读', '离线') 'command diagnosis'
  }

  Invoke-CzxtContract 'command appendix publishes the trusted close transaction call' {
    $section = Get-BorrowingMarkdownSection $Text '关闭事项'
    Assert-BorrowingOrderedText $section @(
      'close-borrowing-item.ps1', '-Root', '-CardPath', '-ClosedAt',
      '-Reason', '-Confirmation'
    ) 'trusted close command'
    Assert-BorrowingDocContainsAll $section @(
      '.staging-close-', '原活动卡', '失败候选', '完整根 P4t'
    ) 'trusted close recovery'
  }

  Invoke-CzxtContract 'command appendix locks preflight staging failure output' {
    $recovery = Get-BorrowingMarkdownSection $Text '失败恢复'
    Assert-BorrowingLineSequence $recovery $script:BorrowingStagingFailureLines `
      'command staging failure output'
  }

  Invoke-CzxtContract 'command appendix hides transport injection and manual capture' {
    Assert-BorrowingCommandPublicSurface $Text
  }
}
