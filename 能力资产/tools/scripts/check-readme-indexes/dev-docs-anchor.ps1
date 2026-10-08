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
    Add-Failure "Development document is missing: $Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$readme = Read-Doc "Docs/3-开发文档/README.md"
$flow = Read-Doc "Docs/3-开发文档/开发流程.md"
$schema = Read-Doc "Docs/3-开发文档/数据库schema.md"
$structure = Read-Doc "Docs/3-开发文档/项目结构.md"
$apiSpec = Read-Doc "Docs/3-开发文档/API规范.md"

if ($readme -notmatch "项目实例真值|project instance source of truth" -or $readme -notmatch "模板根不预设|template root does not prescribe") { Add-Failure "Docs/3-开发文档/README.md lacks project-instance authority or template-neutrality guidance" }
if ($flow -notmatch "历史快照|historical snapshot" -or $flow -notmatch "操作系统/07_完整工作流/实施循环.md") { Add-Failure "开发流程.md does not identify its historical snapshot and current workflow entry" }
if ($schema -notmatch "项目实例真值|project instance source of truth" -or $schema -notmatch "迁移与兼容|migration and compatibility" -or $schema -notmatch "\[填写\]|\[fill in\]" -or $schema -match "当前 schema 版本：v16|Current schema version: v16") { Add-Failure "数据库schema.md does not remain an instance-specific template, or reintroduces fixed v16 guidance" }
if ($structure -match "(?m)^├── .*agent\\\\") { Add-Failure "项目结构.md still treats the obsolete agent/ directory as a current root" }
if ($structure -notmatch "模板根导航|template root navigation" -or $structure -notmatch "项目实例导航|project instance navigation" -or $structure -notmatch "\{\{APP_REPO_DIR\}\}/") { Add-Failure "项目结构.md lacks neutral template-root, project-instance, and application-repository navigation" }
if ($apiSpec -notmatch "真实(密钥| apiKey)|real (secrets|apiKey)" -or $apiSpec -notmatch "tracked 文件|tracked files" -or $apiSpec -notmatch "协议层|protocol layer" -or $apiSpec -notmatch "模型层|model layer") { Add-Failure "API规范.md lacks secret-safety or protocol/model layer separation guidance" }

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Development-document entry anchors aligned"
exit 0
