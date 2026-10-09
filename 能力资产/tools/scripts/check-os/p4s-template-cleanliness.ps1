param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "framework-scope.ps1")
. (Join-Path $PSScriptRoot "adr-governance-truth.ps1")

if (-not (Test-IsTemplateRoot -Root $Root)) {
  Write-Host "  ℹ️ Not a template root; skipping template-neutrality guard"
  exit 0
}

$failures = New-Object System.Collections.Generic.List[string]

function Get-RelativePathCompat {
  param([string]$BasePath, [string]$FullPath)

  $base = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
  $full = [System.IO.Path]::GetFullPath($FullPath)
  if ($full.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($base.Length)
  }
  return $full
}

function Test-CurrentTruthFile {
  param(
    [string]$RelativePath,
    [string[]]$RequiredTerms = @(),
    [string[]]$ForbiddenTerms = @(),
    [string]$Purpose = "current template truth"
  )

  $fullPath = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    $failures.Add("$RelativePath is missing; cannot verify ${Purpose}")
    return
  }

  try {
    $text = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
  } catch {
    $failures.Add("$RelativePath cannot be read; cannot verify ${Purpose}: $($_.Exception.Message)")
    return
  }

  # Exact translations of required semantic anchors; all existing requirements remain mandatory.
  $anchorAliases = @{
    "ADR 永久档案" = "permanent ADR records"
    "P1 已完成" = "P1 complete"
    "P2 未完成" = "P2 incomplete"
    "P1 complete" = "P1 已完成"
    "P2 incomplete" = "P2 未完成"
    "自托管首证" = "initial self-hosted evidence"
    "项目实例真值" = "project instance source of truth"
    "模板根不预设" = "template root does not prescribe"
    "模板根导航" = "template root navigation"
    "项目实例导航" = "project instance navigation"
    "[填写]" = "[fill in]"
    "协议层" = "protocol layer"
    "模型层" = "model layer"
    "迁移与兼容" = "migration and compatibility"
    "定向当前真值检查" = "targeted current-truth checks"
  }
  foreach ($term in $RequiredTerms) {
    $hasTerm = $text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    $hasAlias = $anchorAliases.ContainsKey($term) -and
      ($text.IndexOf($anchorAliases[$term], [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
    if (-not $hasTerm -and -not $hasAlias) {
      $failures.Add("$RelativePath is missing the ${Purpose} anchor: $term")
    }
  }

  # Translated stale assertions remain forbidden; localization must not bypass these gates.
  $forbiddenAliases = @{
    "准备进入长期产品化模板阶段" = "preparing to enter long-term template productization"
    "再做首个受控提交" = "then make the first controlled commit"
    "38 ADR 永久现行" = "38 permanently current ADRs"
    "## P1 前验收" = "## Pre-P1 acceptance"
    "Dexie schema 索引" = "Dexie schema index"
    "APK 大小: 5.5 MB" = "APK size: 5.5 MB"
    "Bundle 大小（v2.2" = "Bundle size (v2.2"
    "### 4 个 AI 能力" = "### 4 AI capabilities"
    "当前 schema 版本：v16" = "Current schema version: v16"
    "19 张业务表 + meta" = "19 business tables + meta"
    "小米自研 MiMo" = "Xiaomi's in-house MiMo"
  }
  foreach ($term in $ForbiddenTerms) {
    $variants = @($term)
    if ($forbiddenAliases.ContainsKey($term)) { $variants += $forbiddenAliases[$term] }
    foreach ($variant in $variants) {
      $idx = $text.IndexOf($variant, [System.StringComparison]::OrdinalIgnoreCase)
      if ($idx -lt 0) { continue }
      $line = ($text.Substring(0, $idx) -split "`n").Count
      $failures.Add("$RelativePath`:L$line still contains source-project or stale current facts: $variant; use an instance placeholder, authoritative-source pointer, or explicit stage assessment")
    }
  }
}

$currentTruthChecks = @(
  @{
    Path = "README.md"
    Purpose = "Productization stage"
    Required = @("P1 complete", "P2 incomplete")
    Forbidden = @("准备进入长期产品化模板阶段", "再做首个受控提交")
  },
  @{
    Path = "操作系统/00_总入口.md"
    Purpose = "ADR status"
    Required = @("ADR 永久档案")
    Forbidden = @("38 ADR 永久现行")
  },
  @{
    Path = "操作系统/04_台账/长期产品化路线图.md"
    Purpose = "Productization stage"
    Required = @("P1 已完成", "P2 未完成", "自托管首证")
    Forbidden = @("## P1 前验收")
  },
  @{
    Path = "Docs/3-开发文档/README.md"
    Purpose = "Development-document template neutrality"
    Required = @("项目实例真值", "模板根不预设")
    Forbidden = @("Dexie schema 索引", "src/shared/database/schema.js")
  },
  @{
    Path = "Docs/3-开发文档/项目结构.md"
    Purpose = "Neutral directory navigation"
    Required = @("模板根导航", "项目实例导航", "项目实例真值")
    Forbidden = @("AppShell.jsx", "health/Health.jsx", "accounting/Accounting.jsx", "timeline/Timeline.jsx")
  },
  @{
    Path = "Docs/3-开发文档/技术栈.md"
    Purpose = "Technology-stack template"
    Required = @("项目实例真值", "[填写]")
    Forbidden = @("| React | 18.3.1 |", "| Dexie | 4.4.2 |", "APK 大小: 5.5 MB", "Bundle 大小（v2.2")
  },
  @{
    Path = "Docs/3-开发文档/API规范.md"
    Purpose = "API template"
    Required = @("项目实例真值", "协议层", "模型层", "[填写]")
    Forbidden = @("token-plan-sgp.xiaomimimo.com", "mimo-v2.5-pro", "### 4 个 AI 能力", "analyzeMealImage", "parseLedgerWithAI", "summarizeDay")
  },
  @{
    Path = "Docs/3-开发文档/数据库schema.md"
    Purpose = "Database schema template"
    Required = @("项目实例真值", "迁移与兼容", "[填写]")
    Forbidden = @("当前 schema 版本：v16", "19 张业务表 + meta", "### userProfile", "### dailyTasks")
  },
  @{
    Path = "能力资产/skills/项目体检.md"
    Purpose = "P4s capability description"
    Required = @("定向当前真值检查", "项目实例真值")
    Forbidden = @()
  },
  @{
    Path = "能力资产/tools/依赖矩阵.md"
    Purpose = "Dependency-matrix project instance source of truth"
    Required = @("项目实例真值")
    Forbidden = @("mimo-v2.5-pro", "schema v1-v16", "^4.4.2")
  },
  @{
    Path = "能力资产/shared/品牌词典.md"
    Purpose = "Brand protocol/model layer separation"
    Required = @("协议层", "模型层")
    Forbidden = @("mimo-v2.5-pro", "token-plan-cn.xiaomimimo.com", "token-plan-sgp.xiaomimimo.com")
  },
  @{ Path = "操作系统/05_记忆/INDEX.md"; Purpose = "Project identity in memory"; Required = @("项目实例真值"); Forbidden = @("mimo-v2.5-pro", "小米自研 MiMo") }
)

foreach ($check in $currentTruthChecks) {
  Test-CurrentTruthFile -RelativePath $check.Path -RequiredTerms $check.Required -ForbiddenTerms $check.Forbidden -Purpose $check.Purpose
}

$adrTruth = Get-CzxtAdrGovernanceTruth -Root $Root
foreach ($failure in $adrTruth.Failures) {
  $failures.Add("ADR source check failed: $failure")
}
foreach ($failure in @(Test-CzxtAdrMainEntryAnchor -Root $Root -Truth $adrTruth)) {
  $failures.Add($failure)
}

$currentPlaybooks = @(
  "操作系统/02_智能体/操作系统PM-框架管家.md",
  "操作系统/02_智能体/产品PM-需求拆解者.md",
  "操作系统/02_智能体/技术PM-修复决策者.md",
  "操作系统/02_智能体/测试PM-质量门户.md",
  "操作系统/02_智能体/开发PM-实施者.md",
  "操作系统/02_智能体/测试发布PM-闭环者.md",
  "操作系统/02_智能体/运营PM-运营咪咪.md"
)
foreach ($playbook in $currentPlaybooks) {
  Test-CurrentTruthFile -RelativePath $playbook -RequiredTerms @("项目实例真值") -Purpose "current playbook"
}

$configDir = Join-Path $Root "项目配置"
if (Test-Path -LiteralPath $configDir -PathType Container) {
  foreach ($file in Get-ChildItem -LiteralPath $configDir -Filter "*.project.json" -File) {
    if ($file.Name -ne "_模板.project.json") {
      $rel = Get-RelativePathCompat -BasePath $Root -FullPath $file.FullName
      $failures.Add("$rel must not enter the template repository; keep project-specific cards in the local project directory or 项目区/本地实例/")
    }
  }
}

$terms = @(
  ("小小" + "的我"),
  ("x" + "xdw"),
  ("com.zlbdh." + "mimi"),
  ("轻薄" + "肌"),
  ("小" + "眯"),
  ("知乎" + "首篇"),
  ("5-" + "Tab"),
  ("品牌" + "尽调"),
  ("A" + "阶段发布"),
  ("W1-" + "L1"),
  ("xiaoxiao" + "dewo")
)
$extensions = @(".md", ".ps1", ".json", ".txt", ".html", ".js", ".ts", ".jsx", ".tsx", ".yml", ".yaml")
$skipDirs = @("\.git\", "\本地实例\")

$files = Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Where-Object {
  $path = $_.FullName
  foreach ($skip in $skipDirs) {
    if ($path -like "*$skip*") { return $false }
  }
  $extensions -contains $_.Extension.ToLowerInvariant()
}

foreach ($file in $files) {
  $rel = Get-RelativePathCompat -BasePath $Root -FullPath $file.FullName
  foreach ($term in $terms) {
    if ($rel.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
      $failures.Add("$rel path contains source-project remnants: $term")
    }
  }

  try {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  } catch {
    continue
  }
  foreach ($term in $terms) {
    $idx = $text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase)
    if ($idx -lt 0) { continue }
    $line = ($text.Substring(0, $idx) -split "`n").Count
    $failures.Add("$rel`:L$line contains source-project remnants: $term")
  }
}

if ($failures.Count -gt 0) {
  Write-Host "  🔴 Template-neutrality check failed: $($failures.Count) findings" -ForegroundColor Red
  foreach ($failure in $failures) { Write-Host "    - $failure" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ Template-neutrality check passed: no specific-project cards or known source-project remnants; current-truth entries remain neutral" -ForegroundColor Green
exit 0
