$ErrorActionPreference = 'Stop'

function global:Throw-BorrowingJsonParseFailure {
  $exception = New-Object InvalidOperationException('invalid Web metadata JSON')
  $exception.Data['BorrowingStage'] = 'input'
  $exception.Data['BorrowingReasonCode'] = 'source-boundary'
  throw $exception
}

function global:New-BorrowingJsonNode {
  param([string]$Kind, $Value, [string]$Lexeme = '')
  return [pscustomobject]@{ Kind = $Kind; Value = $Value; Lexeme = $Lexeme }
}

function global:Skip-BorrowingJsonWhitespace {
  while ($script:BorrowingJsonIndex -lt $script:BorrowingJsonText.Length -and `
      " `t`r`n".IndexOf($script:BorrowingJsonText[$script:BorrowingJsonIndex]) -ge 0) {
    $script:BorrowingJsonIndex++
  }
}

function global:Read-BorrowingJsonHex4 {
  if ($script:BorrowingJsonIndex + 4 -gt $script:BorrowingJsonText.Length) {
    Throw-BorrowingJsonParseFailure
  }
  $hex = $script:BorrowingJsonText.Substring($script:BorrowingJsonIndex, 4)
  if ($hex -notmatch '^[0-9A-Fa-f]{4}$') { Throw-BorrowingJsonParseFailure }
  $script:BorrowingJsonIndex += 4
  return [Convert]::ToInt32($hex, 16)
}

