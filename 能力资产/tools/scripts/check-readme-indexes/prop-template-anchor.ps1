param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "PROP 模板锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Read-Head([string]$Rel, [int]$Lines = 14) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "PROP 模板锚点缺文件：$Rel"
    return ""
  }
  return (Get-Content -LiteralPath $path -TotalCount $Lines -Encoding UTF8) -join "`n"
}

$template = Read-Text "确认改动\_模板.md"
if ($template -notmatch '```powershell' -or $template -match '```bash|grep PROP-|2>/dev/null') {
  Add-Failure "PROP 模板编号查询未使用当前 PowerShell 口径"
}

$readme = Read-Text "确认改动\README.md"
if ($readme -notmatch "已批未收口" -or $readme -notmatch "待排期 / 待重审 / 外部能力跟踪") {
  Add-Failure "确认改动 README 仍把进行中简化为纯实施中"
}

$prop038 = Read-Text "确认改动\已审批\进行中\PROP-038-2026-05-22-多形式自动化-Layer4.md"
if ($prop038 -match "Sprint-9 候选" -or $prop038 -notmatch "外部能力跟踪") {
  Add-Failure "PROP-038 未标为 v0 已落地后的外部能力跟踪"
}

$prop039 = Read-Text "确认改动\已审批\进行中\PROP-039-2026-05-22-Mem0+Skills-SDK集成.md"
if ($prop039 -notmatch "重估暂停说明" -or $prop039 -notmatch "不得按下表直接实施") {
  Add-Failure "PROP-039 原 AC/实施路径未显式暂停重估"
}

foreach ($rel in @(
  "确认改动\已审批\已完成\PROP-004-2026-05-09-rules目录按语义重构.md",
  "确认改动\已审批\已完成\PROP-005-2026-05-09-框架自动化升级.md",
  "确认改动\已审批\已完成\PROP-014-2026-05-12-流程优先与交接卡强制.md",
  "确认改动\已审批\已完成\PROP-017-2026-05-12-agent健康度治理.md"
)) {
  $head = ((Read-Text $rel) -split "`n" | Select-Object -First 12) -join "`n"
  if ($head -notmatch "历史封存说明" -or $head -notmatch "当前执行入口") {
    Add-Failure "$rel 缺少历史封存说明"
  }
}

$completedDir = Join-Path $Root "确认改动\已审批\已完成"
if (Test-Path -LiteralPath $completedDir -PathType Container) {
  $riskPattern = "(?i)agent[\\/]|TaskCreate|AskUserQuestion|git reset --hard|rm\s+\.git/index|apiKey|baseUrl|API key 泄漏|chat 简版\s*①-⑥|交接卡\s*6\s*段|Python/Bash 写"
  foreach ($file in Get-ChildItem -LiteralPath $completedDir -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue) {
    $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($text -notmatch $riskPattern) { continue }

    $head = Read-Head $rel 14
    if ($head -notmatch "历史|封存|旧|草案" -or $head -notmatch "当前|现行|不得照抄|不作为当前执行入口") {
      Add-Failure "$rel 命中旧路径/危险命令/API/chat 旧口径但首屏缺历史边界"
    }

    if ($text -match "git reset --hard|rm\s+\.git/index" -and $head -notmatch "不得照抄|三类行为铁律|用户明确授权") {
      Add-Failure "$rel 含破坏性 git 历史命令但首屏未前置禁止照抄语义"
    }
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ PROP 模板与历史封存口径对齐" -ForegroundColor Green
exit 0
