param(
  [ValidateSet("Check", "Apply")]
  [string]$Mode = "Check",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"

function Sanitize-Cell {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return "—" }
  return ($Value -replace '\|', '/' -replace '\r?\n', ' ').Trim()
}

function Get-AdrMetadata {
  param([System.IO.FileInfo]$File)
  $lines = Get-Content -LiteralPath $File.FullName -Encoding UTF8
  $id = [regex]::Match($File.BaseName, 'ADR-\d{3}').Value
  $title = $File.BaseName -replace '^ADR-\d{3}-', ''
  $status = "现行"
  $date = "—"

  foreach ($line in $lines) {
    if ($line -match '^#\s+ADR-\d{3}\s*[·\-—]\s*(.+)$') {
      $title = $matches[1].Trim()
    }
    if ($line -match '^\-\s+\*\*状态\*\*[:：]\s*(.+)$') {
      $status = $matches[1].Trim()
    }
    if ($line -match '^\-\s+\*\*日期\*\*[:：]\s*(.+)$') {
      $date = $matches[1].Trim()
    }
    if ($line -match '^##\s+') { break }
  }

  [pscustomobject]@{
    Id = $id
    Title = Sanitize-Cell $title
    Status = Sanitize-Cell $status
    Date = Sanitize-Cell $date
  }
}

function Parse-ExistingRows {
  param([string[]]$Lines)
  $rows = @{}
  foreach ($line in $Lines) {
    if ($line -match '^\| (ADR-\d{3}) \| .+ \| .+ \| .+ \|$') {
      $rows[$matches[1]] = $line
    }
  }
  return $rows
}

$adrDir = Join-Path $Root "Docs\3-开发文档\adr"
$readmePath = Join-Path $adrDir "README.md"
if (-not (Test-Path -LiteralPath $adrDir)) { throw "找不到 ADR 目录：$adrDir" }
if (-not (Test-Path -LiteralPath $readmePath)) { throw "找不到 ADR README：$readmePath" }

$readmeLines = Get-Content -LiteralPath $readmePath -Encoding UTF8
$existingRows = Parse-ExistingRows $readmeLines
$adrFiles = @(Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md" -File | Sort-Object Name)

$generatedRows = New-Object System.Collections.Generic.List[string]
foreach ($file in $adrFiles) {
  $meta = Get-AdrMetadata $file
  if ($existingRows.ContainsKey($meta.Id)) {
    $generatedRows.Add($existingRows[$meta.Id])
  } else {
    $generatedRows.Add("| $($meta.Id) | $($meta.Title) | $($meta.Status) | $($meta.Date) |")
  }
}

$tableStart = -1
for ($i = 0; $i -lt $readmeLines.Count; $i++) {
  if ($readmeLines[$i] -match '^\| 编号 \| 标题 \| 状态 \| 日期 \|$') {
    $tableStart = $i
    break
  }
}
if ($tableStart -lt 0) { throw "ADR README 中找不到索引表头" }

$tableEnd = $tableStart
while ($tableEnd + 1 -lt $readmeLines.Count -and $readmeLines[$tableEnd + 1] -match '^\|') {
  $tableEnd++
}

$newTable = @(
  "| 编号 | 标题 | 状态 | 日期 |",
  "|---|---|---|---|"
) + $generatedRows.ToArray()

$currentTable = $readmeLines[$tableStart..$tableEnd]
$needsUpdate = (($currentTable -join "`n") -ne ($newTable -join "`n"))

$countPattern = 'description: ADR 永久决策档案索引（\d+ 个 ADR'
$newLines = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $readmeLines.Count; $i++) {
  if ($i -eq $tableStart) {
    foreach ($line in $newTable) { $newLines.Add($line) }
    $i = $tableEnd
    continue
  }
  $lineToAdd = $readmeLines[$i]
  if ($lineToAdd -match $countPattern) {
    $lineToAdd = [regex]::Replace($lineToAdd, $countPattern, "description: ADR 永久决策档案索引（$($adrFiles.Count) 个 ADR")
  }
  $newLines.Add($lineToAdd)
}

$descriptionChanged = (($readmeLines -join "`n") -ne ($newLines.ToArray() -join "`n")) -and -not $needsUpdate
$changed = $needsUpdate -or $descriptionChanged

if ($changed -and $Mode -eq "Apply") {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($readmePath, (($newLines.ToArray()) -join "`r`n") + "`r`n", $utf8NoBom)
  Write-Host "✅ ADR README 已更新：$($adrFiles.Count) 个 ADR"
  exit 0
}

if ($changed) {
  Write-Host "🔴 ADR README 需要更新：$($adrFiles.Count) 个 ADR（运行 -Mode Apply 写入）" -ForegroundColor Red
  exit 10
}

Write-Host "✅ ADR README 已同步：$($adrFiles.Count) 个 ADR"
exit 0
