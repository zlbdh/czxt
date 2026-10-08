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
{{PROJECT_NAME}} native Codex hooks are connected.
- External identity: Project PM Mimi; switch to Operating System PM Framework Steward for framework/hooks work.
- Authoritative executable hooks: $Root\能力资产\tools\hooks.
- Native Codex entry: $Root\.codex\hooks.json; do not copy business scripts into global Codex configuration.
- For changes to 操作系统/, 能力资产/, 确认改动/, 交接区/, or 状态.md, complete the PM role trace and seven-part handoff before finishing.
- Current cwd: $cwd.
"@

[ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = "SessionStart"
    additionalContext = $context.Trim()
  }
} | ConvertTo-Json -Depth 6 -Compress
