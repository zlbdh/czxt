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
  if (-not (Test-Path -LiteralPath (Join-Path $Root $rel))) { $failures.Add("$rel 缺失：$label") }
}

function Add-Hits([string]$rel, [string]$pattern, [string]$label) {
  $text = Read-Text $rel
  if ($null -eq $text) { $failures.Add("$rel 缺失，无法检查：$label"); return }
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
  $failures.Add("PM工作区 目录缺失")
} else {
  foreach ($pm in $pms) {
    Add-Missing "PM工作区/$pm" "PM 工作区目录"
    Add-Missing "PM工作区/$pm/README.md" "PM 工作区 README"
  }
}

foreach ($anchor in @("PM工作区/README.md", "操作系统/01_架构/PM工作区边界.md")) {
  $text = Read-Text $anchor
  if ($null -eq $text) { $failures.Add("$anchor 缺失，无法核对 9 PM 清单"); continue }
  foreach ($pm in $pms) {
    if ($text -notmatch [regex]::Escape($pm)) { $failures.Add("$anchor 缺 $pm") }
  }
}

$roleText = Read-Text "操作系统/01_架构/角色边界.md"
if ($null -eq $roleText) {
  $failures.Add("操作系统/01_架构/角色边界.md 缺失，无法核对 9 PM 角色名")
} else {
  foreach ($role in ($pms | ForEach-Object { To-Role $_ })) {
    if ($roleText -notmatch [regex]::Escape($role)) { $failures.Add("角色边界.md 缺 $role，9 PM 角色清单不同步") }
  }
}

$projectSkillIndex = Read-Text "PM工作区/项目PM-咪咪/速查表/INDEX.md"
if ($null -eq $projectSkillIndex) {
  $failures.Add("PM工作区/项目PM-咪咪/速查表/INDEX.md 缺失")
} else {
  foreach ($pm in $pms) {
    if ($projectSkillIndex -notmatch [regex]::Escape("PM工作区/$pm/")) { $failures.Add("项目 PM INDEX 未列 $pm") }
  }
}

$skillIndexCount = 0
foreach ($pm in $pms) {
  $indexPath = Join-Path $workspace "$pm\速查表\INDEX.md"
  if (Test-Path -LiteralPath $indexPath -PathType Leaf) {
    $skillIndexCount++
  } else {
    $failures.Add("PM工作区/$pm/速查表/INDEX.md 缺失")
  }
}
$selfDir = Join-Path $workspace "项目PM-咪咪\PM自纠"
$artifactCount = 0
if (Test-Path -LiteralPath $selfDir -PathType Container) {
  $artifactCount = (Get-ChildItem -LiteralPath $selfDir -Filter "PM自纠-*.md" -File).Count
}
$selfIndex = Read-Text "PM工作区/项目PM-咪咪/PM自纠/INDEX.md"
if ($null -eq $selfIndex) {
  $failures.Add("PM工作区/项目PM-咪咪/PM自纠/INDEX.md 缺失")
} elseif ($artifactCount -gt 0 -and $selfIndex -notmatch "$artifactCount\s*个独立") {
  $failures.Add("PM自纠 INDEX 未同步当前 artifact 文件数：实际 $artifactCount")
}

$checks = @(
  @{ P = "PM工作区/项目PM-咪咪/PM自纠/INDEX.md"; R = '当前累积（21\+|下一次 PM 自纠（#64\+'; L = "PM自纠 INDEX 旧入口" },
  @{ P = "PM工作区/项目PM-咪咪/README.md"; R = '项目PM/速查表/|单文件 ≤ 2KB'; L = "项目PM README 旧路径/硬大小" },
  @{ P = "PM工作区/项目PM-咪咪/速查表/INDEX.md"; R = '待 Sprint-8|PM工作区/运营PM-运营咪咪/速查表/`\s*\|\s*🌱 待累积'; L = "项目PM INDEX 旧 Sprint/6PM" },
  @{ P = "PM工作区/项目PM-咪咪/速查表/ADR-022决定5-4类角色铁律.md"; R = '\|\s*\*\*Claude Code\*\*\s*\||\|\s*\*\*Codex\*\*\s*\||交接卡给 Claude Code'; L = "ADR-022 工具作主语" },
  @{ P = "PM工作区/操作系统PM-框架管家/README.md"; R = '`tools/`|`Docs/3/`|`Docs/7/`'; L = "框架管家路径旧口径" },
  @{ P = "PM工作区/运营PM-运营咪咪/README.md"; R = '当前状态（2026-05-21）|草稿/` \| 各平台草稿（待建|Docs/1-需求文档/` 增长相关|交接区/分支间|已 ship 内容：（空'; L = "运营 README 旧状态/越界" },
  @{ P = "PM工作区/沉淀PM-沉淀者/速查表/INDEX.md"; R = '9 条'; L = "沉淀 INDEX 旧计数" },
  @{ P = "PM工作区/开发PM-实施者/README.md"; R = '待 Sprint-8 启动后'; L = "开发 README 旧 Sprint" },
  @{ P = "PM工作区/README.md"; R = '每文件 ≤ 2KB'; L = "PM工作区硬大小阈值" }
)
foreach ($c in $checks) { Add-Hits $c.P $c.R $c.L }

if ($failures.Count -gt 0) {
  Write-Host "  🔴 PM 工作区入口未对齐：$($failures.Count) 处" -ForegroundColor Red
  foreach ($f in $failures) { Write-Host "    - $f" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ PM 工作区入口对齐" -ForegroundColor Green
Write-Host "  ℹ️ 速查表 INDEX：$skillIndexCount / $($pms.Count)；PM自纠：$artifactCount" -ForegroundColor Gray
Write-Host "  ℹ️ 产物/历史不进P4b，守入口" -ForegroundColor Gray
exit 0
