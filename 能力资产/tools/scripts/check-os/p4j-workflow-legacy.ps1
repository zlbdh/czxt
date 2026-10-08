param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$hits = @()

$checks = @(
    @{ Path = "AGENTS.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "状态.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "操作系统/05_记忆/INDEX.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6|3\s*questions|three questions)" },
    @{ Path = "操作系统/05_记忆/行为反思.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "操作系统/07_完整工作流/decision-checkpoint.md"; Pattern = "Q7\s*检查[^\r\n]{0,40}Q1-Q6" },
    @{ Path = "操作系统/07_完整工作流/decision-checkpoint.md"; Pattern = "\*\*decision-checkpoint\*\*[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "操作系统/07_完整工作流/decision-checkpoint-判定细则.md"; Pattern = "Q7\s*检查[^\r\n]{0,40}Q1-Q6|decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "操作系统/07_完整工作流/decision-checkpoint-附录.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "操作系统/07_完整工作流/实施循环.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "操作系统/07_完整工作流/实施循环-附录.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" },
    @{ Path = "能力资产/skills/项目体检.md"; Pattern = "decision-checkpoint[^\r\n]{0,80}(3\s*问|三问|Q1-Q6)" }
)

foreach ($check in $checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    foreach ($match in [regex]::Matches($text, $check.Pattern)) {
        $line = ($text.Substring(0, $match.Index) -split "`n").Count
        $hits += "$($check.Path):L$line $($match.Value.Trim())"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  🔴 Obsolete decision-checkpoint language remains: $($hits.Count) matches" -ForegroundColor Red
    foreach ($hit in $hits) { Write-Host "    - $hit" -ForegroundColor Red }
    exit 10
}

Write-Host "  ✅ Current live documents contain no obsolete three-question/Q1-Q6 decision-checkpoint language" -ForegroundColor Green
exit 0
