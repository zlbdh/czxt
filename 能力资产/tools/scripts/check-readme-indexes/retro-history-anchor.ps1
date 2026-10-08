param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "RETRO 历史锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$readme = Read-Text "Docs/7-复盘/README.md"
$readmeAliases = @{
  '历史安全覆盖说明' = 'Historical safety override:'
  'RETRO 正文记录当时事实，不等于当前 SOP' = 'RETRO bodies record facts at the time; they are not current operating procedures.'
  'Q1-Q7' = 'Q1–Q7'
  '①-⑦' = '①–⑦'
  'Framework PROP' = 'framework PROP'
  '9 PM' = 'nine-PM/agent scheduling model'
}
foreach ($required in @(
  "历史安全覆盖说明", "RETRO 正文记录当时事实，不等于当前 SOP",
  "git reset --hard HEAD", "git push origin master", "Q1-Q7", "①-⑦",
  "Framework PROP", "9 PM"
)) {
  $pattern = [regex]::Escape($required)
  if ($readmeAliases.ContainsKey($required)) {
    $pattern += '|' + [regex]::Escape($readmeAliases[$required])
  }
  if ($readme -notmatch $pattern) {
    Add-Failure "Docs/7-复盘/README.md 缺少历史覆盖说明锚点：$required"
  }
}

$retroDir = Join-Path $Root "Docs\7-复盘"
if (Test-Path -LiteralPath $retroDir -PathType Container) {
  $officialRetros = @(Get-ChildItem -LiteralPath $retroDir -Filter "RETRO-*.md" -File |
    Where-Object { $_.Name -notmatch "候选" })
  $indexedRows = @([regex]::Matches($readme, '(?m)^\| \[RETRO-\d{3}\]')).Count
  if ($indexedRows -ne $officialRetros.Count) {
    Add-Failure "RETRO README 索引行数不一致：README $indexedRows vs 文件 $($officialRetros.Count)"
  }
  if ($readme -notmatch "P4i / readme-index|P4i, and README-index checks jointly compare this index with actual RETRO files\.") {
    Add-Failure "RETRO README 未声明 P4i / readme-index 共同守索引"
  }
}

$template = Read-Text "Docs/7-复盘/_模板.md"
if ($template -match "agent/workflows|agent/skills|5 个必问|five mandatory questions") {
  Add-Failure "RETRO 模板仍含旧路径或旧 5 问口径"
}

$tasksHeadPath = Join-Path $Root "TASKS.md"
if (Test-Path -LiteralPath $tasksHeadPath -PathType Leaf) {
  $tasksHead = (Get-Content -LiteralPath $tasksHeadPath -TotalCount 45 -Encoding UTF8) -join "`n"
  if (($tasksHead -match "TaskCreate|TaskUpdate") -and $tasksHead -notmatch "不再用 TaskCreate / TaskUpdate") {
    Add-Failure "TASKS.md 顶部当前区仍把 TaskCreate/TaskUpdate 写作当前维护入口"
  }
  if ($tasksHead -match "等 RETRO-012|议题 BW 接近永久关闭|如属议题 backl") {
    Add-Failure "TASKS.md 顶部当前区仍含旧维护口径或已关闭 BW pending"
  }
}

$retro009 = Read-Text "Docs/7-复盘/RETRO-009-2026-05.md"
if ($retro009 -match "git reset --hard HEAD|预批路径|preapproved path" -and $retro009 -notmatch "当前安全覆盖说明|Current safety override(?:\*\*)?:") {
  Add-Failure "RETRO-009 含 reset 预批旧口径但缺当前安全覆盖说明"
}

$retro010 = Read-Text "Docs/7-复盘/RETRO-010-2026-05.md"
if ($retro010 -match "git reset --hard HEAD|预批|preapproved" -and $retro010 -notmatch "当前安全覆盖说明|Current safety override(?:\*\*)?:") {
  Add-Failure "RETRO-010 含 reset 预批旧口径但缺当前安全覆盖说明"
}
if ($retro010 -match "git push origin master" -and $retro010 -notmatch "当前分支覆盖说明|Current branch override:") {
  Add-Failure "RETRO-010 含 master 旧口径但缺当前分支覆盖说明"
}

$retro013 = Read-Text "Docs/7-复盘/RETRO-013-2026-05.md"
if ($retro013 -match "git reset --hard|预批 git reset|preapproved git reset" -and $retro013 -notmatch "当前安全覆盖说明|Current safety override(?:\*\*)?:") {
  Add-Failure "RETRO-013 含 reset 旧口径但缺当前安全覆盖说明"
}

$retro009Candidate = Read-Text "Docs/7-复盘/RETRO-009-候选议题.md"
if ($retro009Candidate -match "agent/" -and $retro009Candidate -notmatch "历史链接说明|Historical links:") {
  Add-Failure "RETRO-009 候选议题含 agent/ 旧链接但缺历史链接说明"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ RETRO 历史安全覆盖锚点对齐"
exit 0
