param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
$gitFlowPath = Join-Path $Root "操作系统/07_完整工作流/git流程.md"
$releaseFlowPath = Join-Path $Root "操作系统/07_完整工作流/发布流程.md"

if ((Test-Path -LiteralPath $gitFlowPath) -and (Test-Path -LiteralPath $releaseFlowPath)) {
    $gitFlowText = Get-Content -LiteralPath $gitFlowPath -Raw -ErrorAction SilentlyContinue
    $releaseFlowText = Get-Content -LiteralPath $releaseFlowPath -Raw -ErrorAction SilentlyContinue
    if ($gitFlowText -match "单 main 分支") {
        $matches = [regex]::Matches($releaseFlowText, "hotfix/|创建\s+hotfix\s+分支|merge\s+回\s+main")
        if ($matches.Count -gt 0) {
            Write-Host "  🔴 发布流程仍含 hotfix 分支步骤：$($matches.Count) 处" -ForegroundColor Red
            exit 10
        }
        Write-Host "  ✅ 发布流程未发现 hotfix 分支步骤，符合单 main 策略" -ForegroundColor Green
        exit 0
    }
    Write-Host "  ℹ️ git流程未声明单 main 分支，跳过 P4l" -ForegroundColor Gray
    exit 0
}

Write-Host "  ℹ️ git流程.md 或 发布流程.md 不存在，P4a 已应提示" -ForegroundColor Gray
exit 0
