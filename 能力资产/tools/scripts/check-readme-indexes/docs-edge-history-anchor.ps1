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
    Add-Failure "Historical edge-document anchor file is missing: $Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Read-Head([string]$Rel, [int]$Lines = 20) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "Historical edge-document anchor file is missing: $Rel"
    return ""
  }
  return (Get-Content -LiteralPath $path -TotalCount $Lines -Encoding UTF8) -join "`n"
}

function Get-Rel([string]$Path) {
  return $Path.Substring($Root.Length).TrimStart('\')
}

foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root "Docs\1-需求文档") -Filter "Sprint-*需求清单.md" -File -ErrorAction SilentlyContinue) {
  $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
  $head = Read-Head $rel 8
  if ($head -notmatch "历史 Sprint 需求清单" -or $head -notmatch "不代表当前待办") {
    Add-Failure "$rel lacks a historical Sprint boundary near the top"
  }
}

$legacyReq = Read-Text "Docs/1-需求文档/前作需求/README.md"
if ($legacyReq -notmatch "历史候选池" -or $legacyReq -notmatch "当前是否纳入开发") {
  Add-Failure "Previous-project requirements README lacks a historical-candidate boundary and current candidate source"
}
if ($legacyReq -match "Sprint-7\+.*移植候选") {
  Add-Failure "Previous-project requirements README still uses obsolete Sprint-7+ current-candidate guidance"
}

$gapAuditHead = Read-Head "Docs/1-需求文档/v3.0需求实现度审计-缺口台账.md" 12
if ($gapAuditHead -notmatch "历史审计快照" -or $gapAuditHead -notmatch ('不代表 v3\.52\.0 / ' + [regex]::Escape('{{CURRENT_SPRINT}}') + ' 当前 backlog')) {
  Add-Failure "The v3.0 requirements audit lacks historical-snapshot and noncurrent-backlog boundaries near the top"
}

$reqHistoryHead = Read-Head "Docs/1-需求文档/需求历史.md" 14
if ($reqHistoryHead -notmatch "计划中 / 进行中 / 未启动.*当时语境" -or $reqHistoryHead -notmatch "v3\.0（历史：当时计划中") {
  Add-Failure "Requirements history does not limit old planned/in-progress language to its historical context near the top"
}
$reqHistory = Read-Text "Docs/1-需求文档/需求历史.md"
if ($reqHistory -match "agent/rules|agent/workflows") {
  if ($reqHistory -notmatch "历史路径；现行入口见") {
    Add-Failure "Requirements history contains obsolete agent/ paths without current-entry guidance"
  }
}

$docs6ReadmeRel = "Docs/6-历史归档/README.md"
$docs6 = Read-Text $docs6ReadmeRel
if ($docs6 -notmatch "不代表当前待办" -or $docs6 -notmatch "不可直接复制执行") {
  Add-Failure "Docs/6 historical archive README lacks a prohibition on copying into execution"
}

$docs6Dir = Join-Path $Root "Docs\6-历史归档"
if (Test-Path -LiteralPath $docs6Dir -PathType Container) {
  $docs6ReadmePath = Join-Path $Root $docs6ReadmeRel
  foreach ($file in Get-ChildItem -LiteralPath $docs6Dir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue) {
    if ($file.FullName -eq $docs6ReadmePath) { continue }
    $rel = Get-Rel $file.FullName
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $head = ($text -split "`n" | Select-Object -First 12) -join "`n"
    if ($head -notmatch "历史归档" -or $head -notmatch "不可直接复制执行") {
      Add-Failure "$rel lacks a historical boundary near the top"
    }
    if ($text -match "当前 APP|目标 APP|内置自用 key|硬编码.*key") {
      if ($head -notmatch "旧口径|当时旧口径" -or $head -notmatch "不代表现在.*AI 配置方式|不代表当前.*AI 配置") {
        Add-Failure "$rel has obsolete current-app/key language without historical clarification near the top"
      }
    }
    if ($text -match "(?i)api[_-]?key\s*[:=]\s*['""][A-Za-z0-9_\-]{12,}|tp-[a-z0-9]{8,}") {
      Add-Failure "$rel may contain text resembling a real key/token"
    }
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Historical edge-document guidance aligned (Sprint/previous projects/Docs6)" -ForegroundColor Green
exit 0
