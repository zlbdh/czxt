[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-machine-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-resource-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-output-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-web-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-parameter-cases.ps1')

function Assert-BorrowingUpstreamThirdThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected third-review rejection: {0}" -f $Context)
}

function New-BorrowingUpstreamThirdTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'third-review self-test rejects resource key stage depth and reason drift' {
  $header = @('资源项', '适用来源', '计量对象与时点', 'reason')
  $rows = Get-BorrowingResourceMeasurementRows
  $valid = New-BorrowingUpstreamThirdTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid third-review resources'
  foreach ($invalid in @(
      $valid.Replace('单项字节', '单项'),
      $valid.Replace('metadata 字节', 'metadata'),
      $valid.Replace('根级文件=1；空集=0', '根级文件=0'),
      $valid.Replace('复制后对 source-after/staging 重复检查', '复制后不复查'),
      $valid.Replace('仅 fetch 后在 staging 内检查', 'fetch 前检查'),
      $valid.Replace('p4t-process-failed', 'resource-limit')
    )) {
    Assert-BorrowingUpstreamThirdThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid resource contract'
    } 'resource key, stage, depth, or reason drift'
  }
  $stageHeader = @('适用来源', '固定范围', '固定检查阶段')
  $stageRows = Get-BorrowingResourceStageRows
  $stages = New-BorrowingUpstreamThirdTable $stageHeader $stageRows
  Assert-BorrowingExactOrderedTable $stages $stageHeader $stageRows 'valid resource stages'
  Assert-BorrowingUpstreamThirdThrows {
    Assert-BorrowingExactOrderedTable `
      ($stages.Replace('创建 staging 前检查', '创建 staging 后检查')) `
      $stageHeader $stageRows 'late staging checks'
  } 'Local or Web limit runs after staging creation'
  $commonHeader = @('资源公共项', '精确合同')
  $commonRows = Get-BorrowingResourceCommonRows
  $common = New-BorrowingUpstreamThirdTable $commonHeader $commonRows
  Assert-BorrowingExactOrderedTable $common $commonHeader $commonRows 'valid common resources'
  Assert-BorrowingUpstreamThirdThrows {
    Assert-BorrowingExactOrderedTable `
      ($common.Replace('任一计数或求和溢出即硬失败', 'Int64 溢出后截断')) `
      $commonHeader $commonRows 'overflow truncation'
  } 'Int64 overflow is tolerated'
}

Invoke-CzxtContract 'third-review self-test rejects old P4t domains and rollback gaps' {
  $lines = Get-BorrowingFacadeOutputLines
  $validLines = $lines -join "`n"
  Assert-BorrowingLineSequence $validLines $lines 'valid four-state P4t lines'
  $oldDomain = $validLines.Replace(
    '<not-run|start-failed|timeout|integer>', '<not-run|integer>'
  )
  Assert-BorrowingUpstreamThirdThrows {
    Assert-BorrowingLineSequence $oldDomain $lines 'old P4t domain'
  } 'P4t fields omit start-failed and timeout'
  $header = @('P4t 情形', '输出合同')
  $rows = Get-BorrowingP4tOutputRows
  $valid = New-BorrowingUpstreamThirdTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid four-state P4t table'
  foreach ($invalid in @(
      $valid.Replace('已启动后超时并杀进程树', '超时但不杀进程树'),
      $valid.Replace('对应字段=start-failed', '对应字段=not-run'),
      $valid.Replace('均原子 rollback', '不回退')
    )) {
    Assert-BorrowingUpstreamThirdThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid P4t state table'
    } 'P4t state, reason, or rollback drift'
  }
}

Invoke-CzxtContract 'third-review self-test rejects noncanonical JSON strings and MIME cells' {
  $header = @('canonical JSON string 项', '精确合同')
  $rows = Get-BorrowingCanonicalJsonStringRows
  $valid = New-BorrowingUpstreamThirdTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid canonical JSON string'
  foreach ($invalid in @(
      $valid.Replace('quote→\"', 'quote 原样'),
      $valid.Replace('大写 4 位 \uXXXX', '小写可变位数转义'),
      $valid.Replace('非 BMP 原样', '非 BMP 转义为 surrogate pair'),
      $valid.Replace('不转义', '转义为 \/')
    )) {
    Assert-BorrowingUpstreamThirdThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid canonical JSON string'
    } 'JSON string escaping drift'
  }
  $regex = '^[a-z0-9][a-z0-9!#$%&''*+.^_~-]*/[a-z0-9][a-z0-9!#$%&''*+.^_~-]*$'
  $mimeTable = @(
    '| Web 规范化项 | 精确合同 |'
    '|---|---|'
    ('| mime | `' + $regex + '` |')
  ) -join "`n"
  Assert-BorrowingSingleInlineCodeTableCell $mimeTable @('Web 规范化项', '精确合同') `
    'mime' 1 $regex 'valid MIME regex span'
  Assert-BorrowingUpstreamThirdThrows {
    Assert-BorrowingSingleInlineCodeTableCell ($mimeTable.Replace('`', '')) `
      @('Web 规范化项', '精确合同') 'mime' 1 $regex 'plain MIME regex'
  } 'MIME regex is not one inline-code span'
}

Invoke-CzxtContract 'third-review self-test rejects host and validated-output boundary drift' {
  $header = @('参数边界项', '精确合同')
  $rows = Get-BorrowingFacadeParameterRows
  $valid = New-BorrowingUpstreamThirdTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid parameter boundary'
  foreach ($invalid in @(
      $valid.Replace('PositionalBinding=$false', 'PositionalBinding=$true'),
      $valid.Replace('均不存在', '允许 Mandatory'),
      $valid.Replace('unknown / duplicate / positional-extra；合同外', '全部脚本内处理'),
      $valid.Replace(
        '类型转换与内嵌调用合同外',
        'PowerShell 自动类型转换属于支持合同'
      )
    )) {
    Assert-BorrowingUpstreamThirdThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid parameter boundary'
    } 'parameter binding or host boundary drift'
  }
  $outputHeader = @('输出字段', '精确合同')
  $outputRows = Get-BorrowingFacadeValidatedOutputRows
  $outputs = New-BorrowingUpstreamThirdTable $outputHeader $outputRows
  Assert-BorrowingExactOrderedTable $outputs $outputHeader $outputRows `
    'valid identifier output boundary'
  foreach ($invalid in @(
      $outputs.Replace('否则 none', '否则原样回显'),
      $outputs.Replace('禁止输入 CR/LF 进入任何一行', '移除 CR/LF 后继续输出')
    )) {
    Assert-BorrowingUpstreamThirdThrows {
      Assert-BorrowingExactOrderedTable $invalid $outputHeader $outputRows `
        'invalid identifier or newline output'
    } 'invalid IDs or newlines enter fixed output'
  }
}

Complete-CzxtContracts
