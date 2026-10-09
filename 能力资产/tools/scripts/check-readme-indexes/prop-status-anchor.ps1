param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
. (Join-Path $PSScriptRoot "anchor-common.ps1")
. (Join-Path $PSScriptRoot "prop-status-helpers.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "check-os\framework-scope.ps1")
$isTemplateRoot = Test-IsTemplateRoot -Root $Root
$isLegacyProject = Test-IsCzxtLegacyProjectProfile -Root $Root

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
  Add-Failure "Duplicate PROP ID without a declared exception: PROP-$('{0:D3}' -f [int]$g.Name)"
}

$numbers = @($groups | ForEach-Object { [int]$_.Name } | Sort-Object -Unique)
if ($numbers.Count -gt 0) {
  $max = ($numbers | Measure-Object -Maximum).Maximum
  $missing = @(1..$max | Where-Object { $numbers -notcontains $_ })
  if ($missing.Count -gt 0) {
    Add-Failure "Missing PROP IDs: $($missing | ForEach-Object { 'PROP-' + ('{0:D3}' -f $_) } -join ', ')"
  }
}

foreach ($file in $propFiles) {
  $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
  $status = Get-PropHeaderStatus -Path $file.FullName -Rel $rel

  if ($rel -like "确认改动\已审批\已完成\PROP-020-路径D-方案v0.md") {
    if ($status -notmatch "附属方案") { Add-Failure "$rel status field does not identify the subsidiary proposal" }
    continue
  }

  $matchedStates = @($propStates | Where-Object { $rel -like $_.RelPattern })
  if ($matchedStates.Count -eq 0) {
    Add-Failure "$rel is outside the five PROP state directories"
  } elseif ($matchedStates.Count -gt 1) {
    Add-Failure "$rel matches multiple PROP state directories"
  } elseif ($status -notmatch $matchedStates[0].StatusPattern) {
    Add-Failure "$rel is in the $($matchedStates[0].Label) directory but its status field does not match: $status"
  }
}

$propReadme = Join-Path $Root "确认改动\README.md"
if (Test-Path -LiteralPath $propReadme -PathType Leaf) {
  $readmeText = Get-Content -LiteralPath $propReadme -Raw -Encoding UTF8
  if ($readmeText -match "谁都可以往这里放|zlbdh\s*/\s*咪咪\s*/\s*测试|已审批\s*·\s*实施中|状态字段改\s*\r?\n\s*「实施中」|Anyone may place a proposal here|zlbdh\s*/\s*Mimi\s*/\s*Testing|Approved\s*·\s*Implementing|set the status to\s*\r?\n\s*Implementing") {
    Add-Failure "确认改动/README.md still contains write permissions that bypass role boundaries or the old implementation-in-progress convention"
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
        Add-Failure "确认改动/README.md lacks a $($state.Label) detail link: $($file.Name)"
      }
    }
  }
}

$propTemplate = Join-Path $Root "确认改动\_模板.md"
if (Test-Path -LiteralPath $propTemplate -PathType Leaf) {
  $templateText = Get-Content -LiteralPath $propTemplate -Raw -Encoding UTF8
  if ($templateText -match "已审批\s*·\s*实施中|已审批\s*·\s*进行中|咪咪\s*/\s*测试发现|Approved\s*·\s*Implementing|Approved\s*·\s*In progress|Mimi\s*/\s*Testing findings") {
    Add-Failure "确认改动/_模板.md still contains the old implementation-in-progress state or an author example that bypasses PM allowlists"
  }
}

$approvalDoc = Join-Path $Root "操作系统\07_完整工作流\审批与归档.md"
if (Test-Path -LiteralPath $approvalDoc -PathType Leaf) {
  $approvalText = Get-Content -LiteralPath $approvalDoc -Raw -Encoding UTF8
  if ($approvalText -match "已审批\s*·\s*实施中") {
    Add-Failure "操作系统/07_完整工作流/审批与归档.md still uses the old implementation-in-progress convention"
  }
}

$inProgressDir = Join-Path $Root "确认改动\已审批\进行中"
if (Test-Path -LiteralPath $inProgressDir -PathType Container) {
  foreach ($file in @(Get-ChildItem -LiteralPath $inProgressDir -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue)) {
    $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $head = if ($text.Length -gt 2400) { $text.Substring(0, 2400) } else { $text }
    if ($head -match "等\s*zlbdh\s*approve|Sprint-\d+\s*第\s*N\s*棒候选|P0\s*/\s*Sprint-\d+\s*候选") {
      Add-Failure "$rel still contains old start-work prompts, an old Sprint candidate, or a direct-start P0 label"
    }
  }
}

$prop037 = Join-Path $Root "确认改动\已审批\进行中\PROP-037-2026-05-22-记忆scope-YAML显式化.md"
if (Test-Path -LiteralPath $prop037 -PathType Leaf) {
  $text = Get-Content -LiteralPath $prop037 -Raw -Encoding UTF8
  if ($text -match "低价值 backlog|暂搁|未阻塞" -and $text -notmatch "待重审") {
    Add-Failure "PROP-037 is deferred but its status does not explicitly await reassessment"
  }
}

$prop039 = Join-Path $Root "确认改动\已审批\进行中\PROP-039-2026-05-22-Mem0+Skills-SDK集成.md"
if (Test-Path -LiteralPath $prop039 -PathType Leaf) {
  $text = Get-Content -LiteralPath $prop039 -Raw -Encoding UTF8
  if ($text -match "等待 SDK GA 后推进|等 SDK GA|未 GA / 等" -or $text -notmatch "已重估拆分") {
    Add-Failure "PROP-039 does not reflect reassessment and splitting, or still treats the SDK not being GA as the current blocker"
  }
}

$rootReadme = Join-Path $Root "README.md"
if ((Test-Path -LiteralPath $rootReadme -PathType Leaf) -and $isLegacyProject) {
  $rootText = Get-Content -LiteralPath $rootReadme -Raw -Encoding UTF8
  if ($rootText -match "都等外部条件|PROP-039.*等.*GA|PROP-039.*未 GA" -or $rootText -notmatch "PROP-039.*已重估拆分") {
    Add-Failure "The root README active PROP summary does not reflect that PROP-039 was reassessed and split"
  }
} elseif (-not $isLegacyProject) {
  $profileLabel = if ($isTemplateRoot) { 'template-root mode' } else { 'generic project' }
  Write-Host "  ℹ️ ${profileLabel}: skipping active PROP summary anchors from the legacy source project" -ForegroundColor Gray
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ PROP IDs and status-field semantics are aligned" -ForegroundColor Green
exit 0
