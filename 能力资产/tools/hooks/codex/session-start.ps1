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

$raw = [Console]::In.ReadToEnd()
$event = $null
if (-not [string]::IsNullOrWhiteSpace($raw)) {
  try {
    $event = $raw | ConvertFrom-Json
  } catch {
    $event = $null
  }
}

$cwd = if ($event -and $event.cwd) { [string]$event.cwd } else { (Get-Location).Path }
$context = @"
{{PROJECT_NAME}} Codex 原生 hooks 已接入。
- 对外身份：项目 PM「咪咪」；涉及 framework/hooks 时切操作系统 PM「框架管家」。
- 可执行 hooks 真源头：$Root\能力资产\tools\hooks。
- Codex 原生入口：$Root\.codex\hooks.json；不要把业务脚本复制进全局 Codex 配置。
- 涉及 操作系统/、能力资产/、确认改动/、交接区/、状态.md 的改动，收尾前补 PM 切换轨迹并发 ①-⑦ 交接卡。
- 当前 cwd：$cwd。
"@

[ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = "SessionStart"
    additionalContext = $context.Trim()
  }
} | ConvertTo-Json -Depth 6 -Compress
