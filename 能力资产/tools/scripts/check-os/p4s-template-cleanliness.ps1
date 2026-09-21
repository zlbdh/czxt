param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "framework-scope.ps1")
. (Join-Path $PSScriptRoot "adr-governance-truth.ps1")

if (-not (Test-IsTemplateRoot -Root $Root)) {
  Write-Host "  ℹ️ 非模板根模式：跳过模板纯净度守卫"
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
    [string]$Purpose = "模板当前真值"
  )

  $fullPath = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    $failures.Add("$RelativePath 缺失；无法验证${Purpose}")
    return
  }

  try {
    $text = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
  } catch {
    $failures.Add("$RelativePath 无法读取；无法验证${Purpose}：$($_.Exception.Message)")
    return
  }

  foreach ($term in $RequiredTerms) {
    if ($text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $failures.Add("$RelativePath 缺少「${Purpose}」锚点：$term")
    }
  }

  foreach ($term in $ForbiddenTerms) {
    $idx = $text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase)
    if ($idx -lt 0) { continue }
    $line = ($text.Substring(0, $idx) -split "`n").Count
    $failures.Add("$RelativePath`:L$line 仍含来源项目或过期当前事实：$term；应改为项目实例占位、真源指针或显式阶段判定")
  }
}

$currentTruthChecks = @(
  @{
    Path = "README.md"
    Purpose = "产品化阶段"
    Required = @("P1 已完成", "P2 未完成")
    Forbidden = @("准备进入长期产品化模板阶段", "再做首个受控提交")
  },
  @{
    Path = "操作系统/00_总入口.md"
    Purpose = "ADR 状态"
    Required = @("ADR 永久档案")
    Forbidden = @("38 ADR 永久现行")
  },
  @{
    Path = "操作系统/04_台账/长期产品化路线图.md"
    Purpose = "产品化阶段"
    Required = @("P1 已完成", "P2 未完成", "自托管首证")
    Forbidden = @("## P1 前验收")
  },
  @{
    Path = "Docs/3-开发文档/README.md"
    Purpose = "开发文档模板中立"
    Required = @("项目实例真值", "模板根不预设")
    Forbidden = @("Dexie schema 索引", "src/shared/database/schema.js")
  },
  @{
    Path = "Docs/3-开发文档/项目结构.md"
    Purpose = "中性目录导航"
    Required = @("模板根导航", "项目实例导航", "项目实例真值")
    Forbidden = @("AppShell.jsx", "health/Health.jsx", "accounting/Accounting.jsx", "timeline/Timeline.jsx")
  },
  @{
    Path = "Docs/3-开发文档/技术栈.md"
    Purpose = "技术栈填写模板"
    Required = @("项目实例真值", "[填写]")
    Forbidden = @("| React | 18.3.1 |", "| Dexie | 4.4.2 |", "APK 大小: 5.5 MB", "Bundle 大小（v2.2")
  },
  @{
    Path = "Docs/3-开发文档/API规范.md"
    Purpose = "API 填写模板"
    Required = @("项目实例真值", "协议层", "模型层", "[填写]")
    Forbidden = @("token-plan-sgp.xiaomimimo.com", "mimo-v2.5-pro", "### 4 个 AI 能力", "analyzeMealImage", "parseLedgerWithAI", "summarizeDay")
  },
  @{
    Path = "Docs/3-开发文档/数据库schema.md"
    Purpose = "数据库 Schema 填写模板"
    Required = @("项目实例真值", "迁移与兼容", "[填写]")
    Forbidden = @("当前 schema 版本：v16", "19 张业务表 + meta", "### userProfile", "### dailyTasks")
  },
  @{
    Path = "能力资产/skills/项目体检.md"
    Purpose = "P4s 能力说明"
    Required = @("定向当前真值检查", "项目实例真值")
    Forbidden = @()
  },
  @{
    Path = "能力资产/tools/依赖矩阵.md"
    Purpose = "依赖矩阵项目实例真值"
    Required = @("项目实例真值")
    Forbidden = @("mimo-v2.5-pro", "schema v1-v16", "^4.4.2")
  },
  @{
    Path = "能力资产/shared/品牌词典.md"
    Purpose = "品牌协议层与模型层分离"
    Required = @("协议层", "模型层")
    Forbidden = @("mimo-v2.5-pro", "token-plan-cn.xiaomimimo.com", "token-plan-sgp.xiaomimimo.com")
  },
  @{ Path = "操作系统/05_记忆/INDEX.md"; Purpose = "记忆项目身份"; Required = @("项目实例真值"); Forbidden = @("mimo-v2.5-pro", "小米自研 MiMo") }
)

foreach ($check in $currentTruthChecks) {
  Test-CurrentTruthFile -RelativePath $check.Path -RequiredTerms $check.Required -ForbiddenTerms $check.Forbidden -Purpose $check.Purpose
}

$adrTruth = Get-CzxtAdrGovernanceTruth -Root $Root
foreach ($failure in $adrTruth.Failures) {
  $failures.Add("ADR 真源失败：$failure")
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
  Test-CurrentTruthFile -RelativePath $playbook -RequiredTerms @("项目实例真值") -Purpose "现行 playbook"
}

$configDir = Join-Path $Root "项目配置"
if (Test-Path -LiteralPath $configDir -PathType Container) {
  foreach ($file in Get-ChildItem -LiteralPath $configDir -Filter "*.project.json" -File) {
    if ($file.Name -ne "_模板.project.json") {
      $rel = Get-RelativePathCompat -BasePath $Root -FullPath $file.FullName
      $failures.Add("$rel 不应进入模板仓库；具体项目卡请放本机项目目录或 项目区/本地实例/")
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
      $failures.Add("$rel 路径名发现来源项目残留：$term")
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
    $failures.Add("$rel`:L$line 发现来源项目残留：$term")
  }
}

if ($failures.Count -gt 0) {
  Write-Host "  🔴 模板纯净度失败：$($failures.Count) 处" -ForegroundColor Red
  foreach ($failure in $failures) { Write-Host "    - $failure" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ 模板纯净度通过：无具体项目卡 / 无已知来源项目残留 / 当前真值入口保持模板中立" -ForegroundColor Green
exit 0
