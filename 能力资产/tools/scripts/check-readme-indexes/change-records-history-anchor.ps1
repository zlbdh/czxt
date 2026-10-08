param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

$dir = Join-Path $Root "操作系统\00_变更记录"
if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
  Add-Failure "The 00_变更记录 directory is missing"
} else {
  $indexPath = Join-Path $dir "README.md"
  if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    Add-Failure "The 00_变更记录/README.md file is missing"
  } else {
    $indexText = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
    if ((-not $indexText.Contains('除 `CHANGELOG.md` 外') -and -not $indexText.Contains('Except for `CHANGELOG.md`')) -or (-not $indexText.Contains("不作为当前执行流程或当前真相源") -and -not $indexText.Contains("not current execution procedures or current sources of truth"))) {
      Add-Failure "00_变更记录/README.md lacks the directory-wide historical boundary"
    }
  }

  Get-ChildItem -LiteralPath $dir -File -Filter "*.md" |
    Where-Object { $_.Name -match '^CHANGELOG-2026|^agent-.*历史\.md$' } |
    ForEach-Object {
      $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
      $head = (($text -split "`r?`n") | Select-Object -First 18) -join "`n"
      $rel = $_.FullName.Substring($Root.Length).TrimStart('\')

      if ($head -notmatch "历史安全边界|Historical safety boundary" -or $head -notmatch "不可直接复制执行|Do not copy and execute directly") {
        Add-Failure "$rel lacks a historical safety boundary or prohibition on copying into execution near the top"
      }

      $boundaryMatch = [regex]::Match($text, "历史安全边界|Historical safety boundary")
      $boundaryIndex = if ($boundaryMatch.Success) { $boundaryMatch.Index } else { -1 }
      foreach ($term in @("下次归档触发", "新会话", "当前活的导航路径全部从 agent", "唯一入口", "Next archival trigger", "new session", "all currently active navigation paths start from", "sole entry point")) {
        $termIndex = $text.IndexOf($term)
        if ($termIndex -ge 0 -and ($boundaryIndex -lt 0 -or $termIndex -lt $boundaryIndex)) {
          Add-Failure "$rel contains potentially misleading current-sounding language before the historical safety boundary: $term"
        }
      }
    }
}

$readmeSpecPath = Join-Path $Root "操作系统\01_架构\README设计规范.md"
if (Test-Path -LiteralPath $readmeSpecPath -PathType Leaf) {
  $readmeSpecText = Get-Content -LiteralPath $readmeSpecPath -Raw -Encoding UTF8
  if ($readmeSpecText -match "历史归档/2026-05/议题全景-2026-05-22-历史快照\.md.*(?:ADR 永久现行表|permanent/current ADR table)") {
    Add-Failure "README设计规范.md incorrectly presents the issue-panorama historical snapshot as the current permanent-ADR table"
  }
  if ($readmeSpecText -notmatch "历史快照只作追溯抽检|Historical snapshots support traceability spot checks") {
    Add-Failure "README设计规范.md lacks the historical-snapshots-for-traceability-only explanation"
  }
}

foreach ($rel in @("操作系统\01_架构\元规则池.md", "操作系统\01_架构\工具载体矩阵.md")) {
  $path = Join-Path $Root $rel
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -match "本文件归档|This file is archived") {
      Add-Failure "$rel is an active document and must not claim that this file is archived"
    }
  }
}

foreach ($rel in @("操作系统\01_架构\工具载体矩阵.md", "操作系统\01_架构\元规则池-附录.md")) {
  $path = Join-Path $Root $rel
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -match "历史归档\\|历史归档/" -and $text -notmatch "历史愿景快照，仅追溯|以下仅作演化追溯|historical vision snapshot for traceability only|These support evolution traceability only") {
      Add-Failure "$rel cites a historical source without limiting it to traceability"
    }
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ Change-record archive boundaries near document tops aligned" -ForegroundColor Green
exit 0
