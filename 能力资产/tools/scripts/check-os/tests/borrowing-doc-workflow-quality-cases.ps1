$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'borrowing-doc-skill-workflow-contract-data.ps1')

function Invoke-BorrowingWorkflowQualityCases {
  param([string]$Text)

  Invoke-CzxtContract 'borrowing workflow locks one shared close transaction' {
    $completion = Get-BorrowingMarkdownSection $Text '完成条件'
    $close = Get-BorrowingMarkdownSection $completion '关闭事务' 3
    Assert-BorrowingExactOrderedTable $close @('关闭顺序', '精确动作', '失败边界') `
      $script:BorrowingCloseTransactionRows 'workflow close transaction table'
    Assert-BorrowingLineSequence $close @($script:BorrowingCloseScopeLine) `
      'workflow close transaction scope'
  }

  Invoke-CzxtContract 'borrowing workflow locks immutable terminal states' {
    $state = Get-BorrowingMarkdownSection $Text '状态流'
    Assert-BorrowingLineSequence $state $script:BorrowingTerminalStateLines `
      'workflow terminal-state invariants'
  }

  Invoke-CzxtContract 'borrowing workflow locks independent audit exit semantics' {
    $recovery = Get-BorrowingMarkdownSection $Text '失败恢复'
    $header = @('事件', '精确结果')
    Assert-BorrowingTableCellValue $recovery $header '独立审计 exit 5' 1 `
      '仅 WARN；不得推进任何状态' 'independent audit exit 5'
    Assert-BorrowingTableCellValue $recovery $header '独立审计 exit 10' 1 `
      'FAIL；硬失败；不得推进任何状态；不得修复写入' 'independent audit exit 10'
  }

  Invoke-CzxtContract 'borrowing workflow rejects circular ready-write wording' {
    $recovery = Get-BorrowingMarkdownSection $Text '失败恢复'
    Assert-BorrowingDocExcludesAll $recovery @(
      '成功后才写入 ready', '成功后才写入ready', '前四步全部成功后才写入'
    ) 'workflow circular ready wording'
  }
}
