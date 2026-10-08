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
  $line = [regex]::Match($text, '(?m)^\| (?:\[`06_工具治理/`\]|\[Tool governance\]\(06_工具治理/\)).*$')
  if ($line.Success -and ($line.Value -match 'hooks') -and ($line.Value -match '体检|health checks')) {
    Write-Host "  ✅ Main-entry tool-governance summary includes hooks and health checks"
  } else {
    Add-Failure "Main-entry tool-governance summary omits hooks or health checks"
  }
}

$toolsGovReadmePath = Join-Path $Root "操作系统\06_工具治理\README.md"
if (Test-Path -LiteralPath $toolsGovReadmePath) {
  $text = Get-Content -LiteralPath $toolsGovReadmePath -Raw -Encoding UTF8
  if ($text -match '按\s*7\s*检查项核查|7\s*检查项\s*\+\s*报告模板|check against\s*7\s*items|7\s*check items\s*\+\s*report template') {
    Add-Failure "Tool-governance README still treats the obsolete seven-item manual health check as current"
  } else {
    Write-Host "  ✅ Tool-governance README avoids obsolete seven-item manual health-check guidance"
  }
  if ($text -match '能力资产/tools/hooks/tests/hooks-smoke\.ps1') {
    Write-Host "  ✅ Tool-governance README includes the full hooks-smoke path"
  } else {
    Add-Failure "Tool-governance README omits the full hooks-smoke path"
  }
  if ($text -match 'check-plan\.ps1' -and $text -match 'check-plan-assert\.ps1') {
    Write-Host "  ✅ Tool-governance README maintenance SOP includes the table-driven check-plan entry"
  } else {
    Add-Failure "Tool-governance README maintenance SOP omits the check-plan/check-plan-assert synchronization reminder"
  }
}

$frameworkHealthPath = Join-Path $Root "操作系统\06_工具治理\framework体检.md"
if (Test-Path -LiteralPath $frameworkHealthPath) {
  $text = Get-Content -LiteralPath $frameworkHealthPath -Raw -Encoding UTF8
  if (($text -match '7\s*项检查清单|手动跑\s*/\s*不是\s*cron|按上\s*7\s*检查项|7-item checklist|manual run\s*/\s*not cron|follow the above\s*7\s*checks') -and ($text -notmatch '历史指针|historical pointer')) {
    Add-Failure "Framework health document retains obsolete instructions without a historical-pointer label"
  } else {
    Write-Host "  ✅ Framework health document is a historical pointer or contains no obsolete current guidance"
  }
  if ($text -match 'decision-checkpoint' -and $text -match 'Q1-Q7') {
    Write-Host "  ✅ Framework health document requires Q1-Q7 self-checks after scripted checks"
  } else {
    Add-Failure "Framework health document omits decision-checkpoint Q1-Q7 after check-operating-system"
  }
}

$visionEntryPath = Join-Path $Root "操作系统\06_工具治理\操作系统终态愿景-v4.0-2026-05-21.md"
if (Test-Path -LiteralPath $visionEntryPath) {
  $text = Get-Content -LiteralPath $visionEntryPath -Raw -Encoding UTF8
  if ($text -match 'decision-checkpoint\.md') {
    Write-Host "  ✅ Tool-governance v4 historical vision entry includes the current Q1-Q7 authority"
  } else {
    Add-Failure "Tool-governance v4 historical vision entry lacks the current decision-checkpoint authority"
  }
}

$memoryIndexPath = Join-Path $Root "操作系统\05_记忆\INDEX.md"
if (Test-Path -LiteralPath $memoryIndexPath) {
  $text = Get-Content -LiteralPath $memoryIndexPath -Raw -Encoding UTF8
  if ($text -match 'Claude\s*起手必读|Claude\s*startup required reading') {
    Add-Failure "Memory INDEX still uses Claude-only startup wording"
  } else {
    Write-Host "  ✅ Memory INDEX uses neutral multi-runtime and new-session entry wording"
  }
}

$memoryReflectionPath = Join-Path $Root "操作系统\05_记忆\行为反思.md"
if (Test-Path -LiteralPath $memoryReflectionPath) {
  $text = Get-Content -LiteralPath $memoryReflectionPath -Raw -Encoding UTF8
  if ($text -match 'Claude\s*起手必读|Claude\s*startup required reading|Cowork\s*↔\s*Codex\s*↔\s*Claude Code\s*三角协作|Cowork\s*↔\s*Codex\s*↔\s*Claude Code\s*triangle collaboration') {
    Add-Failure "Behavioral reflections still use obsolete single-tool or tool-triangle entry wording"
  } else {
    Write-Host "  ✅ Behavioral reflections avoid obsolete single-tool and tool-triangle entry wording"
  }
}

if ($failures.Count -gt 0) { exit 10 }
exit 0
