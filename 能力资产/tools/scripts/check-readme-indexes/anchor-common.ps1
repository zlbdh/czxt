$ErrorActionPreference = "Stop"

function Add-Failure {
  param([string]$Message)
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Get-Text {
  param([string]$Rel)
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "缺少文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Get-Head {
  param(
    [string]$Rel,
    [int]$Lines = 16
  )
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "缺少文件：$Rel"
    return ""
  }
  return (Get-Content -LiteralPath $path -TotalCount $Lines -Encoding UTF8) -join "`n"
}

function Assert-Contains {
  param(
    [string]$Rel,
    [string]$Pattern,
    [string]$Label
  )
  $text = Get-Text $Rel
  if ($text -notmatch $Pattern) {
    Add-Failure "$Label：$Rel 未命中 $Pattern"
  }
}

function Assert-NotContains {
  param(
    [string]$Rel,
    [string]$Pattern,
    [string]$Label
  )
  $text = Get-Text $Rel
  foreach ($match in [regex]::Matches($text, $Pattern)) {
    $line = ($text.Substring(0, $match.Index) -split "`n").Count
    Add-Failure "$Label：$Rel L$line 命中旧口径 $($match.Value)"
  }
}
