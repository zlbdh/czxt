[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-workflow-cases.ps1')

function Assert-BorrowingWorkflowSelfTestThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected workflow-contract rejection: {0}" -f $Context)
}

function New-BorrowingWorkflowTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'workflow self-test rejects human RootMode labels and template total denial' {
  $header = @('marker 组合', 'RootMode 实际返回值', 'workflow 权限')
  $valid = New-BorrowingWorkflowTable $header $script:BorrowingRootModeRows
  Assert-BorrowingExactOrderedTable $valid $header $script:BorrowingRootModeRows `
    'valid RootMode fixture'
  foreach ($invalid in @(
      $valid.Replace('| template |', '| 模板模式 |'),
      $valid.Replace('仅允许模板模式只读 P4t 审计', '零写入；硬失败')
    )) {
    Assert-BorrowingWorkflowSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $script:BorrowingRootModeRows `
        'invalid RootMode fixture'
    } $invalid
  }
  Assert-BorrowingLineSequence $script:BorrowingRootModeReturnLine `
    @($script:BorrowingRootModeReturnLine) 'valid RootMode return line'
}

Invoke-CzxtContract 'workflow self-test rejects shuffled capture gate keywords' {
  $header = @('顺序', '捕获晋升步骤', '精确结果')
  $valid = New-BorrowingWorkflowTable $header $script:BorrowingCapturePromotionRows
  Assert-BorrowingExactOrderedTable $valid $header $script:BorrowingCapturePromotionRows `
    'valid capture promotion fixture'
  $rows = $script:BorrowingCapturePromotionRows
  $shuffled = @($rows[0], $rows[2], $rows[1], $rows[3], $rows[4])
  Assert-BorrowingWorkflowSelfTestThrows {
    Assert-BorrowingExactOrderedTable `
      (New-BorrowingWorkflowTable $header $shuffled) $header `
      $script:BorrowingCapturePromotionRows 'shuffled capture gates'
  } 'atomic move before pre-promotion P4t'
  $readyLoop = $valid.Replace(
    '前后根 P4t 均 exit 0 后才确认/输出',
    '前四步全部成功后才写入 ready'
  )
  Assert-BorrowingWorkflowSelfTestThrows {
    Assert-BorrowingExactOrderedTable $readyLoop $header `
      $script:BorrowingCapturePromotionRows 'circular ready write'
  } 'ready is written only after ready validation'
}

Invoke-CzxtContract 'workflow self-test requires post-gate rollback and audit non-progression' {
  $header = @('事件', '精确结果')
  $valid = New-BorrowingWorkflowTable $header $script:BorrowingCaptureFailureRows
  Assert-BorrowingExactOrderedTable $valid $header $script:BorrowingCaptureFailureRows `
    'valid capture failure fixture'
  $missingRollback = @(
    $script:BorrowingCaptureFailureRows[0],
    $script:BorrowingCaptureFailureRows[2],
    $script:BorrowingCaptureFailureRows[3]
  )
  Assert-BorrowingWorkflowSelfTestThrows {
    Assert-BorrowingExactOrderedTable `
      (New-BorrowingWorkflowTable $header $missingRollback) $header `
      $script:BorrowingCaptureFailureRows 'missing post-gate rollback'
  } 'post-promotion failure without atomic staging rollback'
  $advancingAudit = $valid.Replace('仅 WARN；不得推进任何状态', 'WARN；推进到 ready')
  Assert-BorrowingWorkflowSelfTestThrows {
    Assert-BorrowingExactOrderedTable $advancingAudit $header `
      $script:BorrowingCaptureFailureRows 'audit advances state'
  } 'independent audit exit 5 advances state'
  $missingExit10 = $script:BorrowingCaptureFailureRows[0..2]
  Assert-BorrowingWorkflowSelfTestThrows {
    Assert-BorrowingExactOrderedTable `
      (New-BorrowingWorkflowTable $header $missingExit10) $header `
      $script:BorrowingCaptureFailureRows 'missing audit exit 10'
  } 'independent audit omits exit 10 hard failure'
}

Invoke-CzxtContract 'workflow self-test rejects cross-document RootMode contradictions' {
  $header = @('RootMode', 'Skill 允许模式', '写入边界')
  $valid = New-BorrowingWorkflowTable $header $script:BorrowingSkillRootModeRows
  Assert-BorrowingExactOrderedTable $valid $header $script:BorrowingSkillRootModeRows `
    'valid Skill RootMode matrix'
  foreach ($invalid in @(
      $valid.Replace('仅离线只读 P4t 审计', '无'),
      $valid.Replace('所有模式零写入硬失败', '仅接入模式硬失败')
    )) {
    Assert-BorrowingWorkflowSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header `
        $script:BorrowingSkillRootModeRows 'contradictory Skill RootMode matrix'
    } $invalid
  }
}

Invoke-CzxtContract 'workflow self-test rejects seal loops and missing close rollback' {
  $header = @('关闭顺序', '精确动作', '失败边界')
  $rows = $script:BorrowingCloseTransactionRows
  $valid = New-BorrowingWorkflowTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid close transaction'
  $invalidTables = @(
    $valid.Replace(
      '状态与历史写为 closed；closure_seal_sha256 为空',
      '进入 closed 前 closure_seal_sha256 已存在'
    ),
    (New-BorrowingWorkflowTable $header @(
        $rows[0], $rows[2], $rows[1], $rows[3], $rows[4]
      )),
    (New-BorrowingWorkflowTable $header $rows[0..3])
  )
  foreach ($invalid in $invalidTables) {
    Assert-BorrowingWorkflowSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid close transaction'
    } 'seal loop, wrong order, or missing rollback'
  }
}

Invoke-CzxtContract 'workflow self-test rejects evidence append on terminal states' {
  $valid = $script:BorrowingTerminalStateLines -join "`n"
  Assert-BorrowingLineSequence $valid $script:BorrowingTerminalStateLines `
    'valid terminal-state lines'
  $invalid = 'closed/cancelled 为终态；同状态只允许追加证据。'
  Assert-BorrowingWorkflowSelfTestThrows {
    Assert-BorrowingLineSequence $invalid $script:BorrowingTerminalStateLines `
      'terminal evidence append'
  } 'closed or cancelled permits same-state evidence append'
}

Complete-CzxtContracts
