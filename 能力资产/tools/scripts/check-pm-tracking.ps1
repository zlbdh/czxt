# 能力资产/tools/scripts/check-pm-tracking.ps1
# Full improvement 2 — automatic PM transition history check (PROP-027 v2 upgraded to the full version)
# Adapted from the Kiro Hooks pattern: check the PM history timestamp at the end of 状态.md and alert when overdue
#
# Usage:
#   powershell -File 能力资产/tools/scripts/check-pm-tracking.ps1
#   powershell -File 能力资产/tools/scripts/check-pm-tracking.ps1 -Threshold 10
#
# Output:
#   ✅ PM history synchronized: X minutes since the last entry (< threshold)
#   🔴 PM history collapse: X minutes since the last entry (> threshold) + Git changes → prompt to add an entry
#
# ⚠️ FIX 2026-05-29: change $projectRoot ascent from 1 level to 3; task #109 moved the script into
#    能力资产\tools\scripts\, so the old Split-Path -Parent $PSScriptRoot resolved to 能力资产\tools,
#    could not find 状态.md (exit 1), and made P4f ineffective. Now ascend 3 levels to the project root.

param(
    [string]$Root = "",
    [int]$Threshold = 30  # Threshold in minutes; default 30
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
    # FIX: 能力资产\tools\scripts → ascend 3 levels to the project root
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
} else {
    $projectRoot = [System.IO.Path]::GetFullPath($Root)
}
$helperPath = Join-Path $PSScriptRoot "check-pm-tracking\git-status.ps1"
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host "❌ PM history Git-status helper is missing: $helperPath" -ForegroundColor Red
    exit 10
}
. $helperPath

$stateFile = Join-Path $projectRoot "状态.md"

if (-not (Test-Path $stateFile)) {
    Write-Host "❌ Cannot find 状态.md: $stateFile" -ForegroundColor Red
    exit 1
}

# Step 1: find the last PM transition history row (match "| 2026-MM-DD HH:MM" plus PM to avoid mistaking ordinary schedules for PM history)
$content = Get-Content $stateFile -Encoding UTF8
$lastTrackLine = $null
$lastTrackLineNum = -1

for ($i = $content.Count - 1; $i -ge 0; $i--) {
    if ($content[$i] -match '^\| (\d{4}-\d{2}-\d{2} \d{2}:\d{2}).*PM') {
        $lastTrackLine = $content[$i]
        $lastTrackTimestamp = $matches[1]
        $lastTrackLineNum = $i + 1
        break
    }
}

if (-not $lastTrackLine) {
    Write-Host "⚠️ No PM transition history timestamp found in 状态.md" -ForegroundColor Yellow
    exit 2
}

# Step 2: calculate minutes elapsed to the current time
try {
    $lastTime = [DateTime]::ParseExact($lastTrackTimestamp, "yyyy-MM-dd HH:mm", $null)
    $now = Get-Date
    $diffMinutes = [int]($now - $lastTime).TotalMinutes
} catch {
    Write-Host "❌ Failed to parse timestamp: $lastTrackTimestamp" -ForegroundColor Red
    exit 3
}

$trackWindowEnd = $lastTime.AddMinutes(1)
$changeProbe = Get-PmTrackingFrameworkChangeProbe -ProjectRoot $projectRoot -TrackWindowEnd $trackWindowEnd
$frameworkChangedPaths = @($changeProbe.ChangedPaths)
$frameworkChanged = [bool]$changeProbe.FrameworkChanged

# Step 4: decide and report
Write-Host ""
Write-Host "🔍 Automatic PM transition history check (PROP-027 v2, full version)" -ForegroundColor Cyan
Write-Host "  Last entry: $lastTrackTimestamp (状态.md L$lastTrackLineNum)"
Write-Host "  Current time: $($now.ToString('yyyy-MM-dd HH:mm'))"
Write-Host "  Elapsed: $diffMinutes minutes (threshold $Threshold minutes)"
Write-Host "  Framework changes: $(if ($frameworkChanged) {'✅ yes'} else {'❌ no'})"
Write-Host "  Detection method: $(if ($changeProbe.Method -eq 'git') {'Git working-tree/index status'} elseif ($changeProbe.Method -eq 'mtime') {'mtime fallback'} else {'Git status unreadable'})"
if ($frameworkChanged) {
    @($frameworkChangedPaths | Sort-Object | Select-Object -First 5) | ForEach-Object {
        Write-Host "    - $_"
    }
}

if (-not $changeProbe.StatusAvailable) {
    Write-Host ""
    Write-Host "🔴 PM history check cannot read Git status — it must not pretend the tree is clean" -ForegroundColor Red
    Write-Host "  Fix Git status retrieval before deciding whether to add a PM history entry" -ForegroundColor Red
    exit 10
}

if ($diffMinutes -gt $Threshold -and $frameworkChanged) {
    Write-Host ""
    Write-Host "🔴 PM history collapse alert — risk of the 10+ recurrence of issue AJ" -ForegroundColor Red
    Write-Host "  Last entry was $diffMinutes minutes ago (over the $Threshold minute threshold)" -ForegroundColor Red
    Write-Host "  Framework changes exist — immediately append PM transition history to 状态.md" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Entry template:" -ForegroundColor Yellow
    Write-Host "  | $($now.ToString('yyyy-MM-dd HH:mm')) | Project PM | <destination role> | <task description> | ✅ | ✅ |" -ForegroundColor Yellow
    exit 10
} elseif ($diffMinutes -gt $Threshold) {
    Write-Host ""
    Write-Host "🟡 PM history is overdue but the framework has no changes — monitor" -ForegroundColor Yellow
    exit 5
} else {
    Write-Host ""
    Write-Host "✅ PM history synchronized ($diffMinutes minutes since the last entry)" -ForegroundColor Green
    exit 0
}
