param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {
  # Best effort for older PowerShell hosts.
}

function Continue-Hook {
  [ordered]@{ continue = $true } | ConvertTo-Json -Depth 4 -Compress
  exit 0
}

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) {
  Continue-Hook
}

try {
  $event = $raw | ConvertFrom-Json
} catch {
  Continue-Hook
}

if ($event.stop_hook_active -eq $true) {
  Continue-Hook
}

$message = if ($event.last_assistant_message) { [string]$event.last_assistant_message } else { "" }
if ([string]::IsNullOrWhiteSpace($message)) {
  Continue-Hook
}

$readOnlyNoChange = $message -match '只读审计|未修改文件|未改文件|没有改文件|\bRead-only audit\b|\bNo files changed\b|\bNo files modified\b'
if ($readOnlyNoChange) {
  Continue-Hook
}
$hasCloseoutSignal = $message -match '文件变更|已修改|修改了|新增|测试[:：]|验证[:：]|PM 切换轨迹|交接区/待接手|commit hash|vitest|build|smoke|APK|push|commit|发布|验证|测试|构建|提交|\bFile changes\b|\bFiles changed\b|\bModified files\b|\bFiles modified\b|\bAdded files\b|\bTests\s*:|\bVerification\s*:|\bPM (?:role )?transitions\b'

$looksLikeImplementationCloseout = $hasCloseoutSignal

if (-not $looksLikeImplementationCloseout) {
  Continue-Hook
}

$tmpPath = Join-Path ([System.IO.Path]::GetTempPath()) ("czxt-codex-stop-chat-" + [guid]::NewGuid().ToString("N") + ".txt")
$message | Set-Content -LiteralPath $tmpPath -Encoding UTF8

$runner = Join-Path $Root "能力资产\tools\hooks\run-hooks.ps1"
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner -Trigger chat-output -Mode Check -Root $Root -TextPath $tmpPath 2>&1
$code = $LASTEXITCODE
Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue

if ($code -eq 0) {
  Continue-Hook
}

$reason = "This response appears to complete implementation but lacks the {{PROJECT_NAME}} seven-part handoff or PM role-transition trace. Complete the handoff before ending. Check output: $($output -join ' ')"
[ordered]@{
  decision = "block"
  reason = $reason
} | ConvertTo-Json -Depth 6 -Compress
