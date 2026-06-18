param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$failures = @()
$repoRoot = (Resolve-Path $Root).Path

function Add-Failure {
    param([string]$Message)
    $script:failures += $Message
    Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text {
    param([string]$RelativePath)
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "缺台账锚点文件：$RelativePath"
        return $null
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Test-Anchor {
    param(
        [string]$RelativePath,
        [string]$Text,
        [string]$Needle,
        [string]$Label
    )
    if ($null -eq $Text) { return }
    if ($Text.Contains($Needle)) {
        Write-Host "  ✅ $RelativePath $Label：$Needle" -ForegroundColor Green
    } else {
        Add-Failure "$RelativePath $Label 缺失：$Needle"
    }
}

$pkgPath = Join-Path $repoRoot "{{APP_REPO_DIR}}/package.json"
$sotVersion = $null
if (Test-Path -LiteralPath $pkgPath -PathType Leaf) {
    try { $sotVersion = (Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch { $sotVersion = $null }
}

$statePath = Join-Path $repoRoot "状态.md"
$sotSprint = $null
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    $stateText = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    $m = [regex]::Match($stateText, "3 秒起手速查（[^）]*?Sprint-(\d+)")
    if ($m.Success) { $sotSprint = "Sprint-$($m.Groups[1].Value)" }
}

$indexText = Read-Text "操作系统/04_台账/INDEX.md"
$versionText = Read-Text "操作系统/04_台账/版本时间线.md"
$sprintText = Read-Text "操作系统/04_台账/Sprint节奏.md"

if ($sotVersion) {
    $versionNeedle = "v$sotVersion"
    Test-Anchor "操作系统/04_台账/INDEX.md" $indexText $versionNeedle "当前版本锚点"
    Test-Anchor "操作系统/04_台账/版本时间线.md" $versionText $versionNeedle "当前版本锚点"
} else {
    Write-Host "  ℹ️ package.json version 未解析，跳过台账版本锚点" -ForegroundColor Gray
}

if ($sotSprint) {
    Test-Anchor "操作系统/04_台账/INDEX.md" $indexText $sotSprint "当前 Sprint 锚点"
    Test-Anchor "操作系统/04_台账/Sprint节奏.md" $sprintText $sotSprint "当前 Sprint 锚点"
} else {
    Write-Host "  ℹ️ 状态.md Sprint 未解析，跳过台账 Sprint 锚点" -ForegroundColor Gray
}

if ($failures.Count -gt 0) { exit 10 }
exit 0
