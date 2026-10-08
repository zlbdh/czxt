function Write-OsHealthSummary {
  param(
    [object]$Failures,
    [object]$Warnings,
    [int]$PassCount,
    [bool]$StateStale = $false,
    [string]$StaleReason = ""
  )

  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
  if ($Failures.Count -gt 0) {
    Write-Host ""
    Write-Host "🔴 Required checks failed ($($Failures.Count) findings):" -ForegroundColor Red
    foreach ($f in $Failures) { Write-Host "  $f" -ForegroundColor Red }
  }

  Write-Host ""
  Write-Host "✅ P4a passed: $PassCount checks" -ForegroundColor Green
  if ($Warnings.Count -gt 0) {
    Write-Host "🟡 Advisory warnings: $($Warnings.Count) (P4b file sizes / subcheck warnings; nonblocking)" -ForegroundColor Yellow
  }
  if ($StateStale) {
    Write-Host "🟡 P4d 状态.md stale: $StaleReason (nonblocking; prompt update recommended)" -ForegroundColor Yellow
  }

  Write-Host ""
  if ($Failures.Count -gt 0) {
    Write-Host "❌ Health check failed; fix required 🔴 findings and rerun" -ForegroundColor Red
    return 1
  }
  if ($Warnings.Count -gt 0 -or $StateStale) {
    Write-Host "⚠️  P4a-P4t passed with warnings/staleness; add these to RETRO issues" -ForegroundColor Yellow
  } else {
    Write-Host "🎉 P4a-P4t all passed: framework healthy, including PM traces, ADR-032 v2 list consistency, version/Sprint/ADR/RETRO/PROP counts, workflow/collaboration language, branch policy, skill commands, PM workspace entries, Markdown links/anchors, remaining capability assets, governance semantics, hooks configuration/runtime, template neutrality, and borrowing completion consistency" -ForegroundColor Green
  }
  Write-Host "ℹ️  P4e mount-cache reminder shown (issue D; nonblocking)" -ForegroundColor Gray
  Write-Host ""
  Write-Host "Next: fix required 🔴 failures first; add advisory 🟡 findings to the RETRO backlog or the next handoff." -ForegroundColor Gray
  Write-Host ""
  return 0
}
