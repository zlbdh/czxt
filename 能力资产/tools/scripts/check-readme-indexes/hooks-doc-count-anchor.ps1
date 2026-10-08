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
  if (-not $m.Success) {
    Write-Host "  🔴 $Label is missing its count anchor" -ForegroundColor Red
    $script:ok = $false
    return
  }
  $claimed = [int]$m.Groups[1].Value
  if ($claimed -eq $Truth) {
    Write-Host "  ✅ ${Label}: $claimed = actual $Truth"
  } else {
    Write-Host "  🔴 $Label drift: claimed $claimed vs actual $Truth" -ForegroundColor Red
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
    Write-Host "  🔴 $Label is missing its count anchor" -ForegroundColor Red
    $script:ok = $false
    return
  }
  $claimed = [int]$m.Groups[1].Value
  if ($claimed -eq $Truth) {
    Write-Host "  ✅ ${Label}: $claimed = actual $Truth"
  } else {
    Write-Host "  🔴 $Label drift: claimed $claimed vs actual $Truth" -ForegroundColor Red
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
  Test-HookDocCount $hrText "hooks README project hook count (vs manifest)" '(?:当前 hooks（|Current hooks \()(\d+)(?: 个| total;)' $manifestN
  Test-HookDocCount $hrText "hooks README Codex event count (vs .codex/hooks.json)" '(?:Codex 原生 hooks（|Native Codex hooks \()(\d+)(?: 个事件| events\))' $codexN
  Test-HookDocCount $hrText "hooks README Claude event count (vs .claude/settings.json)" '(?:Claude Code 原生 hooks（|Native Claude Code hooks \()(\d+)(?: 个事件| events\))' $claudeN
  $hookTablePattern = '\|\s*(?:类别|Category)\s*\|\s*Hook\s*\|\s*\r?\n\|\s*---\s*\|\s*---\s*\|\s*\r?\n\|\s*(?:索引/状态|Index/state)\s*\|[^\r\n]+\|\s*\r?\n\|\s*(?:安装/健康|Installation/health)\s*\|[^\r\n]+\|\s*\r?\n\|\s*(?:发布/沉淀|Release/knowledge retention)\s*\|[^\r\n]+\|'
  if ($hrText -notmatch $hookTablePattern) {
    Write-Host "  🔴 hooks README category table is not contiguous or is missing one of three categories" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "  ✅ hooks README category table is contiguous"
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
    Assert-HookDocCount $designOnly "hooks design project hook count (vs manifest)" '(?:现有\s+|authoritative for the\s+)(\d+)(?:\s+个项目 hook|\s+project hooks)' $manifestN
    Assert-HookDocCount $designOnly "hooks design Codex event count (vs .codex/hooks.json)" '(?:Codex 原生入口接\s+|Native Codex connects\s+)(\d+)(?:\s+个事件|\s+events)' $codexN
    Assert-HookDocCount $designOnly "hooks design Claude event count (vs .claude/settings.json)" '(?:Claude Code 原生入口接\s+|native Claude Code connects\s+)(\d+)(?:\s+个事件|\s+events)' $claudeN
  }
  if ($designText -match 'Codex\s*(?:侧)?\s*(?:PostToolUse/PreToolUse|PostToolUse\s*\+\s*PreToolUse)[^。\r\n]*(?:后续可镜像|can be mirrored later)') {
    Write-Host "  🔴 hooks design drift: Codex PostToolUse/PreToolUse are registered but described as future mirrors" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "  ✅ hooks design: registered Codex PostToolUse/PreToolUse have no obsolete future-mirroring claim"
  }
}

if (-not $ok) { exit 10 }
exit 0
