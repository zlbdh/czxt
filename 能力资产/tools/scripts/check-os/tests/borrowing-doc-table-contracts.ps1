$ErrorActionPreference = 'Stop'

function ConvertFrom-BorrowingMarkdownTableLine {
  param([string]$Line)
  if ($Line -notmatch '^[ ]{0,3}\|.*\|[ \t]*$') { return $null }
  $cells = [string[]]@($Line.Trim().Trim('|').Split('|') | ForEach-Object {
      $_.Trim().Replace('`', '')
    })
  return ,$cells
}

function ConvertFrom-BorrowingMarkdownRawTableLine {
  param([string]$Line)
  if ($Line -notmatch '^[ ]{0,3}\|.*\|[ \t]*$') { return $null }
  $cells = [string[]]@($Line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
  return ,$cells
}

function Test-BorrowingCellArrayEqual {
  param([string[]]$Left, [string[]]$Right)
  if ($Left.Count -ne $Right.Count) { return $false }
  for ($index = 0; $index -lt $Left.Count; $index++) {
    if ($Left[$index] -cne $Right[$index]) { return $false }
  }
  return $true
}

function Test-BorrowingSeparatorCells {
  param([string[]]$Cells)
  if ($null -eq $Cells -or $Cells.Count -eq 0) { return $false }
  foreach ($cell in $Cells) {
    if ($cell -notmatch '^:?-{3,}:?$') { return $false }
  }
  return $true
}

function Get-BorrowingMarkdownTableByHeader {
  param([string]$Text, [string[]]$Header, [string]$Context)
  $scan = Get-BorrowingMarkdownScan $Text
  $lines = $scan.Lines
  $starts = New-Object 'Collections.Generic.List[int]'
  for ($index = 0; $index -lt $lines.Count - 1; $index++) {
    if (-not $scan.OutsideFence[$index] -or -not $scan.OutsideFence[$index + 1]) { continue }
    $cells = ConvertFrom-BorrowingMarkdownTableLine $lines[$index]
    if ($null -eq $cells -or -not (Test-BorrowingCellArrayEqual $cells $Header)) { continue }
    $separator = ConvertFrom-BorrowingMarkdownTableLine $lines[$index + 1]
    if ((Test-BorrowingSeparatorCells $separator) -and $separator.Count -eq $Header.Count) {
      [void]$starts.Add($index)
    }
  }
  Assert-CzxtEqual 1 $starts.Count ("{0} exact-header table count" -f $Context)

  $rows = @()
  $rawRows = @()
  for ($index = $starts[0] + 2; $index -lt $lines.Count; $index++) {
    if (-not $scan.OutsideFence[$index]) { break }
    $cells = ConvertFrom-BorrowingMarkdownTableLine $lines[$index]
    if ($null -eq $cells) { break }
    Assert-CzxtTrue (-not (Test-BorrowingSeparatorCells $cells)) `
      ("{0} contains an unexpected separator row" -f $Context)
    $rows += ,$cells
    $rawRows += ,(ConvertFrom-BorrowingMarkdownRawTableLine $lines[$index])
  }
  return [pscustomobject]@{
    Header = $Header
    Rows = [object[]]$rows
    RawRows = [object[]]$rawRows
  }
}

function Get-BorrowingTableRowSignature {
  param([string[]]$Cells)
  return ('{0}:{1}' -f $Cells.Count, ($Cells -join [char]0x1F))
}

function Assert-BorrowingExactTable {
  param(
    [string]$Text, [string[]]$Header,
    [object[]]$ExpectedRows, [string]$Context
  )
  $table = Get-BorrowingMarkdownTableByHeader $Text $Header $Context
  $actual = @($table.Rows | ForEach-Object {
      Get-BorrowingTableRowSignature ([string[]]$_)
    })
  $expected = @($ExpectedRows | ForEach-Object {
      Get-BorrowingTableRowSignature ([string[]]$_)
    })
  Assert-CzxtEqual $expected.Count $actual.Count ("{0} data-row count" -f $Context)
  foreach ($signature in $expected) {
    $count = @($actual | Where-Object { $_ -ceq $signature }).Count
    Assert-CzxtEqual 1 $count ("{0} exact row occurrence: {1}" -f $Context, $signature)
  }
}

function Assert-BorrowingExactOrderedTable {
  param(
    [string]$Text, [string[]]$Header,
    [object[]]$ExpectedRows, [string]$Context
  )
  $table = Get-BorrowingMarkdownTableByHeader $Text $Header $Context
  Assert-CzxtEqual $ExpectedRows.Count $table.Rows.Count `
    ("{0} ordered data-row count" -f $Context)
  for ($index = 0; $index -lt $ExpectedRows.Count; $index++) {
    $actual = [string[]]$table.Rows[$index]
    $expected = [string[]]$ExpectedRows[$index]
    Assert-CzxtTrue (Test-BorrowingCellArrayEqual $expected $actual) `
      ("{0} exact ordered row {1}" -f $Context, ($index + 1))
  }
}

function Assert-BorrowingExactFirstColumnTable {
  param(
    [string]$Text, [string[]]$Header,
    [string[]]$ExpectedFirstColumn, [string]$Context
  )
  $table = Get-BorrowingMarkdownTableByHeader $Text $Header $Context
  $actual = New-Object 'Collections.Generic.List[string]'
  foreach ($row in @($table.Rows)) {
    Assert-CzxtEqual $Header.Count $row.Count ("{0} column count" -f $Context)
    [void]$actual.Add([string]$row[0])
  }
  Assert-CzxtEqual $ExpectedFirstColumn.Count $actual.Count ("{0} data-row count" -f $Context)
  foreach ($field in $ExpectedFirstColumn) {
    $count = @($actual | Where-Object { $_ -ceq $field }).Count
    Assert-CzxtEqual 1 $count ("{0} first-column occurrence: {1}" -f $Context, $field)
  }
}

function Get-BorrowingUniqueTableRowIndex {
  param($Table, [string]$FirstCell, [string]$Context)
  $indexes = New-Object 'Collections.Generic.List[int]'
  for ($index = 0; $index -lt $Table.Rows.Count; $index++) {
    if ($Table.Rows[$index].Count -gt 0 -and $Table.Rows[$index][0] -ceq $FirstCell) {
      [void]$indexes.Add($index)
    }
  }
  Assert-CzxtEqual 1 $indexes.Count ("{0} row count: {1}" -f $Context, $FirstCell)
  return $indexes[0]
}

function Assert-BorrowingTableCellValue {
  param(
    [string]$Text, [string[]]$Header, [string]$FirstCell,
    [int]$ColumnIndex, [string]$Expected, [string]$Context
  )
  $table = Get-BorrowingMarkdownTableByHeader $Text $Header $Context
  $rowIndex = Get-BorrowingUniqueTableRowIndex $table $FirstCell $Context
  Assert-CzxtEqual $Header.Count $table.Rows[$rowIndex].Count ("{0} column count" -f $Context)
  Assert-CzxtEqual $Expected $table.Rows[$rowIndex][$ColumnIndex] `
    ("{0} cell value: {1}" -f $Context, $FirstCell)
}

function Assert-BorrowingSingleInlineCodeTableCell {
  param(
    [string]$Text, [string[]]$Header, [string]$FirstCell,
    [int]$ColumnIndex, [string]$Expected, [string]$Context
  )
  $table = Get-BorrowingMarkdownTableByHeader $Text $Header $Context
  $rowIndex = Get-BorrowingUniqueTableRowIndex $table $FirstCell $Context
  $raw = [string]$table.RawRows[$rowIndex][$ColumnIndex]
  $match = [regex]::Match($raw, '^`(?<value>[^`\r\n]+)`$')
  Assert-CzxtTrue $match.Success ("{0} must be one single-backtick inline-code span" -f $Context)
  Assert-CzxtEqual $Expected $match.Groups['value'].Value ("{0} inline-code value" -f $Context)
}
