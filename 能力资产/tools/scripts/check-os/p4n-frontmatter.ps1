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
            $hits += "$rel`:L$line PM workspace frontmatter must not label a PM as an agent"
        }
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 PM frontmatter has obsolete agent semantics: $($hits.Count) matches" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ PM workspace frontmatter uses PM semantics" -ForegroundColor Green
exit 0
