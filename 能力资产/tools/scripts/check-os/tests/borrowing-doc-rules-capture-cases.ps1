$ErrorActionPreference = 'Stop'

function Get-BorrowingCaptureLinkContractRows {
  return @(
    @('非单链接', '硬失败'),
    @('链接数不可确认', '硬失败')
  )
}

function Get-BorrowingIdempotencyContractRows {
  return @(
    @(
      '复用键',
      'source_id + source_type + fingerprint_algorithm + full fingerprint'
    ),
    @('唯一合法 ready', '同一复用键恰好 1 个 ready、0 个 retired；仅此情况允许复用'),
    @('既有合法性', '复用前既有来源卡仍须按完整 schema 全量合法'),
    @(
      '复用一致性',
      '稳定比较包含 canonical_locator、适用类型事实、九维生效值、所有偏离默认的规范化授权 time/source/scope'
    ),
    @(
      '稳定比较排除',
      'capture_id、captured_at、初始历史、默认授权时间、非适用表、本机路径状态'
    ),
    @(
      '冲突',
      '任一不一致 / ready+retired / 同一复用键多个 ready → idempotency-conflict'
    ),
    @('retired', '拒绝复活或重复登记'),
    @('不同 fingerprint 的多个 ready', '合法'),
    @('不同 full fingerprint', '新建 capture'),
    @('短前缀冲突', '硬失败'),
    @(
      'existing tracked',
      '复用、修复或冲突均不修改既有来源卡及其他 tracked 字节/mtime'
    ),
    @(
      '缺失 ignored cache',
      '预期 ignored cache 集合全部缺失且稳定事实一致→允许仅从本次 candidate 恢复缺失集合'
    ),
    @(
      'partial/mismatch cache',
      '部分缺失、任一现存 cache 损坏或指纹不符→idempotency-conflict；禁止覆盖'
    )
  )
}

function Invoke-BorrowingRuleCaptureCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing rule locks ordered link hard failures' {
    $section = Get-BorrowingMarkdownSection $Text '捕获安全'
    Assert-BorrowingExactOrderedTable $section @('捕获安全判定', '精确结果') `
      (Get-BorrowingCaptureLinkContractRows) 'capture link hard-failure table'
  }

  Invoke-CzxtContract 'borrowing rule locks exact capture idempotency semantics' {
    $section = Get-BorrowingMarkdownSection $Text '捕获安全'
    Assert-BorrowingExactOrderedTable $section @('幂等场景', '精确合同') `
      (Get-BorrowingIdempotencyContractRows) 'capture idempotency table'
  }

  Invoke-CzxtContract 'borrowing rule binds normalized final URL to canonical locator' {
    $web = Get-BorrowingMarkdownSection $Text 'Web 事实表' 3
    Assert-BorrowingTableCellValue $web @('事实字段', '合同') '最终 URL' 1 `
      '净化；等于 canonical_locator' 'Web final URL canonical locator'
  }

  Invoke-CzxtContract 'borrowing rule makes isolation tokens and leaf RootMode fail closed' {
    $section = Get-BorrowingMarkdownSection $Text '捕获安全'
    Assert-BorrowingDocContainsAll $section @(
      'path token', '行首', '`=`', '`:`', '`(`', '`[`',
      '传入 `Mode`', '不可信提示', '独立判定实际 RootMode',
      'project-as-template', 'template-as-project', 'fail closed'
    ) 'isolation token and leaf mode boundary'
  }
}
