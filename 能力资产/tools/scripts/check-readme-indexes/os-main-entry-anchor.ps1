param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

$entry = Get-Text "操作系统\00_总入口.md"
$agents = Get-Text "AGENTS.md"

$expectedModules = @(
  "00_变更记录/",
  "01_架构/",
  "02_智能体/",
  "03_交接/",
  "04_台账/",
  "05_记忆/",
  "06_工具治理/",
  "07_完整工作流/"
)

$englishModuleLabels = @(
  "Change records", "Architecture", "Agents", "Handoffs",
  "Ledgers", "Memory", "Tool governance", "Complete workflows"
)
$moduleMatches = @([regex]::Matches($entry, '(?m)^\| \[(?<label>[^\]]+)\]\((?<target>\d{2}_[^)]*/)\) \|'))
if ($moduleMatches.Count -ne $expectedModules.Count) {
  Add-Failure "Main entry must contain eight numbered modules; found $($moduleMatches.Count)"
} else {
  for ($i = 0; $i -lt $expectedModules.Count; $i++) {
    $label = $moduleMatches[$i].Groups["label"].Value.Trim([char]96)
    $target = $moduleMatches[$i].Groups["target"].Value
    if (($label -ne $expectedModules[$i] -and $label -ne $englishModuleLabels[$i]) -or $target -ne $expectedModules[$i]) {
      Add-Failure "Main-entry module order/link mismatch at item $($i + 1): $label -> $target"
    }
  }
}

$expectedStart = @(
  '\[`?AGENTS\.md`?\]\(\.\./AGENTS\.md\)',
  '\[(?:`?状态\.md`?|Status)\]\(\.\./状态\.md\)',
  '\[(?:`?05_记忆/INDEX\.md`?|Memory index)\]\(05_记忆/INDEX\.md\)',
  '\[(?:`?01_架构/角色边界\.md`?|Role boundaries)\]\(01_架构/角色边界\.md\)',
  '\[(?:`?07_完整工作流/decision-checkpoint\.md`?|Decision checkpoint)\]\(07_完整工作流/decision-checkpoint\.md\)',
  '`交接区/待接手/`',
  '(?:`../能力资产/skills/项目体检\.md`|\[Project health check\]\(\.\./能力资产/skills/项目体检\.md\))',
  '(?:`状态\.md` 末尾 PM 轨迹 5 行|Last five PM transition rows in `状态\.md`)'
)

$startMatches = @([regex]::Matches($entry, '(?m)^(?<num>[1-8])\. ✅ (?<body>.+)$'))
if ($startMatches.Count -ne $expectedStart.Count) {
  Add-Failure "Unexpected main-entry required-reading count: $($startMatches.Count)"
} else {
  for ($i = 0; $i -lt $expectedStart.Count; $i++) {
    $num = [int]$startMatches[$i].Groups["num"].Value
    $body = $startMatches[$i].Groups["body"].Value
    if ($num -ne ($i + 1) -or $body -notmatch $expectedStart[$i]) {
      Add-Failure "Main-entry startup item $($i + 1) differs: $body"
    }
  }
}

if ($entry -notmatch '(?:AGENTS\.md 是\*\*5 秒指引\*\*|AGENTS\.md is the \*\*five-second guide\*\*)' -or $entry -notmatch '(?:本文件是\*\*深入目录导航\*\*|This file provides \*\*detailed navigation\*\*)') {
  Add-Failure "Main entry does not distinguish the AGENTS five-second guide from detailed directory navigation"
}

if ($agents -notmatch 'Full rules are in `操作系统/00_总入口\.md`' -or $agents -notmatch 'Read `操作系统/00_总入口\.md`') {
  Add-Failure "AGENTS.md does not preserve its complementary startup link to the main entry"
}

if ($entry -notmatch '(?:除项目 PM 主会话外，每个 PM 的实际工作默认实例化为真实 agent|Except for the Project PM.s main session, each PM.s actual work defaults to a real agent)') {
  Add-Failure "Main-entry scheduling reference lacks the default real-agent mechanism"
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Main-entry startup-chain anchors aligned" -ForegroundColor Green
exit 0
