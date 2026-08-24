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

function Get-CzxtRootMode {
  param([string]$Root)

  $template = Test-Path -LiteralPath (Join-Path $Root '.czxt-template-root') -PathType Leaf
  $project = Test-Path -LiteralPath (Join-Path $Root '.czxt-project-root') -PathType Leaf
  if ($template -and $project) { return 'conflict' }
  if ($template) { return 'template' }
  if ($project) { return 'project' }
  return 'unknown'
}

function Test-IsTemplateRoot {
  param([string]$Root)
  return (Get-CzxtRootMode -Root $Root) -eq 'template'
}

function Test-IsCzxtLegacyProjectProfile {
  param([string]$Root)

  if ((Get-CzxtRootMode -Root $Root) -ne 'project') { return $false }

  # Keep this bootstrap file ASCII-only so the public BOM gate can report
  # a damaged framework-scope.ps1 as exit 10 instead of failing while loading it.
  $requirements = -join @([char]0x9700, [char]0x6c42, [char]0x6587, [char]0x6863)
  $testDocs = -join @([char]0x6d4b, [char]0x8bd5, [char]0x6587, [char]0x6863)
  $testStrategy = -join @([char]0x6d4b, [char]0x8bd5, [char]0x7b56, [char]0x7565)
  $changeRoot = -join @([char]0x786e, [char]0x8ba4, [char]0x6539, [char]0x52a8)
  $approved = -join @([char]0x5df2, [char]0x5ba1, [char]0x6279)
  $completed = -join @([char]0x5df2, [char]0x5b8c, [char]0x6210)
  $legacySignaturePaths = @(
    ('Docs\1-' + $requirements + '\PRD-v3.md'),
    ('Docs\4-' + $testDocs + '\' + $testStrategy + '.md'),
    ($changeRoot + '\' + $approved + '\' + $completed +
      '\PROP-040-2026-05-22-Sprint-8-W-1-F-F1-AI' + (-join @([char]0x9910, [char]0x98df)) +
      (-join @([char]0x63a8, [char]0x8350)) + '.md')
  )
  foreach ($relativePath in $legacySignaturePaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $relativePath) -PathType Leaf)) {
      return $false
    }
  }
  return $true
}
