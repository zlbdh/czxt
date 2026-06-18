param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
. (Join-Path $PSScriptRoot "p4o-markdown-link-utils.ps1")
. (Join-Path $PSScriptRoot "framework-scope.ps1")

$issues = New-Object System.Collections.Generic.List[string]
$files = New-Object System.Collections.Generic.List[object]
$linkCount = 0
$script:IsTemplateRoot = Test-IsTemplateRoot -Root $Root

function Add-File([string]$Path, [int]$MaxLines = 0) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ($MaxLines -gt 0) {
    $lines = $text -split "`r?`n"
    $text = ($lines | Select-Object -First $MaxLines) -join "`n"
  }
  $text = Remove-CodeFences $text
  $files.Add([PSCustomObject]@{ Path = $Path; Text = $text }) | Out-Null
}

function Add-Scope([string]$Rel) {
  $base = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $base -PathType Container)) { return }
  Get-ChildItem -LiteralPath $base -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-IsFrameworkArchivePath $_.FullName) -and $_.FullName -notmatch 'PM自纠\\PM自纠-' } |
    ForEach-Object { Add-File $_.FullName }
}

Add-Scope "操作系统"
Add-Scope "能力资产"
Add-Scope "交接区\待接手"

foreach ($entry in @(
  "交接区\README.md",
  "确认改动\README.md",
  "Docs\1-需求文档\功能清单.md",
  "Docs\1-需求文档\需求历史.md",
  "Docs\2-产品文档\产品介绍.md",
  "Docs\2-产品文档\信息架构.md",
  "Docs\2-产品文档\产品路线图.md",
  "Docs\3-开发文档\README.md",
  "Docs\3-开发文档\adr\README.md",
  "Docs\4-测试文档\测试策略.md",
  "Docs\7-复盘\RETRO-022-2026-06.md",
  "Docs\7-复盘\README.md"
)) {
  Add-File (Join-Path $Root $entry)
}

$pmRoot = Join-Path $Root "PM工作区"
if (Test-Path -LiteralPath $pmRoot -PathType Container) {
  Get-ChildItem -LiteralPath $pmRoot -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\README\.md$|\\速查表\\|\\PM自纠\\INDEX\.md$' } |
    ForEach-Object { Add-File $_.FullName }
}

foreach ($rf in @("README.md", "AGENTS.md", "TASKS.md")) {
  Add-File (Join-Path $Root $rf)
}
Add-File (Join-Path $Root "状态.md") 120

$slugCache = @{}
foreach ($f in $files) {
  foreach ($m in [regex]::Matches($f.Text, '(!?\[[^\]]*\]\(([^)]+)\))')) {
    Check-Link $f $m.Index $m.Groups[2].Value
  }

  $refs = @{}
  foreach ($m in [regex]::Matches($f.Text, '(?m)^\s{0,3}\[([^\]\^][^\]]*)\]:\s*(\S.*)$')) {
    $refLabel = Normalize-RefLabel $m.Groups[1].Value
    $refs[$refLabel] = $true
    Check-Link $f $m.Index $m.Groups[2].Value
  }
  foreach ($m in [regex]::Matches($f.Text, '(?<!!)\[([^\]]+)\]\[([^\]]*)\]')) {
    $label = $m.Groups[2].Value
    if ([string]::IsNullOrWhiteSpace($label)) { $label = $m.Groups[1].Value }
    $refLabel = Normalize-RefLabel $label
    if (-not $refs.ContainsKey($refLabel)) {
      $issues.Add("$(Get-Rel $f.Path):L$(Get-Line $f.Text $m.Index) 引用定义缺失：[$label]") | Out-Null
    }
  }
}

Write-Host "  扫描活跃 Markdown：$($files.Count) 文件 / $linkCount 相对链接"
if ($issues.Count -gt 0) {
  Write-Host "  🔴 Markdown 相对链接/锚点问题：$($issues.Count) 处" -ForegroundColor Red
  $issues | Select-Object -First 40 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
  exit 10
}

Write-Host "  ✅ 活跃 Markdown 相对链接/锚点可解析" -ForegroundColor Green
exit 0
