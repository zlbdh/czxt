param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

# Claude Code Stop adapter (PROP-038 issue CK), mirroring codex/stop-chat-summary.ps1.
# Codex provides last_assistant_message directly in Stop; Claude Code provides transcript_path as JSONL.
# Accept both: prefer last_assistant_message, otherwise read the final assistant text from transcript_path.
# Reuse run-hooks chat-output checks for the seven-part handoff and PM role trace. Fail safe: uncertainty continues without a false block.

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
if ([string]::IsNullOrWhiteSpace($raw)) { Continue-Hook }

try {
  $event = $raw | ConvertFrom-Json
} catch {
  Continue-Hook
}

if ($event.stop_hook_active -eq $true) { Continue-Hook }

# 1) Codex format: last_assistant_message provides the text directly.
$message = if ($event.last_assistant_message) { [string]$event.last_assistant_message } else { "" }

# 2) Claude format: search transcript_path JSONL backward for the final assistant text blocks.
if ([string]::IsNullOrWhiteSpace($message) -and $event.transcript_path -and (Test-Path -LiteralPath $event.transcript_path)) {
  try {
    $lines = Get-Content -LiteralPath $event.transcript_path -ErrorAction Stop
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
      $line = $lines[$i]
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      try { $obj = $line | ConvertFrom-Json } catch { continue }
      if ($obj.type -ne 'assistant') { continue }
      $content = $obj.message.content
      if ($null -eq $content) { continue }
      $texts = @()
      foreach ($block in $content) {
        if ($block.type -eq 'text' -and $block.text) { $texts += [string]$block.text }
      }
      if ($texts.Count -gt 0) { $message = ($texts -join "`n"); break }
    }
  } catch {
    $message = ""
  }
}

if ([string]::IsNullOrWhiteSpace($message)) { Continue-Hook }

$readOnlyNoChange = $message -match '只读审计|未修改文件|未改文件|没有改文件|\bRead-only audit\b|\bNo files changed\b|\bNo files modified\b'
if ($readOnlyNoChange) {
  Continue-Hook
}
$hasCloseoutSignal = $message -match '文件变更|已修改|修改了|新增|测试[:：]|验证[:：]|PM 切换轨迹|交接区/待接手|commit hash|vitest|build|smoke|APK|push|commit|发布|验证|测试|构建|提交|\bFile changes\b|\bFiles changed\b|\bModified files\b|\bFiles modified\b|\bAdded files\b|\bTests\s*:|\bVerification\s*:|\bPM (?:role )?transitions\b'

$looksLikeImplementationCloseout = $hasCloseoutSignal

if (-not $looksLikeImplementationCloseout) { Continue-Hook }

$tmpPath = Join-Path ([System.IO.Path]::GetTempPath()) ("czxt-claude-stop-chat-" + [guid]::NewGuid().ToString("N") + ".txt")
$message | Set-Content -LiteralPath $tmpPath -Encoding UTF8

$runner = Join-Path $Root "能力资产\tools\hooks\run-hooks.ps1"
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner -Trigger chat-output -Mode Check -Root $Root -TextPath $tmpPath 2>&1
$code = $LASTEXITCODE
Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue

if ($code -eq 0) { Continue-Hook }

$reason = "This response appears to complete implementation but lacks the {{PROJECT_NAME}} seven-part handoff or PM role-transition trace. Complete the handoff before ending. Check output: $($output -join ' ')"
[ordered]@{
  decision = "block"
  reason = $reason
} | ConvertTo-Json -Depth 6 -Compress
