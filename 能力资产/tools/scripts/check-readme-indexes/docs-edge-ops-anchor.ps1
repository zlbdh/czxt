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
    Add-Failure "Operations edge-document anchor file is missing: $Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$backup = Read-Text "Docs/5-运维文档/数据备份恢复.md"
if ($backup -match "自动备份（Sprint 3 实现|每周日自动写一份") {
  Add-Failure "数据备份恢复.md still presents automatic backups as implemented"
}
if ($backup -notmatch "当前未实现" -or $backup -notmatch "手动导出 JSON") {
  Add-Failure "数据备份恢复.md does not identify automatic backups as unimplemented or provide the actual manual JSON export path"
}

$claimsAutoBackup = $backup -match "后台自动写入|每周日自动|自动写入 Android"
if ($claimsAutoBackup) {
  $codeHits = @(
    Get-ChildItem -LiteralPath (Join-Path $Root "{{APP_REPO_DIR}}\src") -Recurse -File -Include "*.js","*.jsx","*.ts","*.tsx" -ErrorAction SilentlyContinue |
      Select-String -Pattern "@capacitor/filesystem|Filesystem\.writeFile|writeFile\(" -ErrorAction SilentlyContinue
  )
  if ($codeHits.Count -eq 0 -and $backup -notmatch "当前未实现") {
    Add-Failure "Documentation claims automatic backups, but application code has no Filesystem write capability"
  }
}

$trouble = Read-Text "Docs/5-运维文档/故障排查.md"
if ($trouble -match "手动 SQL|待 Sprint 3") {
  Add-Failure "故障排查.md still has obsolete manual-SQL or pending-Sprint-3 guidance"
}
if ($trouble -notmatch "默认只做只读核验" -or $trouble -notmatch "另起明确授权") {
  Add-Failure "故障排查.md lacks read-only DevTools verification and authorization requirements for manual database changes"
}

$actions = Read-Text "Docs/5-运维文档/GitHubActions说明.md"
if ($actions -match "Sprint 3 实施时会写完整版") {
  Add-Failure "GitHubActions说明.md still describes the release workflow as pending documentation"
}
if ($actions -notmatch "当前仓库没有 release 签名 APK workflow") {
  Add-Failure "GitHubActions说明.md does not state that no signed-release APK workflow currently exists"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Operations edge-document guidance aligned (backup/troubleshooting/release workflow)" -ForegroundColor Green
exit 0
