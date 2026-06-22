$ErrorActionPreference = "Stop"

# PROP-001 路径 C 类软门禁契约（claude）。
# 从 hooks-smoke-claude-contracts.ps1 拆出：历史归档 / 嵌套归档 / apk 已存在 / apk 新建 / 普通 framework 放行。
# 本文件只负责 PROP-001 路径门禁断言，密钥检测契约仍在 claude-contracts。
function Invoke-HooksSmokeClaudePathGateContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  # PROP-001 路径 C 类软门禁（claude：permissionDecision=ask）
  # 正向 1：写 Docs/6-历史归档/ 历史归档（任意层级，无密钥也 ask；新建也 ask）。
  $archiveInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "Docs/6-历史归档/x.md"; content = "普通历史归档内容，无密钥。" }
  } | ConvertTo-Json -Depth 5 -Compress
  $archiveJson = ($archiveInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root) | ConvertFrom-Json
  Assert-True ($archiveJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for Docs/6-历史归档"
  Assert-True ($archiveJson.hookSpecificOutput.permissionDecisionReason -match "历史归档") "Claude PreToolUse archive reason should cite 历史归档"

  # 正向 1b：归档命中也对子层级 / 绝对路径生效。
  $archiveDeepInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "D:/WGKJ/x/Docs/6-历史归档/2025/old.md"; new_string = "改归档" }
  } | ConvertTo-Json -Depth 5 -Compress
  $archiveDeepJson = ($archiveDeepInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root) | ConvertFrom-Json
  Assert-True ($archiveDeepJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for nested/absolute Docs/6-历史归档"

  # 正向 2：写已存在的 apk/ 历史 APK → ask（构造真实存在文件）。
  $apkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-hooks-claude-apk-" + [guid]::NewGuid().ToString("N"))
  try {
    $apkDir = Join-Path $apkRoot "apk"
    New-Item -ItemType Directory -Force -Path $apkDir | Out-Null
    Set-Content -LiteralPath (Join-Path $apkDir "old.apk") -Encoding UTF8 -Value "fake-apk-bytes"
    $apkExistingInput = [ordered]@{
      hook_event_name = "PreToolUse"
      tool_input = [ordered]@{ file_path = "apk/old.apk"; content = "覆盖历史 APK" }
    } | ConvertTo-Json -Depth 5 -Compress
    $apkExistingJson = ($apkExistingInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $apkRoot) | ConvertFrom-Json
    Assert-True ($apkExistingJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for existing apk/ file"
    Assert-True ($apkExistingJson.hookSpecificOutput.permissionDecisionReason -match "APK") "Claude PreToolUse apk reason should cite 历史 APK"

    # 负向 2b：写 apk/ 下不存在的新文件 → 放行（仅"修改已存在"才 ask）。
    $apkNewInput = [ordered]@{
      hook_event_name = "PreToolUse"
      tool_input = [ordered]@{ file_path = "apk/brand-new.apk"; content = "新建 APK" }
    } | ConvertTo-Json -Depth 5 -Compress
    $apkNewJson = ($apkNewInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $apkRoot) | ConvertFrom-Json
    Assert-True ($apkNewJson.continue -eq $true) "Claude PreToolUse should allow new (non-existing) apk/ file"
  } finally {
    if (Test-Path -LiteralPath $apkRoot) { Remove-Item -LiteralPath $apkRoot -Recurse -Force }
  }

  # 负向 1：写普通 framework 文件（无密钥、非归档、非 apk）→ 放行 continue。
  $normalInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "操作系统/00_总入口.md"; content = "普通 framework 文档内容。" }
  } | ConvertTo-Json -Depth 5 -Compress
  $normalJson = ($normalInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root) | ConvertFrom-Json
  Assert-True ($normalJson.continue -eq $true) "Claude PreToolUse should allow normal framework file"
  Assert-True (-not $normalJson.hookSpecificOutput) "Claude PreToolUse normal file should not emit ask"
}
