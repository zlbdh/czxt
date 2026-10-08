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
  throw "Target path cannot be the template root itself: $ProjectRoot"
}

$TargetTemplateMarker = Join-Path $ProjectRoot ".czxt-template-root"
if (Test-Path -LiteralPath $TargetTemplateMarker) {
  throw "Target already has a template-root marker; refusing instantiation: $TargetTemplateMarker"
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
    throw "ProjectRoot overlaps a recursive copy source; refusing instantiation: $src"
  }
  $dst = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $ProjectRoot $item) -Context ("Copy target {0}" -f $item)
  if (!(Test-Path -LiteralPath $src)) {
    throw "Template is missing a required item: $item"
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
  # After preflight, recheck immediately before writing so -Force cannot traverse an existing junction/reparse point outside the project root.
  $dst = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $entry.Target -Context ("Copy target {0}" -f $entry.Item)
  if ($Force -and $entry.Item -ceq "状态.md" -and
      $null -ne $entry.ExpectedPresentState) {
    $PreservedStatusState = (Get-CzxtInstallerFileSnapshot `
        -ProjectRoot $ProjectRoot -TargetPath $dst -Context 'Force-preserved state history' `
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

# Project area: copy only scaffolding (README/checklist/.gitignore + empty 本地实例/.gitkeep).
# Never recursively copy 本地实例/*: self-instantiation would repeatedly copy the growing instance into itself (infinite nesting).
# Also prevent a new project from inheriting local-instance remnants from the template.
$pzSrc = Join-Path $TemplateRoot "项目区"
$pzDst = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath (Join-Path $ProjectRoot "项目区") -Context 'Project-area target'
if (!(Test-Path -LiteralPath $pzSrc)) {
  throw "Template is missing a required item: project area"
}
$pzWasPresent = Test-Path -LiteralPath $pzDst
if ($pzWasPresent -and -not $Force) {
  throw "Target already exists: $pzDst. Add -Force if you confirm overwriting."
}
if ($pzWasPresent -and -not (Test-Path -LiteralPath $pzDst -PathType Container)) {
  throw "Project-area target is not a directory: $pzDst"
}
$pzLocalInstances = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath (Join-Path $pzDst "本地实例") -Context 'Project-area local-instance target'
[void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
  -TargetPath $pzLocalInstances -Context 'Project-area local-instance target')
[void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath $pzLocalInstances -Context 'Project-area local-instance target')
foreach ($pzFile in @("README.md", "清单.md", ".gitignore")) {
  $pzf = Join-Path $pzSrc $pzFile
  if (Test-Path -LiteralPath $pzf) {
    $pzfTarget = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath (Join-Path $pzDst $pzFile) -Context ("Project-area copy target {0}" -f $pzFile)
    [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
      -CandidatePath $pzfTarget -Context ("Project-area copy target {0}" -f $pzFile))
    Copy-CzxtInstallerBoundFile -ProjectRoot $ProjectRoot -SourcePath $pzf `
      -TargetPath $pzfTarget -Context ("Project-area copy target {0}" -f $pzFile) `
      -AllowExisting:$Force -InstalledFiles $InstalledFiles
  }
}
$pzKeep = Join-Path $pzSrc "本地实例\.gitkeep"
if (Test-Path -LiteralPath $pzKeep) {
  $pzKeepTarget = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $pzLocalInstances ".gitkeep") -Context 'Project-area .gitkeep copy target'
  [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $pzKeepTarget -Context 'Project-area .gitkeep copy target')
  Copy-CzxtInstallerBoundFile -ProjectRoot $ProjectRoot -SourcePath $pzKeep `
    -TargetPath $pzKeepTarget -Context 'Project-area .gitkeep copy target' `
    -AllowExisting:$Force -InstalledFiles $InstalledFiles
}

Copy-BorrowingZoneSkeleton -TemplateRoot $TemplateRoot -ProjectRoot $ProjectRoot `
  -Force:$Force -InstalledFiles $InstalledFiles

function Ensure-Directory {
  param([string]$RelativePath)
  $path = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $ProjectRoot $RelativePath) -Context ("Directory target {0}" -f $RelativePath)
  [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
    -TargetPath $path -Context ("Directory target {0}" -f $RelativePath))
}

function Write-TextIfMissing {
  param(
    [string]$RelativePath,
    [string]$Content
  )

  $path = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath (Join-Path $ProjectRoot $RelativePath) -Context ("Text target {0}" -f $RelativePath)
  if ((Test-Path -LiteralPath $path -PathType Leaf) -and -not $Force) {
    return
  }
  $expectation = Get-CzxtInstallerTargetExpectation -ProjectRoot $ProjectRoot `
    -TargetPath $path -Context ("Text target {0}" -f $RelativePath) `
    -AllowExisting:$Force
  $parent = Split-Path -Parent $path
  if (!(Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-CzxtInstallerBoundDirectory -ProjectRoot $ProjectRoot `
      -TargetPath $parent -Context ("Text parent directory {0}" -f $RelativePath))
  }
  [void](Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
    -CandidatePath $path -Context ("Text target {0}" -f $RelativePath))
  Write-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $path `
    -Content $Content -Encoding $Utf8NoBom -Context ("Text target {0}" -f $RelativePath) `
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
# {{PROJECT_NAME}} Task Board

