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
    Add-Failure "运维边缘锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$backup = Read-Text "Docs/5-运维文档/数据备份恢复.md"
if ($backup -match "自动备份（Sprint 3 实现|每周日自动写一份") {
  Add-Failure "数据备份恢复.md 仍把自动备份写成已实现能力"
}
if ($backup -notmatch "当前未实现" -or $backup -notmatch "手动导出 JSON") {
  Add-Failure "数据备份恢复.md 未明确自动备份当前未实现与手动导出 JSON 真路径"
}

$claimsAutoBackup = $backup -match "后台自动写入|每周日自动|自动写入 Android"
if ($claimsAutoBackup) {
  $codeHits = @(
    Get-ChildItem -LiteralPath (Join-Path $Root "{{APP_REPO_DIR}}\src") -Recurse -File -Include "*.js","*.jsx","*.ts","*.tsx" -ErrorAction SilentlyContinue |
      Select-String -Pattern "@capacitor/filesystem|Filesystem\.writeFile|writeFile\(" -ErrorAction SilentlyContinue
  )
  if ($codeHits.Count -eq 0 -and $backup -notmatch "当前未实现") {
    Add-Failure "文档宣称自动备份，但业务代码未见 Filesystem 写入能力"
  }
}

$trouble = Read-Text "Docs/5-运维文档/故障排查.md"
if ($trouble -match "手动 SQL|待 Sprint 3") {
  Add-Failure "故障排查.md 仍含手动 SQL / 待 Sprint 3 旧运维口径"
}
if ($trouble -notmatch "默认只做只读核验" -or $trouble -notmatch "另起明确授权") {
  Add-Failure "故障排查.md 未明确 DevTools 只读核验与手动改库需授权"
}

$actions = Read-Text "Docs/5-运维文档/GitHubActions说明.md"
if ($actions -match "Sprint 3 实施时会写完整版") {
  Add-Failure "GitHubActions说明.md 仍含 release workflow 旧待补口径"
}
if ($actions -notmatch "当前仓库没有 release 签名 APK workflow") {
  Add-Failure "GitHubActions说明.md 未说明当前无 release 签名 APK workflow"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Docs/5 运维边缘口径对齐（备份/故障排查/release workflow）" -ForegroundColor Green
exit 0
