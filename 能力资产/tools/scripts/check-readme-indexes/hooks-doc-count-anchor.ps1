param([string]$Root)

$ErrorActionPreference = "Stop"
$ok = $true

function Test-HookDocCount {
  param(
    [string]$Text,
    [string]$Label,
    [string]$Pattern,
    [int]$Truth
  )
  if ($Truth -lt 0) { return }
  $m = [regex]::Match($Text, $Pattern)
  if (-not $m.Success) { return }
  $claimed = [int]$m.Groups[1].Value
  if ($claimed -eq $Truth) {
    Write-Host "  ✅ $Label：$claimed = 真实 $Truth"
  } else {
    Write-Host "  🔴 $Label 漂移：声称 $claimed vs 真实 $Truth" -ForegroundColor Red
    $script:ok = $false
  }
}

function Assert-HookDocCount {
  param(
    [string]$Text,
    [string]$Label,
    [string]$Pattern,
    [int]$Truth
  )
  $m = [regex]::Match($Text, $Pattern)
  if (-not $m.Success) {
    Write-Host "  🔴 $Label 缺少计数锚点" -ForegroundColor Red
    $script:ok = $false
    return
  }
  $claimed = [int]$m.Groups[1].Value
  if ($claimed -eq $Truth) {
    Write-Host "  ✅ $Label：$claimed = 真实 $Truth"
  } else {
    Write-Host "  🔴 $Label 漂移：声称 $claimed vs 真实 $Truth" -ForegroundColor Red
    $script:ok = $false
  }
}

$manifestN = -1
$codexN = -1
$claudeN = -1
$codexHookNames = @()

try {
  $manifest = Get-Content -LiteralPath (Join-Path $Root "能力资产\tools\hooks\manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $manifestN = @($manifest.hooks).Count
} catch {}

try {
  $codexHooks = Get-Content -LiteralPath (Join-Path $Root ".codex\hooks.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $codexHookNames = @($codexHooks.hooks.PSObject.Properties.Name)
  $codexN = @($codexHooks.hooks.PSObject.Properties).Count
} catch {}

try {
  $claudeHooks = Get-Content -LiteralPath (Join-Path $Root ".claude\settings.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $claudeN = @($claudeHooks.hooks.PSObject.Properties).Count
} catch {}

$hooksReadmePath = Join-Path $Root "能力资产\tools\hooks\README.md"
if (Test-Path -LiteralPath $hooksReadmePath) {
  $hrText = Get-Content -LiteralPath $hooksReadmePath -Raw -Encoding UTF8
  Test-HookDocCount $hrText "hooks README 当前 hooks 数(vs manifest)" '当前 hooks（(\d+) 个' $manifestN
  Test-HookDocCount $hrText "hooks README Codex 事件数(vs .codex/hooks.json)" 'Codex 原生 hooks（(\d+) 个事件' $codexN
  Test-HookDocCount $hrText "hooks README Claude 事件数(vs .claude/settings.json)" 'Claude Code 原生 hooks（(\d+) 个事件' $claudeN
  $hookTablePattern = '\|\s*类别\s*\|\s*Hook\s*\|\s*\r?\n\|\s*---\s*\|\s*---\s*\|\s*\r?\n\|\s*索引/状态\s*\|[^\r\n]+\|\s*\r?\n\|\s*安装/健康\s*\|[^\r\n]+\|\s*\r?\n\|\s*发布/沉淀\s*\|[^\r\n]+\|'
  if ($hrText -notmatch $hookTablePattern) {
    Write-Host "  🔴 hooks README 当前 hooks 分类表不连续或缺少三类锚点" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "  ✅ hooks README 当前 hooks 分类表连续"
  }
}

if (($codexHookNames -contains "PostToolUse") -and ($codexHookNames -contains "PreToolUse")) {
  $designText = ""
  $designOnly = ""
  foreach ($path in @(
    "操作系统\06_工具治理\hooks-设计.md",
    "操作系统\06_工具治理\hooks-事件矩阵.md",
    "操作系统\06_工具治理\hooks-事件矩阵-附录.md"
  )) {
    $fullPath = Join-Path $Root $path
    if (Test-Path -LiteralPath $fullPath) {
      $chunk = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
      if ($path -eq "操作系统\06_工具治理\hooks-设计.md") { $designOnly = $chunk }
      $designText += "`n" + $chunk
    }
  }
  if ($designOnly) {
    Assert-HookDocCount $designOnly "hooks 设计项目 hooks 数(vs manifest)" '现有\s+(\d+)\s+个项目 hook' $manifestN
    Assert-HookDocCount $designOnly "hooks 设计 Codex 事件数(vs .codex/hooks.json)" 'Codex 原生入口接\s+(\d+)\s+个事件' $codexN
    Assert-HookDocCount $designOnly "hooks 设计 Claude 事件数(vs .claude/settings.json)" 'Claude Code 原生入口接\s+(\d+)\s+个事件' $claudeN
  }
  if ($designText -match 'Codex\s*(?:侧)?\s*(?:PostToolUse/PreToolUse|PostToolUse\s*\+\s*PreToolUse)[^。\r\n]*后续可镜像') {
    Write-Host "  🔴 hooks 设计文档语义漂移：Codex PostToolUse/PreToolUse 已注册，但仍写后续可镜像" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "  ✅ hooks 设计语义：Codex PostToolUse/PreToolUse 已注册且主文/附录无后续可镜像旧句"
  }
}

if (-not $ok) { exit 10 }
exit 0
