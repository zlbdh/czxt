param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Write-Host ""
Write-Host "  ⚠️ Cowork 端 bash wc -c 可能看到 stale 字节数（mount 协议缓存）" -ForegroundColor Yellow
Write-Host "     → 信本 PS1（Windows host 真值）+ Read 工具复核，不信单独 bash" -ForegroundColor Yellow
Write-Host ""
Write-Host "  历史实战（10 次累计）：" -ForegroundColor Gray
Write-Host "    - RETRO-005 卡 2          Health.jsx mount 缓存读到旧字节" -ForegroundColor Gray
Write-Host "    - PM 自纠 #9 / #12        PS1 同步失败 / 警告差异" -ForegroundColor Gray
Write-Host "    - PM 自纠 #23 / #25       F-PREP-1 字节差 -5129B / -2913B" -ForegroundColor Gray
Write-Host "    - PM 自纠 #26 / #32 / #36 F-BRIEFING-1 / F-DEVIATION-2 -4111B / -2913B 等" -ForegroundColor Gray
Write-Host "    - PROP-018 P1            CHANGELOG 拆分 Read 复核验证写入" -ForegroundColor Gray
Write-Host ""
Write-Host "  Cowork PM 防御规则（议题 D 落地，4 条）：" -ForegroundColor Cyan
Write-Host "    ① Read 工具复核警戒 / 危险文件大小 — 不信 bash wc -c" -ForegroundColor Green
Write-Host "    ② Edit / Write / apply_patch 改 framework 文件后立即 Read 复核 tail 验证写入" -ForegroundColor Green
Write-Host "    ③ git status 不一致时刷新 mount 或重启 Cowork session" -ForegroundColor Green
Write-Host "    ④ P4b 警戒清单字节数：信 PS1（Windows host 真值）不信 Cowork bash" -ForegroundColor Green
Write-Host ""
Write-Host "  议题 D 状态：P0 → PROP-018 P2 落地（2026-05-13）" -ForegroundColor Gray
Write-Host "  后续：PROP-018 P6 收档时与议题 V/X/P 合并升 ADR-022（跨工具同步规范）" -ForegroundColor Gray

exit 0
