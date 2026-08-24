[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-capture-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-link-stage-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-resource-cases.ps1')

function Assert-BorrowingUpstreamRuleResourceThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected upstream rejection: {0}" -f $Context)
}

function New-BorrowingUpstreamRuleResourceTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'upstream self-test rejects incomplete link stages and weak link counts' {
  $header = @('链接检查对象', '固定检查时点', '失败语义')
  $rows = Get-BorrowingLinkStageContractRows
  $valid = New-BorrowingUpstreamRuleResourceTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid link stages'
  foreach ($invalid in @(
      $valid.Replace('读前 + 读后', '仅读前'),
      $valid.Replace('candidate 前 + move 前', '仅 candidate 前'),
      $valid.Replace('move 后', 'move 前'),
      $valid.Replace('复用前', '复用后')
    )) {
    Assert-BorrowingUpstreamRuleResourceThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid link stages'
    } 'link stage missing or shifted'
  }
  $invariantHeader = @('链接检查项', '精确合同')
  $invariants = Get-BorrowingLinkInvariantRows
  $invariantTable = New-BorrowingUpstreamRuleResourceTable $invariantHeader $invariants
  Assert-BorrowingExactOrderedTable $invariantTable $invariantHeader $invariants `
    'valid link invariants'
  Assert-BorrowingUpstreamRuleResourceThrows {
    Assert-BorrowingExactOrderedTable `
      ($invariantTable.Replace('链接计数 API 不可用 | 硬失败', '链接计数 API 不可用 | WARN')) `
      $invariantHeader $invariants 'weak link-count API behavior'
  } 'link-count API unavailable is tolerated'
}

Invoke-CzxtContract 'upstream self-test rejects overbroad or mutating idempotency' {
  $header = @('幂等场景', '精确合同')
  $rows = Get-BorrowingIdempotencyContractRows
  $valid = New-BorrowingUpstreamRuleResourceTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid idempotency contract'
  foreach ($invalid in @(
      $valid.Replace('恰好 1 个 ready、0 个 retired', '至少 1 个 ready'),
      $valid.Replace(
        '九维生效值、所有偏离默认的规范化授权 time/source/scope',
        '权限大致一致'
      ),
      $valid.Replace('同一复用键多个 ready', '任意多个 ready'),
      $valid.Replace('不同 fingerprint 的多个 ready | 合法', '不同 fingerprint 的多个 ready | 冲突'),
      $valid.Replace('均不修改既有来源卡', '会更新既有来源卡')
    )) {
    Assert-BorrowingUpstreamRuleResourceThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid idempotency contract'
    } 'idempotency ambiguity or existing mutation'
  }
}

Invoke-CzxtContract 'upstream self-test rejects incorrect resource measurement' {
  $header = @('资源项', '适用来源', '计量对象与时点', 'reason')
  $rows = Get-BorrowingResourceMeasurementRows
  $valid = New-BorrowingUpstreamRuleResourceTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid resource measurement'
  foreach ($invalid in @(
      $valid.Replace('选定 tree 的非 tree 条目数', '选定 tree 的全部条目数'),
      $valid.Replace('重复路径重复计', '重复 blob 去重'),
      $valid.Replace(
        '输入字节与 canonical 文件字节（含末尾 LF）各自计量',
        '只计输入字节'
      ),
      $valid.Replace('单项字节', '单项'),
      $valid.Replace('仅 fetch 后在 staging 内检查', 'fetch 前检查并清理 staging')
    )) {
    Assert-BorrowingUpstreamRuleResourceThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid resource measurement'
    } 'resource measurement object, timing, or overflow drift'
  }
}

Invoke-CzxtContract 'upstream self-test rejects timeout process leaks and wrong reasons' {
  $header = @('超时项', '计时边界', '超时动作', 'stage / reason')
  $rows = Get-BorrowingTimeoutContractRows
  $valid = New-BorrowingUpstreamRuleResourceTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid timeout contract'
  foreach ($invalid in @(
      $valid.Replace('超时杀进程树', '仅停止等待'),
      $valid.Replace('stage=capture；reason_code=resource-limit', 'stage=input；reason_code=capture-failed'),
      $valid.Replace('reason_code=p4t-process-failed', 'reason_code=p4t-not-zero')
    )) {
    Assert-BorrowingUpstreamRuleResourceThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid timeout contract'
    } 'timeout leaves process tree or maps wrong failure'
  }
}

Complete-CzxtContracts
