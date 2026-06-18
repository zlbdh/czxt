# 能力资产/tools/scripts/check-retro-cadence.ps1
# 沉淀节奏闹钟 — 议题 CK / Layer 4 自动化用在「沉淀触发」上（PROP-044 一脉 hooks）
#
# 监控 RETRO 沉淀节奏：距上次 RETRO 后 CHANGELOG 已积累 ≥N 个 framework 活动「天批次」
# 就提醒**项目 PM 派沉淀 PM 写新 RETRO**（不是让沉淀 PM 自唤醒 — 那破单点）。
# 与现有 hooks 一脉：pm-tracking 守留痕 / P4h 守锚点 / pre-release 守发布。
#
# 用法：
#   powershell -File 能力资产/tools/scripts/check-retro-cadence.ps1
#   powershell -File 能力资产/tools/scripts/check-retro-cadence.ps1 -Threshold 3
#
# 退出码：0 = 沉淀节奏正常 / 找不到数据(fail-safe) | 5 = 非阻塞提醒（积累 ≥ 阈值）
# 设计：这是**提醒**不是阻塞，exit 5 = 非阻塞警告（runner allowExitCodes 含 5）。

param(
    [int]$Threshold = 2   # 距上次 RETRO 后 CHANGELOG 活动「天批次」阈值，默认 2
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# 对齐 check-operating-system.ps1：脚本在 能力资产\tools\scripts\，上溯 3 层到项目根
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")

$retroDir = Join-Path $root "Docs\7-复盘"
$changelogPath = Join-Path $root "操作系统\00_变更记录\CHANGELOG.md"

Write-Host ""
Write-Host "🔔 沉淀节奏闹钟（议题 CK / Layer 4 — RETRO 沉淀触发）" -ForegroundColor Cyan

# ===== Step 1：找最新 RETRO（编号最大）=====
if (-not (Test-Path -LiteralPath $retroDir -PathType Container)) {
    Write-Host "🟡 找不到复盘目录（$retroDir）— fail-safe 跳过，不误报阻塞" -ForegroundColor Yellow
    exit 0
}

$retroFiles = @(Get-ChildItem -LiteralPath $retroDir -File -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^RETRO-(\d+)-' } |
    ForEach-Object {
        [PSCustomObject]@{ File = $_; Num = [int]([regex]::Match($_.Name, '^RETRO-(\d+)-').Groups[1].Value) }
    })

if ($retroFiles.Count -eq 0) {
    Write-Host "🟡 复盘目录下未找到 RETRO-NNN- 文件 — fail-safe 跳过，不误报阻塞" -ForegroundColor Yellow
    exit 0
}

$latest = $retroFiles | Sort-Object Num -Descending | Select-Object -First 1
$retroNum = $latest.Num
$retroFile = $latest.File

# 解析最新 RETRO 的日期：取文件内**第一个** YYYY-MM-DD；解析不到则退回文件名 YYYY-MM + "-01"
$retroDate = $null
$retroContent = Get-Content -LiteralPath $retroFile.FullName -Raw -ErrorAction SilentlyContinue
if ($retroContent) {
    $mDate = [regex]::Match($retroContent, '\d{4}-\d{2}-\d{2}')
    if ($mDate.Success) {
        try { $retroDate = [datetime]::ParseExact($mDate.Value, "yyyy-MM-dd", $null) } catch { $retroDate = $null }
    }
}
if ($null -eq $retroDate) {
    # 退回文件名里的 YYYY-MM 拼 "-01"
    $mName = [regex]::Match($retroFile.Name, '(\d{4}-\d{2})')
    if ($mName.Success) {
        try { $retroDate = [datetime]::ParseExact($mName.Groups[1].Value + "-01", "yyyy-MM-dd", $null) } catch { $retroDate = $null }
    }
}

if ($null -eq $retroDate) {
    Write-Host "🟡 RETRO-$retroNum（$($retroFile.Name)）解析不到日期 — fail-safe 跳过，不误报阻塞" -ForegroundColor Yellow
    exit 0
}

$retroDateStr = $retroDate.ToString("yyyy-MM-dd")

# ===== Step 2：数「距上次 RETRO 的 CHANGELOG 活动天批次」=====
if (-not (Test-Path -LiteralPath $changelogPath -PathType Leaf)) {
    Write-Host "🟡 找不到 CHANGELOG（$changelogPath）— fail-safe 跳过，不误报阻塞" -ForegroundColor Yellow
    exit 0
}

$changelogContent = Get-Content -LiteralPath $changelogPath -Raw -ErrorAction SilentlyContinue
$dateMatches = [regex]::Matches($changelogContent, '(?m)^## (\d{4}-\d{2}-\d{2})')
$sinceDates = @($dateMatches | ForEach-Object {
    try { [datetime]::ParseExact($_.Groups[1].Value, "yyyy-MM-dd", $null) } catch { $null }
} | Where-Object { $_ -ne $null -and $_ -gt $retroDate } | Sort-Object -Unique)
$sinceCount = @($sinceDates).Count

# ===== Step 3：判定 + 输出（仿 check-pm-tracking 风格）=====
Write-Host "  最新 RETRO：RETRO-$retroNum（日期 $retroDateStr · $($retroFile.Name)）"
Write-Host "  距上次 RETRO 的 framework 活动天批次：$sinceCount（阈值 $Threshold）"

if ($sinceCount -ge $Threshold) {
    Write-Host ""
    Write-Host "🟡 沉淀节奏提醒：距 RETRO-$retroNum 已积累 $sinceCount 个 framework 活动批次，建议**项目 PM 派沉淀 PM 写新 RETRO**（每 3 个 L3+ 改动复盘一次 / RETRO 节奏）" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  补登提示：项目 PM 派沉淀 PM 起草 RETRO-$($retroNum + 1)（覆盖距 RETRO-$retroNum 以来的 $sinceCount 个活动批次）" -ForegroundColor Yellow
    exit 5
} else {
    Write-Host ""
    Write-Host "✅ 沉淀节奏正常（距 RETRO-$retroNum 活动批次 $sinceCount < 阈值 $Threshold）" -ForegroundColor Green
    exit 0
}