> Initial task board for the instantiated project. Actual tasks follow the current project cadence, handoff cards, and requirements documents.

## Current

- [ ] Complete the project card: copy `项目配置/_模板.project.json` to a local project location and fill it in.
- [ ] Add the project's actual requirements under `Docs/1-需求文档/`.
- [ ] Confirm that `{{APP_REPO_DIR}}/` points to the actual business repository directory.

### 🟢 Business P4b Historical Debt Monitoring

| Scope | Status | Handling policy |
|---|---|---|
| `{{APP_REPO_DIR}}/src` | P4b business historical debt; owner=Development PM 'Implementer' | Does not indicate unfinished operating-system work; split when a feature change calls for it, not solely to reduce a number |

#### P4b Business Debt Policy Entry

- Test growth: handle during test refactoring or test-case migration.
- Shared production logic: handle alongside actual business feature changes.
- Feature UI: handle during iteration on the corresponding page/component.
- App hooks: handle alongside application-level entry-point or state-management changes.
"@

Write-TextIfMissing "Docs\1-需求文档\README.md" @"
# {{PROJECT_NAME}} Requirements

> This directory holds actual requirements for the instantiated project; the template provides only an entry point and does not prescribe business content.

## Getting started

- Put the current project PRD, requirements list, or phase objectives here.
- If an external requirements source already exists, add its index and synchronization rules here.
- Before requirements enter implementation, follow Q1-Q7 in `操作系统/07_完整工作流/需求接收.md`.
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
      -InstalledFiles $InstalledFiles -TargetPath $file.FullName -Context 'Placeholder replacement target'
    $text = $snapshot.Text
    $rewritten = ConvertTo-CzxtInstallerRenderedText -Text $text `
      -Extension $file.Extension -Values $renderValues
    if ($rewritten -cne $text) {
      if ($null -eq $rewriteParentLease) {
        $rewriteParentLease = Open-CzxtInstallerParentDirectoryLease `
          -ProjectRoot $ProjectRoot -TargetPath $file.FullName `
          -Context 'Placeholder replacement parent directory'
      }
      $writeEncoding = if ($file.Extension.Equals(".ps1", `
          [StringComparison]::OrdinalIgnoreCase)) {
        $Utf8Bom
      } else { $Utf8NoBom }
      Write-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $file.FullName `
        -Content $rewritten -Encoding $writeEncoding -Context 'Placeholder replacement target' `
        -ExpectedPresentState $snapshot.State -InstalledFiles $InstalledFiles `
        -ParentDirectoryLease $rewriteParentLease
    }
  }
}
finally {
  if ($null -ne $rewriteParentLease) { $rewriteParentLease.Native.Dispose() }
}

$statePath = Join-Path $ProjectRoot "状态.md"
$trackLine = "| $InitTime | Operating System PM 'Framework Steward' | Operating System PM 'Framework Steward' | Instantiate the operating system at $ProjectRoot; generate scaffolding for the project area, project configuration, requirements entry, TASKS, and business repository directory, then replace placeholders. | ✅ Q1-Q7: framework / Operating System PM | ✅ |"
$statePath = Assert-CzxtInstallerTargetPath -ProjectRoot $ProjectRoot `
  -CandidatePath $statePath -Context 'State history target'
if ($null -ne $PreservedStatusState) {
  Set-CzxtInstallerOutputState -InstalledFiles $InstalledFiles `
    -State $PreservedStatusState
}
$stateExpected = Get-CzxtInstallerOutputState -InstalledFiles $InstalledFiles -Path $statePath
Add-CzxtInstallerTextFile -ProjectRoot $ProjectRoot -TargetPath $statePath `
  -Content "`n$trackLine" -Encoding $Utf8NoBom -Context 'State history target' `
  -ExpectedPresentState $stateExpected -InstalledFiles $InstalledFiles

Complete-CzxtInstallerOutput -ProjectRoot $ProjectRoot -InstalledFiles $InstalledFiles `
  -Encoding $Utf8NoBom -Force:$Force -OnVerified {
    Write-Host "✅ Operating system instantiated at: $ProjectRoot"
    Write-Host "Next: review/trust .codex hooks in the target project and run 能力资产/tools/scripts/check-operating-system.ps1."
  }
