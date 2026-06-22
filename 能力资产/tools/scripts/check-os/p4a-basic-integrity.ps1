param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path,
  [object]$Failures = $null,
  [object]$Warnings = $null,
  [object]$Passes = $null
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "framework-scope.ps1")

$localFailures = New-Object System.Collections.Generic.List[string]
$localWarnings = New-Object System.Collections.Generic.List[string]
$localPasses = New-Object System.Collections.Generic.List[string]

$failureSink = $localFailures
if ($null -ne $Failures) { $failureSink = $Failures }
$warningSink = $localWarnings
if ($null -ne $Warnings) { $warningSink = $Warnings }
$passSink = $localPasses
if ($null -ne $Passes) { $passSink = $Passes }
$isTemplateRoot = Test-IsTemplateRoot -Root $Root

function Test-RequiredFile {
  param([string]$RelativePath)
  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $failureSink.Add("🔴 缺必查文件：$RelativePath")
  } else {
    $passSink.Add($RelativePath)
  }
}

function Test-OptionalFile {
  param([string]$RelativePath)
  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $warningSink.Add("🟡 缺可选文件（低活跃）：$RelativePath")
  } else {
    $passSink.Add($RelativePath)
  }
}

function Test-RequiredDirectory {
  param([string]$RelativePath)
  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Container)) {
    $failureSink.Add("🔴 缺必查目录：$RelativePath")
  } else {
    $passSink.Add($RelativePath)
  }
}

