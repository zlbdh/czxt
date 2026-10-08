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
    Add-Failure "GitHub Actions anchor file is missing: $Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$workflow = Read-Text "{{APP_REPO_DIR}}/.github/workflows/build-apk.yml"
$manualOnly = ($workflow -match 'workflow_dispatch') -and ($workflow -notmatch '(?m)^\s*push\s*:')

if (-not $manualOnly) {
  Write-Host "  ℹ️ GitHub Actions build-apk.yml is not manual-only; skipping manual-trigger documentation anchors"
  exit 0
}

$docs = @(
  @{ Rel = "README.md"; Label = "Root README" },
  @{ Rel = "Docs/5-运维文档/GitHubActions说明.md"; Label = "GitHub Actions guide" },
  @{ Rel = "操作系统/07_完整工作流/实施循环-附录.md"; Label = "Implementation-loop appendix" },
  @{ Rel = "能力资产/skills/出APK.md"; Label = "APK build skill" }
)

foreach ($doc in $docs) {
  $text = Read-Text $doc.Rel
  if ($text -match 'main\s*/\s*master|git push\s*触发|push\s*触发|推完\s*commit\s*自动跑|automatically (?:run|build|trigger)[^\r\n]*(?:after|on) (?:a )?(?:git )?push|(?:git )?push (?:triggers|automatically triggers)') {
    Add-Failure "$($doc.Label) still describes manual-only GitHub Actions as push-triggered or automatic"
  }
}

$githubDoc = Read-Text "Docs/5-运维文档/GitHubActions说明.md"
if ($githubDoc -match '(?m)^\s*git add \.\s*$') {
  Add-Failure "GitHub Actions guide still contains an unrestricted git add . command"
}
if ($githubDoc -notmatch 'workflow_dispatch' -or $githubDoc -notmatch '不会自动触发') {
  Add-Failure "GitHub Actions guide does not distinguish manual workflow_dispatch from nontriggering pushes"
}

$rootReadme = Read-Text "README.md"
if ($rootReadme -notmatch 'workflow_dispatch' -or $rootReadme -notmatch 'git push.*不自动出 APK') {
  Add-Failure "Root README does not state that GitHub Actions uses manual workflow_dispatch and pushes do not automatically build APKs"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ GitHub Actions manual-trigger anchors aligned"
exit 0
