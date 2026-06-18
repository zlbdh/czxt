param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Claude Code PreCompact 适配器（PROP-038 / 议题 CK）：context 压缩前快照「最后 PM 切换轨迹」并提醒，
# 防 PM 留痕 / 未发收尾交接卡在自动压缩中丢失（治本 session 反复踩的留痕崩塌）。
# 全程 fail-safe：任何不确定 / 出错都输出 {continue:true}，绝不阻断压缩。零文件副作用（只发 systemMessage）。

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
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }  # 防个别宿主在 stdin 头塞 BOM 导致 JSON 解析失败
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
    Pass ("⚠️ context 压缩（{0}）：压缩后请 re-read 状态.md 末尾确认 PM 留痕未断、补未发收尾交接卡。" -f $trigger)
  }
  $lineNo = $lastIdx + 1
  $ts = ([regex]::Match($lines[$lastIdx], '\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}')).Value
  Pass ("⚠️ context 压缩（{0}）前快照：最后 PM 轨迹 状态.md L{1}（{2}）。压缩后请 re-read 状态.md 末尾确认留痕未断、补未发收尾交接卡。" -f $trigger, $lineNo, $ts)
} catch {
  Pass
}
