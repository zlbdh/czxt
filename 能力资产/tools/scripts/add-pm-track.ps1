# 能力资产/tools/scripts/add-pm-track.ps1
# PM 切换轨迹追加器 — RETRO-023 候选 DW 落地（PM 轨迹时间戳自动化）
# 核心：调用时自动用 Get-Date 盖真实时间戳，追加一行规范 PM 轨迹到 状态.md 末尾，
#       杜绝手填（手猜值 vs 真值差几十分钟 → P4f「轨迹崩塌」红，已 3 次复发）。
#
# 用法：
#   powershell -NoProfile -File 能力资产/tools/scripts/add-pm-track.ps1 `
#     -From "项目 PM「咪咪」" -To "操作系统 PM「框架管家」" -Task "干了啥"
#   含 ASCII 引号/特殊字符的 task → 改用 -TaskFile <文件>（把 task 写文件再传），避开命令行引号截断。
#
# 行为：
#   1. 时间戳 = Get-Date -Format 'yyyy-MM-dd HH:mm'（自动取真值，不接受外部传时间）
#   2. From/To/Task/Checkpoint/Done 里的 `|` 替换为 `/`、去掉换行，避免破坏 markdown 表格
#   3. 追加 `| <时间> | <From> | <To> | <Task> | <Checkpoint> | <Done> |` 到 状态.md 末尾
#      （UTF-8 无 BOM，保留原内容，末尾不留多余空行）
#   4. 打印追加的那一行供确认
#   5. fail-safe：StatePath 不存在或非法时报错退出非 0，不静默破坏

param(
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To,
    [string]$Task = "",
    [string]$TaskFile = "",
    [string]$Checkpoint = "✅ Q1-Q7：framework / 操作系统 PM",
    [string]$Done = "✅",
    [string]$StatePath = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# StatePath 默认：能力资产\tools\scripts → 上溯 3 层到项目根（对齐同目录 check-pm-tracking.ps1）
if ([string]::IsNullOrWhiteSpace($StatePath)) {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $stateFile = Join-Path $projectRoot "状态.md"
} else {
    $stateFile = [System.IO.Path]::GetFullPath($StatePath)
}

# fail-safe：文件不存在则报错退出非 0，不静默创建/破坏
if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
    Write-Host "❌ 找不到 状态.md（StatePath 不存在或非文件）：$stateFile" -ForegroundColor Red
    exit 1
}

# 单元格转义：`|` → `/`，去换行、去首尾空白（避免破坏 markdown 表格）
function Format-Cell {
    param([string]$Value)
    if ($null -eq $Value) { return "" }
    return ($Value -replace '\|', '/' -replace '[\r\n]+', ' ').Trim()
}

# -TaskFile 优先（robust：含 ASCII 引号/特殊字符的 task 走文件读，避开命令行 arg 引号截断 → dogfood 实战发现）
if (-not [string]::IsNullOrWhiteSpace($TaskFile)) {
    if (-not (Test-Path -LiteralPath $TaskFile -PathType Leaf)) {
        Write-Host "❌ 找不到 TaskFile：$TaskFile" -ForegroundColor Red
        exit 1
    }
    $Task = [System.IO.File]::ReadAllText($TaskFile, [System.Text.UTF8Encoding]::new($false))
}
if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-Host "❌ 必须提供 -Task 或 -TaskFile（任务描述不能为空）" -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'   # 核心：自动取真值
$cFrom = Format-Cell $From
$cTo = Format-Cell $To
$cTask = Format-Cell $Task
$cCheckpoint = Format-Cell $Checkpoint
$cDone = Format-Cell $Done

$newLine = "| $timestamp | $cFrom | $cTo | $cTask | $cCheckpoint | $cDone |"

# 读原文（保留原始字节/行尾），追加一行：
#   状态.md 为 UTF-8 无 BOM、LF 行尾、末尾单换行 → 直接 append "<line>`n"，不引入多余空行。
$existing = [System.IO.File]::ReadAllText($stateFile, [System.Text.UTF8Encoding]::new($false))

# 推断现有行尾（默认 LF，对齐真 状态.md），并确保正文与新行之间恰好一个换行。
$nl = "`n"
if ($existing -match "`r`n") { $nl = "`r`n" }
$body = $existing -replace '[\r\n]+$', ''   # 砍掉尾部所有换行，避免多余空行
$content = $body + $nl + $newLine + $nl

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($stateFile, $content, $utf8NoBom)

Write-Host "✅ 已追加 PM 轨迹到 状态.md 末尾（时间戳为 Get-Date 真值）：" -ForegroundColor Green
Write-Host $newLine
exit 0
