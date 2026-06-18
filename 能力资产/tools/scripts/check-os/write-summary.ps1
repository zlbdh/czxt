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
    Write-Host "🔴 必查失败（$($Failures.Count) 项）：" -ForegroundColor Red
    foreach ($f in $Failures) { Write-Host "  $f" -ForegroundColor Red }
  }

  Write-Host ""
  Write-Host "✅ P4a 通过：$PassCount 项" -ForegroundColor Green
  if ($Warnings.Count -gt 0) {
    Write-Host "🟡 软警告：$($Warnings.Count) 项（P4b 文件大小 / 子检查 warning，均不阻塞）" -ForegroundColor Yellow
  }
  if ($StateStale) {
    Write-Host "🟡 P4d 状态.md stale：$StaleReason（不阻塞，但建议立刻更新）" -ForegroundColor Yellow
  }

  Write-Host ""
  if ($Failures.Count -gt 0) {
    Write-Host "❌ 体检失败 — 修 🔴 必查项后重跑" -ForegroundColor Red
    return 1
  }
  if ($Warnings.Count -gt 0 -or $StateStale) {
    Write-Host "⚠️  P4a-P4s 通过（含警告 / stale — 进 RETRO 议题）" -ForegroundColor Yellow
  } else {
    Write-Host "🎉 P4a-P4s 全过 — framework 完全健康（含 PM 轨迹 + ADR-032 v2 列表一致性 + 版本/Sprint/ADR/RETRO/PROP 治理计数/工作流旧口径/协作旧口径/分支策略/skills命令/PM工作区入口/Markdown 链接/锚点/能力资产剩余区/治理语义锚点/hooks 配置与运行态/模板纯净度）" -ForegroundColor Green
  }
  Write-Host "ℹ️  P4e mount 缓存陷阱提醒已输出（议题 D，不阻塞）" -ForegroundColor Gray
  Write-Host ""
  Write-Host "下一步：若出现 🔴 必查失败先修；仅有 🟡 警告则进入 RETRO backlog 或下一棒交接。" -ForegroundColor Gray
  Write-Host ""
  return 0
}
