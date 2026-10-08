param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$gitFlowPath = Join-Path $Root "操作系统/07_完整工作流/git流程.md"
$releaseFlowPath = Join-Path $Root "操作系统/07_完整工作流/发布流程.md"

if ((Test-Path -LiteralPath $gitFlowPath) -and (Test-Path -LiteralPath $releaseFlowPath)) {
    $gitFlowText = Get-Content -LiteralPath $gitFlowPath -Raw -ErrorAction SilentlyContinue
    $releaseFlowText = Get-Content -LiteralPath $releaseFlowPath -Raw -ErrorAction SilentlyContinue
    if ($gitFlowText -match "单 main 分支|Single main branch") {
        $matches = [regex]::Matches($releaseFlowText, "hotfix/|创建\s+hotfix\s+分支|merge\s+回\s+main|create\s+a\s+hotfix\s+branch|merge\s+back\s+into\s+main")
        if ($matches.Count -gt 0) {
            Write-Host "  🔴 Release flow still includes hotfix branch steps: $($matches.Count) matches" -ForegroundColor Red
            exit 10
        }
        Write-Host "  ✅ Release flow has no hotfix branch steps and follows the single-main policy" -ForegroundColor Green
        exit 0
    }
    Write-Host "  ℹ️ Git flow does not declare a single main branch; skipping P4l" -ForegroundColor Gray
    exit 0
}

Write-Host "  ℹ️ git流程.md or 发布流程.md is missing; P4a should already have reported it" -ForegroundColor Gray
exit 0
