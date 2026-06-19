$ErrorActionPreference = "Stop"

function Get-FrameworkTargetExtensions {
  return @(".jsx", ".js", ".ts", ".tsx", ".md", ".ps1", ".json")
}

function Test-IsFrameworkArchivePath {
  param([string]$Path)

  $normalized = $Path -replace '/', '\'
  $name = [System.IO.Path]::GetFileName($normalized)
  if ($normalized -match '(?i)(^|\\)(历史归档|状态-archive)(\\|$)') { return $true }
  if ($name -match '^CHANGELOG-2026') { return $true }
  if ($name -match '^agent-(INDEX|README)-历史\.md$') { return $true }
  return $false
}

function Test-IsTemplateRoot {
  param([string]$Root)

  $readme = Join-Path $Root "README.md"
  if (-not (Test-Path -LiteralPath $readme -PathType Leaf)) { return $false }
  $text = Get-Content -LiteralPath $readme -Raw -Encoding UTF8
  $hasTemplateTitle = $text -match '#\s*操作系统模板'
  $hasTemplateScaffold = (
    (Test-Path -LiteralPath (Join-Path $Root "项目配置\_模板.project.json") -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $Root "项目区\清单.md") -PathType Leaf)
  )
  return ($hasTemplateTitle -and $hasTemplateScaffold)
}
