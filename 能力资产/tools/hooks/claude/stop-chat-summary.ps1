param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

# Claude Code 侧 Stop 适配器（PROP-038 议题 CK / 镜像 codex/stop-chat-summary.ps1）。
# 差异：Codex 在 Stop 事件直接传 last_assistant_message；Claude Code 传 transcript_path（JSONL）。
# 本脚本两者都吃：优先 last_assistant_message，否则从 transcript_path 读最后一条 assistant 文本，
# 再复用同一条 run-hooks chat-output 检查（①-⑦ 交接卡 + PM 切换轨迹）。全程 fail-safe（任何不确定都 continue，绝不误 block）。

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

# 1) Codex 风格：last_assistant_message 直接给文本
$message = if ($event.last_assistant_message) { [string]$event.last_assistant_message } else { "" }

# 2) Claude 风格：从 transcript_path JSONL 倒序找最后一条 assistant 的 text 块
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

$readOnlyNoChange = $message -match '只读审计|未修改文件|未改文件|没有改文件'
if ($readOnlyNoChange) {
  Continue-Hook
}
$hasCloseoutSignal = $message -match '文件变更|已修改|修改了|新增|测试[:：]|验证[:：]|PM 切换轨迹|交接区/待接手|commit hash|vitest|build|smoke|APK|push|commit|发布|验证|测试|构建|提交'

$looksLikeImplementationCloseout = $hasCloseoutSignal

if (-not $looksLikeImplementationCloseout) { Continue-Hook }

$tmpPath = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-claude-stop-chat-" + [guid]::NewGuid().ToString("N") + ".txt")
$message | Set-Content -LiteralPath $tmpPath -Encoding UTF8

$runner = Join-Path $Root "能力资产\tools\hooks\run-hooks.ps1"
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner -Trigger chat-output -Mode Check -Root $Root -TextPath $tmpPath 2>&1
$code = $LASTEXITCODE
Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue

if ($code -eq 0) { Continue-Hook }

$reason = "本次回复像实施收尾，但缺少{{PROJECT_NAME}} ①-⑦ 交接卡或 PM 切换轨迹说明。请补齐交接卡后再结束。检查输出：$($output -join ' ')"
[ordered]@{
  decision = "block"
  reason = $reason
} | ConvertTo-Json -Depth 6 -Compress
