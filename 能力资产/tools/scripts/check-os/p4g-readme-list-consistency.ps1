param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$adrDir = Join-Path $Root "Docs/3-开发文档/adr"
$adrReadmePath = Join-Path $adrDir "README.md"
if ((Test-Path -LiteralPath $adrDir) -and (Test-Path -LiteralPath $adrReadmePath)) {
    $adrFiles = (Get-ChildItem -LiteralPath $adrDir -Filter "ADR-*.md").Count
    $adrReadmeRows = (Get-Content -LiteralPath $adrReadmePath -Encoding UTF8 | Select-String -Pattern "^\| ADR-").Count
    if ($adrFiles -eq $adrReadmeRows) {
        Write-Host "  ✅ ADR README：文件 $adrFiles = README 表 $adrReadmeRows" -ForegroundColor Green
    } else {
        Write-Host "  🔴 ADR README 不一致：文件 $adrFiles vs README 表 $adrReadmeRows（PM 自纠 #91 复发）" -ForegroundColor Red
        $failures.Add("ADR README 一致性 — 文件 $adrFiles vs README $adrReadmeRows")
    }
} else {
    Write-Host "  ⚠️ ADR 目录或 README 不存在" -ForegroundColor Yellow
}

$panoramaPaths = @(
    (Join-Path $Root "操作系统/04_台账/议题全景.md"),
    (Join-Path $Root "操作系统/04_台账/历史归档/2026-05/议题全景-2026-05-22-历史快照.md")
)
$panoramaFound = $false
$panoramaAdrRows = 0
foreach ($panoramaPath in $panoramaPaths) {
    if (Test-Path -LiteralPath $panoramaPath) {
        $panoramaFound = $true
        $panoramaAdrRows += (Get-Content -LiteralPath $panoramaPath -Encoding UTF8 | Select-String -Pattern "^\| \*\*(?:🆕 )?ADR-").Count
    }
}
if ($panoramaFound) {
    Write-Host "  ℹ️ 议题全景 ADR 扫描完成（主文+历史快照 / 人工语义表不自动阻塞）" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️ 议题全景.md 不存在" -ForegroundColor Yellow
}

$poolPath = Join-Path $Root "操作系统/01_架构/元规则池.md"
if (Test-Path -LiteralPath $poolPath) {
    $poolContent = Get-Content -LiteralPath $poolPath -Raw -Encoding UTF8
    $section2 = if ($poolContent -match "(?s)## 二、.*?(?=## 三、)") { $matches[0] } else { "" }
    $poolRows = ([regex]::Matches($section2, "(?m)^\| \*\*")).Count
    $claimMatch = [regex]::Match($poolContent, "\*\*v3\.\d+(?:\.\d+)?\*\*[^|]*\| \*\*当前\*\*[^|]*\| \*\*(\d+)")
    if ($claimMatch.Success) {
        $poolClaim = [int]$claimMatch.Groups[1].Value
        if ($poolRows -eq $poolClaim) {
            Write-Host "  ✅ 元规则池：二表行数 $poolRows = 声明 $poolClaim 永久" -ForegroundColor Green
        } else {
            Write-Host "  🔴 元规则池不一致：二表 $poolRows vs 声明 $poolClaim 永久" -ForegroundColor Red
            $failures.Add("元规则池一致性 — 二表 $poolRows vs 声明 $poolClaim")
        }
    } else {
        Write-Host "  ℹ️ 元规则池声明 N 永久数未识别（regex 未匹配 / 人工核）" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️ 元规则池.md 不存在" -ForegroundColor Yellow
}

$readmes = Get-ChildItem -LiteralPath $Root -Filter "README.md" -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch "\\\.git\\|\\node_modules\\|\\已接手\\|\\状态-archive\\|CHANGELOG-2026|\\本地实例\\"
}
$total = $readmes.Count
$withFm = 0
foreach ($r in $readmes) {
    $firstLine = Get-Content -LiteralPath $r.FullName -TotalCount 1 -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($firstLine -eq "---") { $withFm++ }
}
if ($total -gt 0) {
    $pct = [math]::Round($withFm * 100 / $total)
    if ($pct -eq 100) {
        Write-Host "  ✅ README frontmatter 覆盖：$withFm / $total = 100%" -ForegroundColor Green
    } elseif ($pct -ge 80) {
        Write-Host "  🟡 README frontmatter 覆盖：$withFm / $total = $pct%（议题 CW / ADR-028 / 待补）" -ForegroundColor Yellow
        $warnings.Add("README frontmatter 覆盖率 $pct% （$($total-$withFm) 个待补）")
    } else {
        Write-Host "  🔴 README frontmatter 覆盖：$withFm / $total = $pct%（议题 CW 严重缺位）" -ForegroundColor Red
        $failures.Add("README frontmatter 覆盖率仅 $pct%")
    }
}

if ($failures.Count -gt 0) { exit 10 }
if ($warnings.Count -gt 0) { exit 5 }
exit 0