function global:Read-BorrowingJsonString {
  if ($script:BorrowingJsonText[$script:BorrowingJsonIndex] -ne '"') {
    Throw-BorrowingJsonParseFailure
  }
  $script:BorrowingJsonIndex++
  $builder = New-Object Text.StringBuilder
  while ($script:BorrowingJsonIndex -lt $script:BorrowingJsonText.Length) {
    $character = $script:BorrowingJsonText[$script:BorrowingJsonIndex++]
    if ($character -eq '"') { return $builder.ToString() }
    if ([int]$character -lt 0x20) { Throw-BorrowingJsonParseFailure }
    if ($character -eq '\') {
      if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length) {
        Throw-BorrowingJsonParseFailure
      }
      $escape = $script:BorrowingJsonText[$script:BorrowingJsonIndex++]
      switch ($escape) {
        '"' { [void]$builder.Append('"') }
        '\' { [void]$builder.Append('\') }
        '/' { [void]$builder.Append('/') }
        'b' { [void]$builder.Append([char]0x08) }
        'f' { [void]$builder.Append([char]0x0C) }
        'n' { [void]$builder.Append([char]0x0A) }
        'r' { [void]$builder.Append([char]0x0D) }
        't' { [void]$builder.Append([char]0x09) }
        'u' {
          $code = Read-BorrowingJsonHex4
          if ($code -ge 0xD800 -and $code -le 0xDBFF) {
            if ($script:BorrowingJsonIndex + 2 -gt $script:BorrowingJsonText.Length -or `
                $script:BorrowingJsonText.Substring($script:BorrowingJsonIndex, 2) -cne '\u') {
              Throw-BorrowingJsonParseFailure
            }
            $script:BorrowingJsonIndex += 2
            $low = Read-BorrowingJsonHex4
            if ($low -lt 0xDC00 -or $low -gt 0xDFFF) { Throw-BorrowingJsonParseFailure }
            [void]$builder.Append([char]$code)
            [void]$builder.Append([char]$low)
          }
          elseif ($code -ge 0xDC00 -and $code -le 0xDFFF) { Throw-BorrowingJsonParseFailure }
          else { [void]$builder.Append([char]$code) }
        }
        default { Throw-BorrowingJsonParseFailure }
      }
      continue
    }
    if ([char]::IsHighSurrogate($character)) {
      if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length -or `
          -not [char]::IsLowSurrogate($script:BorrowingJsonText[$script:BorrowingJsonIndex])) {
        Throw-BorrowingJsonParseFailure
      }
      [void]$builder.Append($character)
      [void]$builder.Append($script:BorrowingJsonText[$script:BorrowingJsonIndex++])
    }
    elseif ([char]::IsLowSurrogate($character)) { Throw-BorrowingJsonParseFailure }
    else { [void]$builder.Append($character) }
  }
  Throw-BorrowingJsonParseFailure
}

function global:Read-BorrowingJsonNumber {
  $remaining = $script:BorrowingJsonText.Substring($script:BorrowingJsonIndex)
  $match = [regex]::Match($remaining, '^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?')
  if (-not $match.Success) { Throw-BorrowingJsonParseFailure }
  $script:BorrowingJsonIndex += $match.Length
  return New-BorrowingJsonNode number $match.Value $match.Value
}

function global:Read-BorrowingJsonArray {
  $script:BorrowingJsonIndex++
  $items = New-Object 'Collections.Generic.List[object]'
  Skip-BorrowingJsonWhitespace
  if ($script:BorrowingJsonIndex -lt $script:BorrowingJsonText.Length -and `
      $script:BorrowingJsonText[$script:BorrowingJsonIndex] -eq ']') {
    $script:BorrowingJsonIndex++
    return New-BorrowingJsonNode array $items
  }
  while ($true) {
    [void]$items.Add((Read-BorrowingJsonValue))
    Skip-BorrowingJsonWhitespace
    if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length) {
      Throw-BorrowingJsonParseFailure
    }
    $delimiter = $script:BorrowingJsonText[$script:BorrowingJsonIndex++]
    if ($delimiter -eq ']') { return New-BorrowingJsonNode array $items }
    if ($delimiter -ne ',') { Throw-BorrowingJsonParseFailure }
    Skip-BorrowingJsonWhitespace
  }
}

function global:Read-BorrowingJsonObject {
  $script:BorrowingJsonIndex++
  $members = New-Object 'Collections.Generic.Dictionary[string,object]' `
    ([StringComparer]::Ordinal)
  Skip-BorrowingJsonWhitespace
  if ($script:BorrowingJsonIndex -lt $script:BorrowingJsonText.Length -and `
      $script:BorrowingJsonText[$script:BorrowingJsonIndex] -eq '}') {
    $script:BorrowingJsonIndex++
    return New-BorrowingJsonNode object $members
  }
  while ($true) {
    if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length -or `
        $script:BorrowingJsonText[$script:BorrowingJsonIndex] -ne '"') {
      Throw-BorrowingJsonParseFailure
    }
    $key = Read-BorrowingJsonString
    if ($members.ContainsKey($key)) { Throw-BorrowingJsonParseFailure }
    Skip-BorrowingJsonWhitespace
    if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length -or `
        $script:BorrowingJsonText[$script:BorrowingJsonIndex++] -ne ':') {
      Throw-BorrowingJsonParseFailure
    }
    Skip-BorrowingJsonWhitespace
    $members.Add($key, (Read-BorrowingJsonValue))
    Skip-BorrowingJsonWhitespace
    if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length) {
      Throw-BorrowingJsonParseFailure
    }
    $delimiter = $script:BorrowingJsonText[$script:BorrowingJsonIndex++]
    if ($delimiter -eq '}') { return New-BorrowingJsonNode object $members }
    if ($delimiter -ne ',') { Throw-BorrowingJsonParseFailure }
    Skip-BorrowingJsonWhitespace
  }
}

function global:Read-BorrowingJsonValue {
  Skip-BorrowingJsonWhitespace
  if ($script:BorrowingJsonIndex -ge $script:BorrowingJsonText.Length) {
    Throw-BorrowingJsonParseFailure
  }
  $character = $script:BorrowingJsonText[$script:BorrowingJsonIndex]
  if ($character -eq '"') {
    return New-BorrowingJsonNode string (Read-BorrowingJsonString)
  }
  if ($character -eq '{') { return Read-BorrowingJsonObject }
  if ($character -eq '[') { return Read-BorrowingJsonArray }
  foreach ($literal in @(
      @('true', 'boolean', $true), @('false', 'boolean', $false), @('null', 'null', $null)
    )) {
    if ($script:BorrowingJsonText.Substring($script:BorrowingJsonIndex).StartsWith(
        $literal[0], [StringComparison]::Ordinal)) {
      $script:BorrowingJsonIndex += $literal[0].Length
      return New-BorrowingJsonNode $literal[1] $literal[2] $literal[0]
    }
  }
  if ($character -eq '-' -or [char]::IsDigit($character)) { return Read-BorrowingJsonNumber }
  Throw-BorrowingJsonParseFailure
}

function global:ConvertFrom-BorrowingStrictJson {
  param([byte[]]$Bytes)
  if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and `
      $Bytes[2] -eq 0xBF) { Throw-BorrowingJsonParseFailure }
  try {
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    $script:BorrowingJsonText = $encoding.GetString($Bytes)
  }
  catch { Throw-BorrowingJsonParseFailure }
  $script:BorrowingJsonIndex = 0
  $node = Read-BorrowingJsonValue
  Skip-BorrowingJsonWhitespace
  if ($script:BorrowingJsonIndex -ne $script:BorrowingJsonText.Length) {
    Throw-BorrowingJsonParseFailure
  }
  return $node
}
