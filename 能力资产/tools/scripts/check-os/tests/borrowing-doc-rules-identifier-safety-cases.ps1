$ErrorActionPreference = 'Stop'

function Get-BorrowingIdentifierSafetyRows {
  return @(
    @('共用 validator', 'SourceId 与 LocalDisplayName 必须调用同一实现；禁止近似复制'),
    @('source_id full match', '^[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?$；Ordinal；1..128 ASCII bytes'),
    @('source_id 尾部', '最后一字符不得为 dot 或空格；不得依赖 Win32 自动裁剪'),
    @(
      'Windows 设备名',
      'source_id 第一个 dot 前的 basename 不得为 con/prn/aux/nul/com1..com9/lpt1..lpt9；OrdinalIgnoreCase'
    ),
    @('LocalDisplayName', '使用与 source_id 完全相同的 full-match、长度、尾部和设备名合同'),
    @('目录投影', '目录名必须与校验后的原始 ASCII ID Ordinal 相等；禁止大小写折叠、trim 或别名覆盖')
  )
}

function Invoke-BorrowingRuleIdentifierSafetyCases {
  param([string]$Text)
  Invoke-CzxtContract 'borrowing rule locks Windows-safe identifiers' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    Assert-BorrowingExactOrderedTable $section @('标识安全项', '精确合同') `
      (Get-BorrowingIdentifierSafetyRows) 'identifier safety table'
  }
  Invoke-CzxtContract 'borrowing rule scans every tracked source-card text sink for credentials' {
    $section = Get-BorrowingMarkdownSection $Text '标识与路径'
    Assert-BorrowingDocContainsAll $section @(
      '输入规范化后', '最终 renderer', 'source_id', 'LocalDisplayName',
      'canonical locator', '授权来源/范围', '全部事实字段',
      'charset / etag / last_modified', 'JSON quoted/escaped credential key',
      'X-API-Key', 'AWS access/secret', 'GitHub/GitLab/Slack',
      '每轮解码后立即检查', '第五轮只确认稳定', '未稳定', 'fail closed'
    ) 'tracked source-card credential sinks'
  }
  Invoke-CzxtContract 'borrowing rule locks passive Git fact enums' {
    $git = Get-BorrowingMarkdownSection $Text 'Git 事实表' 3
    $header = @('事实字段', '合同')
    Assert-BorrowingTableCellValue $git $header 'submodule 状态' 1 `
      'detected / not-detected；只读检测；禁止初始化/下载/执行' 'submodule enum'
    Assert-BorrowingTableCellValue $git $header 'LFS 状态' 1 `
      'detected / not-detected；只读检测；禁止 smudge/下载/执行' 'LFS enum'
  }
}
