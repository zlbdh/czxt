param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$pms = "项目PM-咪咪 沉淀PM-沉淀者 操作系统PM-框架管家 产品PM-需求拆解者 技术PM-修复决策者 测试PM-质量门户 运营PM-运营咪咪 开发PM-实施者 测试发布PM-闭环者" -split " "
$failures = New-Object System.Collections.Generic.List[string]

function Read-Text([string]$rel) {
  $p = Join-Path $Root $rel
  if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
  Get-Content -LiteralPath $p -Raw -Encoding UTF8
}

function Add-Missing([string]$rel, [string]$label) {
  if (-not (Test-Path -LiteralPath (Join-Path $Root $rel))) { $failures.Add("$rel is missing: $label") }
}

function Add-Hits([string]$rel, [string]$pattern, [string]$label) {
  $text = Read-Text $rel
  if ($null -eq $text) { $failures.Add("$rel is missing; cannot check: $label"); return }
  foreach ($m in [regex]::Matches($text, $pattern)) {
    $line = ($text.Substring(0, $m.Index) -split "`n").Count
    $failures.Add("$rel`:L$line $label")
  }
}
function To-Role([string]$pm) {
  if ($pm -match '^(.+?)PM-(.+)$') { return "$($Matches[1]) PM「$($Matches[2])」" }
  return $pm
}

$workspace = Join-Path $Root "PM工作区"
if (-not (Test-Path -LiteralPath $workspace -PathType Container)) {
  $failures.Add("The PM workspace directory is missing")
} else {
  foreach ($pm in $pms) {
    Add-Missing "PM工作区/$pm" "PM workspace directory"
    Add-Missing "PM工作区/$pm/README.md" "PM workspace README"
  }
}

foreach ($anchor in @("PM工作区/README.md", "操作系统/01_架构/PM工作区边界.md")) {
  $text = Read-Text $anchor
  if ($null -eq $text) { $failures.Add("$anchor is missing; cannot verify the 9 PM inventory"); continue }
  foreach ($pm in $pms) {
    if ($text -notmatch [regex]::Escape($pm)) { $failures.Add("$anchor is missing $pm") }
  }
}

$roleText = Read-Text "操作系统/01_架构/角色边界.md"
if ($null -eq $roleText) {
  $failures.Add("操作系统/01_架构/角色边界.md is missing; cannot verify the 9 PM role names")
} else {
  $roleAliases = @{
    '项目 PM「咪咪」' = 'Project PM “Mimi”'
    '沉淀 PM「沉淀者」' = 'Knowledge PM “Curator”'
    '操作系统 PM「框架管家」' = 'Operating System PM “Framework Steward”'
    '产品 PM「需求拆解者」' = 'Product PM “Requirements Analyst”'
    '技术 PM「修复决策者」' = 'Technical PM “Fix Strategist”'
    '测试 PM「质量门户」' = 'Test PM “Quality Gate”'
    '运营 PM「运营咪咪」' = 'Operations PM “Operations Mimi”'
    '开发 PM「实施者」' = 'Development PM “Implementer”'
    '测试发布 PM「闭环者」' = 'Test and Release PM “Closer”'
  }
  foreach ($role in ($pms | ForEach-Object { To-Role $_ })) {
    $hasLegacyRole = $roleText -match [regex]::Escape($role)
    $hasEnglishRole = $roleAliases.ContainsKey($role) -and
      ($roleText -match [regex]::Escape($roleAliases[$role]))
    if (-not $hasLegacyRole -and -not $hasEnglishRole) { $failures.Add("角色边界.md lacks $role; the 9 PM role inventory is out of sync") }
  }
}

$projectSkillIndex = Read-Text "PM工作区/项目PM-咪咪/速查表/INDEX.md"
if ($null -eq $projectSkillIndex) {
  $failures.Add("PM工作区/项目PM-咪咪/速查表/INDEX.md is missing")
} else {
  foreach ($pm in $pms) {
    if ($projectSkillIndex -notmatch [regex]::Escape("PM工作区/$pm/")) { $failures.Add("Project PM INDEX does not list $pm") }
  }
}

