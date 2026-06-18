param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
. (Join-Path $PSScriptRoot "anchor-common.ps1")
. (Join-Path $PSScriptRoot "prop-status-helpers.ps1")
$isTemplateRoot = $false
$rootReadmeForMode = Join-Path $Root "README.md"
if (Test-Path -LiteralPath $rootReadmeForMode -PathType Leaf) {
  $rootModeText = Get-Content -LiteralPath $rootReadmeForMode -Raw -Encoding UTF8
  $isTemplateRoot = ($rootModeText -match '#\s*操作系统模板' -and $rootModeText -match '\{\{PROJECT_ROOT\}\}')
}

$propRoot = Join-Path $Root "确认改动"
$propStates = Get-PropStateSpecs
$propFiles = @(Get-ChildItem -LiteralPath $propRoot -Recurse -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_模板.md" })
$groups = $propFiles |
  ForEach-Object {
    $m = [regex]::Match($_.Name, '^PROP-(\d{3})')
    if ($m.Success) { [PSCustomObject]@{ Number = [int]$m.Groups[1].Value; Name = $_.Name } }
  } |
  Group-Object Number

foreach ($g in @($groups | Where-Object { $_.Count -gt 1 -and @(20, 27) -notcontains [int]$_.Name })) {
  Add-Failure "PROP 编号重复且未声明例外：PROP-$('{0:D3}' -f [int]$g.Name)"
}

$numbers = @($groups | ForEach-Object { [int]$_.Name } | Sort-Object -Unique)
if ($numbers.Count -gt 0) {
  $max = ($numbers | Measure-Object -Maximum).Maximum
  $missing = @(1..$max | Where-Object { $numbers -notcontains $_ })
  if ($missing.Count -gt 0) {
    Add-Failure "PROP 编号缺号：$($missing | ForEach-Object { 'PROP-' + ('{0:D3}' -f $_) } -join ', ')"
  }
}

foreach ($file in $propFiles) {
  $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
  $status = Get-PropHeaderStatus -Path $file.FullName -Rel $rel

  if ($rel -like "确认改动\已审批\已完成\PROP-020-路径D-方案v0.md") {
    if ($status -notmatch "附属方案") { Add-Failure "$rel 状态字段未声明附属方案" }
    continue
  }

  $matchedStates = @($propStates | Where-Object { $rel -like $_.RelPattern })
  if ($matchedStates.Count -eq 0) {
    Add-Failure "$rel 不在 PROP 五态目录"
  } elseif ($matchedStates.Count -gt 1) {
    Add-Failure "$rel 同时匹配多个 PROP 状态目录"
  } elseif ($status -notmatch $matchedStates[0].StatusPattern) {
    Add-Failure "$rel 位于$($matchedStates[0].Label)目录但状态字段不匹配：$status"
  }
}

$propReadme = Join-Path $Root "确认改动\README.md"
if (Test-Path -LiteralPath $propReadme -PathType Leaf) {
  $readmeText = Get-Content -LiteralPath $propReadme -Raw -Encoding UTF8
  if ($readmeText -match "谁都可以往这里放|zlbdh\s*/\s*咪咪\s*/\s*测试|已审批\s*·\s*实施中|状态字段改\s*\r?\n\s*「实施中」") {
    Add-Failure "确认改动/README.md 仍含绕过角色边界的写权或旧实施中状态口径"
  }
  foreach ($state in $propStates) {
    $linked = @{}
    $pattern = '\]\(' + [regex]::Escape($state.LinkPrefix) + '([^)]*?\.md)\)'
    foreach ($m in [regex]::Matches($readmeText, $pattern)) {
      $linked[$m.Groups[1].Value] = $true
    }
    $dir = Join-Path $Root $state.DirRel
    $files = @(
      Get-ChildItem -LiteralPath $dir -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "_模板.md" -and $_.Name -ne "PROP-020-路径D-方案v0.md" }
    )
    foreach ($file in $files) {
      if (-not $linked.ContainsKey($file.Name)) {
        Add-Failure "确认改动/README.md $($state.Label)明细漏链：$($file.Name)"
      }
    }
  }
}

$propTemplate = Join-Path $Root "确认改动\_模板.md"
if (Test-Path -LiteralPath $propTemplate -PathType Leaf) {
  $templateText = Get-Content -LiteralPath $propTemplate -Raw -Encoding UTF8
  if ($templateText -match "已审批\s*·\s*实施中|已审批\s*·\s*进行中|咪咪\s*/\s*测试发现") {
    Add-Failure "确认改动/_模板.md 仍含旧实施中状态或绕过 PM 白名单的提议人示例"
  }
}

$approvalDoc = Join-Path $Root "操作系统\07_完整工作流\审批与归档.md"
if (Test-Path -LiteralPath $approvalDoc -PathType Leaf) {
  $approvalText = Get-Content -LiteralPath $approvalDoc -Raw -Encoding UTF8
  if ($approvalText -match "已审批\s*·\s*实施中") {
    Add-Failure "操作系统/07_完整工作流/审批与归档.md 仍含旧实施中状态口径"
  }
}

$inProgressDir = Join-Path $Root "确认改动\已审批\进行中"
if (Test-Path -LiteralPath $inProgressDir -PathType Container) {
  foreach ($file in @(Get-ChildItem -LiteralPath $inProgressDir -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue)) {
    $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $head = if ($text.Length -gt 2400) { $text.Substring(0, 2400) } else { $text }
    if ($head -match "等\s*zlbdh\s*approve|Sprint-\d+\s*第\s*N\s*棒候选|P0\s*/\s*Sprint-\d+\s*候选") {
      Add-Failure "$rel 仍含旧开工诱导、旧 Sprint 候选或 P0 直开标签"
    }
  }
}

$prop037 = Join-Path $Root "确认改动\已审批\进行中\PROP-037-2026-05-22-记忆scope-YAML显式化.md"
if (Test-Path -LiteralPath $prop037 -PathType Leaf) {
  $text = Get-Content -LiteralPath $prop037 -Raw -Encoding UTF8
  if ($text -match "低价值 backlog|暂搁|未阻塞" -and $text -notmatch "待重审") {
    Add-Failure "PROP-037 已暂搁但状态未显式待重审"
  }
}

$prop039 = Join-Path $Root "确认改动\已审批\进行中\PROP-039-2026-05-22-Mem0+Skills-SDK集成.md"
if (Test-Path -LiteralPath $prop039 -PathType Leaf) {
  $text = Get-Content -LiteralPath $prop039 -Raw -Encoding UTF8
  if ($text -match "等待 SDK GA 后推进|等 SDK GA|未 GA / 等" -or $text -notmatch "已重估拆分") {
    Add-Failure "PROP-039 未反映已重估拆分，或仍以 SDK 未 GA 作为当前阻塞"
  }
}

$rootReadme = Join-Path $Root "README.md"
if ((Test-Path -LiteralPath $rootReadme -PathType Leaf) -and -not $isTemplateRoot) {
  $rootText = Get-Content -LiteralPath $rootReadme -Raw -Encoding UTF8
  if ($rootText -match "都等外部条件|PROP-039.*等.*GA|PROP-039.*未 GA" -or $rootText -notmatch "PROP-039.*已重估拆分") {
    Add-Failure "根 README 进行中 PROP 摘要未反映 PROP-039 已重估拆分"
  }
} elseif ($isTemplateRoot) {
  Write-Host "  ℹ️ 模板根模式：跳过来源项目进行中 PROP 摘要锚点" -ForegroundColor Gray
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ PROP 编号/状态字段语义对齐" -ForegroundColor Green
exit 0
