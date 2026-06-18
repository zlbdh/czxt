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
  Add-Failure "缺少 00_变更记录目录"
} else {
  $indexPath = Join-Path $dir "README.md"
  if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    Add-Failure "缺少 00_变更记录/README.md"
  } else {
    $indexText = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
    if (-not $indexText.Contains('除 `CHANGELOG.md` 外') -or -not $indexText.Contains("不作为当前执行流程或当前真相源")) {
      Add-Failure "00_变更记录/README.md 缺目录级历史边界"
    }
  }

  Get-ChildItem -LiteralPath $dir -File -Filter "*.md" |
    Where-Object { $_.Name -match '^CHANGELOG-2026|^agent-.*历史\.md$' } |
    ForEach-Object {
      $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
      $head = (($text -split "`r?`n") | Select-Object -First 18) -join "`n"
      $rel = $_.FullName.Substring($Root.Length).TrimStart('\')

      if ($head -notmatch "历史安全边界" -or $head -notmatch "不可直接复制执行") {
        Add-Failure "$rel 首屏缺历史安全边界 / 不可直接复制执行"
      }

      $boundaryIndex = $text.IndexOf("历史安全边界")
      foreach ($term in @("下次归档触发", "新会话", "当前活的导航路径全部从 agent", "唯一入口")) {
        $termIndex = $text.IndexOf($term)
        if ($termIndex -ge 0 -and ($boundaryIndex -lt 0 -or $termIndex -lt $boundaryIndex)) {
          Add-Failure "$rel 在历史安全边界前出现可能误读为现行的旧口径：$term"
        }
      }
    }
}

$readmeSpecPath = Join-Path $Root "操作系统\01_架构\README设计规范.md"
if (Test-Path -LiteralPath $readmeSpecPath -PathType Leaf) {
  $readmeSpecText = Get-Content -LiteralPath $readmeSpecPath -Raw -Encoding UTF8
  if ($readmeSpecText -match "历史归档/2026-05/议题全景-2026-05-22-历史快照\.md.*ADR 永久现行表") {
    Add-Failure "README设计规范.md 将议题全景历史快照误列为当前 ADR 永久现行表"
  }
  if ($readmeSpecText -notmatch "历史快照只作追溯抽检") {
    Add-Failure "README设计规范.md 缺历史快照只作追溯抽检说明"
  }
}

foreach ($rel in @("操作系统\01_架构\元规则池.md", "操作系统\01_架构\工具载体矩阵.md")) {
  $path = Join-Path $Root $rel
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -match "本文件归档") {
      Add-Failure "$rel 是活文档，不应使用“本文件归档”"
    }
  }
}

foreach ($rel in @("操作系统\01_架构\工具载体矩阵.md", "操作系统\01_架构\元规则池-附录.md")) {
  $path = Join-Path $Root $rel
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -match "历史归档\\|历史归档/" -and $text -notmatch "历史愿景快照，仅追溯|以下仅作演化追溯") {
      Add-Failure "$rel 引用历史源时缺“仅追溯”语义"
    }
  }
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ 00_变更记录历史归档首屏边界对齐" -ForegroundColor Green
exit 0
