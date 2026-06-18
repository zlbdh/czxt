param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "GitHub Actions 锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$workflow = Read-Text "{{APP_REPO_DIR}}/.github/workflows/build-apk.yml"
$manualOnly = ($workflow -match 'workflow_dispatch') -and ($workflow -notmatch '(?m)^\s*push\s*:')

if (-not $manualOnly) {
  Write-Host "  ℹ️ GitHub Actions build-apk.yml 非手动-only，跳过手动触发文档锚点"
  exit 0
}

$docs = @(
  @{ Rel = "README.md"; Label = "根 README" },
  @{ Rel = "Docs/5-运维文档/GitHubActions说明.md"; Label = "GitHub Actions 说明" },
  @{ Rel = "操作系统/07_完整工作流/实施循环-附录.md"; Label = "实施循环附录" },
  @{ Rel = "能力资产/skills/出APK.md"; Label = "出APK skill" }
)

foreach ($doc in $docs) {
  $text = Read-Text $doc.Rel
  if ($text -match 'main\s*/\s*master|git push\s*触发|push\s*触发|推完\s*commit\s*自动跑') {
    Add-Failure "$($doc.Label) 仍把手动-only GitHub Actions 写成 push/自动触发"
  }
}

$githubDoc = Read-Text "Docs/5-运维文档/GitHubActions说明.md"
if ($githubDoc -match '(?m)^\s*git add \.\s*$') {
  Add-Failure "GitHub Actions 说明仍含 git add . 裸命令"
}
if ($githubDoc -notmatch 'workflow_dispatch' -or $githubDoc -notmatch '不会自动触发') {
  Add-Failure "GitHub Actions 说明未明确 workflow_dispatch 手动触发与 push 不自动触发"
}

$rootReadme = Read-Text "README.md"
if ($rootReadme -notmatch 'workflow_dispatch' -or $rootReadme -notmatch 'git push.*不自动出 APK') {
  Add-Failure "根 README 未明确 GitHub Actions 手动 workflow_dispatch 与 push 不自动出 APK"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ GitHub Actions 手动触发锚点对齐"
exit 0
