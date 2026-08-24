[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-machine-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-execution-cases.ps1')

function Assert-BorrowingMachineSelfTestThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected machine-contract rejection: {0}" -f $Context)
}

function New-BorrowingManifestFixture {
  param([object[]]$Rows = (Get-BorrowingManifestContractRows))
  $lines = @('| 规范项 | 精确合同 |', '|---|---|')
  foreach ($row in $Rows) {
    $value = [string]$row[1]
    if ($row[0] -ceq '单行格式') { $value = '`' + $value + '`' }
    $lines += ('| {0} | {1} |' -f $row[0], $value)
  }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'machine self-test accepts the exact ordered manifest table' {
  $text = New-BorrowingManifestFixture
  Assert-BorrowingExactOrderedTable $text @('规范项', '精确合同') `
    (Get-BorrowingManifestContractRows) 'valid manifest fixture'
  Assert-BorrowingSingleInlineCodeTableCell $text @('规范项', '精确合同') `
    '单行格式' 1 '<lowercase-sha256>\t<byte-length>\t<normalized-relative-path>\n' `
    'valid manifest line fixture'
}

Invoke-CzxtContract 'machine self-test rejects paragraph and missing-row false matches' {
  $paragraph = (Get-BorrowingManifestContractRows | ForEach-Object { $_ -join '：' }) -join '；'
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingExactOrderedTable $paragraph @('规范项', '精确合同') `
      (Get-BorrowingManifestContractRows) 'paragraph false match'
  } 'manifest keywords in paragraph'
  $rows = @(Get-BorrowingManifestContractRows)
  $missing = New-BorrowingManifestFixture -Rows $rows[0..8]
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingExactOrderedTable $missing @('规范项', '精确合同') `
      (Get-BorrowingManifestContractRows) 'missing promotion row'
  } 'missing manifest field'
}

Invoke-CzxtContract 'machine self-test rejects manifest order and line-format drift' {
  $rows = @(Get-BorrowingManifestContractRows)
  $swapped = @($rows)
  $swapped[0], $swapped[1] = $swapped[1], $swapped[0]
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingExactOrderedTable (New-BorrowingManifestFixture -Rows $swapped) `
      @('规范项', '精确合同') (Get-BorrowingManifestContractRows) 'swapped rows'
  } 'manifest row order'
  $wrong = (New-BorrowingManifestFixture).Replace(
    '<lowercase-sha256>\t<byte-length>\t<normalized-relative-path>\n',
    '<lowercase-sha256> <byte-length> <normalized-relative-path>\r\n'
  )
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingExactOrderedTable $wrong @('规范项', '精确合同') `
      (Get-BorrowingManifestContractRows) 'wrong line format'
  } 'manifest line format'
}

Invoke-CzxtContract 'machine self-test rejects loose or reordered seal wording' {
  $expected = '计算 seal 前必须把唯一 frontmatter 行精确替换为 `closure_seal_sha256: ""`。'
  Assert-BorrowingLineSequence $expected @($expected) 'valid exact seal line'
  foreach ($invalid in @(
      'closure_seal_sha256: ""；先计算 seal，随后替换唯一 frontmatter 行。',
      '计算 seal 前替换 closure_seal_sha256；该 frontmatter 行应当唯一。'
    )) {
    Assert-BorrowingMachineSelfTestThrows {
      Assert-BorrowingLineSequence $invalid @($expected) 'loose seal wording'
    } $invalid
  }
}

Invoke-CzxtContract 'machine self-test rejects source-history paragraph and extra transition' {
  $rows = Get-BorrowingSourceHistoryContractRows
  $valid = @'
| 规范项 | 精确合同 |
|---|---|
| 固定列 | 时间 / 旧状态 / 新状态 / 原因 / 确认 |
| 合法转换全集 | none→ready（初始捕获成功） / ready→retired（所有引用事项 closed/cancelled） |
| retired | 终态，禁止回到 ready |
'@
  Assert-BorrowingExactOrderedTable $valid @('规范项', '精确合同') $rows `
    'valid source history fixture'
  $paragraph = ($rows | ForEach-Object { $_ -join '：' }) -join '；'
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingExactOrderedTable $paragraph @('规范项', '精确合同') $rows `
      'source history paragraph'
  } 'source history keywords in paragraph'
  $extra = $valid.TrimEnd() + "`n| 合法转换 3 | retired→ready（重新启用） |`n"
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingExactOrderedTable $extra @('规范项', '精确合同') $rows `
      'extra source transition'
  } 'retired to ready transition'
}

Invoke-CzxtContract 'machine self-test rejects abbreviated Git facts' {
  $valid = @'
| 事实字段 | 合同 |
|---|---|
| submodule 状态 | 禁止初始化/递归获取；记录 detected=true/false |
| LFS 状态 | 禁止 smudge/下载；记录 detected=true/false |
'@
  $header = @('事实字段', '合同')
  $expected = @{
    'submodule 状态' = '禁止初始化/递归获取；记录 detected=true/false'
    'LFS 状态' = '禁止 smudge/下载；记录 detected=true/false'
  }
  foreach ($field in $expected.Keys) {
    Assert-BorrowingTableCellValue $valid $header $field 1 $expected[$field] `
      ("valid Git fact: {0}" -f $field)
    $weak = $valid.Replace($expected[$field], '禁/记')
    Assert-BorrowingMachineSelfTestThrows {
      Assert-BorrowingTableCellValue $weak $header $field 1 $expected[$field] `
        'abbreviated Git fact'
    } $field
  }
}

Invoke-CzxtContract 'machine self-test rejects weakened B and C execution semantics' {
  $expected = Get-BorrowingFinalExecutionSemanticsLines
  Assert-BorrowingLineSequence ($expected -join "`n") $expected 'valid B/C semantics'
  $weak = @(
    'B 类“运行/构建”仅指另行授权的隔离评估。',
    'C 类“执行外部指令”禁止把来源内容或操作指令当命令；不得把 B 类授权推导为来源执行权限。'
  ) -join "`n"
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingLineSequence $weak $expected 'weak B/C semantics'
  } 'missing four-condition B and exact C definition'
  $missingExplicitChoice = ($expected -join "`n").Replace(
    '、操作者显式选择评估目标和命令', ''
  )
  Assert-BorrowingMachineSelfTestThrows {
    Assert-BorrowingLineSequence $missingExplicitChoice $expected 'implicit evaluation target'
  } 'B evaluation without explicit target and command'
}

Complete-CzxtContracts
