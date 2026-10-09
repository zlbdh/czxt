param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

$activeDir = Join-Path $Root "确认改动\已审批\进行中"
foreach ($file in Get-ChildItem -LiteralPath $activeDir -Filter "PROP-*.md" -File -ErrorAction SilentlyContinue) {
  $rel = $file.FullName.Substring($Root.Length).TrimStart('\')
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $head = (Get-Content -LiteralPath $file.FullName -TotalCount 16 -Encoding UTF8) -join "`n"

  if ($text -match "(?i)\.env\.local|apiKey|baseUrl|API key") {
    if ($head -notmatch "三类行为铁律|ADR-022|真实 key|tracked 文件|B 类|C 类") {
      Add-Failure "$rel contains sensitive configuration but lacks the ADR-022 / B-C boundary near the top"
    }
  }

  if ($text -match "(?i)\bpush\b|\btag\b|version|package\.json|APK") {
    if ($head -notmatch "ADR-016|测试发布 PM|B 类|失败.*停手|闭环者") {
      Add-Failure "$rel contains release/git/version semantics but lacks the ADR-016 / Test and Release PM boundary near the top"
    }
  }

  if ($text -match "backlog|待排期|待重审|待重估|外部能力跟踪|暂停") {
    if ($head -match "状态.*已审批\s*·\s*实施中" -and $head -notmatch "未收口") {
      Add-Failure "$rel is a backlog/reassessment PROP but its opening still states only implementation in progress"
    }
  }
}

$readmePath = Join-Path $Root "确认改动\README.md"
if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
  $readme = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
  if ($readme -notmatch "已审批·未收口|Approved · Open" -or $readme -notmatch "待重估|await scheduling, rereview, external capability tracking, or reassessment") {
    Add-Failure "The confirmed-change README does not describe the active directory as approved but unclosed / awaiting reassessment"
  }
  if ($readme -match "PROP-012.*git tag / 发版 / API key 仍 C 类" -and $readme -notmatch "现行见.*三类行为铁律|当前.*三类行为铁律") {
    Add-Failure "The confirmed-change README summary for PROP-012 may still misrepresent current git/tag/API boundaries"
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Active PROP sensitive-configuration and release boundaries are aligned" -ForegroundColor Green
exit 0
