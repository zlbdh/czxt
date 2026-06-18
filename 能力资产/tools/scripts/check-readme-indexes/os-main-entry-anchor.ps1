param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
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

$moduleMatches = @([regex]::Matches($entry, '(?m)^\| \[`(?<dir>\d{2}_[^`]+/)`\]\((?<target>[^)]+)\) \|'))
if ($moduleMatches.Count -ne $expectedModules.Count) {
  Add-Failure "00_总入口 8 个编号模块数量异常：$($moduleMatches.Count)"
} else {
  for ($i = 0; $i -lt $expectedModules.Count; $i++) {
    $dir = $moduleMatches[$i].Groups["dir"].Value
    $target = $moduleMatches[$i].Groups["target"].Value
    if ($dir -ne $expectedModules[$i] -or $target -ne $expectedModules[$i]) {
      Add-Failure "00_总入口 8 模块顺序/链接异常：第 $($i + 1) 项为 $dir -> $target"
    }
  }
}

$expectedStart = @(
  '\[`?AGENTS\.md`?\]\(\.\./AGENTS\.md\)',
  '\[`?状态\.md`?\]\(\.\./状态\.md\)',
  '\[`?05_记忆/INDEX\.md`?\]\(05_记忆/INDEX\.md\)',
  '\[`?01_架构/角色边界\.md`?\]\(01_架构/角色边界\.md\)',
  '\[`?07_完整工作流/decision-checkpoint\.md`?\]\(07_完整工作流/decision-checkpoint\.md\)',
  '`交接区/待接手/`',
  '`../能力资产/skills/项目体检\.md`',
  '`状态\.md` 末尾 PM 轨迹 5 行'
)

$startMatches = @([regex]::Matches($entry, '(?m)^(?<num>[1-8])\. ✅ (?<body>.+)$'))
if ($startMatches.Count -ne $expectedStart.Count) {
  Add-Failure "00_总入口 起手必读顺序数量异常：$($startMatches.Count)"
} else {
  for ($i = 0; $i -lt $expectedStart.Count; $i++) {
    $num = [int]$startMatches[$i].Groups["num"].Value
    $body = $startMatches[$i].Groups["body"].Value
    if ($num -ne ($i + 1) -or $body -notmatch $expectedStart[$i]) {
      Add-Failure "00_总入口 起手第 $($i + 1) 项漂移：$body"
    }
  }
}

if ($entry -notmatch 'AGENTS\.md 是\*\*5 秒指引\*\*' -or $entry -notmatch '本文件是\*\*深入目录导航\*\*') {
  Add-Failure "00_总入口 未明确 AGENTS 5 秒指引 / 本文件深入目录导航分工"
}

if ($agents -notmatch '完整规范在 `操作系统/00_总入口\.md`' -or $agents -notmatch '读 `操作系统/00_总入口\.md`') {
  Add-Failure "AGENTS.md 未保持指向 00_总入口 的互补起手关系"
}

if ($entry -notmatch '除项目 PM 主会话外，每个 PM 的实际工作默认实例化为真实 agent') {
  Add-Failure "00_总入口 子 agent 调度速记缺默认真实 agent 机制"
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 00_总入口 起手链路锚点对齐" -ForegroundColor Green
exit 0
