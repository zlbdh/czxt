$ErrorActionPreference = 'Stop'

function Invoke-BorrowingRulePolicyCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing rule locks all permission enums and defaults by row' {
    $section = Get-BorrowingMarkdownSection $Text '权限模型'
    $rows = @(
      @('rights_status', 'unverified / verified / restricted', 'unverified'),
      @('access_policy', 'local-read-only / source-read-only', 'local-read-only'),
      @('reuse_scope', 'inspect-and-analyze-only / copy-internal-approved / adapt-internal-approved / redistribute-approved', 'inspect-and-analyze-only'),
      @('execution_policy', 'deny / sandbox-approved', 'deny'),
      @('network_policy', 'deny / source-read-only', 'deny'),
      @('storage_policy', 'local-only / tracked-metadata-only / tracked-content-approved', 'local-only'),
      @('distribution_policy', 'deny / internal-approved / external-approved', 'deny'),
      @('upstream_write_policy', 'deny', 'deny'),
      @('auto_refresh', 'false', 'false')
    )
    Assert-BorrowingExactTable $section @('权限字段', '允许值', '默认值') $rows 'permission enum/default table'
  }

  Invoke-CzxtContract 'borrowing rule locks source-type permission combinations' {
    $section = Get-BorrowingMarkdownSection $Text '权限模型'
    $header = @('来源类型', 'access_policy', 'network_policy', 'execution_policy', 'upstream_write_policy')
    $rows = @(
      @('Git/Web ready', 'source-read-only', 'source-read-only', 'deny', 'deny'),
      @('Local ready', 'local-read-only', 'deny', 'deny', 'deny')
    )
    Assert-BorrowingExactTable $section $header $rows 'source-type permission table'
    Assert-BorrowingDocContainsAll $section @(
      '一个维度', '不能推导', '受信任捕获工具', '不等于允许运行来源内容'
    ) 'permission independence'
  }

  Invoke-CzxtContract 'borrowing rule locks deviation authorization evidence' {
    $section = Get-BorrowingMarkdownSection $Text '权限模型'
    Assert-BorrowingTableRow $section @(
      '权限维度', '生效值', '授权时间', '授权来源', '适用范围'
    ) 'authorization evidence table header'
    Assert-BorrowingDocContainsAll $section @(
      '偏离默认值', 'ISO 8601', '可审计来源', '有限适用范围',
      '缺一不可', 'default-policy', '不得包含凭据'
    ) 'deviation authorization contract'
    Assert-BorrowingLineSequence $section @(
      'AuthorizationTime 必须含时区；解析后统一投影 UTC `yyyy-MM-ddTHH:mm:ss.fffZ`；偏离默认的幂等比较使用规范化值。'
    ) 'authorization time canonicalization'
  }

  Invoke-CzxtContract 'borrowing rule locks one authorization row per permission dimension' {
    $section = Get-BorrowingMarkdownSection $Text '权限模型'
    $dimensions = @(
      'rights_status', 'access_policy', 'reuse_scope', 'execution_policy',
      'network_policy', 'storage_policy', 'distribution_policy',
      'upstream_write_policy', 'auto_refresh'
    )
    Assert-BorrowingExactFirstColumnTable $section @(
      '权限维度', '生效值', '授权时间', '授权来源', '适用范围'
    ) $dimensions 'permission authorization table'
  }

  Invoke-CzxtContract 'borrowing rule binds authorization values to frontmatter' {
    $section = Get-BorrowingMarkdownSection $Text '权限模型'
    Assert-BorrowingDocContainsAll $section @(
      '九维各恰好一行', '不得缺失、重复或额外',
      '生效值与同名 frontmatter 完全一致'
    ) 'permission authorization binding'
  }

  Invoke-CzxtContract 'borrowing rule owns capture safety invariants' {
    $section = Get-BorrowingMarkdownSection $Text '捕获安全'
    Assert-BorrowingDocContainsAll $section @(
      '路径逃逸', 'symlink', 'junction', 'reparse point', '静默漏读',
      '外部命令与提示', '不可信数据', '不执行来源内容',
      '业务零依赖', 'import', 'require', 'file:', '工作区/构建配置',
      '脚本调用', '运行时读取'
    ) 'capture safety section'
  }

  Invoke-CzxtContract 'borrowing rule locks the non-executing machine boundary' {
    $section = Get-BorrowingMarkdownSection $Text '捕获安全'
    Assert-BorrowingOrderedText $section @(
      '捕获器、P4t、审计', '永不执行来源内容', '不暴露来源执行入口',
      'sandbox-approved', '仅记录', '另行授权', '隔离评估', '不赋权捕获器'
    ) 'non-executing machine boundary'
  }
}
