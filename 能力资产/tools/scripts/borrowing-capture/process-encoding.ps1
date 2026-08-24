$ErrorActionPreference = 'Stop'

function global:ConvertFrom-BorrowingStrictUtf8 {
  param([byte[]]$Bytes, [bool]$AllowNul, [string]$Stage,
    [string]$ReasonCode)
  if (-not $AllowNul -and [Array]::IndexOf($Bytes, [byte]0) -ge 0) {
    Throw-BorrowingFailure -Stage $Stage -ReasonCode $ReasonCode `
      -Reason 'process output is invalid'
  }
  try {
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    return $encoding.GetString($Bytes)
  }
  catch {
    Throw-BorrowingFailure -Stage $Stage -ReasonCode $ReasonCode `
      -Reason 'process output is invalid'
  }
}
