param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Claude Code PreCompact adapter (PROP-038 / issue CK): snapshot the latest PM role-transition trace and remind before context compaction.
# Preserve PM traces and pending completion handoffs across automatic compaction, addressing repeated trace loss during remediation sessions.
# Fail safe: uncertainty or errors return {continue:true}; never block compaction. No file writes; only systemMessage output.

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

function Pass {
  param($msg)
  $o = [ordered]@{ continue = $true }
  if ($msg) { $o.systemMessage = $msg }
  $o | ConvertTo-Json -Depth 5 -Compress
  exit 0
}

$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }  # Strip a leading stdin BOM from hosts that would otherwise cause JSON parsing to fail.
$trigger = "unknown"
try {
  if (-not [string]::IsNullOrWhiteSpace($raw)) {
    $e = $raw | ConvertFrom-Json
    if ($e.trigger) { $trigger = [string]$e.trigger }
  }
} catch {}

try {
  $statePath = Join-Path $Root "状态.md"
  if (-not (Test-Path -LiteralPath $statePath)) { Pass }
  $lines = @(Get-Content -LiteralPath $statePath -ErrorAction Stop)
  $lastIdx = -1
  for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match '^\|\s*\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s*\|') { $lastIdx = $i; break }
  }
  if ($lastIdx -lt 0) {
    Pass ("⚠️ Context compaction ({0}): afterward, reread the end of 状态.md to verify uninterrupted PM traces and provide any pending completion handoff." -f $trigger)
  }
  $lineNo = $lastIdx + 1
  $ts = ([regex]::Match($lines[$lastIdx], '\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}')).Value
  Pass ("⚠️ Before context compaction ({0}): latest PM trace at 状态.md L{1} ({2}). Afterward, reread the end of 状态.md to verify the trace and provide any pending completion handoff." -f $trigger, $lineNo, $ts)
} catch {
  Pass
}
