[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-rules-capture-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-cases.ps1')

function Assert-BorrowingRuleCommandSelfTestThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected rule/command rejection: {0}" -f $Context)
}

function New-BorrowingRuleCommandTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'rule command self-test rejects loose or reordered capture safety' {
  $linkHeader = @('捕获安全判定', '精确结果')
  $linkRows = Get-BorrowingCaptureLinkContractRows
  $valid = New-BorrowingRuleCommandTable $linkHeader $linkRows
  Assert-BorrowingExactOrderedTable $valid $linkHeader $linkRows 'valid link safety'
  foreach ($invalid in @(
      (($linkRows | ForEach-Object { $_ -join '：' }) -join '；'),
      (New-BorrowingRuleCommandTable $linkHeader @($linkRows[1], $linkRows[0]))
    )) {
    Assert-BorrowingRuleCommandSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $linkHeader $linkRows `
        'loose capture link safety'
    } $invalid
  }
  $idHeader = @('幂等场景', '精确合同')
  $idRows = Get-BorrowingIdempotencyContractRows
  $idTable = New-BorrowingRuleCommandTable $idHeader $idRows
  Assert-BorrowingExactOrderedTable $idTable $idHeader $idRows 'valid idempotency'
  $weakKey = $idTable.Replace(
    'source_id + source_type + fingerprint_algorithm + full fingerprint',
    'source_id + fingerprint'
  )
  Assert-BorrowingRuleCommandSelfTestThrows {
    Assert-BorrowingExactOrderedTable $weakKey $idHeader $idRows 'weak reuse key'
  } 'idempotency key omits source type and algorithm'
}

Invoke-CzxtContract 'rule command self-test rejects lossy Web projections' {
  $header = @('metadata 项', '精确合同')
  $rows = Get-BorrowingWebMetadataContractRows
  $valid = New-BorrowingRuleCommandTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid Web projection'
  $invalids = @(
    $valid.Replace('canonical_locator=规范化 final_url', 'canonical_locator=original_url'),
    $valid.Replace('status_code,location_url', 'location_url,status_code'),
    $valid.Replace('无空白 JSON', '带空白 JSON'),
    $valid.Replace('JSON null 投影为字面量 null', 'JSON null 投影为空字符串'),
    $valid.Replace('fingerprint=raw SHA-256', 'fingerprint=decoded-text SHA-256')
  )
  foreach ($invalid in $invalids) {
    Assert-BorrowingRuleCommandSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'lossy Web projection'
    } 'Web projection drift'
  }
}

Invoke-CzxtContract 'rule command self-test rejects resource limit override and plus-one acceptance' {
  $header = @('资源项', '固定上限', '精确边界')
  $rows = Get-BorrowingResourceLimitRows
  $valid = New-BorrowingRuleCommandTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid resource limits'
  foreach ($invalid in @(
      $valid.Replace('10000 合法；10001 失败', '10001 合法'),
      (New-BorrowingRuleCommandTable $header $rows[0..8])
    )) {
    Assert-BorrowingRuleCommandSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid resource limits'
    } 'plus-one accepted or limit missing'
  }
  $line = '所有上限固定且无 override；任一越界统一 reason_code=resource-limit。'
  Assert-BorrowingRuleCommandSelfTestThrows {
    Assert-BorrowingLineSequence '允许 override；越界可重试。' @($line) `
      'resource override'
  } 'resource limits allow override'
}

Invoke-CzxtContract 'rule command self-test rejects facade line and enum drift' {
  $lines = Get-BorrowingFacadeOutputLines
  $validLines = $lines -join "`n"
  Assert-BorrowingLineSequence $validLines $lines 'valid facade stdout'
  foreach ($invalid in @(
      (@($lines[0], $lines[2], $lines[1]) + $lines[3..11] -join "`n"),
      ($lines[0..10] -join "`n")
    )) {
    Assert-BorrowingRuleCommandSelfTestThrows {
      Assert-BorrowingLineSequence $invalid $lines 'invalid facade stdout'
    } 'facade line reordered or missing'
  }
  $header = @('机读项', '精确合同')
  $rows = Get-BorrowingFacadeSemanticsRows
  $valid = New-BorrowingRuleCommandTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid facade semantics'
  foreach ($invalid in @(
      $valid.Replace('0 / 10', '0 / 5 / 10'),
      $valid.Replace(' / complete', ' / invented / complete'),
      $valid.Replace(' / resource-limit /', ' /'),
      $valid.Replace('为空；不得泄露来源内容', '写入来源错误详情')
    )) {
    Assert-BorrowingRuleCommandSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid facade semantics'
    } 'facade exit, enum, or stderr drift'
  }
}

Complete-CzxtContracts
