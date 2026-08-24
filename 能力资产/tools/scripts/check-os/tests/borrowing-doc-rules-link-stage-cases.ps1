$ErrorActionPreference = 'Stop'

function Get-BorrowingLinkStageContractRows {
  return @(
    @('Local/Web 输入', '读前 + 读后', '变化按对应阶段硬失败'),
    @('新 staging', 'candidate 前 + move 前', '变化按对应阶段硬失败；不得晋升'),
    @('Git cache', 'fetch 后', '变化按对应阶段硬失败；保留 staging'),
    @('target', 'move 后', '变化属于后验失败；原子回退'),
    @('existing', '复用前', '变化按 idempotency 阶段硬失败；不修改 existing')
  )
}

function Get-BorrowingLinkInvariantRows {
  return @(
    @('所有常规文件', 'NumberOfLinks=1'),
    @('链接计数 API 不可用', '硬失败')
  )
}

function Invoke-BorrowingRuleLinkStageCases {
  param([string]$Text)
  $section = Get-BorrowingMarkdownSection $Text '捕获安全'

  Invoke-CzxtContract 'borrowing rule locks every link-check stage' {
    Assert-BorrowingExactOrderedTable $section @(
      '链接检查对象', '固定检查时点', '失败语义'
    ) (Get-BorrowingLinkStageContractRows) 'link-check stage table'
  }

  Invoke-CzxtContract 'borrowing rule locks link-count invariants' {
    Assert-BorrowingExactOrderedTable $section @('链接检查项', '精确合同') `
      (Get-BorrowingLinkInvariantRows) 'link-count invariant table'
  }
}
