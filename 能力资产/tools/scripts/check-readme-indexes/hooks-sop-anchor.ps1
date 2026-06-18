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
    Write-Host "  🔴 hooks SOP Codex Post/PreToolUse 未写明 apply_patch matcher" -ForegroundColor Red
    exit 10
  }
}
if (($text -match "PreToolUse") -and (
    $text -notmatch "不是完整 C 类判定器" -or
    $text -notmatch "baseUrl" -or
    $text -notmatch "用户数据删除"
  )) {
  Write-Host "  🔴 hooks SOP 未写明 PreToolUse 只做密钥结构提醒，不能替代 C/B 类边界判断" -ForegroundColor Red
  exit 10
}
if ($text -notmatch "check-operating-system\.ps1" -or $text -notmatch "P4r hooks 配置与运行态锚点") {
  Write-Host "  🔴 hooks SOP 未把 P4r 作为 hooks 文档/运行态变更后的收口检查" -ForegroundColor Red
  exit 10
}
Write-Host "  ✅ hooks SOP Codex apply_patch 口径与 .codex/hooks.json 对齐"
exit 0
