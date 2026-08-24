$ErrorActionPreference = 'Stop'

function Get-BorrowingResourceLimitRows {
  return @(
    @('leaf', '10000', '10000 合法；10001 失败'),
    @('总字节', '536870912', '536870912 合法；536870913 失败'),
    @('单项字节', '67108864', '67108864 合法；67108865 失败'),
    @('Git cache 字节', '536870912', '536870912 合法；536870913 失败'),
    @('深度', '64', '64 合法；65 失败'),
    @('路径 UTF-8 字节', '1024', '1024 合法；1025 失败'),
    @('metadata 字节', '65536', '65536 合法；65537 失败'),
    @('redirect', '10', '10 合法；11 失败'),
    @('Git timeout', '300000ms', '300000ms 合法；300001ms 失败'),
    @('P4t timeout', '120000ms', '120000ms 合法；120001ms 失败')
  )
}

function Get-BorrowingFacadeOutputLines {
  return @(
    'CZXT_BORROWING_CAPTURE_V1',
    'result=READY|REUSED|FAIL',
    'stage=<stage>',
    'source_id=<value|none>',
    'capture_id=<value|none>',
    'fingerprint=<value|none>',
    'capture_path=<absolute-path|none（未创建）>',
    'staging_path=<absolute-path|none（未创建）|none（已晋升）|none（已清理）>',
    'p4t_before=<not-run|start-failed|timeout|integer>',
    'p4t_after=<not-run|start-failed|timeout|integer>',
    'reason_code=<stable-code>',
    'reason=<single-line-sanitized-detail>'
  )
}

function Get-BorrowingFacadeSemanticsRows {
  return @(
    @('进程 exit code 全集', '0 / 10'),
    @('P4t exit 5', '映射 façade exit 10'),
    @(
      'stage 全集',
      'preflight / input / capture / candidate / idempotency / p4t-before / promotion / p4t-after / rollback / cleanup / complete'
    ),
    @(
      'reason_code 全集',
      'none / invalid-root / invalid-mode / missing-trusted-component / invalid-parameters / invalid-permissions / source-boundary / resource-limit / source-unsafe / capture-failed / candidate-invalid / idempotency-conflict / p4t-not-zero / p4t-process-failed / promotion-failed / rollback-failed / cleanup-failed'
    ),
    @('已处理失败 stderr', '为空；不得泄露来源内容')
  )
}

function Invoke-BorrowingCommandMachineCases {
  param([string]$Text)
  $usage = Get-BorrowingMarkdownSection $Text '使用边界'

  Invoke-CzxtContract 'command appendix locks v1 fixed resource limits' {
    $section = Get-BorrowingMarkdownSection $usage 'v1 固定资源上限' 3
    Assert-BorrowingExactOrderedTable $section @('资源项', '固定上限', '精确边界') `
      (Get-BorrowingResourceLimitRows) 'v1 fixed resource limit table'
    Assert-BorrowingLineSequence $section @(
      '所有上限固定且无 override；除 P4t timeout 使用 reason_code=p4t-process-failed 外，其余越界统一 reason_code=resource-limit。'
    ) 'v1 resource limit failure semantics'
  }

  Invoke-CzxtContract 'command appendix locks the 12-line facade output' {
    $section = Get-BorrowingMarkdownSection $usage 'façade 机读输出' 3
    Assert-BorrowingLineSequence $section (Get-BorrowingFacadeOutputLines) `
      'facade 12-line stdout'
  }

  Invoke-CzxtContract 'command appendix locks facade exit stage reason and stderr semantics' {
    $section = Get-BorrowingMarkdownSection $usage 'façade 机读输出' 3
    Assert-BorrowingExactOrderedTable $section @('机读项', '精确合同') `
      (Get-BorrowingFacadeSemanticsRows) 'facade machine semantics table'
  }
}
