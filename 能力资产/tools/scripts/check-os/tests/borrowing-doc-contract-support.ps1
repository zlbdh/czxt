$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'borrowing-doc-markdown-parser.ps1')

function Get-BorrowingDocPath {
  param([string]$Root, [string]$RelativePath)
  return Join-Path $Root ($RelativePath.Replace('/', '\'))
}

function Test-BorrowingDocFile {
  param([string]$Root, [string]$RelativePath)
  return Test-Path -LiteralPath (Get-BorrowingDocPath $Root $RelativePath) -PathType Leaf
}

function Get-BorrowingDocText {
  param([string]$Root, [string]$RelativePath)
  $path = Get-BorrowingDocPath $Root $RelativePath
  Assert-CzxtTrue (Test-Path -LiteralPath $path -PathType Leaf) ("missing file: {0}" -f $RelativePath)
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Assert-BorrowingDocContainsAll {
  param([string]$Text, [string[]]$Needles, [string]$Context)
  foreach ($needle in $Needles) {
    Assert-CzxtTrue $Text.Contains($needle) ("{0} missing: {1}" -f $Context, $needle)
  }
}

function Assert-BorrowingDocExcludesAll {
  param([string]$Text, [string[]]$Needles, [string]$Context)
  foreach ($needle in $Needles) {
    Assert-CzxtTrue (-not $Text.Contains($needle)) ("{0} must not contain: {1}" -f $Context, $needle)
  }
}

function Assert-BorrowingDocMatches {
  param([string]$Text, [string]$Pattern, [string]$Context)
  Assert-CzxtTrue ([regex]::IsMatch($Text, $Pattern)) ("{0} missing pattern: {1}" -f $Context, $Pattern)
}

function Assert-BorrowingDocNoMatch {
  param([string]$Text, [string]$Pattern, [string]$Context)
  Assert-CzxtTrue (-not [regex]::IsMatch($Text, $Pattern)) ("{0} contains forbidden pattern: {1}" -f $Context, $Pattern)
}

function Assert-BorrowingDocMatchCount {
  param([string]$Text, [string]$Pattern, [int]$Expected, [string]$Context)
  $count = [regex]::Matches($Text, $Pattern).Count
  Assert-CzxtEqual $Expected $count $Context
}

function Assert-BorrowingTableRow {
  param([string]$Text, [string[]]$ExpectedCells, [string]$Context)
  foreach ($row in @(Get-BorrowingTableRows $Text)) {
    if ($row.Count -ne $ExpectedCells.Count) { continue }
    $same = $true
    for ($index = 0; $index -lt $ExpectedCells.Count; $index++) {
      if ($row[$index] -cne $ExpectedCells[$index]) { $same = $false; break }
    }
    if ($same) { return }
  }
  throw ("{0} missing exact table row: {1}" -f $Context, ($ExpectedCells -join ' | '))
}

function Assert-BorrowingTableFirstCell {
  param([string]$Text, [string]$Expected, [string]$Context)
  foreach ($row in @(Get-BorrowingTableRows $Text)) {
    if ($row.Count -gt 0 -and $row[0] -ceq $Expected) { return }
  }
  throw ("{0} missing table first cell: {1}" -f $Context, $Expected)
}

function Assert-BorrowingOrderedText {
  param([string]$Text, [string[]]$Needles, [string]$Context)
  $cursor = 0
  foreach ($needle in $Needles) {
    $found = $Text.IndexOf($needle, $cursor, [StringComparison]::Ordinal)
    if ($found -lt 0) {
      throw ("{0} missing or out of order: {1}" -f $Context, $needle)
    }
    $cursor = $found + $needle.Length
  }
}

function Assert-BorrowingIndexLink {
  param(
    [string]$Text, [string]$Heading, [string]$Label,
    [string]$Target, [int]$Expected = 1
  )
  $section = Get-BorrowingMarkdownSection $Text $Heading
  $pattern = '\[' + [regex]::Escape($Label) + '\]\(' + [regex]::Escape($Target) + '\)'
  Assert-BorrowingDocMatchCount $section $pattern $Expected ("{0} link count in {1}" -f $Label, $Heading)
}

function Assert-BorrowingRelativeLink {
  param(
    [string]$Root, [string]$SourceRelativePath,
    [string]$Text, [string]$Target, [int]$Expected = 1
  )
  $pattern = '\]\(' + [regex]::Escape($Target) + '\)'
  Assert-BorrowingDocMatchCount $Text $pattern $Expected ("relative link count: {0} -> {1}" -f $SourceRelativePath, $Target)
  $source = Get-BorrowingDocPath $Root $SourceRelativePath
  $candidate = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $source) $Target))
  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
  Assert-CzxtTrue $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) `
    ("relative link escapes root: {0}" -f $Target)
  Assert-CzxtTrue (Test-Path -LiteralPath $candidate -PathType Leaf) `
    ("relative link target missing: {0}" -f $Target)
}

function Assert-BorrowingLineSequence {
  param([string]$Text, [string[]]$ExpectedLines, [string]$Context)
  $actual = @($Text.Replace("`r`n", "`n") -split "`n")
  for ($start = 0; $start -le $actual.Count - $ExpectedLines.Count; $start++) {
    $matched = $true
    for ($offset = 0; $offset -lt $ExpectedLines.Count; $offset++) {
      if ($actual[$start + $offset] -cne $ExpectedLines[$offset]) { $matched = $false; break }
    }
    if ($matched) { return }
  }
  throw ("{0} missing exact contiguous lines" -f $Context)
}
