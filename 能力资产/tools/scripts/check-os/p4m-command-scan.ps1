function Test-P4mRequiredFiles {
  param(
    [string]$Root,
    [string[]]$Files
  )

  $hits = @()
  foreach ($relativePath in $Files) {
    $path = Join-Path $Root $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      $hits += "$relativePath 缺状态推断关键文件，P4m 不能静默跳过"
    }
  }
  return @($hits)
}

function Invoke-P4mPatternChecks {
  param(
    [string]$Root,
    [object[]]$Checks
  )

  $hits = @()
  foreach ($check in $Checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
      $line = ($text.Substring(0, $match.Index) -split "`n").Count
      $hits += "$($check.Path):L$line $($check.Label)"
    }
  }
  return @($hits)
}

function Complete-P4mScan {
  param(
    [object[]]$Hits,
    [string]$FailureTitle,
    [string]$SuccessMessage
  )

  if ($Hits.Count -gt 0) {
    Write-Host "  🔴 $FailureTitle：$($Hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $Hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
  }

  Write-Host "  ✅ $SuccessMessage" -ForegroundColor Green
  exit 0
}
