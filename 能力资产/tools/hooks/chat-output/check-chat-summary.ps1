param(
  [string]$TextPath = "",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($TextPath)) {
  Write-Host "🟡 chat-output hook ready: no TextPath supplied"
  Write-Host "   Usage: powershell -File 能力资产/tools/hooks/chat-output/check-chat-summary.ps1 -TextPath <chat-output.txt>"
  exit 0
}

if (-not (Test-Path -LiteralPath $TextPath)) {
  throw "Chat output file not found: $TextPath"
}

$text = Get-Content -LiteralPath $TextPath -Raw -Encoding UTF8
$required = @(
  @{ Marker = "①"; Label = "(?:时间|Time)" },
  @{ Marker = "②"; Label = "(?:文件变更|File changes)" },
  @{ Marker = "③"; Label = "(?:测试|Tests)" },
  @{ Marker = "④"; Label = "(?:你要做|Your next steps)" },
  @{ Marker = "⑤"; Label = "(?:警戒|Cautions)" },
  @{ Marker = "⑥"; Label = "(?:详情|Details)" },
  @{ Marker = "⑦"; Label = "PM\s*(?:切换轨迹|transitions)" }
)
$missing = @()
$positions = @{}
foreach ($spec in $required) {
  $marker = $spec.Marker
  $pattern = "(?m)^\s*$([regex]::Escape($marker))\s*$($spec.Label)"
  $matches = [regex]::Matches($text, $pattern)
  $positions[$marker] = $matches
  if ($matches.Count -eq 0) {
    $missing += $marker
  }
}

if ($missing.Count -gt 0) {
  Write-Host "🔴 chat-output is missing handoff sections: $($missing -join ', ')" -ForegroundColor Red
  exit 10
}

$previous = -1
foreach ($spec in $required) {
  $marker = $spec.Marker
  $candidate = $positions[$marker] | Where-Object { $_.Index -gt $previous } | Select-Object -First 1
  if (-not $candidate) {
    Write-Host "🔴 chat-output handoff sections are out of order: $marker" -ForegroundColor Red
    exit 12
  }
  $positions[$marker] = $candidate.Index
  $previous = $candidate.Index
}

if ($text -notmatch 'PM (?:切换轨迹|transitions)') {
  Write-Host "🔴 chat-output is missing the PM-transition explanation" -ForegroundColor Red
  exit 11
}

$pmText = $text.Substring([int]$positions["⑦"])
if ($pmText -match '(?m)^\s*⑦\s*PM\s*(?:切换轨迹|transitions).*?N=0\s*/\s*(?:本 session 无切帽子|no role switch this session)') {
  Write-Host "✅ chat-output handoff format passed (N=0, no role switch)"
  exit 0
}

$detailStart = [int]$positions["⑥"]
$detailLength = [int]$positions["⑦"] - $detailStart
$detailText = $text.Substring($detailStart, $detailLength)
$detailMatch = [regex]::Match($detailText, '(?m)^\s*⑥\s*(?:详情|Details)[：:]\s*(?:读|Read)\s+`?([^`\r\n]+\.md)`?')
if (-not $detailMatch.Success) {
  Write-Host "🔴 chat-output section ⑥ is missing a readable handoff-card path" -ForegroundColor Red
  exit 13
}

