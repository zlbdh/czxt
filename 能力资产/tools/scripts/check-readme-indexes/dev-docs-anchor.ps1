param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Doc([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "开发文档缺失：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$readme = Read-Doc "Docs/3-开发文档/README.md"
$flow = Read-Doc "Docs/3-开发文档/开发流程.md"
$schema = Read-Doc "Docs/3-开发文档/数据库schema.md"
$structure = Read-Doc "Docs/3-开发文档/项目结构.md"
$apiSpec = Read-Doc "Docs/3-开发文档/API规范.md"

if ($readme -notmatch "当前工程事实优先级") { Add-Failure "Docs/3-开发文档/README.md 缺当前真源说明" }
if ($flow -notmatch "历史快照" -or $flow -notmatch "操作系统/07_完整工作流/实施循环.md") { Add-Failure "开发流程.md 未标明历史快照与现行流程入口" }
if ($schema -notmatch "当前 schema 版本：v16" -or $schema -notmatch "database/schema.js") { Add-Failure "数据库schema.md 未对齐当前 v16 / schema.js 真源" }
if ($structure -match "(?m)^├── .*agent\\\\") { Add-Failure "项目结构.md 仍把旧 agent/ 当当前根目录" }
if ($structure -notmatch "操作系统/" -or $structure -notmatch "能力资产/" -or $structure -notmatch "{{APP_REPO_DIR}}/apk/") { Add-Failure "项目结构.md 当前根目录导航不完整" }
if ($apiSpec -notmatch "真实 apiKey 只允许由用户在本机配置" -or $apiSpec -notmatch "tracked 文件") { Add-Failure "API规范.md 缺真实 key / tracked 文件安全说明" }

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Docs/3 开发文档入口锚点对齐"
exit 0
