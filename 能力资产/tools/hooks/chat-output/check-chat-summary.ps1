param(
  [string]$TextPath = "",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($TextPath)) {
  Write-Host "🟡 chat-output hook ready: no TextPath supplied"
  Write-Host "   用法：powershell -File 能力资产/tools/hooks/chat-output/check-chat-summary.ps1 -TextPath <chat-output.txt>"
  exit 0
}

if (-not (Test-Path -LiteralPath $TextPath)) {
  throw "找不到 chat output 文件：$TextPath"
}

$text = Get-Content -LiteralPath $TextPath -Raw -Encoding UTF8
$required = @(
  @{ Marker = "①"; Label = "时间" },
  @{ Marker = "②"; Label = "文件变更" },
  @{ Marker = "③"; Label = "测试" },
  @{ Marker = "④"; Label = "你要做" },
  @{ Marker = "⑤"; Label = "警戒" },
  @{ Marker = "⑥"; Label = "详情" },
  @{ Marker = "⑦"; Label = "PM\s*切换轨迹" }
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
  Write-Host "🔴 chat-output 缺少交接卡段：$($missing -join ', ')" -ForegroundColor Red
  exit 10
}

$previous = -1
foreach ($spec in $required) {
  $marker = $spec.Marker
  $candidate = $positions[$marker] | Where-Object { $_.Index -gt $previous } | Select-Object -First 1
  if (-not $candidate) {
    Write-Host "🔴 chat-output 交接卡段顺序异常：$marker" -ForegroundColor Red
    exit 12
  }
  $positions[$marker] = $candidate.Index
  $previous = $candidate.Index
}

if ($text -notmatch 'PM 切换轨迹') {
  Write-Host "🔴 chat-output 缺少 PM 切换轨迹说明" -ForegroundColor Red
  exit 11
}

$pmText = $text.Substring([int]$positions["⑦"])
if ($pmText -match '(?m)^\s*⑦\s*PM\s*切换轨迹.*?N=0\s*/\s*本 session 无切帽子') {
  Write-Host "✅ chat-output 交接卡格式通过（N=0，无切帽子）"
  exit 0
}

$detailStart = [int]$positions["⑥"]
$detailLength = [int]$positions["⑦"] - $detailStart
$detailText = $text.Substring($detailStart, $detailLength)
$detailMatch = [regex]::Match($detailText, '(?m)^\s*⑥\s*详情[：:]\s*读\s+`?([^`\r\n]+\.md)`?')
if (-not $detailMatch.Success) {
  Write-Host "🔴 chat-output ⑥ 详情缺少可读交接卡路径" -ForegroundColor Red
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
    Write-Host "🔴 chat-output ⑥ 详情必须指向交接区/待接手/ 下的交接卡；接收归档且待接手为空时可指向交接区/已接手/：$detailRel" -ForegroundColor Red
    exit 13
  }
  $detailPath = Join-Path $Root $detailNorm
}
if (-not (Test-Path -LiteralPath $detailPath)) {
  Write-Host "🔴 chat-output ⑥ 详情路径不存在：$detailRel" -ForegroundColor Red
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
    Write-Host "🔴 chat-output ⑥ 详情必须是交接区/待接手/ 下的交接卡；仅接收归档且待接手为空时可指向 accepted 已接手卡：$detailRel" -ForegroundColor Red
    exit 13
  }
}

$lineMatch = [regex]::Match($pmText, '(?m)^\s*⑦\s*PM\s*切换轨迹.*?状态\.md\s+L(\d+)')
if ($lineMatch.Success) {
  $statePath = Join-Path $Root "状态.md"
  if (-not (Test-Path -LiteralPath $statePath)) {
    Write-Host "🔴 chat-output 找不到状态.md" -ForegroundColor Red
    exit 15
  }
  $lineNumber = [int]$lineMatch.Groups[1].Value
  $stateLines = Get-Content -LiteralPath $statePath -Encoding UTF8
  $stateLineCount = $stateLines.Count
  if ($lineNumber -lt 1 -or $lineNumber -gt $stateLineCount) {
    Write-Host "🔴 chat-output ⑦ PM 切换轨迹行号不存在：状态.md L$lineNumber" -ForegroundColor Red
    exit 16
  }
  $stateLine = $stateLines[$lineNumber - 1]
  if ($stateLine -notmatch '^\|\s*\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s*\|' -or $stateLine -notmatch 'PM') {
    Write-Host "🔴 chat-output ⑦ 状态.md L$lineNumber 不是 PM 切换轨迹表行" -ForegroundColor Red
    exit 18
  }
} elseif ($pmText -notmatch '(?m)^\s*⑦\s*PM\s*切换轨迹.*?N=0\s*/\s*本 session 无切帽子') {
  Write-Host "🔴 chat-output ⑦ 缺少状态.md L<line> 或 N=0 无切帽子说明" -ForegroundColor Red
  exit 17
}

Write-Host "✅ chat-output 交接卡格式通过"
exit 0
