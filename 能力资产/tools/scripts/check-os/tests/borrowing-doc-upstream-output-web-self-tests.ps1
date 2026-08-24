[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-output-cases.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-web-cases.ps1')

function Assert-BorrowingUpstreamOutputWebThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected output/Web rejection: {0}" -f $Context)
}

function New-BorrowingUpstreamOutputWebTable {
  param([string[]]$Header, [object[]]$Rows)
  $lines = @(
    ('| ' + ($Header -join ' | ') + ' |')
    ('|' + (@($Header | ForEach-Object { '---' }) -join '|') + '|')
  )
  foreach ($row in $Rows) { $lines += '| ' + ($row -join ' | ') + ' |' }
  return ($lines -join "`n") + "`n"
}

Invoke-CzxtContract 'upstream self-test rejects result exit and path association drift' {
  $header = @('结果关联项', '精确合同')
  $rows = Get-BorrowingResultAssociationRows
  $valid = New-BorrowingUpstreamOutputWebTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid result associations'
  foreach ($invalid in @(
      $valid.Replace('当且仅当 result=READY 或 REUSED', 'result=READY 时'),
      $valid.Replace('p4t_after=0', 'p4t_after=not-run'),
      $valid.Replace('p4t_after=not-run', 'p4t_after=0'),
      $valid.Replace('reason_code 非 none；reason 非空', 'reason_code=none；reason 为空'),
      $valid.Replace('none（已清理）', 'none（已晋升）')
    )) {
    Assert-BorrowingUpstreamOutputWebThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows 'invalid result association'
    } 'result/exit/P4t/path association drift'
  }
}

Invoke-CzxtContract 'upstream self-test rejects P4t and handled-output drift' {
  $p4tHeader = @('P4t 情形', '输出合同')
  $p4tRows = Get-BorrowingP4tOutputRows
  $p4t = New-BorrowingUpstreamOutputWebTable $p4tHeader $p4tRows
  Assert-BorrowingExactOrderedTable $p4t $p4tHeader $p4tRows 'valid P4t output'
  foreach ($invalid in @(
      $p4t.Replace('reason_code=p4t-not-zero', 'reason_code=p4t-process-failed'),
      $p4t.Replace('正常退出原码', '统一写 0'),
      $p4t.Replace('字段=not-run', '字段为空')
    )) {
    Assert-BorrowingUpstreamOutputWebThrows {
      Assert-BorrowingExactOrderedTable $invalid $p4tHeader $p4tRows 'invalid P4t output'
    } 'P4t reason or field mapping drift'
  }
  $handledHeader = @('调用类别', 'stdout', 'stderr')
  $handledRows = Get-BorrowingHandledOutputRows
  $handled = New-BorrowingUpstreamOutputWebTable $handledHeader $handledRows
  Assert-BorrowingExactOrderedTable $handled $handledHeader $handledRows 'valid handled output'
  foreach ($invalid in @(
      $handled.Replace('内部异常 | 固定 12 行 | 空', '内部异常 | 无 stdout | 错误详情'),
      $handled.Replace('host 未知参数绑定错误 | 合同外', 'host 未知参数绑定错误 | 固定 12 行')
    )) {
    Assert-BorrowingUpstreamOutputWebThrows {
      Assert-BorrowingExactOrderedTable $invalid $handledHeader $handledRows `
        'invalid handled output'
    } 'internal error or host boundary drift'
  }
}

Invoke-CzxtContract 'upstream self-test rejects unsafe reason and path disclosure' {
  $reasonHeader = @('reason 规则', '精确合同')
  $reasonRows = Get-BorrowingReasonSanitizationRows
  $reason = New-BorrowingUpstreamOutputWebTable $reasonHeader $reasonRows
  Assert-BorrowingExactOrderedTable $reason $reasonHeader $reasonRows 'valid reason rules'
  foreach ($invalid in @(
      $reason.Replace('仅可信常量 + 字段名/阶段', '可信常量 + 输入值'),
      $reason.Replace('禁止 C0 / C1 / U+2028 / U+2029', '仅禁止 CR/LF'),
      $reason.Replace('UTF-8 不超过 512 字节', '字符数不超过 512')
    )) {
    Assert-BorrowingUpstreamOutputWebThrows {
      Assert-BorrowingExactOrderedTable $invalid $reasonHeader $reasonRows 'unsafe reason'
    } 'reason leaks input or weakens sanitation'
  }
  $pathHeader = @('路径输出项', '精确合同')
  $pathRows = Get-BorrowingOutputPathRows
  $paths = New-BorrowingUpstreamOutputWebTable $pathHeader $pathRows
  Assert-BorrowingExactOrderedTable $paths $pathHeader $pathRows 'valid output paths'
  Assert-BorrowingUpstreamOutputWebThrows {
    Assert-BorrowingExactOrderedTable `
      ($paths.Replace('禁止输出 | LocalPath / Web 输入路径 / Git URL', '禁止输出 | Git URL')) `
      $pathHeader $pathRows 'input path disclosure'
  } 'LocalPath or Web input path can leak'
}

Invoke-CzxtContract 'upstream self-test rejects noncanonical Web projection' {
  $header = @('Web 规范化项', '精确合同')
  $rows = Get-BorrowingWebNormalizationRows
  $valid = New-BorrowingUpstreamOutputWebTable $header $rows
  Assert-BorrowingExactOrderedTable $valid $header $rows 'valid Web normalization'
  foreach ($invalid in @(
      $valid.Replace('禁止 userinfo、query、fragment、backslash、CR、LF', '仅禁止 CR/LF'),
      $valid.Replace('IDN 转 ASCII 后小写', '保留 Unicode host'),
      $valid.Replace('仅允许默认 443；规范化输出移除端口', '允许任意端口'),
      $valid.Replace('percent 十六进制大写', '保留 percent 原大小写'),
      $valid.Replace('与 JSON null 可区分', '等同于 JSON null'),
      $valid.Replace(
        '^[a-z0-9][a-z0-9!#$%&''*+.^_~-]*/[a-z0-9][a-z0-9!#$%&''*+.^_~-]*$',
        '任意 MIME 字符串'
      ),
      $valid.Replace('禁止原始 pipe、TAB、CR、LF', '仅禁止 CR/LF')
    )) {
    Assert-BorrowingUpstreamOutputWebThrows {
      Assert-BorrowingExactOrderedTable $invalid $header $rows `
        'noncanonical Web projection'
    } 'Web URL, JSON, MIME, or cell sanitation drift'
  }
}

Complete-CzxtContracts
