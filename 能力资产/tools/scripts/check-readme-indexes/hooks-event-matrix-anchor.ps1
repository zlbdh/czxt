param([string]$Root)

$ErrorActionPreference = "Stop"
$matrix = Join-Path $Root "操作系统\06_工具治理\hooks-事件矩阵.md"
$appendix = Join-Path $Root "操作系统\06_工具治理\hooks-事件矩阵-附录.md"
$manifest = Join-Path $Root "能力资产\tools\hooks\manifest.json"
$codex = Join-Path $Root ".codex\hooks.json"
$claude = Join-Path $Root ".claude\settings.json"
if (-not (Test-Path -LiteralPath $matrix)) { exit 0 }

$text = Get-Content -LiteralPath $matrix -Raw -Encoding UTF8
$allText = $text
$appendixText = ""
if (Test-Path -LiteralPath $appendix) {
  $appendixText = Get-Content -LiteralPath $appendix -Raw -Encoding UTF8
  $allText += "`n" + $appendixText
}

$manifestCount = @((Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json).hooks).Count
$codexJson = Get-Content -LiteralPath $codex -Raw -Encoding UTF8 | ConvertFrom-Json
$codexCount = @($codexJson.hooks.PSObject.Properties).Count
$claudeCount = @((Get-Content -LiteralPath $claude -Raw -Encoding UTF8 | ConvertFrom-Json).hooks.PSObject.Properties).Count

$ok = $true
if ($text -notmatch "$manifestCount\s*个项目 hook") { Write-Host "  🔴 hooks 事件矩阵缺项目 hook 计数锚点 $manifestCount" -ForegroundColor Red; $ok = $false }
if ($text -notmatch "Codex 原生：$codexCount\s*个 lifecycle") { Write-Host "  🔴 hooks 事件矩阵缺 Codex 计数锚点 $codexCount" -ForegroundColor Red; $ok = $false }
if ($text -notmatch "Claude Code 原生：$claudeCount\s*个 lifecycle") { Write-Host "  🔴 hooks 事件矩阵缺 Claude 计数锚点 $claudeCount" -ForegroundColor Red; $ok = $false }
if ($text -notmatch 'PostToolUse`?（Edit\\\|Write\\\|apply_patch）' -or $text -notmatch 'PreToolUse`?（Edit\\\|Write\\\|apply_patch）') { Write-Host "  🔴 hooks 事件矩阵缺 Codex apply_patch matcher" -ForegroundColor Red; $ok = $false }
if ($text -notmatch 'PostToolUse`?（Edit\\\|Write）' -or $text -notmatch 'PreToolUse`?（Edit\\\|Write）') { Write-Host "  🔴 hooks 事件矩阵缺 Claude Edit|Write matcher" -ForegroundColor Red; $ok = $false }
if ($allText -match '后续可镜像') { Write-Host "  🔴 hooks 事件矩阵仍含后续可镜像旧句" -ForegroundColor Red; $ok = $false }
if ($appendixText -match '外部改盘同步仍由 Windows watcher / scheduled 兜底') { Write-Host "  🔴 hooks 附录仍把 FileChanged 兜底说成通用外部改盘同步" -ForegroundColor Red; $ok = $false }
if ($appendixText -and ($appendixText -notmatch '仅 ADR README.*Windows watcher' -or $appendixText -notmatch 'daily scheduled.*每日健康检查')) { Write-Host "  🔴 hooks 附录未写清 FileChanged 只由 ADR watcher / daily health 局部兜底" -ForegroundColor Red; $ok = $false }
if ($text -notmatch 'Stop.*阻断') { Write-Host "  🔴 hooks 事件矩阵未写清 Stop 阻断语义" -ForegroundColor Red; $ok = $false }

if (-not $ok) { exit 10 }
Write-Host "  ✅ hooks 事件矩阵计数与 matcher 锚点对齐"
exit 0
