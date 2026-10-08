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
  throw "Cannot find handoff state-links helper: $stateLinksHelper"
}
. $stateLinksHelper
$cardFormatHelper = Join-Path $PSScriptRoot "check-handoff-zone\card-format.ps1"
if (-not (Test-Path -LiteralPath $cardFormatHelper -PathType Leaf)) {
  throw "Cannot find handoff card-format helper: $cardFormatHelper"
}
. $cardFormatHelper
$fileListHelper = Join-Path $PSScriptRoot "check-handoff-zone\file-list.ps1"
if (-not (Test-Path -LiteralPath $fileListHelper -PathType Leaf)) {
  throw "Cannot find handoff card file-list helper: $fileListHelper"
}
. $fileListHelper
$reportHelper = Join-Path $PSScriptRoot "check-handoff-zone\report.ps1"
if (-not (Test-Path -LiteralPath $reportHelper -PathType Leaf)) {
  throw "Cannot find handoff report helper: $reportHelper"
}
. $reportHelper
$branchHandoffHelper = Join-Path $PSScriptRoot "check-handoff-zone\branch-handoff.ps1"
if (-not (Test-Path -LiteralPath $branchHandoffHelper -PathType Leaf)) {
  throw "Cannot find cross-branch handoff helper: $branchHandoffHelper"
}
. $branchHandoffHelper

if (-not (Test-Path -LiteralPath $pendingDir)) {
  throw "Cannot find pending handoff directory: $pendingDir"
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

Write-Host "🔎 Handoff area health check"
Write-Host "  Pending: $($pending.Count) / $MaxPending"
Write-Host "  Cross-branch pending: $($branchPending.Count) / $MaxPending"
Write-Host "  Cross-branch processed: $($branchProcessed.Count)"
Write-Host "  Cross-branch structure/card-age issues: $($branchIssues.Count)"
Write-Host "  Pending card structure issues: $($pendingFormatIssues.Count)"
Write-Host "  Accepted cards older than $OldDoneDays days: $($oldDone.Count)"
Write-Host "  Accepted cards with pending metadata: $($donePendingMetadata.Count)"
Write-Host "  Accepted cards with pending-receipt action prompts: $($doneReceiveLanguage.Count)"
Write-Host "  状态.md obsolete/broken handoff paths: $($stateBrokenLinks.Count)"
Write-Host "  状态.md top pending-summary drift: $($stateTopIssues.Count)"
Write-Host "  Soft warnings: $($pendingWarnings.Count + $branchWarnings.Count)"

if ($pending.Count -gt 0) {
  Write-Host "  Latest pending handoffs:"
  $pending | Sort-Object @{ Expression = { Get-HandoffSortValue $_ }; Descending = $true }, Name -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host "    - $($_.Name)"
  }
}

Write-HandoffIssueBlock -Items $stateBrokenLinks -Title "🟡 状态.md contains moved or nonexistent handoff paths:" -Limit 20 -Format { param($item) "    L$($item.Line): $($item.From) -> $($item.To)" }
Write-HandoffIssueBlock -Items $stateTopIssues -Title "🟡 The top of 状态.md is not synchronized with the latest pending card:" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $pendingFormatIssues -Title "🟡 Pending handoff cards have incomplete structure:" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $pendingWarnings -Title "🟡 Pending handoff card soft warnings:" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $branchIssues -Title "🟡 Cross-branch handoff area needs attention:" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $donePendingMetadata -Title "🟡 Accepted handoff card metadata is not synchronized:" -Format { param($item) "    $($item.File): $($item.Issue)" }
Write-HandoffIssueBlock -Items $doneReceiveLanguage -Title "🟡 Accepted handoff cards still contain pending-receipt action prompts:" -Limit 10 -Format { param($item) "    $($item.File): $($item.Issue)" }

if ($pending.Count -gt $MaxPending -or $pendingFormatIssues.Count -gt 0 -or $oldDone.Count -gt 0 -or $donePendingMetadata.Count -gt 0 -or $doneReceiveLanguage.Count -gt 0 -or $stateBrokenLinks.Count -gt 0 -or $stateTopIssues.Count -gt 0 -or $branchIssues.Count -gt 0) {
  Write-Host "🟡 Handoff area needs cleanup: manually archive completed cards first, then retain genuinely pending cards"
  exit 5
}

Write-Host "✅ Handoff area is healthy"
exit 0
