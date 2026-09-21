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
$InitTime = Get-Date -Format "yyyy-MM-dd HH:mm"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Utf8Bom = New-Object System.Text.UTF8Encoding($true)
. (Join-Path $TemplateRoot "能力资产\tools\scripts\installer-borrowing-zone.ps1")

$InstallerLayout = Resolve-CzxtInstallerLayout -ProjectRoot $ProjectRoot -AppRepoDir $AppRepoDir
$ProjectRoot = $InstallerLayout.ProjectRoot
$AppRepoDir = $InstallerLayout.AppRepoDir.Replace('\', '/')
$AppRepoPath = $InstallerLayout.AppRepoPath
$ProjectRootPosix = $ProjectRoot.Replace("\", "/")
$ProjectRootLower = $ProjectRoot.ToLowerInvariant()

$TemplateRootFull = [System.IO.Path]::GetFullPath($TemplateRoot)
if ($ProjectRootLower -eq $TemplateRootFull.ToLowerInvariant()) {
  throw "目标路径不能是模板根自身：$ProjectRoot"
}

$TargetTemplateMarker = Join-Path $ProjectRoot ".czxt-template-root"
if (Test-Path -LiteralPath $TargetTemplateMarker) {
  throw "目标已存在模板根标记，拒绝实例化：$TargetTemplateMarker"
}

if ([string]::IsNullOrWhiteSpace($ProjectSlug)) {
  $ProjectSlug = (($ProjectName.ToLowerInvariant()) -replace '[^a-z0-9]+','-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($ProjectSlug)) { $ProjectSlug = "project" }
}
if ([string]::IsNullOrWhiteSpace($AppId)) { $AppId = $ProjectSlug }

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

$copyPlan = New-Object 'Collections.Generic.List[object]'
foreach ($item in $copyItems) {
  $src = Join-Path $TemplateRoot $item
  if ((Test-Path -LiteralPath $src -PathType Container) -and
      (Test-CzxtInstallerPathsOverlapFinal -FirstPath $ProjectRoot -SecondPath $src)) {
    throw "ProjectRoot 与递归复制来源重叠，拒绝实例化：$src"
  }
  $dst = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $ProjectRoot $item) -Context ("复制目标 {0}" -f $item)
  if (!(Test-Path -LiteralPath $src)) {
    throw "模板缺少必要项：$item"
  }
  $copyPlan.Add((New-CzxtInstallerCopyPlanEntry -ProjectRoot $ProjectRoot `
      -SourcePath $src -TargetPath $dst -Item $item -Force:$Force))
}

if (!(Test-Path -LiteralPath $ProjectRoot)) {
  [void](New-CzxtInstallerBoundProjectRoot -ProjectRoot $ProjectRoot `
    -Context 'ProjectRoot')
}
[void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath $ProjectRoot -Context 'ProjectRoot')
$InstalledFiles = New-CzxtInstallerOutputManifest
$PreservedStatusState = $null

foreach ($entry in $copyPlan) {
  # 预检后再贴近落盘复核，避免 -Force 穿过既有 junction/reparse 写出项目根。
  $dst = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $entry.Target -Context ("复制目标 {0}" -f $entry.Item)
  if ($Force -and $entry.Item -ceq "状态.md" -and
      $null -ne $entry.ExpectedPresentState) {
    $PreservedStatusState = (Get-CzxtInstallerFileSnapshot `
        -ProjectRoot $ProjectRoot -TargetPath $dst -Context 'Force 保留状态轨迹' `
        -ExpectedTargetState $entry.ExpectedPresentState).State
    continue
  }
  Copy-CzxtInstallerTree -TemplateRoot $TemplateRoot -ProjectRoot $ProjectRoot `
    -SourcePath $entry.Source -TargetPath $dst `
    -ExpectAbsentTree:$entry.ExpectAbsentTree `
    -TreePlan $entry.TreePlan `
    -ExpectedPresentState $entry.ExpectedPresentState `
    -ExpectedSourceState $entry.ExpectedSourceState -InstalledFiles $InstalledFiles
}

# 项目区：只复制骨架（README/清单/.gitignore + 空 本地实例/.gitkeep），
# 绝不递归复制 本地实例/* —— 防自实例化时把生成中的实例反复拷进自己（无限套娃），
# 同时避免新项目继承模板的本地实例残留。
$pzSrc = Join-Path $TemplateRoot "项目区"
$pzDst = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath (Join-Path $ProjectRoot "项目区") -Context '项目区目标'
if (!(Test-Path -LiteralPath $pzSrc)) {
  throw "模板缺少必要项：项目区"
}
$pzWasPresent = Test-Path -LiteralPath $pzDst
if ($pzWasPresent -and -not $Force) {
  throw "目标已存在：$pzDst。若确认覆盖，请加 -Force。"
}
if ($pzWasPresent -and -not (Test-Path -LiteralPath $pzDst -PathType Container)) {
  throw "项目区目标不是目录：$pzDst"
}
$pzLocalInstances = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath (Join-Path $pzDst "本地实例") -Context '项目区本地实例目标'
[void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
  -TargetPath $pzLocalInstances -Context '项目区本地实例目标')
[void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath $pzLocalInstances -Context '项目区本地实例目标')
foreach ($pzFile in @("README.md", "清单.md", ".gitignore")) {
  $pzf = Join-Path $pzSrc $pzFile
  if (Test-Path -LiteralPath $pzf) {
    $pzfTarget = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath (Join-Path $pzDst $pzFile) -Context ("项目区复制目标 {0}" -f $pzFile)
    [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath $pzfTarget -Context ("项目区复制目标 {0}" -f $pzFile))
    Copy-CzxtInstallerBoundFile -ProjectRoot $ProjectRoot -SourcePath $pzf `
      -TargetPath $pzfTarget -Context ("项目区复制目标 {0}" -f $pzFile) `
      -AllowExisting:$Force -InstalledFiles $InstalledFiles
  }
}
$pzKeep = Join-Path $pzSrc "本地实例\.gitkeep"
if (Test-Path -LiteralPath $pzKeep) {
  $pzKeepTarget = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $pzLocalInstances ".gitkeep") -Context '项目区 .gitkeep 复制目标'
  [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $pzKeepTarget -Context '项目区 .gitkeep 复制目标')
  Copy-CzxtInstallerBoundFile -ProjectRoot $ProjectRoot -SourcePath $pzKeep `
    -TargetPath $pzKeepTarget -Context '项目区 .gitkeep 复制目标' `
    -AllowExisting:$Force -InstalledFiles $InstalledFiles
}

Copy-BorrowingZoneSkeleton -TemplateRoot $TemplateRoot -ProjectRoot $ProjectRoot `
  -Force:$Force -InstalledFiles $InstalledFiles

function Ensure-Directory {
  param([string]$RelativePath)
  $path = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $ProjectRoot $RelativePath) -Context ("目录目标 {0}" -f $RelativePath)
  [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
    -TargetPath $path -Context ("目录目标 {0}" -f $RelativePath))
}

function Write-TextIfMissing {
  param(
    [string]$RelativePath,
    [string]$Content
  )

  $path = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $ProjectRoot $RelativePath) -Context ("文本目标 {0}" -f $RelativePath)
  if ((Test-Path -LiteralPath $path -PathType Leaf) -and -not $Force) {
    return
  }
  $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
    -TargetPath $path -Context ("文本目标 {0}" -f $RelativePath) `
    -AllowExisting:$Force
  $parent = Split-Path -Parent $path
  if (!(Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context ("文本父目录 {0}" -f $RelativePath))
  }
  [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $path -Context ("文本目标 {0}" -f $RelativePath))
  Write-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $path `
    -Content $Content -Encoding $Utf8NoBom -Context ("文本目标 {0}" -f $RelativePath) `
    -ExpectAbsent:($expectation.Mode -eq 'ExpectAbsent') `
    -ExpectedPresentState $expectation.State `
    -InstalledFiles $InstalledFiles
}

Ensure-Directory "Docs\1-需求文档"
if (!(Test-Path -LiteralPath $AppRepoPath -PathType Container)) {
  [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
    -TargetPath $AppRepoPath -Context 'AppRepoDir')
}

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
$files = @(Get-CzxtInstallerOutputStates -InstalledFiles $InstalledFiles | ForEach-Object {
    [pscustomobject]@{
      FullName = $_.Path
      Extension = [IO.Path]::GetExtension($_.Path)
    }
  }) |
  Where-Object { $textExt -contains $_.Extension.ToLowerInvariant() } |
  Where-Object { Test-CzxtBorrowingPlaceholderRewriteAllowed -ProjectRoot $ProjectRoot -CandidatePath $_.FullName }

$rewriteParent = ''
$rewriteParentLease = $null
$renderValues = @{
  PROJECT_ROOT=$ProjectRoot; PROJECT_ROOT_POSIX=$ProjectRootPosix
  PROJECT_ROOT_LOWER=$ProjectRootLower; PROJECT_NAME=$ProjectName; APP_REPO_DIR=$AppRepoDir
  PROJECT_SLUG=$ProjectSlug; APP_ID=$AppId; CURRENT_VERSION=$CurrentVersion
  CURRENT_SPRINT=$CurrentSprint; INIT_TIME=$InitTime
}
try {
  foreach ($file in $files) {
    $fileParent = Get-CzxtBorrowingFullPath (Split-Path -Parent $file.FullName)
    if (-not $fileParent.Equals(
        $rewriteParent, [StringComparison]::OrdinalIgnoreCase)) {
      if ($null -ne $rewriteParentLease) {
        $rewriteParentLease.Native.Dispose()
        $rewriteParentLease = $null
      }
      $rewriteParent = $fileParent
    }
    $snapshot = Get-CzxtInstallerOutputTextSnapshot -ProjectRoot $ProjectRoot `
      -InstalledFiles $InstalledFiles -TargetPath $file.FullName -Context '占位符替换目标'
    $text = $snapshot.Text
    $rewritten = ConvertTo-CzxtInstallerRenderedText -Text $text `
      -Extension $file.Extension -Values $renderValues
    if ($rewritten -cne $text) {
      if ($null -eq $rewriteParentLease) {
        $rewriteParentLease = Open-CzxtInstallerParentDirectoryLease `
          -ProjectRoot $ProjectRoot -TargetPath $file.FullName `
          -Context '占位符替换父目录'
      }
      $writeEncoding = if ($file.Extension.Equals(".ps1", `
          [StringComparison]::OrdinalIgnoreCase)) {
        $Utf8Bom
      } else { $Utf8NoBom }
      Write-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $file.FullName `
        -Content $rewritten -Encoding $writeEncoding -Context '占位符替换目标' `
        -ExpectedPresentState $snapshot.State -InstalledFiles $InstalledFiles `
        -ParentDirectoryLease $rewriteParentLease
    }
  }
}
finally {
  if ($null -ne $rewriteParentLease) { $rewriteParentLease.Native.Dispose() }
}

$statePath = Join-Path $ProjectRoot "状态.md"
$trackLine = "| $InitTime | 操作系统 PM「框架管家」 | 操作系统 PM「框架管家」 | 实例化操作系统到 $ProjectRoot：生成项目区/项目配置/需求入口/TASKS/业务仓库目录骨架，并完成占位符替换。 | ✅ Q1-Q7：framework / 操作系统 PM | ✅ |"
$statePath = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath $statePath -Context '状态轨迹目标'
if ($null -ne $PreservedStatusState) {
  Set-CzxtInstallerOutputState -InstalledFiles $InstalledFiles `
    -State $PreservedStatusState
}
$stateExpected = Get-CzxtInstallerOutputState -InstalledFiles $InstalledFiles -Path $statePath
Add-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $statePath `
  -Content "`n$trackLine" -Encoding $Utf8NoBom -Context '状态轨迹目标' `
  -ExpectedPresentState $stateExpected -InstalledFiles $InstalledFiles

Complete-CzxtInstallerOutput -ProjectRoot $ProjectRoot -InstalledFiles $InstalledFiles `
  -Encoding $Utf8NoBom -Force:$Force -OnVerified {
    Write-Host "✅ 操作系统已实例化到：$ProjectRoot"
    Write-Host "下一步：在目标项目中 review/trust .codex hooks，并运行 能力资产/tools/scripts/check-operating-system.ps1。"
  }
