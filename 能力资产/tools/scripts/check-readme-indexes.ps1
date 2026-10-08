param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"
# Child checks calculate relative paths from Root.Length or the Root prefix; always pass an absolute root.
$Root = (Resolve-Path -LiteralPath $Root).Path
$failures = @()
$isTemplateRoot = $false
$frameworkScope = Join-Path $PSScriptRoot "check-os\framework-scope.ps1"
if (Test-Path -LiteralPath $frameworkScope -PathType Leaf) {
  . $frameworkScope
  $isTemplateRoot = Test-IsTemplateRoot -Root $Root
}

function Count-Lines {
  param(
    [string]$Path,
    [string]$Pattern
  )
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  return @((Select-String -LiteralPath $Path -Pattern $Pattern)).Count
}

function Add-Failure {
  param([string]$Message)
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Count-PropFiles {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return 0 }
  return @(
    Get-ChildItem -LiteralPath $Path -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -ne "_模板.md" }
  ).Count
}

Write-Host "🔎 README / INDEX consistency check"

$adrDir = Join-Path $Root "Docs\3-开发文档\adr"
$adrReadme = Join-Path $adrDir "README.md"
$adrFiles = @()
if (Test-Path -LiteralPath $adrDir) {
  $adrFiles = @(Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md" -File)
}
$adrRows = Count-Lines -Path $adrReadme -Pattern '^\| ADR-'
if ($adrFiles.Count -eq $adrRows) {
  Write-Host "  ✅ ADR README: files $($adrFiles.Count) = README rows $adrRows"
} else {
  Add-Failure "ADR README mismatch: files $($adrFiles.Count) vs README rows $adrRows"
}

$propReadme = Join-Path $Root "确认改动\README.md"
if (Test-Path -LiteralPath $propReadme) {
  $propTruth = [ordered]@{
    "待审批" = Count-PropFiles (Join-Path $Root "确认改动\待审批")
    "进行中" = Count-PropFiles (Join-Path $Root "确认改动\已审批\进行中")
    "已完成" = Count-PropFiles (Join-Path $Root "确认改动\已审批\已完成")
    "已弃用" = Count-PropFiles (Join-Path $Root "确认改动\已审批\已弃用")
    "拒绝" = Count-PropFiles (Join-Path $Root "确认改动\拒绝")
  }
  $propText = Get-Content -LiteralPath $propReadme -Raw -Encoding UTF8
  $propMatch = [regex]::Match($propText, '(?m)^\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|')
  if ($propMatch.Success) {
    $claimed = @(
      [int]$propMatch.Groups[1].Value,
      [int]$propMatch.Groups[2].Value,
      [int]$propMatch.Groups[3].Value,
      [int]$propMatch.Groups[4].Value,
      [int]$propMatch.Groups[5].Value
    )
    $actual = @(
      $propTruth["待审批"],
      $propTruth["进行中"],
      $propTruth["已完成"],
      $propTruth["已弃用"],
      $propTruth["拒绝"]
    )
    $claimedText = $claimed -join "/"
    $actualText = $actual -join "/"
    if ($claimedText -eq $actualText) {
      Write-Host "  ✅ PROP README: $claimedText = actual $actualText"
    } else {
      Add-Failure "PROP README mismatch: README $claimedText vs actual $actualText"
    }
  } else {
    Add-Failure "PROP README has no five-column count row"
  }
} else {
  Add-Failure "Missing 确认改动/README.md"
}

$poolPath = Join-Path $Root "操作系统\01_架构\元规则池.md"
if (Test-Path -LiteralPath $poolPath) {
  $poolText = Get-Content -LiteralPath $poolPath -Raw -Encoding UTF8
  $declaredMatch = [regex]::Match($poolText, '## (?:二、|2\. The )(\d+) (?:已永久化元规则|permanent meta-rules)')
  $declared = if ($declaredMatch.Success) { [int]$declaredMatch.Groups[1].Value } else { -1 }
  $sectionMatch = [regex]::Match($poolText, '(?s)## (?:二、|2\. ).*?(\| (?:编号|ID) \|.*?)(?:\r?\n## (?:三、|3\. ))')
  $poolRows = 0
  if ($sectionMatch.Success) {
    $poolRows = @([regex]::Matches($sectionMatch.Groups[1].Value, '(?m)^\| \*\*')).Count
  }
  if ($declared -eq $poolRows -and $declared -ge 0) {
    Write-Host "  ✅ Meta-rule pool: declared $declared = table rows $poolRows"
  } else {
    Add-Failure "Meta-rule pool mismatch: declared $declared vs table rows $poolRows"
  }
} else {
  Add-Failure "Missing 元规则池.md"
}

$panoramaPaths = @(
  (Join-Path $Root "操作系统\04_台账\议题全景.md"),
  (Join-Path $Root "操作系统\04_台账\历史归档\2026-05\议题全景-2026-05-22-历史快照.md")
)
$panoramaFound = $false
foreach ($panoramaPath in $panoramaPaths) {
  if (Test-Path -LiteralPath $panoramaPath) {
    $panoramaFound = $true
  }
}
if ($panoramaFound) {
  Write-Host "  ℹ️ Issue panorama ADR scan complete (current document and historical snapshot; manually maintained semantic tables do not automatically block)"
} else {
  Write-Host "  🟡 Missing 议题全景.md (informational)" -ForegroundColor Yellow
}

$templateSkip = @("github-actions-anchor.ps1","docs-edge-ops-anchor.ps1","docs-edge-history-anchor.ps1","product-docs-anchor.ps1","ledger-spec-anchor.ps1","smoke-history-semantics-anchor.ps1","prop-template-anchor.ps1")

foreach ($helper in @(
  "os-main-entry-anchor.ps1",
  "tool-governance-anchor.ps1",
  "tools-governance-history-anchor.ps1",
  "hooks-doc-count-anchor.ps1",
  "hooks-sop-anchor.ps1",
  "hooks-event-matrix-anchor.ps1",
  "issue-panorama-history-anchor.ps1",
  "dev-docs-anchor.ps1",
  "github-actions-anchor.ps1",
  "docs-edge-ops-anchor.ps1",
  "docs-edge-history-anchor.ps1",
  "adr-history-anchor.ps1",
  "product-docs-anchor.ps1",
  "change-records-history-anchor.ps1",
  "audit-coverage-anchor.ps1",
  "ledger-spec-anchor.ps1",
  "memory-spec-anchor.ps1",
  "workflow-spec-anchor.ps1",
  "architecture-anchor.ps1",
  "agents-playbook-anchor.ps1",
  "shared-skills-safety-anchor.ps1",
  "handoff-spec-anchor.ps1",
  "retro-history-anchor.ps1",
  "smoke-history-semantics-anchor.ps1",
  "governance-semantics-anchor.ps1",
  "borrowing-governance-anchor.ps1",
  "os-semantics-anchor.ps1",
  "prop-status-anchor.ps1",
  "prop-active-safety-anchor.ps1",
  "prop-template-anchor.ps1",
  "pm-workspace-anchor.ps1",
  "p4b-business-debt-anchor.ps1",
  "markdown-links-anchor.ps1"
)) {
  if ($isTemplateRoot -and ($templateSkip -contains $helper)) {
    Write-Host "  ℹ️ Template root skips source-project anchors in $helper" -ForegroundColor Gray
    continue
  }
  $helperPath = Join-Path $PSScriptRoot "check-readme-indexes\$helper"
  if (-not (Test-Path -LiteralPath $helperPath)) {
    Add-Failure "Missing $helper"
    continue
  }
  & $helperPath -Root $Root
  if ($LASTEXITCODE -ne 0) { Add-Failure "$helper check failed" }
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "🔴 README / INDEX consistency check failed: $($failures.Count) items" -ForegroundColor Red
  exit 10
}

Write-Host "✅ README / INDEX consistency check passed"
exit 0
