param([string]$Root)

$ErrorActionPreference = "Stop"
$sop = Join-Path $Root "操作系统\07_完整工作流\hooks-运行SOP.md"
$codex = Join-Path $Root ".codex\hooks.json"
if (-not (Test-Path -LiteralPath $sop) -or -not (Test-Path -LiteralPath $codex)) { exit 0 }

$text = Get-Content -LiteralPath $sop -Raw -Encoding UTF8
$json = Get-Content -LiteralPath $codex -Raw -Encoding UTF8 | ConvertFrom-Json
$post = [string]@($json.hooks.PostToolUse)[0].matcher
$pre = [string]@($json.hooks.PreToolUse)[0].matcher
if (($post -match "apply_patch") -and ($pre -match "apply_patch")) {
  $hasPost = $text -match 'PostToolUse[^\r\n]*Edit\\?\|Write\\?\|apply_patch'
  $hasPre = $text -match 'PreToolUse[^\r\n]*Edit\\?\|Write\\?\|apply_patch'
  if (-not ($hasPost -and $hasPre)) {
    Write-Host "  🔴 Hooks SOP does not specify the Codex Post/PreToolUse apply_patch matcher" -ForegroundColor Red
    exit 10
  }
}
if (($text -match "PreToolUse") -and (
    $text -notmatch "(?:不是完整 C 类判定器|not a complete Class C classifier)" -or
    $text -notmatch "baseUrl" -or
    $text -notmatch "(?:用户数据删除|user-data deletion)"
  )) {
  Write-Host "  🔴 Hooks SOP does not explain that PreToolUse only flags secret structure and cannot replace Class C/B boundary assessment" -ForegroundColor Red
  exit 10
}
if ($text -notmatch "check-operating-system\.ps1" -or $text -notmatch "(?:P4r hooks 配置与运行态锚点|P4r hook configuration and runtime anchors)") {
  Write-Host "  🔴 Hooks SOP does not require P4r after hooks documentation/runtime changes" -ForegroundColor Red
  exit 10
}
Write-Host "  ✅ Hooks SOP Codex apply_patch guidance matches .codex/hooks.json"
exit 0
