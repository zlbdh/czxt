[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-skill-main-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-cases.ps1')

function Assert-BorrowingSkillCommandSelfTestThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected skill/command rejection: {0}" -f $Context)
}

function New-BorrowingSkillCommandTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'skill command self-test rejects metadata key-list-only contracts' {
  $header = @('metadata 项', '精确合同')
  $rows = Get-BorrowingWebMetadataContractRows
  $valid = New-BorrowingSkillCommandTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid Web metadata contract'
  $keysOnly = New-BorrowingSkillCommandTable $header @(,$rows[1])
  Assert-BorrowingSkillCommandSelfTestThrows {
    Assert-BorrowingExactOrderedTable $keysOnly $header $rows 'metadata keys only'
  } 'metadata contract only lists key names'
  $unknownHash = $valid.TrimEnd() + "`n| hash | trust metadata hash |`n"
  Assert-BorrowingSkillCommandSelfTestThrows {
    Assert-BorrowingExactOrderedTable $unknownHash $header $rows 'unknown hash key'
  } 'metadata contract permits unknown hash'
  $invalidRedirects = @(
    $valid.Replace(
      'schema, original_url, final_url, redirect_chain, status_code',
      'schema, original_url, final_url, redirect_count, status_code'
    ),
    $valid.Replace('数组顺序等于访问顺序', '数组顺序可任意'),
    $valid.Replace('status_code, location_url', 'status_code'),
    $valid.Replace(
      '末项 location_url 必须等于 final_url',
      '末项 location_url 可以不同于 final_url'
    )
  )
  foreach ($invalid in $invalidRedirects) {
    Assert-BorrowingSkillCommandSelfTestThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid redirect chain'
    } 'redirect chain count/order/item/final contract'
  }
}

Invoke-CzxtContract 'skill command self-test rejects replaceable RootMode loader paths' {
  Assert-BorrowingLineSequence $script:BorrowingTrustedRootModeLine `
    @($script:BorrowingTrustedRootModeLine) 'valid trusted RootMode loader'
  foreach ($invalid in @(
      $script:BorrowingTrustedRootModeLine.Replace(
        '能力资产/tools/scripts/check-os/framework-scope.ps1', '<operator-supplied-path>'
      ),
      '调用 `Get-CzxtRootMode` 后按人类标签判断。'
    )) {
    Assert-BorrowingSkillCommandSelfTestThrows {
      Assert-BorrowingLineSequence $invalid @($script:BorrowingTrustedRootModeLine) `
        'replaceable RootMode loader'
    } $invalid
  }
}

Invoke-CzxtContract 'skill command self-test rejects ambiguous preflight staging output' {
  $valid = $script:BorrowingStagingFailureLines -join "`n"
  Assert-BorrowingLineSequence $valid $script:BorrowingStagingFailureLines `
    'valid staging failure output'
  foreach ($invalid in @(
      '失败时报告 staging 路径。',
      ($valid.Replace('none（未创建）', '<staging-path>')),
      ($script:BorrowingStagingFailureLines[0])
    )) {
    Assert-BorrowingSkillCommandSelfTestThrows {
      Assert-BorrowingLineSequence $invalid $script:BorrowingStagingFailureLines `
        'ambiguous staging failure output'
    } $invalid
  }
}

Complete-CzxtContracts
