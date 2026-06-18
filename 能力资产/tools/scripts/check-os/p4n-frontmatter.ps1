param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
$workspace = Join-Path $Root "PM工作区"
$hits = @()

if (Test-Path -LiteralPath $workspace -PathType Container) {
    Get-ChildItem -LiteralPath $workspace -Recurse -Filter "*.md" -File | ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length + 1).Replace("\", "/")
        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        foreach ($m in [regex]::Matches($text, '(?m)^scope: agent$|^agent:')) {
            $line = ($text.Substring(0, $m.Index) -split "`n").Count
            $hits += "$rel`:L$line PM 工作区 frontmatter 不应把 PM 写成 agent"
        }
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 PM frontmatter 旧 agent 语义：$($hits.Count) 处" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ PM 工作区 frontmatter 使用 PM 语义" -ForegroundColor Green
exit 0
