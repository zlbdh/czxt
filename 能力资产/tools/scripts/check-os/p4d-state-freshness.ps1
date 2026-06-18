param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path,
    [datetime]$Now = (Get-Date)
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path $Root).Path
$stateFile = Join-Path $repoRoot "状态.md"
$threshold = $Now.AddDays(-30)
$stale = $false
$reasons = @()

if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
    Write-Host "  🔴 状态.md 不存在 — P4a 已应触发" -ForegroundColor Red
    $stale = $true
    $reasons += "文件缺失"
} else {
    # 维度 1：文件 mtime
    $mtime = (Get-Item -LiteralPath $stateFile).LastWriteTime
    $mtimeDays = [int]($Now - $mtime).TotalDays
    $mtimeStr = $mtime.ToString("yyyy-MM-dd HH:mm")

    if ($mtime -lt $threshold) {
        Write-Host ("  🟡 文件 mtime: {0}（距今 {1} 天，超 30 天）" -f $mtimeStr, $mtimeDays) -ForegroundColor Yellow
        $stale = $true
        $reasons += "mtime 超 30 天"
    } else {
        Write-Host ("  ✅ 文件 mtime: {0}（距今 {1} 天）" -f $mtimeStr, $mtimeDays) -ForegroundColor Green
    }

    # 维度 2：文件内日期戳（防 git checkout 重置 mtime 但内容仍旧）
    $content = Get-Content -LiteralPath $stateFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $matches = [regex]::Matches($content, '\d{4}-\d{2}-\d{2}')
        if ($matches.Count -gt 0) {
            $allDates = @($matches | ForEach-Object {
                try { [datetime]::ParseExact($_.Value, "yyyy-MM-dd", $null) } catch { $null }
            } | Where-Object { $_ -ne $null })
            $futureLimit = $Now.Date.AddDays(1)
            $dates = @($allDates | Where-Object { $_ -le $futureLimit })
            if ($dates.Count -gt 0) {
                $latest = ($dates | Sort-Object -Descending | Select-Object -First 1)
                $latestStr = $latest.ToString("yyyy-MM-dd")
                $latestDays = [int]($Now - $latest).TotalDays
                if ($latest -lt $threshold) {
                    Write-Host ("  🟡 内容最新日期戳: {0}（距今 {1} 天，超 30 天）" -f $latestStr, $latestDays) -ForegroundColor Yellow
                    $stale = $true
                    $reasons += "内容日期戳超 30 天"
                } else {
                    Write-Host ("  ✅ 内容最新日期戳: {0}（距今 {1} 天）" -f $latestStr, $latestDays) -ForegroundColor Green
                }
            } else {
                Write-Host "  🟡 内容未能解析任何 YYYY-MM-DD 日期戳" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  🟡 内容未匹配 YYYY-MM-DD 日期格式" -ForegroundColor Yellow
        }
    }
}

if ($stale) {
    $reasonText = if ($reasons.Count -gt 0) { $reasons -join " + " } else { "未知 stale" }
    Write-Host "  🟡 P4d warning：$reasonText（不阻塞，但建议立刻更新）" -ForegroundColor Yellow
    exit 5
}

exit 0
