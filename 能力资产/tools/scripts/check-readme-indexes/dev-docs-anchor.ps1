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

if ($readme -notmatch "项目实例真值" -or $readme -notmatch "模板根不预设") { Add-Failure "Docs/3-开发文档/README.md 缺项目实例真值 / 模板中立说明" }
if ($flow -notmatch "历史快照" -or $flow -notmatch "操作系统/07_完整工作流/实施循环.md") { Add-Failure "开发流程.md 未标明历史快照与现行流程入口" }
if ($schema -notmatch "项目实例真值" -or $schema -notmatch "迁移与兼容" -or $schema -notmatch "\[填写\]" -or $schema -match "当前 schema 版本：v16") { Add-Failure "数据库schema.md 未保持项目实例填写模板，或回流固定 v16" }
if ($structure -match "(?m)^├── .*agent\\\\") { Add-Failure "项目结构.md 仍把旧 agent/ 当当前根目录" }
if ($structure -notmatch "模板根导航" -or $structure -notmatch "项目实例导航" -or $structure -notmatch "\{\{APP_REPO_DIR\}\}/") { Add-Failure "项目结构.md 缺模板根 / 项目实例 / 业务仓库中性导航" }
if ($apiSpec -notmatch "真实(密钥| apiKey)" -or $apiSpec -notmatch "tracked 文件" -or $apiSpec -notmatch "协议层" -or $apiSpec -notmatch "模型层") { Add-Failure "API规范.md 缺密钥安全或协议层 / 模型层分离说明" }

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Docs/3 开发文档入口锚点对齐"
exit 0
