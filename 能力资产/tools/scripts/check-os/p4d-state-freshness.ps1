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
    Write-Host "  🔴 状态.md is missing; P4a should already have reported it" -ForegroundColor Red
    $stale = $true
    $reasons += "file missing"
} else {
    # Dimension 1: file modification time.
    $mtime = (Get-Item -LiteralPath $stateFile).LastWriteTime
    $mtimeDays = [int]($Now - $mtime).TotalDays
    $mtimeStr = $mtime.ToString("yyyy-MM-dd HH:mm")

    if ($mtime -lt $threshold) {
        Write-Host ("  🟡 File mtime: {0} ({1} days ago; over 30 days)" -f $mtimeStr, $mtimeDays) -ForegroundColor Yellow
        $stale = $true
        $reasons += "mtime is over 30 days old"
    } else {
        Write-Host ("  ✅ File mtime: {0} ({1} days ago)" -f $mtimeStr, $mtimeDays) -ForegroundColor Green
    }

    # Dimension 2: dates in the content, since git checkout can reset mtime without updating stale content.
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
                    Write-Host ("  🟡 Latest content date: {0} ({1} days ago; over 30 days)" -f $latestStr, $latestDays) -ForegroundColor Yellow
                    $stale = $true
                    $reasons += "content date is over 30 days old"
                } else {
                    Write-Host ("  ✅ Latest content date: {0} ({1} days ago)" -f $latestStr, $latestDays) -ForegroundColor Green
                }
            } else {
                Write-Host "  🟡 No valid YYYY-MM-DD date could be parsed from the content" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  🟡 Content contains no YYYY-MM-DD date pattern" -ForegroundColor Yellow
        }
    }
}

if ($stale) {
    $reasonText = if ($reasons.Count -gt 0) { $reasons -join " + " } else { "unknown freshness" }
    Write-Host "  🟡 P4d warning: $reasonText (nonblocking; prompt update recommended)" -ForegroundColor Yellow
    exit 5
}

exit 0
