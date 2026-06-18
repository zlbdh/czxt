param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
  param([string]$Message)
  $script:failures.Add($Message)
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

$osEntryPath = Join-Path $Root "操作系统\00_总入口.md"
if (Test-Path -LiteralPath $osEntryPath) {
  $text = Get-Content -LiteralPath $osEntryPath -Raw -Encoding UTF8
  $line = [regex]::Match($text, '(?m)^\| \[`06_工具治理/`\].*$')
  if ($line.Success -and ($line.Value -match 'hooks') -and ($line.Value -match '体检')) {
    Write-Host "  ✅ 00_总入口 06_工具治理 摘要包含 hooks + 体检"
  } else {
    Add-Failure "00_总入口 06_工具治理 摘要未覆盖 hooks + 体检"
  }
}

$toolsGovReadmePath = Join-Path $Root "操作系统\06_工具治理\README.md"
if (Test-Path -LiteralPath $toolsGovReadmePath) {
  $text = Get-Content -LiteralPath $toolsGovReadmePath -Raw -Encoding UTF8
  if ($text -match '按\s*7\s*检查项核查|7\s*检查项\s*\+\s*报告模板') {
    Add-Failure "06_工具治理 README 仍把旧 7 项手动体检当当前入口"
  } else {
    Write-Host "  ✅ 06_工具治理 README 未回退到旧 7 项手动体检口径"
  }
  if ($text -match '能力资产/tools/hooks/tests/hooks-smoke\.ps1') {
    Write-Host "  ✅ 06_工具治理 README hooks-smoke 路径完整"
  } else {
    Add-Failure "06_工具治理 README 未写明 hooks-smoke 完整路径"
  }
  if ($text -match 'check-plan\.ps1' -and $text -match 'check-plan-assert\.ps1') {
    Write-Host "  ✅ 06_工具治理 README 维护 SOP 包含 check-plan 表驱动入口"
  } else {
    Add-Failure "06_工具治理 README 维护 SOP 未提醒同步 check-plan/check-plan-assert"
  }
}

$frameworkHealthPath = Join-Path $Root "操作系统\06_工具治理\framework体检.md"
if (Test-Path -LiteralPath $frameworkHealthPath) {
  $text = Get-Content -LiteralPath $frameworkHealthPath -Raw -Encoding UTF8
  if (($text -match '7\s*项检查清单|手动跑\s*/\s*不是\s*cron|按上\s*7\s*检查项') -and ($text -notmatch '历史指针')) {
    Add-Failure "framework体检.md 仍是旧体检正文且未标历史指针"
  } else {
    Write-Host "  ✅ framework体检.md 已是历史指针或未含旧当前口径"
  }
  if ($text -match 'decision-checkpoint' -and $text -match 'Q1-Q7') {
    Write-Host "  ✅ framework体检.md 写明脚本体检后仍需 Q1-Q7 自检"
  } else {
    Add-Failure "framework体检.md 未写明 check-operating-system 后仍需 decision-checkpoint Q1-Q7"
  }
}

$visionEntryPath = Join-Path $Root "操作系统\06_工具治理\操作系统终态愿景-v4.0-2026-05-21.md"
if (Test-Path -LiteralPath $visionEntryPath) {
  $text = Get-Content -LiteralPath $visionEntryPath -Raw -Encoding UTF8
  if ($text -match 'decision-checkpoint\.md') {
    Write-Host "  ✅ 06_工具治理 v4 历史愿景入口包含 Q1-Q7 当前真源"
  } else {
    Add-Failure "06_工具治理 v4 历史愿景入口缺 decision-checkpoint 当前真源"
  }
}

$memoryIndexPath = Join-Path $Root "操作系统\05_记忆\INDEX.md"
if (Test-Path -LiteralPath $memoryIndexPath) {
  $text = Get-Content -LiteralPath $memoryIndexPath -Raw -Encoding UTF8
  if ($text -match 'Claude\s*起手必读') {
    Add-Failure "05_记忆 INDEX 仍使用 Claude 起手必读单工具主语"
  } else {
    Write-Host "  ✅ 05_记忆 INDEX 已使用多运行时/新会话中性入口口径"
  }
}

$memoryReflectionPath = Join-Path $Root "操作系统\05_记忆\行为反思.md"
if (Test-Path -LiteralPath $memoryReflectionPath) {
  $text = Get-Content -LiteralPath $memoryReflectionPath -Raw -Encoding UTF8
  if ($text -match 'Claude\s*起手必读|Cowork\s*↔\s*Codex\s*↔\s*Claude Code\s*三角协作') {
    Add-Failure "05_记忆 行为反思仍使用旧单工具/工具三角入口口径"
  } else {
    Write-Host "  ✅ 05_记忆 行为反思未回退到旧单工具/工具三角入口口径"
  }
}

if ($failures.Count -gt 0) { exit 10 }
exit 0
