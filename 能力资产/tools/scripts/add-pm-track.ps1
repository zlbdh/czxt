# 能力资产/tools/scripts/add-pm-track.ps1
# PM transition history appender — implements RETRO-023 candidate DW (automatic PM history timestamps)
# Core: use Get-Date at invocation to stamp the actual time and append one canonical PM history row to 状态.md.
#       Never enter time manually (guesses tens of minutes from actual time trigger P4f history-collapse RED; already recurred 3 times).
#
# Usage:
#   powershell -NoProfile -File 能力资产/tools/scripts/add-pm-track.ps1 `
#     -From "Project PM 'Mimi'" -To "Operating System PM 'Framework Steward'" -Task "Work performed"
#   For a task containing ASCII quotes/special characters, use -TaskFile <file> (write the task to a file first) to avoid command-line quote truncation.
#
# Behavior:
#   1. Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm' (read the actual time automatically; external timestamps are not accepted)
#   2. Replace `|` with `/` and remove newlines in From/To/Task/Checkpoint/Done to protect the Markdown table
#   3. Append `| <time> | <From> | <To> | <Task> | <Checkpoint> | <Done> |` to 状态.md
#      (UTF-8 without BOM; preserve existing content; no extra trailing blank lines)
#   4. Print the appended row for confirmation
#   5. fail-safe: an absent or invalid StatePath errors with a non-0 exit; never silently damage it

param(
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To,
    [string]$Task = "",
    [string]$TaskFile = "",
    [string]$Checkpoint = "✅ Q1-Q7: framework / Operating System PM",
    [string]$Done = "✅",
    [string]$StatePath = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# StatePath default: 能力资产\tools\scripts → ascend 3 levels to the project root (aligned with check-pm-tracking.ps1 in this directory)
if ([string]::IsNullOrWhiteSpace($StatePath)) {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $stateFile = Join-Path $projectRoot "状态.md"
} else {
    $stateFile = [System.IO.Path]::GetFullPath($StatePath)
}

# fail-safe: a missing file errors with a non-0 exit; never silently create or damage it
if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
    Write-Host "❌ Cannot find 状态.md (StatePath is absent or not a file): $stateFile" -ForegroundColor Red
    exit 1
}

# Cell escaping: `|` → `/`; remove newlines and surrounding whitespace to protect the Markdown table
function Format-Cell {
    param([string]$Value)
    if ($null -eq $Value) { return "" }
    return ($Value -replace '\|', '/' -replace '[\r\n]+', ' ').Trim()
}

# Prefer -TaskFile for robustness: read tasks with ASCII quotes/special characters from a file to avoid command-line argument quote truncation (found during internal use)
if (-not [string]::IsNullOrWhiteSpace($TaskFile)) {
    if (-not (Test-Path -LiteralPath $TaskFile -PathType Leaf)) {
        Write-Host "❌ Cannot find TaskFile: $TaskFile" -ForegroundColor Red
        exit 1
    }
    $Task = [System.IO.File]::ReadAllText($TaskFile, [System.Text.UTF8Encoding]::new($false))
}
if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-Host "❌ Provide -Task or -TaskFile (the task description cannot be empty)" -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'   # Core: obtain the actual time automatically
$cFrom = Format-Cell $From
$cTo = Format-Cell $To
$cTask = Format-Cell $Task
$cCheckpoint = Format-Cell $Checkpoint
$cDone = Format-Cell $Done

$newLine = "| $timestamp | $cFrom | $cTo | $cTask | $cCheckpoint | $cDone |"

# Read existing text (preserve original bytes/line endings), then append one row:
#   状态.md uses UTF-8 without BOM, LF, and one final newline; append "<line>`n" directly without extra blank lines.
$existing = [System.IO.File]::ReadAllText($stateFile, [System.Text.UTF8Encoding]::new($false))

# Detect existing line endings (default LF, matching actual 状态.md) and ensure exactly one newline between the body and new row.
$nl = "`n"
if ($existing -match "`r`n") { $nl = "`r`n" }
$body = $existing -replace '[\r\n]+$', ''   # Remove all trailing newlines to avoid extra blank lines
$content = $body + $nl + $newLine + $nl

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($stateFile, $content, $utf8NoBom)

Write-Host "✅ Appended PM history to 状态.md (timestamp is the actual Get-Date value):" -ForegroundColor Green
Write-Host $newLine
exit 0
