[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gate0-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-support.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-table-contracts.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-contract-guards.ps1')
. (Join-Path $PSScriptRoot 'borrowing-doc-command-guard.ps1')

function Assert-BorrowingEdgeThrows {
  param([scriptblock]$Body, [string]$Context)
  $thrown = $false
  try { & $Body }
  catch { $thrown = $true }
  Assert-CzxtTrue $thrown ("expected edge rejection: {0}" -f $Context)
}

Invoke-CzxtContract 'edge self-test normalizes ATX headings and extended headers' {
  $unsafe = @(
    "## **来源清单**`n",
    "## [事项台账](ledger.md) ##`n",
    "| 权限字段 | 允许值 | 默认值 | 备注 |`n|---|---|---|---|`n"
  )
  foreach ($text in $unsafe) {
    Assert-BorrowingEdgeThrows {
      Assert-BorrowingReadmeProjectionOnly $text 'README edge fixture'
    } $text.Trim()
  }
  Assert-BorrowingReadmeProjectionOnly "## **静态导航**`n| 文件 | 一句话 |`n|---|---|`n" 'legal README edge'
}

Invoke-CzxtContract 'edge self-test requires one inline-code span for every ID format' {
  $valid = @'
| 标识 | 固定格式 |
|---|---|
| source_id | `(?:[a-z0-9])(?:[a-z0-9._-])*` |
| capture_id | `<source_type>-<YYYYMMDD>-<12hex>` |
| borrow_id | `borrow-[0-9]{8}-(?:[a-z0-9])(?:[a-z0-9._-])*(?:-[0-9]+)?` |
'@
  $header = @('标识', '固定格式')
  Assert-BorrowingSingleInlineCodeTableCell $valid $header 'source_id' 1 `
    '(?:[a-z0-9])(?:[a-z0-9._-])*' 'valid source ID'
  Assert-BorrowingSingleInlineCodeTableCell $valid $header 'capture_id' 1 `
    '<source_type>-<YYYYMMDD>-<12hex>' 'valid capture ID'
  Assert-BorrowingSingleInlineCodeTableCell $valid $header 'borrow_id' 1 `
    'borrow-[0-9]{8}-(?:[a-z0-9])(?:[a-z0-9._-])*(?:-[0-9]+)?' 'valid borrow ID'
  $adjacent = $valid.Replace(
    '`(?:[a-z0-9])(?:[a-z0-9._-])*`',
    '`(?:[a-z0-9])``(?:[a-z0-9._-])*`'
  )
  Assert-BorrowingEdgeThrows {
    Assert-BorrowingSingleInlineCodeTableCell $adjacent $header 'source_id' 1 `
      '(?:[a-z0-9])(?:[a-z0-9._-])*' 'adjacent source spans'
  } 'adjacent inline-code spans'
  $plainCapture = $valid.Replace('`<source_type>-<YYYYMMDD>-<12hex>`', '<source_type>-<YYYYMMDD>-<12hex>')
  Assert-BorrowingEdgeThrows {
    Assert-BorrowingSingleInlineCodeTableCell $plainCapture $header 'capture_id' 1 `
      '<source_type>-<YYYYMMDD>-<12hex>' 'plain capture format'
  } 'capture format without inline code'
}

Invoke-CzxtContract 'edge self-test rejects every practical direct Git command form' {
  $continued = @'
git `
  -c core.hooksPath=NUL `
  clone https://example.invalid/repo.git
'@
  $fenced = @'
```powershell
git rev-parse HEAD
```
'@
  $unsafe = @(
    'git rev-parse HEAD',
    'git.exe status --short',
    'git -c protocol.file.allow=never clone https://example.invalid/repo.git',
    '$ git log -1',
    '& ''git.exe'' show HEAD',
    '请运行 `git rev-parse HEAD` 诊断。',
    $continued,
    $fenced
  )
  foreach ($text in $unsafe) {
    Assert-BorrowingEdgeThrows { Assert-BorrowingCommandPublicSurface $text } $text
  }
  Assert-BorrowingCommandPublicSurface 'Git 安全参数由执行器落实。'
}

Invoke-CzxtContract 'edge self-test treats four-space and tab actions as code' {
  $valid = @{ A = '   - 只读比较'; B = '- 远端取源'; C = '- 路径逃逸' }
  Assert-BorrowingActionOwnership $valid 'A' @('只读比较') 'three-space action'
  foreach ($text in @('    - 只读比较', "`t- 只读比较")) {
    $invalid = @{ A = $text; B = '- 远端取源'; C = '- 路径逃逸' }
    Assert-BorrowingEdgeThrows {
      Assert-BorrowingActionOwnership $invalid 'A' @('只读比较') 'indented action'
    } $text
  }
}

Complete-CzxtContracts
