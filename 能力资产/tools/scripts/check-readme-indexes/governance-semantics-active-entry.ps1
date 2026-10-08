$statePath = Join-Path $Root "状态.md"
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
  $stateHead = (Get-Content -LiteralPath $statePath -TotalCount 120 -Encoding UTF8) -join "`n"
  if ($stateHead -match 'P4a[-–]P4p|P4j[-–]P4p|主-元-子-子子|git\s+push\s+origin\s+master|hotfix/|创建\s+hotfix\s+分支|AskUserQuestion|TaskCreate|Set-Content\s+-Encoding\s+utf8NoBOM') {
    Add-Failure "The first 120 lines of 状态.md contain obsolete current-guidance terms"
  }
}

$pendingDir = Join-Path $Root "交接区\待接手"
if (Test-Path -LiteralPath $pendingDir -PathType Container) {
  foreach ($card in Get-ChildItem -LiteralPath $pendingDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
    $text = Get-Content -LiteralPath $card.FullName -Raw -Encoding UTF8
    if ($text -match 'git\s+push\s+origin\s+master|hotfix/|创建\s+hotfix\s+分支|AskUserQuestion|TaskCreate|chat 简版\s*⑥(?!.*①-⑦)') {
      Add-Failure "Pending handoff contains obsolete current-guidance terms: $($card.Name)"
    }
  }
}

foreach ($rel in @(
  "Docs\3-开发文档\README.md",
  "Docs\7-复盘\README.md",
  "确认改动\README.md",
  "交接区\README.md"
)) {
  $path = Join-Path $Root $rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  $normalized = $text -replace '禁止\s*TODO', 'SAFE-TODO' -replace '不可直接复制执行', 'SAFE-HISTORY'
  if ($normalized -match '(?i)\bTODO\b|TBD|待补|待完善|占位|填实') {
    Add-Failure "Active entry contains placeholders or incomplete-content language: $rel"
  }
}
