$ErrorActionPreference = "Stop"

# PROP-001 Class C path-warning contracts for Claude.
# Extracted from hooks-smoke-claude-contracts.ps1: archives, nested archives, existing/new APKs, and ordinary framework writes.
# This file covers PROP-001 path gates only; secret-detection contracts remain in claude-contracts.
function Invoke-HooksSmokeClaudePathGateContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  # PROP-001 Class C path warnings: Claude uses permissionDecision=ask.
  # Positive 1: any write under Docs/6-历史归档/ asks, at any depth, even without secrets and even for new files.
  $archiveInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "Docs/6-历史归档/x.md"; content = "Ordinary historical archive content without secrets." }
  } | ConvertTo-Json -Depth 5 -Compress
  $archiveJson = ($archiveInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root) | ConvertFrom-Json
  Assert-True ($archiveJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for Docs/6-历史归档"
  Assert-True ($archiveJson.hookSpecificOutput.permissionDecisionReason -match "historical archive") "Claude PreToolUse archive reason should cite the historical archive"

  # Positive 1b: archive detection also applies to nested and absolute paths.
  $archiveDeepInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "D:/WGKJ/x/Docs/6-历史归档/2025/old.md"; new_string = "Update archive content" }
  } | ConvertTo-Json -Depth 5 -Compress
  $archiveDeepJson = ($archiveDeepInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root) | ConvertFrom-Json
  Assert-True ($archiveDeepJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for nested/absolute Docs/6-历史归档"

  # Positive 2: writing an existing historical APK asks; create a real fixture file.
  $apkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("czxt-hooks-claude-apk-" + [guid]::NewGuid().ToString("N"))
  try {
    $apkDir = Join-Path $apkRoot "apk"
    New-Item -ItemType Directory -Force -Path $apkDir | Out-Null
    Set-Content -LiteralPath (Join-Path $apkDir "old.apk") -Encoding UTF8 -Value "fake-apk-bytes"
    $apkExistingInput = [ordered]@{
      hook_event_name = "PreToolUse"
      tool_input = [ordered]@{ file_path = "apk/old.apk"; content = "Overwrite historical APK" }
    } | ConvertTo-Json -Depth 5 -Compress
    $apkExistingJson = ($apkExistingInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $apkRoot) | ConvertFrom-Json
    Assert-True ($apkExistingJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for existing apk/ file"
    Assert-True ($apkExistingJson.hookSpecificOutput.permissionDecisionReason -match "APK") "Claude PreToolUse APK reason should cite the historical APK"

    # Negative 2b: allow a new file under apk/; only modification of an existing file asks.
    $apkNewInput = [ordered]@{
      hook_event_name = "PreToolUse"
      tool_input = [ordered]@{ file_path = "apk/brand-new.apk"; content = "Create new APK" }
    } | ConvertTo-Json -Depth 5 -Compress
    $apkNewJson = ($apkNewInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $apkRoot) | ConvertFrom-Json
    Assert-True ($apkNewJson.continue -eq $true) "Claude PreToolUse should allow new (non-existing) apk/ file"
  } finally {
    if (Test-Path -LiteralPath $apkRoot) { Remove-Item -LiteralPath $apkRoot -Recurse -Force }
  }

  # Negative 1: an ordinary framework file without secrets, outside archives and apk/, continues.
  $normalInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "操作系统/00_总入口.md"; content = "Ordinary framework documentation." }
  } | ConvertTo-Json -Depth 5 -Compress
  $normalJson = ($normalInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root) | ConvertFrom-Json
  Assert-True ($normalJson.continue -eq $true) "Claude PreToolUse should allow normal framework file"
  Assert-True (-not $normalJson.hookSpecificOutput) "Claude PreToolUse normal file should not emit ask"
}
