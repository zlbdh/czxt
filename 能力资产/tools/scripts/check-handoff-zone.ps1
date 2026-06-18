param(
  [int]$MaxPending = 3,
  [int]$OldDoneDays = 30,
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

if ([string]::IsNullOrWhiteSpace($Root)) {
  $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
} else {
  $root = (Resolve-Path -LiteralPath $Root).Path
}
$pendingDir = Join-Path $root "交接区\待接手"
$doneDir = Join-Path $root "交接区\已接手"
$stateLinksHelper = Join-Path $PSScriptRoot "check-handoff-zone\state-links.ps1"
if (-not (Test-Path -LiteralPath $stateLinksHelper -PathType Leaf)) {
  throw "找不到交接区状态链接 helper：$stateLinksHelper"
}
. $stateLinksHelper
$cardFormatHelper = Join-Path $PSScriptRoot "check-handoff-zone\card-format.ps1"
if (-not (Test-Path -LiteralPath $cardFormatHelper -PathType Leaf)) {
  throw "找不到交接卡格式 helper：$cardFormatHelper"
}
. $cardFormatHelper
$fileListHelper = Join-Path $PSScriptRoot "check-handoff-zone\file-list.ps1"
if (-not (Test-Path -LiteralPath $fileListHelper -PathType Leaf)) {
  throw "找不到交接卡文件清单 helper：$fileListHelper"
}
. $fileListHelper
$reportHelper = Join-Path $PSScriptRoot "check-handoff-zone\report.ps1"
if (-not (Test-Path -LiteralPath $reportHelper -PathType Leaf)) {
  throw "找不到交接区报告 helper：$reportHelper"
}
. $reportHelper
$branchHandoffHelper = Join-Path $PSScriptRoot "check-handoff-zone\branch-handoff.ps1"
if (-not (Test-Path -LiteralPath $branchHandoffHelper -PathType Leaf)) {
  throw "找不到分支间交接 helper：$branchHandoffHelper"
}
. $branchHandoffHelper

if (-not (Test-Path -LiteralPath $pendingDir)) {
  throw "找不到待接手目录：$pendingDir"
}

$pending = @(Get-ChildItem -LiteralPath $pendingDir -File -Filter "*.md" -ErrorAction SilentlyContinue)
$pendingCardIssues = Get-PendingHandoffCardIssues -Pending $pending
$pendingFileIssues = Get-HandoffFileListIssues -Root $root -Pending $pending
$pendingFormatIssues = @($pendingCardIssues.FormatIssues) + @($pendingFileIssues)
$pendingWarnings = @($pendingCardIssues.Warnings)

$oldDone = @()
$donePendingMetadata = @()
$doneReceiveLanguage = @()
if (Test-Path -LiteralPath $doneDir) {
  $threshold = (Get-Date).AddDays(-1 * $OldDoneDays)
  $doneCards = @(Get-ChildItem -LiteralPath $doneDir -File -Filter "*.md" -ErrorAction SilentlyContinue)
  $oldDone = @($doneCards | Where-Object { (Get-HandoffSortValue $_) -lt $threshold })
  $doneIssues = Get-DoneHandoffMetadataIssues -DoneCards $doneCards
  $donePendingMetadata = @($doneIssues.PendingMetadata)
  $doneReceiveLanguage = @($doneIssues.ReceiveLanguage)
}
$stateIssues = Get-HandoffStateIssues -Root $root -Pending $pending
$stateBrokenLinks = @($stateIssues.BrokenLinks)
$stateTopIssues = @($stateIssues.TopIssues)
$branchIssuesResult = Get-BranchHandoffIssues -Root $root -MaxPending $MaxPending -OldPendingDays $OldDoneDays
$branchIssues = @($branchIssuesResult.Issues)
$branchWarnings = @($branchIssuesResult.Warnings)
$branchPending = @($branchIssuesResult.Pending)
$branchProcessed = @($branchIssuesResult.Processed)

Write-Host "🔎 交接区健康检查"
Write-Host "  待接手：$($pending.Count) / $MaxPending"
Write-Host "  分支间待处理：$($branchPending.Count) / $MaxPending"
Write-Host "  分支间已处理：$($branchProcessed.Count)"
Write-Host "  分支间结构/卡龄问题：$($branchIssues.Count)"
Write-Host "  待接手卡结构问题：$($pendingFormatIssues.Count)"
Write-Host "  已接手超 $OldDoneDays 天：$($oldDone.Count)"
Write-Host "  已接手 pending metadata：$($donePendingMetadata.Count)"
Write-Host "  已接手待接收动作提示：$($doneReceiveLanguage.Count)"
Write-Host "  状态.md 交接区旧路径/断链：$($stateBrokenLinks.Count)"
Write-Host "  状态.md 顶部待接手摘要漂移：$($stateTopIssues.Count)"
Write-Host "  软提示：$($pendingWarnings.Count + $branchWarnings.Count)"

if ($pending.Count -gt 0) {
  Write-Host "  最新待接手："
  $pending | Sort-Object @{ Expression = { Get-HandoffSortValue $_ }; Descending = $true }, Name -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host "    - $($_.Name)"
  }
}

Write-HandoffIssueBlock -Items $stateBrokenLinks -Title "🟡 状态.md 存在已移动或不存在的交接区路径：" -Limit 20 -Format { param($item) "    L$($item.Line): $($item.From) -> $($item.To)" }
Write-HandoffIssueBlock -Items $stateTopIssues -Title "🟡 状态.md 顶部未同步最新待接手卡：" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $pendingFormatIssues -Title "🟡 待接手交接卡结构不完整：" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $pendingWarnings -Title "🟡 待接手交接卡软提示：" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $branchIssues -Title "🟡 分支间交接区需要处理：" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $donePendingMetadata -Title "🟡 已接手交接卡 metadata 未同步：" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $doneReceiveLanguage -Title "🟡 已接手交接卡仍含待接收动作提示：" -Limit 10 -Format { param($item) "    $($item.File): $($item.Issue)" }

if ($pending.Count -gt $MaxPending -or $pendingFormatIssues.Count -gt 0 -or $oldDone.Count -gt 0 -or $donePendingMetadata.Count -gt 0 -or $doneReceiveLanguage.Count -gt 0 -or $stateBrokenLinks.Count -gt 0 -or $stateTopIssues.Count -gt 0 -or $branchIssues.Count -gt 0) {
  Write-Host "🟡 交接区需要整理：先人工归档完成卡，再保留真正待处理卡"
  exit 5
}

Write-Host "✅ 交接区健康"
exit 0
