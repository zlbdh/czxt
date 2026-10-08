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
if ($text -notmatch "$manifestCount\s*(?:个项目 hook|project hooks)") { Write-Host "  🔴 hooks event matrix is missing the project hook count anchor $manifestCount" -ForegroundColor Red; $ok = $false }
if ($text -notmatch "(?:Codex 原生：|Native Codex: )$codexCount\s*(?:个 lifecycle|lifecycle events)") { Write-Host "  🔴 hooks event matrix is missing the Codex count anchor $codexCount" -ForegroundColor Red; $ok = $false }
if ($text -notmatch "(?:Claude Code 原生：|Native Claude Code: )$claudeCount\s*(?:个 lifecycle|lifecycle events)") { Write-Host "  🔴 hooks event matrix is missing the Claude count anchor $claudeCount" -ForegroundColor Red; $ok = $false }
if ($text -notmatch 'PostToolUse`?\s*(?:（|\()Edit\\\|Write\\\|apply_patch(?:）|\))' -or $text -notmatch 'PreToolUse`?\s*(?:（|\()Edit\\\|Write\\\|apply_patch(?:）|\))') { Write-Host "  🔴 hooks event matrix is missing a Codex apply_patch matcher" -ForegroundColor Red; $ok = $false }
if ($text -notmatch 'PostToolUse`?\s*(?:（|\()Edit\\\|Write(?:）|\))' -or $text -notmatch 'PreToolUse`?\s*(?:（|\()Edit\\\|Write(?:）|\))') { Write-Host "  🔴 hooks event matrix is missing a Claude Edit|Write matcher" -ForegroundColor Red; $ok = $false }
if ($allText -match '(?:后续可镜像|can be mirrored later)') { Write-Host "  🔴 hooks event matrix still contains an obsolete future-mirroring claim" -ForegroundColor Red; $ok = $false }
if ($appendixText -match '(?:外部改盘同步仍由 Windows watcher / scheduled 兜底|Windows watcher / scheduled still provide general external disk synchronization)') { Write-Host "  🔴 hooks appendix still describes FileChanged fallback as general external disk synchronization" -ForegroundColor Red; $ok = $false }
if ($appendixText -and ($appendixText -notmatch '(?:仅 ADR README.*Windows watcher|Windows watcher synchronizes only the ADR README)' -or $appendixText -notmatch 'daily scheduled.*(?:每日健康检查|performs health checks only)')) { Write-Host "  🔴 hooks appendix does not limit FileChanged fallback to the ADR watcher and daily health checks" -ForegroundColor Red; $ok = $false }
if ($text -notmatch 'Stop.*(?:阻断|Block)') { Write-Host "  🔴 hooks event matrix does not describe Stop blocking behavior" -ForegroundColor Red; $ok = $false }

if (-not $ok) { exit 10 }
Write-Host "  ✅ hooks event matrix counts and matcher anchors are aligned"
exit 0
