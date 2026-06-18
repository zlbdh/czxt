param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

$common = Join-Path $PSScriptRoot "anchor-common.ps1"
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) { throw "缺少 anchor-common.ps1" }
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
  Assert-NotContains $rel "主-元-子-子子|子子\s*(PM|2|层)" "9 PM 四层术语"
}

foreach ($rel in @(
  "AGENTS.md",
  "README.md",
  "操作系统\00_总入口.md",
  "操作系统\01_架构\README.md",
  "操作系统\01_架构\工具载体矩阵.md",
  "操作系统\02_智能体\README.md"
)) {
  Assert-Contains $rel "主-元-决策-实施" "9 PM 四层现行术语"
}
Assert-NotContains "操作系统\05_记忆\行为反思.md" "chat 简版 ⑥ 必含.*PM 切换轨迹" "chat 简版 PM 轨迹段位"
Assert-NotContains "README.md" "交接卡\s*6\s*段格式" "交接卡段数旧口径"
Assert-Contains "操作系统\06_工具治理\历史归档\2026-05\记忆治理方案-2026-05-22.md" "历史快照 / 非当前执行入口" "记忆治理历史归档边界"
Assert-Contains "操作系统\00_变更记录\状态-archive\README.md" "不可直接复制执行" "状态归档危险命令历史边界"

$stateArchiveDir = Join-Path $Root "操作系统\00_变更记录\状态-archive"
if (Test-Path -LiteralPath $stateArchiveDir -PathType Container) {
  foreach ($file in Get-ChildItem -LiteralPath $stateArchiveDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
    if ($file.Name -eq "README.md") { continue }
    $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
    $text = Get-Text $rel
    $head = Get-Head $rel 16
    if ($text -match "(?i)git reset|git push|\bpush\b|\btag\b|hotfix/|\bmaster\b|baseUrl|api[_-]?key|apikey|sk-[A-Za-z0-9_-]{4,}|Bearer\s+[A-Za-z0-9._-]+|密钥|凭证|rm -rf|rm\s+\.git/index|Remove-Item|\.env\.local|tp-[a-z0-9]{4,}|chat 简版\s*(①-⑥|⑥)") {
      if ($head -notmatch "历史安全边界" -or $head -notmatch "不可直接复制执行" -or $head -notmatch "三类行为铁律" -or $head -notmatch "ADR-022") {
        Add-Failure "状态归档正文缺少首屏历史安全边界：$rel"
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
      Add-Failure "变更记录历史正文缺少首屏历史安全边界：$rel"
    }
  }
}

Assert-Contains "交接区\README.md" "历史归档/.*不可直接复制执行" "交接历史归档目录边界"
Assert-Contains "交接区\历史归档\README.md" "不代表当前待办.*不可直接复制执行|不可直接复制执行.*不代表当前待办" "交接历史归档入口边界"

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
  Add-Failure "元规则候选编号已永久化仍在候选表：$id"
}
$declaredCandidate = [regex]::Match($candidateText, '## 一、(\d+) 候选元规则')
if ($declaredCandidate.Success -and [int]$declaredCandidate.Groups[1].Value -ne $candidateIds.Count) {
  Add-Failure "元规则候选数不一致：声明 $($declaredCandidate.Groups[1].Value) vs 表格 $($candidateIds.Count)"
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
  Assert-NotContains $rel "P4a[-–]P4p|P4j[-–]P4p|P4a[-–]P4q|P4j[-–]P4q|P4a[-–]P4r|P4j[-–]P4r" "P4 体检范围"
}
foreach ($rel in @(
  "能力资产\skills\项目体检.md",
  "能力资产\tools\README.md",
  "操作系统\06_工具治理\framework体检.md"
)) {
  Assert-Contains $rel "P4a[-–]P4s|P4j-P4s|P4s" "P4s 体检范围"
}

if ($failures.Count -gt 0) {
  exit 10
}

Write-Host "  ✅ 操作系统层级术语与 P4s 入口语义对齐" -ForegroundColor Green
exit 0
