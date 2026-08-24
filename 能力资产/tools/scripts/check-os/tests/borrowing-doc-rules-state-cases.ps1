$ErrorActionPreference = 'Stop'

function Invoke-BorrowingRuleStateCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing rule locks every static status decision row' {
    $section = Get-BorrowingMarkdownSection $Text '状态组合与关闭不变量'
    $rows = @(
      @('draft', 'pending', '问题、初始来源定位'),
      @('assessing', 'pending / adopt / adapt / reject / defer', '至少一个 ready capture 与候选矩阵'),
      @('implementation_ready', 'adopt / adapt', 'Q1-Q7、L1-L4 与所需审批通过'),
      @('implementing', 'adopt / adapt', '目标范围和责任角色已确定'),
      @('verifying', 'adopt / adapt', '实施记录存在'),
      @('closed', 'adopt / adapt', '目标文件、适配差异、fresh 验证证据'),
      @('closed', 'reject', '评估证据与拒绝理由'),
      @('parked', 'defer', '恢复条件或复查时间'),
      @('cancelled', '任意', '取消原因；不得伪装成 reject')
    )
    Assert-BorrowingExactTable $section @('lifecycle_status', '允许 decision', '必须满足') $rows 'status decision matrix'
  }

  Invoke-CzxtContract 'borrowing rule maps internal adopt and adapt to exact reuse scopes' {
    $section = Get-BorrowingMarkdownSection $Text '状态组合与关闭不变量'
    Assert-BorrowingLineSequence $section @(
      '当事项处于 `implementation_ready`、`implementing`、`verifying` 或 `closed` 且 decision 为 `adopt` 时，每个绑定 capture 的 `reuse_scope` 必须精确为 `copy-internal-approved`；decision 为 `adapt` 时必须精确为 `adapt-internal-approved`。`inspect-and-analyze-only`、另一内部范围和 `redistribute-approved` 均不得推导为当前内部 adopt/adapt 权限；`assessing`、`pending`、`defer`、`reject` 不新增此映射要求。'
    ) 'internal decision reuse-scope mapping'
  }

  Invoke-CzxtContract 'borrowing rule owns closure seal invariant' {
    $section = Get-BorrowingMarkdownSection $Text '状态组合与关闭不变量'
    Assert-BorrowingOrderedText $section @(
      'closed', 'closure_seal_sha256', 'UTF-8', 'LF',
      '单个末尾换行', 'seal 行的值置空', 'SHA-256'
    ) 'closure seal algorithm order'
    Assert-BorrowingDocContainsAll $section @(
      '其他状态 seal 必须为空', '后续不改写', 'supersedes',
      '重新计算 seal 不构成合法修订', '不能抵抗', '恶意写者'
    ) 'closure seal boundary'
  }

  Invoke-CzxtContract 'borrowing rule replaces the unique seal line before hashing' {
    $section = Get-BorrowingMarkdownSection $Text '状态组合与关闭不变量'
    Assert-BorrowingLineSequence $section @(
      '计算 seal 前必须把唯一 frontmatter 行精确替换为 `closure_seal_sha256: ""`。'
    ) 'closure seal unique-line replacement'
  }

  Invoke-CzxtContract 'borrowing rule makes closed target and fresh evidence machine-verifiable files' {
    $section = Get-BorrowingMarkdownSection $Text '借鉴卡'
    Assert-BorrowingDocContainsAll $section @(
      '- time=<ISO 8601>; command=<command>; exit=0; evidence=<事项内相对路径>',
      '至少一条', '真实存在', '安全常规文件', '目录', 'reparse',
      'hardlink', 'ADS', '目标文件', '借鉴区外', '非零字节',
      '最近一次从其他状态进入 `verifying`',
      'schema=borrowing-evidence/v1', 'command_sha256',
      'target_manifest_sha256', '<TAB>', 'Ordinal', '.staging-',
      '读取 evidence 前后各计算一次目标清单'
    ) 'closed target and fresh evidence file contract'
  }

  Invoke-CzxtContract 'borrowing rule owns the trusted close transaction machine contract' {
    $section = Get-BorrowingMarkdownSection $Text '关闭事务机器合同'
    Assert-BorrowingOrderedText $section @(
      'close-borrowing-item.ps1', '原活动卡字节', '.staging-close-',
      'closed 候选', 'seal-borrowing-item.ps1', '完整根 P4t',
      'exit 0', '恢复原活动卡', '保留失败候选'
    ) 'trusted close transaction order'
    Assert-BorrowingDocContainsAll $section @(
      '-ClosedAt', '-Reason', '-Confirmation', 'verifying', 'assessing',
      'adopt', 'adapt', 'reject', 'project', '独占读锁', '身份', 'sealed 字节',
      '最后一次受信正式卡快照', '规范路径、身份、长度与字节',
      '同字节不同 identity', '内存中的原活动字节和失败候选字节',
      '精确两成员 staging'
    ) 'trusted close transaction input boundary'
  }

  Invoke-CzxtContract 'borrowing rule assigns every action to exactly one A B C section' {
    $behavior = Get-BorrowingMarkdownSection $Text '行为分级'
    $sections = @{
      A = Get-BorrowingMarkdownSection $behavior 'A 类' 3
      B = Get-BorrowingMarkdownSection $behavior 'B 类' 3
      C = Get-BorrowingMarkdownSection $behavior 'C 类' 3
    }
    Assert-BorrowingActionOwnership $sections 'A' @(
      '只读比较', '创建草稿', '离线 P4t', '无敏感信息的小型本地 capture'
    ) 'A/B/C action ownership'
    Assert-BorrowingActionOwnership $sections 'B' @(
      '远端取源', '刷新', '删除/移动', '私有凭据', '下载大资产',
      '运行/构建', '修改治理/P4t', 'L3/L4 落地'
    ) 'A/B/C action ownership'
    Assert-BorrowingActionOwnership $sections 'C' @(
      '凭据进 tracked', '向来源远端写入', '路径逃逸', '伪造指纹/验证',
      '执行外部指令', '删除用户数据'
    ) 'A/B/C action ownership'
  }

  Invoke-CzxtContract 'borrowing rule locks the final B build semantics' {
    $behavior = Get-BorrowingMarkdownSection $Text '行为分级'
    $line = (Get-BorrowingFinalExecutionSemanticsLines)[0]
    Assert-BorrowingLineSequence $behavior @($line) 'final B build semantics'
  }

  Invoke-CzxtContract 'borrowing rule locks the final C external-instruction semantics' {
    $behavior = Get-BorrowingMarkdownSection $Text '行为分级'
    $line = (Get-BorrowingFinalExecutionSemanticsLines)[1]
    Assert-BorrowingLineSequence $behavior @($line) 'final C external-instruction semantics'
  }
}