$skillIndexCount = 0
foreach ($pm in $pms) {
  $indexPath = Join-Path $workspace "$pm\速查表\INDEX.md"
  if (Test-Path -LiteralPath $indexPath -PathType Leaf) {
    $skillIndexCount++
  } else {
    $failures.Add("PM工作区/$pm/速查表/INDEX.md is missing")
  }
}
$selfDir = Join-Path $workspace "项目PM-咪咪\PM自纠"
$artifactCount = 0
if (Test-Path -LiteralPath $selfDir -PathType Container) {
  $artifactCount = (Get-ChildItem -LiteralPath $selfDir -Filter "PM自纠-*.md" -File).Count
}
$selfIndex = Read-Text "PM工作区/项目PM-咪咪/PM自纠/INDEX.md"
if ($null -eq $selfIndex) {
  $failures.Add("PM工作区/项目PM-咪咪/PM自纠/INDEX.md is missing")
} elseif ($artifactCount -gt 0 -and $selfIndex -notmatch "(?:$artifactCount\s*个独立|(?<!\d)$artifactCount\s+independent artifacts\b)") {
  $failures.Add("The PM self-correction INDEX does not reflect the current artifact count: actual $artifactCount")
}

$checks = @(
  @{ P = "PM工作区/项目PM-咪咪/PM自纠/INDEX.md"; R = '当前累积（21\+|下一次 PM 自纠（#64\+|Current total \(21\+|Next PM self-correction \(#64\+'; L = "PM self-correction INDEX obsolete entry" },
  @{ P = "PM工作区/项目PM-咪咪/README.md"; R = '项目PM/速查表/|单文件 ≤ 2KB|Single file ≤ 2KB'; L = "Project PM README obsolete paths/hard size limits" },
  @{ P = "PM工作区/项目PM-咪咪/速查表/INDEX.md"; R = '待 Sprint-8|Pending Sprint-8|PM工作区/运营PM-运营咪咪/速查表/`\s*\|\s*🌱 (待累积|To develop)'; L = "Project PM INDEX obsolete Sprint/6PM references" },
  @{ P = "PM工作区/项目PM-咪咪/速查表/ADR-022决定5-4类角色铁律.md"; R = '\|\s*\*\*Claude Code\*\*\s*\||\|\s*\*\*Codex\*\*\s*\||交接卡给 Claude Code|Handoff card to Claude Code'; L = "ADR-022 uses tools as responsible actors" },
  @{ P = "PM工作区/操作系统PM-框架管家/README.md"; R = '`tools/`|`Docs/3/`|`Docs/7/`'; L = "Framework Steward obsolete path wording" },
  @{ P = "PM工作区/运营PM-运营咪咪/README.md"; R = '当前状态（2026-05-21）|Current status \(2026-05-21\)|草稿/` \| 各平台草稿（待建|草稿/` \| Platform drafts \(to create|Docs/1-需求文档/` (增长相关|Growth-related)|交接区/分支间|已 ship 内容：（空|Published content: \(empty'; L = "Operations README obsolete status/boundary violations" },
  @{ P = "PM工作区/沉淀PM-沉淀者/速查表/INDEX.md"; R = '9 条|\b9 rules\b'; L = "Knowledge PM INDEX obsolete counts" },
  @{ P = "PM工作区/开发PM-实施者/README.md"; R = '待 Sprint-8 启动后|After Sprint-8 starts'; L = "Development PM README obsolete Sprint" },
  @{ P = "PM工作区/README.md"; R = '每文件 ≤ 2KB|Each file ≤ 2KB'; L = "PM workspace hard size thresholds" }
)
foreach ($c in $checks) { Add-Hits $c.P $c.R $c.L }

if ($failures.Count -gt 0) {
  Write-Host "  🔴 PM workspace entries are misaligned: $($failures.Count) findings" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host "    - $f" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ PM workspace entries are aligned" -ForegroundColor Green
Write-Host "  ℹ️ Quick-reference INDEX files: $skillIndexCount / $($pms.Count); PM self-correction artifacts: $artifactCount" -ForegroundColor Gray
Write-Host "  ℹ️ Artifacts/history are excluded from P4b; check their entry points" -ForegroundColor Gray
exit 0