function Test-InstallerCopyItems {
  param([string[]]$ExpectedItems)

  $installerRel = "实例化项目.ps1"
  $installerPath = Join-Path $Root $installerRel
  if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    $failureSink.Add("🔴 缺实例化脚本：$installerRel")
    return
  }

  $scriptText = Get-Content -LiteralPath $installerPath -Raw -Encoding UTF8
  $match = [regex]::Match($scriptText, '\$copyItems\s*=\s*@\((?<body>[\s\S]*?)\)')
  if (-not $match.Success) {
    $failureSink.Add("🔴 实例化脚本未找到 `$copyItems 清单")
    return
  }

  $items = @([regex]::Matches($match.Groups["body"].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
  foreach ($item in $ExpectedItems) {
    if ($items -notcontains $item) {
      $failureSink.Add("🔴 实例化脚本 `$copyItems 缺少：$item")
    } else {
      $passSink.Add("实例化脚本复制清单：$item")
    }
  }
}

function Test-InstallerProjectZoneSkeleton {
  $installerRel = "实例化项目.ps1"
  $installerPath = Join-Path $Root $installerRel
  if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    $failureSink.Add("🔴 缺实例化脚本：$installerRel")
    return
  }
  $scriptText = Get-Content -LiteralPath $installerPath -Raw -Encoding UTF8

  # 防递归回归：项目区 不得进 $copyItems 总递归复制清单（否则自实例化时无限套娃）
  $match = [regex]::Match($scriptText, '\$copyItems\s*=\s*@\((?<body>[\s\S]*?)\)')
  $copyItemList = @()
  if ($match.Success) {
    $copyItemList = @([regex]::Matches($match.Groups["body"].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
  }
  if ($copyItemList -contains "项目区") {
    $failureSink.Add("🔴 实例化脚本 `$copyItems 不应含 项目区（会递归套娃）：改为只拷骨架")
  } else {
    $passSink.Add("实例化脚本 项目区 未进总递归清单（防套娃）")
  }

  # 防漏拷回归：项目区 仍须以骨架方式复制（README/清单/.gitignore + 本地实例/.gitkeep）
  if (($scriptText -match '项目区') -and ($scriptText -match '本地实例') -and ($scriptText -match '\.gitkeep')) {
    $passSink.Add("实例化脚本 项目区 骨架复制（含 本地实例/.gitkeep）")
  } else {
    $failureSink.Add("🔴 实例化脚本缺 项目区 骨架复制（README/清单/.gitignore + 本地实例/.gitkeep）")
  }
}

$requiredFiles = @(
  "AGENTS.md", "状态.md", "README.md",
  "操作系统/00_总入口.md",
  "操作系统/01_架构/角色边界.md", "操作系统/01_架构/元规则池.md",
  "操作系统/01_架构/演化哲学.md", "操作系统/01_架构/状态机.md",
  "操作系统/04_台账/INDEX.md",
  "操作系统/04_台账/Sprint节奏.md",
  "操作系统/04_台账/版本时间线.md",
  "操作系统/04_台账/议题全景.md",
  "操作系统/04_台账/项目沉淀/README.md",
  "操作系统/05_记忆/INDEX.md", "操作系统/05_记忆/行为反思.md",
  "操作系统/05_记忆/项目历史指针.md", "操作系统/05_记忆/AppData-memory退役清单.md",
  "操作系统/05_记忆/scope-schema.md",
  "操作系统/02_智能体/共享技能/INDEX.md",
  "能力资产/README.md",
  "能力资产/agents/README.md", "能力资产/workflows/README.md",
  "能力资产/shared/README.md", "能力资产/mcp/README.md", "能力资产/mcp/INSTALLED.md",
  "能力资产/rules/README.md", "能力资产/tools/README.md", "能力资产/skills/README.md",
  "能力资产/skills/项目体检.md", "能力资产/skills/项目体检-检查项.md",
  "能力资产/skills/项目体检-检查项-5-6.md", "能力资产/skills/项目体检-检查项-7-8.md",
  "能力资产/skills/状态推断.md", "能力资产/skills/状态推断-推断项.md",
  "能力资产/skills/状态推断-跨session监控.md", "能力资产/skills/状态推断-跨session监控-附录.md",
  "能力资产/rules/git-commit-编码规范.md",
  "能力资产/tools/scripts/check-operating-system.ps1",
  "能力资产/tools/scripts/check-os/check-plan.ps1",
  "能力资产/tools/scripts/check-os/check-plan-assert.ps1",
  "能力资产/tools/scripts/check-os/p4m-command-scan.ps1",
  "能力资产/tools/scripts/check-os/p4b-size-classification.ps1",
  "能力资产/tools/scripts/check-handoff-zone/report.ps1",
  "能力资产/tools/scripts/check-pm-tracking.ps1",
  "Docs/3-开发文档/README.md",
  "Docs/3-开发文档/adr/README.md", "Docs/7-复盘/README.md"
)

if ($isTemplateRoot) {
  $requiredFiles += @(
    ".gitignore",
    "实例化项目.ps1",
    "项目配置/README.md",
    "项目配置/_模板.project.json",
    "项目配置/.gitkeep",
    "项目区/.gitignore",
    "项目区/README.md",
    "项目区/清单.md",
    "项目区/本地实例/.gitkeep"
  )
} else {
  $requiredFiles += @("TASKS.md")
}

$optionalFiles = @("操作系统/00_变更记录/CHANGELOG.md")

$requiredDirs = @(
  "操作系统", "操作系统/01_架构", "操作系统/02_智能体", "操作系统/04_台账", "操作系统/05_记忆",
  "能力资产", "能力资产/agents", "能力资产/workflows", "能力资产/shared", "能力资产/mcp",
  "能力资产/skills", "能力资产/rules", "能力资产/tools", "能力资产/tools/scripts",
  "Docs", "Docs/3-开发文档", "Docs/3-开发文档/adr", "Docs/7-复盘",
  "确认改动", "确认改动/待审批", "确认改动/已审批",
  "确认改动/已审批/进行中", "确认改动/已审批/已完成",
  "交接区", "交接区/待接手", "交接区/已接手",
  "PM工作区"
)

if ($isTemplateRoot) {
  $requiredDirs += @("项目配置", "项目区", "项目区/本地实例")
} else {
  $requiredDirs += @("Docs/1-需求文档", "{{APP_REPO_DIR}}")
}

foreach ($f in $requiredFiles) { Test-RequiredFile $f }
foreach ($f in $optionalFiles) { Test-OptionalFile $f }
foreach ($d in $requiredDirs) { Test-RequiredDirectory $d }

if ($isTemplateRoot) {
  Test-InstallerCopyItems @(
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
  Test-InstallerProjectZoneSkeleton
}

Write-Host ("  ✅ P4a 通过项：{0}" -f $passSink.Count) -ForegroundColor Green
if ($localFailures.Count -gt 0) {
  exit 10
}
exit 0
