param(
  [Parameter(Mandatory=$true)][string]$ProjectRoot,
  [Parameter(Mandatory=$true)][string]$ProjectName,
  [Parameter(Mandatory=$true)][string]$AppRepoDir,
  [string]$CurrentVersion = "v0.1.0",
  [string]$CurrentSprint = "Sprint-1",
  [string]$AppId = "",
  [string]$ProjectSlug = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$TemplateRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$ProjectRootPosix = $ProjectRoot.Replace("\", "/")
$ProjectRootLower = $ProjectRoot.ToLowerInvariant()
$InitTime = Get-Date -Format "yyyy-MM-dd HH:mm"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$TemplateRootFull = [System.IO.Path]::GetFullPath($TemplateRoot)
if ($ProjectRootLower -eq $TemplateRootFull.ToLowerInvariant()) {
  throw "目标路径不能是模板根自身：$ProjectRoot"
}

if ([string]::IsNullOrWhiteSpace($ProjectSlug)) {
  $ProjectSlug = (($ProjectName.ToLowerInvariant()) -replace '[^a-z0-9]+','-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($ProjectSlug)) { $ProjectSlug = "project" }
}
if ([string]::IsNullOrWhiteSpace($AppId)) { $AppId = $ProjectSlug }

if (!(Test-Path -LiteralPath $ProjectRoot)) {
  New-Item -ItemType Directory -Path $ProjectRoot | Out-Null
}

$copyItems = @(
  ".codex",
  ".claude",
  ".gitignore",
  "AGENTS.md",
  "README.md",
  "状态.md",
  "实例化项目.ps1",
  "操作系统",
  "能力资产",
  "PM工作区",
  "交接区",
  "确认改动",
  "项目配置",
  "Docs"
)

foreach ($item in $copyItems) {
  $src = Join-Path $TemplateRoot $item
  $dst = Join-Path $ProjectRoot $item
  if (!(Test-Path -LiteralPath $src)) {
    throw "模板缺少必要项：$item"
  }
  if ((Test-Path -LiteralPath $dst) -and -not $Force) {
    throw "目标已存在：$dst。若确认覆盖，请加 -Force。"
  }
  Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
}

# 项目区：只复制骨架（README/清单/.gitignore + 空 本地实例/.gitkeep），
# 绝不递归复制 本地实例/* —— 防自实例化时把生成中的实例反复拷进自己（无限套娃），
# 同时避免新项目继承模板的本地实例残留。
$pzSrc = Join-Path $TemplateRoot "项目区"
$pzDst = Join-Path $ProjectRoot "项目区"
if (!(Test-Path -LiteralPath $pzSrc)) {
  throw "模板缺少必要项：项目区"
}
if ((Test-Path -LiteralPath $pzDst) -and -not $Force) {
  throw "目标已存在：$pzDst。若确认覆盖，请加 -Force。"
}
New-Item -ItemType Directory -Path (Join-Path $pzDst "本地实例") -Force | Out-Null
foreach ($pzFile in @("README.md", "清单.md", ".gitignore")) {
  $pzf = Join-Path $pzSrc $pzFile
  if (Test-Path -LiteralPath $pzf) {
    Copy-Item -LiteralPath $pzf -Destination (Join-Path $pzDst $pzFile) -Force
  }
}
$pzKeep = Join-Path $pzSrc "本地实例\.gitkeep"
if (Test-Path -LiteralPath $pzKeep) {
  Copy-Item -LiteralPath $pzKeep -Destination (Join-Path $pzDst "本地实例\.gitkeep") -Force
}

function Ensure-Directory {
  param([string]$RelativePath)
  $path = Join-Path $ProjectRoot $RelativePath
  if (!(Test-Path -LiteralPath $path -PathType Container)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Write-TextIfMissing {
  param(
    [string]$RelativePath,
    [string]$Content
  )

  $path = Join-Path $ProjectRoot $RelativePath
  if ((Test-Path -LiteralPath $path -PathType Leaf) -and -not $Force) {
    return
  }
  $parent = Split-Path -Parent $path
  if (!(Test-Path -LiteralPath $parent -PathType Container)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }
  [System.IO.File]::WriteAllText($path, $Content, $Utf8NoBom)
}

Ensure-Directory "Docs\1-需求文档"
Ensure-Directory $AppRepoDir

Write-TextIfMissing "TASKS.md" @"
# {{PROJECT_NAME}} 任务看板

> 实例化项目的初始任务看板。真实任务以当前项目节奏、交接卡和需求文档为准。

## 当前

- [ ] 填写项目卡：从 `项目配置/_模板.project.json` 复制到本机项目位置后补全。
- [ ] 补齐 `Docs/1-需求文档/` 的项目真实需求。
- [ ] 确认 `{{APP_REPO_DIR}}/` 是否指向真实业务仓库目录。

### 🟢 业务侧 P4b 历史债监控

| 范围 | 状态 | 处理口径 |
|---|---|---|
| `{{APP_REPO_DIR}}/src` | P4b 业务历史债；owner=开发 PM「实施者」 | 不代表操作系统未完成；按功能触发拆，不为数字单独动业务代码 |

#### P4b 业务债策略入口

- 测试膨胀：跟随测试重构或用例迁移处理。
- shared 生产逻辑：跟随真实业务功能改动处理。
- feature UI：跟随对应页面/组件迭代处理。
- app hook：跟随应用级入口或状态管理调整处理。
"@

Write-TextIfMissing "Docs\1-需求文档\README.md" @"
# {{PROJECT_NAME}} 需求文档

> 本目录承载实例化项目的真实需求文档；模板只提供入口，不预设业务内容。

## 起步

- 将当前项目 PRD、需求清单或阶段目标放到本目录。
- 若已有外部需求源，请在这里放索引和同步规则。
- 需求进入实施前，按 `操作系统/07_完整工作流/需求接收.md` 走 Q1-Q7。
"@

$textExt = @(".md", ".ps1", ".json", ".txt", ".yml", ".yaml", ".toml", ".cmd", ".bat")
$files = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File |
  Where-Object { $textExt -contains $_.Extension.ToLowerInvariant() }

foreach ($file in $files) {
  $text = [System.IO.File]::ReadAllText($file.FullName)
  $text = $text.Replace("{{PROJECT_ROOT}}", $ProjectRoot)
  $text = $text.Replace("{{PROJECT_ROOT_POSIX}}", $ProjectRootPosix)
  $text = $text.Replace("{{PROJECT_ROOT_LOWER}}", $ProjectRootLower)
  $text = $text.Replace("{{PROJECT_NAME}}", $ProjectName)
  $text = $text.Replace("{{APP_REPO_DIR}}", $AppRepoDir)
  $text = $text.Replace("{{PROJECT_SLUG}}", $ProjectSlug)
  $text = $text.Replace("{{APP_ID}}", $AppId)
  $text = $text.Replace("{{CURRENT_VERSION}}", $CurrentVersion)
  $text = $text.Replace("{{CURRENT_SPRINT}}", $CurrentSprint)
  $text = $text.Replace("{{INIT_TIME}}", $InitTime)
  [System.IO.File]::WriteAllText($file.FullName, $text, $Utf8NoBom)
}

$statePath = Join-Path $ProjectRoot "状态.md"
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
  $trackLine = "| $InitTime | 操作系统 PM「框架管家」 | 操作系统 PM「框架管家」 | 实例化操作系统到 `$ProjectRoot`：生成项目区/项目配置/需求入口/TASKS/业务仓库目录骨架，并完成占位符替换。 | ✅ Q1-Q7：framework / 操作系统 PM | ✅ |"
  [System.IO.File]::AppendAllText($statePath, "`n$trackLine", $Utf8NoBom)
}

Write-Host "✅ 操作系统已实例化到：$ProjectRoot"
Write-Host "下一步：在目标项目中 review/trust .codex hooks，并运行 能力资产/tools/scripts/check-operating-system.ps1。"
