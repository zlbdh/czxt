param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "Missing anchor-common.ps1" }
. $common

$layerFiles = @(
  "README.md",
  "AGENTS.md",
  "操作系统\00_总入口.md",
  "操作系统\01_架构\README.md",
  "操作系统\01_架构\角色边界.md",
  "操作系统\01_架构\工具载体矩阵.md",
  "操作系统\01_架构\元规则池.md",
  "操作系统\01_架构\元规则池-候选.md",
  "操作系统\01_架构\子agent调度机制.md",
  "操作系统\01_架构\演化哲学.md",
  "操作系统\05_记忆\项目历史指针.md",
  "操作系统\02_智能体\README.md",
  "操作系统\02_智能体\开发PM-实施者.md",
  "操作系统\02_智能体\测试发布PM-闭环者.md",
  "操作系统\02_智能体\沉淀PM-沉淀者.md",
  "操作系统\07_完整工作流\decision-checkpoint-附录.md"
)

foreach ($rel in $layerFiles) {
  Assert-NotContains $rel "主-元-子-子子|子子\s*(PM|2|层)|lead-meta-child-grandchild|grandchild\s*(PM|2|layer)" "Nine-PM four-layer terminology"
}

foreach ($rel in @(
  "AGENTS.md",
  "README.md",
  "操作系统\00_总入口.md",
  "操作系统\01_架构\README.md",
  "操作系统\01_架构\工具载体矩阵.md",
  "操作系统\02_智能体\README.md"
)) {
  if ($rel -in @("AGENTS.md", "README.md")) {
    Assert-Contains $rel "lead, meta, decision, and implementation" "Current nine-PM layer terminology"
  } elseif ($rel -in @("操作系统\00_总入口.md", "操作系统\01_架构\README.md", "操作系统\01_架构\工具载体矩阵.md")) {
    Assert-Contains $rel "主-元-决策-实施|lead, meta, decision, and implementation" "Current nine-PM layer terminology"
  } else {
    Assert-Contains $rel "主-元-决策-实施|lead, meta, decision, and implementation" "Current nine-PM layer terminology"
  }
}
Assert-NotContains "操作系统\05_记忆\行为反思.md" "chat 简版 ⑥ 必含.*PM 切换轨迹|short chat section ⑥ must include.*PM transitions" "PM-transition placement in the short chat summary"
Assert-NotContains "README.md" "交接卡\s*6\s*段格式" "Obsolete handoff-card section count"
Assert-Contains "操作系统\06_工具治理\历史归档\2026-05\记忆治理方案-2026-05-22.md" "历史快照 / 非当前执行入口" "Memory-governance historical archive boundary"
Assert-Contains "操作系统\00_变更记录\状态-archive\README.md" "不可直接复制执行" "Historical boundary for dangerous commands in status archives"

$stateArchiveDir = Join-Path $Root "操作系统\00_变更记录\状态-archive"
if (Test-Path -LiteralPath $stateArchiveDir -PathType Container) {
  foreach ($file in Get-ChildItem -LiteralPath $stateArchiveDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
    if ($file.Name -eq "README.md") { continue }
    $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
    $text = Get-Text $rel
    $head = Get-Head $rel 16
    if ($text -match "(?i)git reset|git push|\bpush\b|\btag\b|hotfix/|\bmaster\b|baseUrl|api[_-]?key|apikey|sk-[A-Za-z0-9_-]{4,}|Bearer\s+[A-Za-z0-9._-]+|密钥|凭证|rm -rf|rm\s+\.git/index|Remove-Item|\.env\.local|tp-[a-z0-9]{4,}|chat 简版\s*(①-⑥|⑥)") {
      if ($head -notmatch "历史安全边界" -or $head -notmatch "不可直接复制执行" -or $head -notmatch "三类行为铁律" -or $head -notmatch "ADR-022") {
        Add-Failure "Status archive lacks a historical safety boundary near the top: $rel"
      }
    }
  }
}

foreach ($rel in @(
  "操作系统\00_变更记录\agent-INDEX-历史.md",
  "操作系统\00_变更记录\agent-README-历史.md",
  "操作系统\00_变更记录\CHANGELOG-2026-06-15-较早条目.md",
  "操作系统\00_变更记录\CHANGELOG-2026-05-21至06-14-较早条目.md",
  "操作系统\00_变更记录\CHANGELOG-2026H1.md"
)) {
  $text = Get-Text $rel
  $head = Get-Head $rel 18
  if ($text -match "(?i)agent[\\/]|git reset|rm -rf|api[_-]?key|apikey|\.env\.local|baseUrl|\btag\b|\bpush\b|hotfix/|\bmaster\b|密钥|凭证|chat 简版\s*(①-⑥|⑥)") {
    if ($head -notmatch "历史安全边界" -or $head -notmatch "不可直接复制执行" -or $head -notmatch "三类行为铁律|操作系统/.+能力资产") {
      Add-Failure "Historical change record lacks a safety boundary near the top: $rel"
    }
  }
}

Assert-Contains "交接区\README.md" "历史归档/.*不可直接复制执行|(?s:历史归档/.*Use them for historical tracing, not as current instructions or copy-and-run commands\.)" "Handoff historical archive directory boundary"
Assert-Contains "交接区\历史归档\README.md" "不代表当前待办.*不可直接复制执行|不可直接复制执行.*不代表当前待办|They are not current tasks and must not be copied and executed directly\." "Handoff historical archive entry boundary"

$permanentText = Get-Text "操作系统\01_架构\元规则池.md"
$candidateText = Get-Text "操作系统\01_架构\元规则池-候选.md"
$permanentIds = @(
  [regex]::Matches($permanentText, '(?m)^\|\s*\*\*([A-Z]{2}(?:\+[A-Z]{2})?)\*\*\s*\|') |
    ForEach-Object { $_.Groups[1].Value }
)
$candidateIds = @(
  [regex]::Matches($candidateText, '(?m)^\|\s*(?:\*\*)?(?:🆕\s*)?([A-Z]{2})(?:\*\*)?\s*\|') |
    ForEach-Object { $_.Groups[1].Value }
)
foreach ($id in @($candidateIds | Where-Object { $permanentIds -contains $_ } | Sort-Object -Unique)) {
  Add-Failure "Promoted meta-rule ID remains in the candidate table: $id"
}
$declaredCandidate = [regex]::Match($candidateText, '## (?:一、|1\. The )(\d+) (?:候选元规则|candidate meta-rules)')
if ($declaredCandidate.Success -and [int]$declaredCandidate.Groups[1].Value -ne $candidateIds.Count) {
  Add-Failure "Meta-rule candidate count mismatch: declared $($declaredCandidate.Groups[1].Value) vs table $($candidateIds.Count)"
}

$p4Docs = @(
  "能力资产\skills\README.md",
  "能力资产\skills\项目体检.md",
  "能力资产\skills\项目体检-检查项-7-8.md",
  "能力资产\tools\README.md",
  "操作系统\01_架构\子agent调度机制.md",
  "操作系统\06_工具治理\framework体检.md",
  "操作系统\07_完整工作流\hooks-运行SOP-附录.md"
)
foreach ($rel in $p4Docs) {
  Assert-NotContains $rel "P4a[-–]P4[p-s]|P4j[-–]P4[p-s]" "Obsolete P4 health-check scope limit"
  Assert-Contains $rel "P4a[-–]P4t|P4j[-–]P4t" "P4t health-check scope"
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ Operating-system layer terminology and P4t entry semantics are aligned" -ForegroundColor Green
exit 0
