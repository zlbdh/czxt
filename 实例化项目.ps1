param(
  [Parameter(Mandatory=$true)][string]$ProjectRoot,
  [Parameter(Mandatory=$true)][string]$ProjectName,
  [Parameter(Mandatory=$true)][string]$AppRepoDir,
  [string]$CurrentVersion = "v0.1.0",
  [string]$CurrentSprint = "Sprint-1",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$TemplateRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$ProjectRootPosix = $ProjectRoot.Replace("\", "/")
$ProjectRootLower = $ProjectRoot.ToLowerInvariant()
$InitTime = Get-Date -Format "yyyy-MM-dd HH:mm"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (!(Test-Path -LiteralPath $ProjectRoot)) {
  New-Item -ItemType Directory -Path $ProjectRoot | Out-Null
}

$copyItems = @(
  ".codex",
  ".claude",
  "AGENTS.md",
  "状态.md",
  "操作系统",
  "能力资产",
  "PM工作区",
  "交接区",
  "确认改动",
  "Docs"
)

foreach ($item in $copyItems) {
  $src = Join-Path $TemplateRoot $item
  $dst = Join-Path $ProjectRoot $item
  if (!(Test-Path -LiteralPath $src)) {
    throw "模板缺少必要项：$item"
  }
  if ((Test-Path -LiteralPath $dst) -and -not $Force) {
    throw "目标已存在：$dst。若确认覆盖，请加 -Force。"
  }
  Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
}

$textExt = @(".md", ".ps1", ".json", ".txt", ".yml", ".yaml", ".toml", ".cmd", ".bat")
$files = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File |
  Where-Object { $textExt -contains $_.Extension.ToLowerInvariant() }

foreach ($file in $files) {
  $text = [System.IO.File]::ReadAllText($file.FullName)
  $text = $text.Replace("{{PROJECT_ROOT}}", $ProjectRoot)
  $text = $text.Replace("{{PROJECT_ROOT_POSIX}}", $ProjectRootPosix)
  $text = $text.Replace("{{PROJECT_ROOT_LOWER}}", $ProjectRootLower)
  $text = $text.Replace("{{PROJECT_NAME}}", $ProjectName)
  $text = $text.Replace("{{APP_REPO_DIR}}", $AppRepoDir)
  $text = $text.Replace("{{CURRENT_VERSION}}", $CurrentVersion)
  $text = $text.Replace("{{CURRENT_SPRINT}}", $CurrentSprint)
  $text = $text.Replace("{{INIT_TIME}}", $InitTime)
  [System.IO.File]::WriteAllText($file.FullName, $text, $Utf8NoBom)
}

Write-Host "✅ 操作系统已实例化到：$ProjectRoot"
Write-Host "下一步：在目标项目中 review/trust .codex hooks，并运行 能力资产/tools/scripts/check-operating-system.ps1。"

