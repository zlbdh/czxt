[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')

function Assert-BorrowingTableSelfTestThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected exact-table rejection: {0}" -f $Context)
}

Invoke-CzxtContract 'table self-test isolates the exact-header contiguous table' {
  $text = @'
| 权限字段 | 允许值 | 默认值 |
|---|---|---|
| access_policy | local-read-only / source-read-only | local-read-only |

| 来源类型 | access_policy | network_policy | execution_policy | upstream_write_policy |
|---|---|---|---|---|
| Local ready | local-read-only | deny | deny | deny |
'@
  $permissionRows = @(,@('access_policy', 'local-read-only / source-read-only', 'local-read-only'))
  Assert-BorrowingExactTable $text @('权限字段', '允许值', '默认值') $permissionRows 'permission fixture'
  $sourceRows = @(,@('Local ready', 'local-read-only', 'deny', 'deny', 'deny'))
  Assert-BorrowingExactTable $text @(
    '来源类型', 'access_policy', 'network_policy', 'execution_policy', 'upstream_write_policy'
  ) $sourceRows 'source fixture'
}

Invoke-CzxtContract 'table self-test ignores fenced tables and accepts the real external table' {
  $fencedOnly = @'
```markdown
| 权限字段 | 允许值 | 默认值 |
|---|---|---|
| access_policy | local-read-only / source-read-only | local-read-only |
```
'@
  $expected = @(,@('access_policy', 'local-read-only / source-read-only', 'local-read-only'))
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $fencedOnly @('权限字段', '允许值', '默认值') $expected 'fenced-only table'
  } 'table exists only inside a fence'
  $withReal = $fencedOnly + @'

| 权限字段 | 允许值 | 默认值 |
|---|---|---|
| access_policy | local-read-only / source-read-only | local-read-only |
'@
  Assert-BorrowingExactTable $withReal @('权限字段', '允许值', '默认值') $expected 'real table outside fence'
}

Invoke-CzxtContract 'table self-test rejects indented code tables but allows three spaces' {
  $expected = @(,@('access_policy', 'local-read-only / source-read-only', 'local-read-only'))
  $fourSpaces = "    | 权限字段 | 允许值 | 默认值 |`n    |---|---|---|`n    | access_policy | local-read-only / source-read-only | local-read-only |`n"
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $fourSpaces @('权限字段', '允许值', '默认值') $expected 'four-space table'
  } 'four-space indented table'
  $tab = "`t| 权限字段 | 允许值 | 默认值 |`n`t|---|---|---|`n`t| access_policy | local-read-only / source-read-only | local-read-only |`n"
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $tab @('权限字段', '允许值', '默认值') $expected 'tab table'
  } 'tab-indented table'
  $threeSpaces = "   | 权限字段 | 允许值 | 默认值 |`n   |---|---|---|`n   | access_policy | local-read-only / source-read-only | local-read-only |`n"
  Assert-BorrowingExactTable $threeSpaces @('权限字段', '允许值', '默认值') $expected 'three-space table'
}

Invoke-CzxtContract 'table self-test rejects extra and duplicate permission rows' {
  $expected = @(,@('access_policy', 'local-read-only / source-read-only', 'local-read-only'))
  $extra = @'
| 权限字段 | 允许值 | 默认值 |
|---|---|---|
| access_policy | local-read-only / source-read-only | local-read-only |
| network_policy | deny / source-read-only | deny |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $extra @('权限字段', '允许值', '默认值') $expected 'extra network_policy'
  } 'extra network_policy'
  $duplicate = @'
| 权限字段 | 允许值 | 默认值 |
|---|---|---|
| access_policy | local-read-only / source-read-only | local-read-only |
| access_policy | local-read-only / source-read-only | local-read-only |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $duplicate @('权限字段', '允许值', '默认值') $expected 'duplicate permission'
  } 'duplicate permission row'
}

Invoke-CzxtContract 'table self-test rejects missing and wrong status rows' {
  $expected = @(
    @('draft', 'pending', '问题、初始来源定位'),
    @('closed', 'reject', '评估证据与拒绝理由')
  )
  $missing = @'
| lifecycle_status | 允许 decision | 必须满足 |
|---|---|---|
| draft | pending | 问题、初始来源定位 |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $missing @('lifecycle_status', '允许 decision', '必须满足') $expected 'missing status'
  } 'missing status row'
  $wrong = @'
| lifecycle_status | 允许 decision | 必须满足 |
|---|---|---|
| draft | adopt | 问题、初始来源定位 |
| closed | reject | 评估证据与拒绝理由 |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $wrong @('lifecycle_status', '允许 decision', '必须满足') $expected 'draft adopt'
  } 'draft/adopt row'
}

Invoke-CzxtContract 'table self-test rejects draft-to-closed and extra borrowing PM' {
  $transitionExpected = @(,@('draft', 'assessing', 'pending；至少一个 ready capture'))
  $transition = @'
| 旧状态 | 新状态 | decision/条件 |
|---|---|---|
| draft | closed | reject；有评估证据与拒绝理由 |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $transition @('旧状态', '新状态', 'decision/条件') $transitionExpected 'draft closed'
  } 'draft to closed'
  $roleExpected = @(,@('项目 PM', '编排与路由', '不借此扩大路径白名单'))
  $roles = @'
| 角色 | 本闭环职责 | 写入边界 |
|---|---|---|
| 项目 PM | 编排与路由 | 不借此扩大路径白名单 |
| 借鉴 PM | 管理全部事实 | 全路径 |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactTable $roles @('角色', '本闭环职责', '写入边界') $roleExpected 'extra borrowing PM'
  } 'extra borrowing PM'
}

Invoke-CzxtContract 'table self-test binds an exact unique first-column field set' {
  $valid = @'
| 公共字段 | 合同 |
|---|---|
| schema | borrowing-source/v1 |
| source_id | stable ID |
'@
  Assert-BorrowingExactFirstColumnTable $valid @('公共字段', '合同') @('schema', 'source_id') 'valid source fields'
  $moved = @'
| 公共字段 | 合同 |
|---|---|
| schema | borrowing-source/v1 |

| 其他字段 | 合同 |
|---|---|
| source_id | stable ID |
'@
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactFirstColumnTable $moved @('公共字段', '合同') @('schema', 'source_id') 'moved field'
  } 'field moved to unrelated table'
  $duplicate = $valid + "`n| source_id | duplicate |`n"
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactFirstColumnTable $duplicate @('公共字段', '合同') @('schema', 'source_id') 'duplicate field'
  } 'duplicate first-column field'
  $unknown = $valid + "`n| invented_field | unknown |`n"
  Assert-BorrowingTableSelfTestThrows {
    Assert-BorrowingExactFirstColumnTable $unknown @('公共字段', '合同') @('schema', 'source_id') 'unknown field'
  } 'unknown first-column field'
}

Complete-CzxtContracts
