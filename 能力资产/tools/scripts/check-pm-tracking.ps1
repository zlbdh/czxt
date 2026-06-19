# 能力资产/tools/scripts/check-pm-tracking.ps1
# 改进 2 完整版 — PM 切换轨迹自动检查（PROP-027 v2 升完整版）
# 借鉴 Kiro Hooks 模式 — 检测状态.md 末尾 PM 轨迹时间戳，超时报警
#
# 用法：
#   powershell -File 能力资产/tools/scripts/check-pm-tracking.ps1
#   powershell -File 能力资产/tools/scripts/check-pm-tracking.ps1 -Threshold 10
#
# 输出：
#   ✅ PM 轨迹同步：距上次 X 分钟（< 阈值）
#   🔴 PM 轨迹崩塌：距上次 X 分钟（> 阈值）+ git 有改动 → 补登提示
#
# ⚠️ FIX 2026-05-29：$projectRoot 上溯由 1 层改 3 层 —— task #109 把脚本挪进
#    能力资产\tools\scripts\ 后，旧的 Split-Path -Parent $PSScriptRoot 落在 能力资产\tools，
#    导致找不到 状态.md（exit 1），P4f 形同虚设。现上溯 3 层到项目根。

param(
    [string]$Root = "",
    [int]$Threshold = 30  # 阈值（分钟），默认 30
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
    # FIX: 能力资产\tools\scripts → 上溯 3 层到项目根
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
} else {
    $projectRoot = [System.IO.Path]::GetFullPath($Root)
}
$stateFile = Join-Path $projectRoot "状态.md"

if (-not (Test-Path $stateFile)) {
    Write-Host "❌ 找不到 状态.md：$stateFile" -ForegroundColor Red
    exit 1
}

# Step 1: 找最后一行 PM 切换轨迹（匹配「| 2026-MM-DD HH:MM」且包含 PM，避免被普通时间表误判）
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
    Write-Host "⚠️ 状态.md 未找到 PM 切换轨迹时间戳" -ForegroundColor Yellow
    exit 2
}

# Step 2: 计算距离当前的分钟数
try {
    $lastTime = [DateTime]::ParseExact($lastTrackTimestamp, "yyyy-MM-dd HH:mm", $null)
    $now = Get-Date
    $diffMinutes = [int]($now - $lastTime).TotalMinutes
} catch {
    Write-Host "❌ 时间解析失败：$lastTrackTimestamp" -ForegroundColor Red
    exit 3
}

# Step 3: 检查项目根 framework 文件是否在最后 PM 轨迹后更新
# 项目根不是 git 仓库，不能用 {{APP_REPO_DIR}}/.git 判断 操作系统/、能力资产/ 等改动。
$frameworkChangedPaths = @()
$trackWindowEnd = $lastTime.AddMinutes(1)
$frameworkDirs = @("操作系统", "能力资产", "PM工作区", "确认改动", "交接区", "Docs")
foreach ($dir in $frameworkDirs) {
    $path = Join-Path $projectRoot $dir
    if (Test-Path -LiteralPath $path) {
        $frameworkChangedPaths += @(Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt $trackWindowEnd } |
            Select-Object -ExpandProperty FullName)
    }
}

$rootFrameworkFiles = @("AGENTS.md", "README.md", "TASKS.md", "状态.md")
foreach ($name in $rootFrameworkFiles) {
    $path = Join-Path $projectRoot $name
    if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path).LastWriteTime -gt $trackWindowEnd)) {
        $frameworkChangedPaths += $path
    }
}

$frameworkChanged = @($frameworkChangedPaths).Count -gt 0

# Step 4: 判定 + 报告
Write-Host ""
Write-Host "🔍 PM 切换轨迹自动检查（PROP-027 v2 完整版）" -ForegroundColor Cyan
Write-Host "  最后轨迹：$lastTrackTimestamp（状态.md L$lastTrackLineNum）"
Write-Host "  当前时间：$($now.ToString('yyyy-MM-dd HH:mm'))"
Write-Host "  距上次：$diffMinutes 分钟（阈值 $Threshold 分钟）"
Write-Host "  framework 改动：$(if ($frameworkChanged) {'✅ 有'} else {'❌ 无'})"
if ($frameworkChanged) {
    @($frameworkChangedPaths | Sort-Object | Select-Object -First 5) | ForEach-Object {
        $rel = $_.Substring($projectRoot.Length).TrimStart('\')
        Write-Host "    - $rel"
    }
}

if ($diffMinutes -gt $Threshold -and $frameworkChanged) {
    Write-Host ""
    Write-Host "🔴 PM 轨迹崩塌警报 — 议题 AJ 第 10+ 次复发风险" -ForegroundColor Red
    Write-Host "  距上次轨迹 $diffMinutes 分钟（超阈值 $Threshold 分钟）" -ForegroundColor Red
    Write-Host "  且 framework 有改动 — 必须立即补登 状态.md 末尾 PM 切换轨迹" -ForegroundColor Red
    Write-Host ""
    Write-Host "  补登模板：" -ForegroundColor Yellow
    Write-Host "  | $($now.ToString('yyyy-MM-dd HH:mm')) | 项目 PM | <切到角色> | <任务描述> | ✅ | ✅ |" -ForegroundColor Yellow
    exit 10
} elseif ($diffMinutes -gt $Threshold) {
    Write-Host ""
    Write-Host "🟡 PM 轨迹时间超阈值但 framework 无改动 — 监控" -ForegroundColor Yellow
    exit 5
} else {
    Write-Host ""
    Write-Host "✅ PM 轨迹同步（距上次 $diffMinutes 分钟）" -ForegroundColor Green
    exit 0
}