$detailRel = $detailMatch.Groups[1].Value.Trim()
$detailNorm = $detailRel -replace '/', '\'
if ([System.IO.Path]::IsPathRooted($detailRel)) {
  $detailPath = $detailNorm
} else {
  $isPendingRel = $detailNorm.StartsWith("交接区\待接手\", [System.StringComparison]::OrdinalIgnoreCase)
  $isDoneRel = $detailNorm.StartsWith("交接区\已接手\", [System.StringComparison]::OrdinalIgnoreCase)
  if (-not $isPendingRel -and -not $isDoneRel) {
    Write-Host "🔴 chat-output section ⑥ must point to a card under 交接区/待接手/; acceptance/archive may point under 交接区/已接手/ when pending is empty: $detailRel" -ForegroundColor Red
    exit 13
  }
  $detailPath = Join-Path $Root $detailNorm
}
if (-not (Test-Path -LiteralPath $detailPath)) {
  Write-Host "🔴 chat-output section ⑥ path does not exist: $detailRel" -ForegroundColor Red
  exit 14
}
$pendingRoot = Join-Path $Root "交接区\待接手"
$doneRoot = Join-Path $Root "交接区\已接手"
$resolvedDetail = (Resolve-Path -LiteralPath $detailPath).Path
$resolvedPending = (Resolve-Path -LiteralPath $pendingRoot).Path
$resolvedDone = (Resolve-Path -LiteralPath $doneRoot).Path
$pendingPrefix = $resolvedPending.TrimEnd('\') + '\'
$donePrefix = $resolvedDone.TrimEnd('\') + '\'
$insidePending = ($resolvedDetail -ne $resolvedPending) -and $resolvedDetail.StartsWith($pendingPrefix, [System.StringComparison]::OrdinalIgnoreCase)
$insideDone = ($resolvedDetail -ne $resolvedDone) -and $resolvedDetail.StartsWith($donePrefix, [System.StringComparison]::OrdinalIgnoreCase)
if (-not $insidePending) {
  $allowAcceptedDone = $false
  if ($insideDone) {
    $pendingCount = @(Get-ChildItem -LiteralPath $pendingRoot -File -ErrorAction SilentlyContinue).Count
    $detailContent = Get-Content -LiteralPath $detailPath -Raw -Encoding UTF8
    $hasAcceptedFrontmatter = $detailContent -match '(?m)^status:\s*accepted\s*$'
    $allowAcceptedDone = ($pendingCount -eq 0 -and $hasAcceptedFrontmatter)
  }
  if (-not $allowAcceptedDone) {
    Write-Host "🔴 chat-output section ⑥ must point under 交接区/待接手/; only acceptance/archive with an empty pending directory may point to an accepted card under 交接区/已接手/: $detailRel" -ForegroundColor Red
    exit 13
  }
}

$lineMatch = [regex]::Match($pmText, '(?m)^\s*⑦\s*PM\s*(?:切换轨迹|transitions).*?状态\.md\s+L(\d+)')
if ($lineMatch.Success) {
  $statePath = Join-Path $Root "状态.md"
  if (-not (Test-Path -LiteralPath $statePath)) {
    Write-Host "🔴 chat-output cannot find 状态.md" -ForegroundColor Red
    exit 15
  }
  $lineNumber = [int]$lineMatch.Groups[1].Value
  $stateLines = Get-Content -LiteralPath $statePath -Encoding UTF8
  $stateLineCount = $stateLines.Count
  if ($lineNumber -lt 1 -or $lineNumber -gt $stateLineCount) {
    Write-Host "🔴 chat-output section ⑦ PM-transition line does not exist: 状态.md L$lineNumber" -ForegroundColor Red
    exit 16
  }
  $stateLine = $stateLines[$lineNumber - 1]
  if ($stateLine -notmatch '^\|\s*\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s*\|' -or $stateLine -notmatch 'PM') {
    Write-Host "🔴 chat-output section ⑦ 状态.md L$lineNumber is not a PM-transition table row" -ForegroundColor Red
    exit 18
  }
} elseif ($pmText -notmatch '(?m)^\s*⑦\s*PM\s*(?:切换轨迹|transitions).*?N=0\s*/\s*(?:本 session 无切帽子|no role switch this session)') {
  Write-Host "🔴 chat-output section ⑦ requires 状态.md L<line> or the N=0 no-role-switch explanation" -ForegroundColor Red
  exit 17
}

Write-Host "✅ chat-output handoff format passed"
exit 0
