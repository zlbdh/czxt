$ErrorActionPreference = 'Stop'

function Get-BorrowingFacadeParameterRows {
  return @(
    @('脚本绑定', 'CmdletBinding(PositionalBinding=$false)'),
    @(
      '显式业务参数',
      '完整且仅有 Root,SourceType,SourceId,GitLocator,GitRef,LocalPath,LocalDisplayName,WebRawBytesPath,WebResponseMetadataPath,RightsStatus,AccessPolicy,ReuseScope,ExecutionPolicy,NetworkPolicy,StoragePolicy,DistributionPolicy,UpstreamWritePolicy,AutoRefresh,AuthorizationTime,AuthorizationSource,AuthorizationScope；按此顺序；全部为可选 [string]'
    ),
    @('禁止参数属性', 'Mandatory / ValidateSet / ValidatePattern 均不存在'),
    @(
      '禁止绑定入口',
      'Alias / ValueFromPipeline / ValueFromPipelineByPropertyName / ValueFromRemainingArguments 均不存在'
    ),
    @('默认表达式', '全部显式参数均无默认表达式；默认值只在脚本内按 SourceType 投影'),
    @('SourceType 输入', '只接受 Git/Local/Web 的 OrdinalIgnoreCase 等价值；禁止 Trim；分别投影 git/local/web'),
    @('必填语义', '名称必须存在于 PSBoundParameters 且值非空白；未绑定、空串、全空白均失败'),
    @('禁止语义', '名称只要存在于 PSBoundParameters 即失败；空串或 null 不能规避'),
    @('已知参数缺失或非法', '脚本内处理；固定 12 行；exit 10'),
    @('矩阵失败', 'stage=input；reason_code=invalid-parameters；P4t 均 not-run；零写入'),
    @('隐式 common parameters', '属于 PowerShell host 边界；不承载业务语义；固定 12 行不保证'),
    @('host 绑定错误', 'unknown / duplicate / positional-extra；合同外'),
    @('支持调用', '仅 powershell -File 的字符串参数边界'),
    @('类型转换', '类型转换与内嵌调用合同外'),
    @('Root 示例', '所有示例使用 -Root $PWD.Path')
  )
}

function Get-BorrowingFacadeSourceMatrixRows {
  return @(
    @(
      'Git', 'git', 'Root,SourceType,SourceId', 'GitLocator,GitRef',
      'LocalPath,LocalDisplayName,WebRawBytesPath,WebResponseMetadataPath',
      'AccessPolicy=source-read-only、NetworkPolicy=source-read-only、ExecutionPolicy=deny、UpstreamWritePolicy=deny；AuthorizationTime/Source/Scope 全部必填'
    ),
    @(
      'Local', 'local', 'Root,SourceType,SourceId', 'LocalPath,LocalDisplayName',
      'GitLocator,GitRef,WebRawBytesPath,WebResponseMetadataPath',
      '缺省使用九维默认值；任一生效值偏离默认时 AuthorizationTime/Source/Scope 全部必填，否则三者全部禁止'
    ),
    @(
      'Web', 'web', 'Root,SourceType,SourceId', 'WebRawBytesPath,WebResponseMetadataPath',
      'GitLocator,GitRef,LocalPath,LocalDisplayName',
      'AccessPolicy=source-read-only、NetworkPolicy=source-read-only、ExecutionPolicy=deny、UpstreamWritePolicy=deny；AuthorizationTime/Source/Scope 全部必填'
    )
  )
}

function Get-BorrowingFacadeValidatedOutputRows {
  return @(
    @('source_id', '仅校验通过才输出；否则 none'),
    @('capture_id', '仅校验通过才输出；否则 none'),
    @('fingerprint', '仅校验通过才输出；否则 none'),
    @('12 行输入边界', '禁止输入 CR/LF 进入任何一行')
  )
}

function Invoke-BorrowingCommandParameterCases {
  param([string]$Text)

  Invoke-CzxtContract 'command appendix locks facade parameter binding boundaries' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'façade 参数边界' 3
    Assert-BorrowingExactOrderedTable $section @('参数边界项', '精确合同') `
      (Get-BorrowingFacadeParameterRows) 'facade parameter boundary table'
  }

  Invoke-CzxtContract 'command appendix locks validated identifiers in 12-line output' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'façade 参数边界' 3
    Assert-BorrowingExactOrderedTable $section @('输出字段', '精确合同') `
      (Get-BorrowingFacadeValidatedOutputRows) 'facade validated output table'
  }

  Invoke-CzxtContract 'command appendix locks exact facade source matrix' {
    $usage = Get-BorrowingMarkdownSection $Text '使用边界'
    $section = Get-BorrowingMarkdownSection $usage 'façade 参数边界' 3
    Assert-BorrowingExactOrderedTable $section @(
      'SourceType 输入', 'source_type 卡片值', '通用必填', '类型必填', '类型禁止', '权限与授权'
    ) (Get-BorrowingFacadeSourceMatrixRows) 'facade source matrix'
  }

  Invoke-CzxtContract 'command appendix uses string Root in all facade examples' {
    foreach ($heading in @('Git 接入', '本地接入', 'Web 接入')) {
      $section = Get-BorrowingMarkdownSection $Text $heading
      Assert-BorrowingLineSequence $section @('  -Root $PWD.Path `') `
        ("facade Root string example: {0}" -f $heading)
    }
  }
}
