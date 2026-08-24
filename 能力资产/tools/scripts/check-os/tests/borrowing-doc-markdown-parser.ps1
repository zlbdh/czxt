$ErrorActionPreference = 'Stop'

function Get-BorrowingMarkdownScan {
  param([string]$Text)
  $lines = [string[]]@($Text.Replace("`r`n", "`n") -split "`n")
  $outside = New-Object 'bool[]' $lines.Count
  $inFence = $false
  $fenceChar = ''
  $fenceLength = 0

  for ($index = 0; $index -lt $lines.Count; $index++) {
    $line = $lines[$index]
    if (-not $inFence) {
      if ($line -match '^(?: {4}|\t)') {
        $outside[$index] = $false
        continue
      }
      $open = [regex]::Match($line, '^[ ]{0,3}(?<marker>`{3,}|~{3,})(?<tail>.*)$')
      $validOpen = $open.Success
      if ($validOpen -and $open.Groups['marker'].Value[0] -eq '`' -and
          $open.Groups['tail'].Value.Contains('`')) {
        $validOpen = $false
      }
      if ($validOpen) {
        $marker = $open.Groups['marker'].Value
        $inFence = $true
        $fenceChar = [string]$marker[0]
        $fenceLength = $marker.Length
        $outside[$index] = $false
        continue
      }
      $outside[$index] = $true
      continue
    }

    $outside[$index] = $false
    $closePattern = '^[ ]{0,3}' + [regex]::Escape($fenceChar) +
      '{' + $fenceLength + ',}[ \t]*$'
    if ([regex]::IsMatch($line, $closePattern)) {
      $inFence = $false
      $fenceChar = ''
      $fenceLength = 0
    }
  }
  return [pscustomobject]@{ Lines = $lines; OutsideFence = $outside }
}

function Get-BorrowingMarkdownSection {
  param([string]$Text, [string]$Heading, [int]$Level = 2)
  $scan = Get-BorrowingMarkdownScan $Text
  $marks = '#' * $Level
  $targetPattern = '^[ ]{0,3}' + [regex]::Escape($marks) + '[ \t]+' +
    [regex]::Escape($Heading) + '(?:[ \t]+#+)?[ \t]*$'
  $starts = New-Object 'Collections.Generic.List[int]'
  for ($index = 0; $index -lt $scan.Lines.Count; $index++) {
    if ($scan.OutsideFence[$index] -and [regex]::IsMatch($scan.Lines[$index], $targetPattern)) {
      [void]$starts.Add($index)
    }
  }
  Assert-CzxtEqual 1 $starts.Count ("section count: {0}" -f $Heading)

  $end = $scan.Lines.Count
  $endPattern = '^[ ]{0,3}#{1,' + $Level + '}[ \t]+'
  for ($index = $starts[0] + 1; $index -lt $scan.Lines.Count; $index++) {
    if ($scan.OutsideFence[$index] -and [regex]::IsMatch($scan.Lines[$index], $endPattern)) {
      $end = $index
      break
    }
  }
  if ($end -le $starts[0] + 1) { return '' }
  return ($scan.Lines[($starts[0] + 1)..($end - 1)] -join "`n")
}

function Get-BorrowingTableRows {
  param([string]$Text)
  $scan = Get-BorrowingMarkdownScan $Text
  for ($index = 0; $index -lt $scan.Lines.Count; $index++) {
    if (-not $scan.OutsideFence[$index]) { continue }
    $line = $scan.Lines[$index]
    if ($line -notmatch '^[ ]{0,3}\|.*\|[ \t]*$') { continue }
    $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object {
        $_.Trim().Replace('`', '')
      })
    $separator = $true
    foreach ($cell in $cells) {
      if ($cell -notmatch '^:?-{3,}:?$') { $separator = $false; break }
    }
    if (-not $separator) { Write-Output -NoEnumerate $cells }
  }
}
