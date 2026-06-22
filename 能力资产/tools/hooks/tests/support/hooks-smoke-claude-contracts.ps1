$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeClaudeContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  $postInput = '{"hook_event_name":"PostToolUse","tool_input":{"file_path":"D:\\WGKJ\\{{PROJECT_NAME}}\\操作系统\\06_工具治理\\hooks-设计.md"}}'
  $claudePostOutput = $postInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $Root
  $claudePostJson = $claudePostOutput | ConvertFrom-Json
  Assert-True ($claudePostJson.continue -eq $true) "Claude PostToolUse bad"

  $postRelativeInput = '{"hook_event_name":"PostToolUse","tool_input":{"file_path":"操作系统/06_工具治理/hooks-设计.md"}}'
  $claudePostRelativeOutput = $postRelativeInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $Root
  $claudePostRelativeJson = $claudePostRelativeOutput | ConvertFrom-Json
  Assert-True ($claudePostRelativeJson.continue -eq $true) "Claude PostToolUse relative path bad"

  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-hooks-claude-pm-" + [guid]::NewGuid().ToString("N"))
  $tempScriptDir = Join-Path $tempRoot "能力资产\tools\scripts"
  New-Item -ItemType Directory -Force -Path $tempScriptDir | Out-Null
  Set-Content -LiteralPath (Join-Path $tempScriptDir "check-readme-indexes.ps1") -Encoding UTF8 -Value "param([string]`$Root)`nWrite-Host 'fake pm-workspace drift'`nexit 10`n"
  $pmPostInput = [ordered]@{
    hook_event_name = "PostToolUse"
    tool_input = [ordered]@{ file_path = "PM工作区/项目PM-咪咪/README.md" }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudePmPostOutput = $pmPostInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $tempRoot
  $claudePmPostJson = $claudePmPostOutput | ConvertFrom-Json
  Assert-True ($claudePmPostJson.systemMessage -match "fake pm-workspace drift") "Claude PostToolUse should run checker for PM工作区"

  $docs7PostInput = [ordered]@{
    hook_event_name = "PostToolUse"
    tool_input = [ordered]@{ file_path = "Docs/7-复盘/README.md" }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudeDocs7PostOutput = $docs7PostInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $tempRoot
  $claudeDocs7PostJson = $claudeDocs7PostOutput | ConvertFrom-Json
  Assert-True ($claudeDocs7PostJson.systemMessage -match "fake pm-workspace drift") "Claude PostToolUse should run checker for Docs/7-复盘"

  $tasksPostInput = [ordered]@{
    hook_event_name = "PostToolUse"
    tool_input = [ordered]@{ file_path = "TASKS.md" }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudeTasksPostOutput = $tasksPostInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $tempRoot
  $claudeTasksPostJson = $claudeTasksPostOutput | ConvertFrom-Json
  Assert-True ($claudeTasksPostJson.systemMessage -match "fake pm-workspace drift") "Claude PostToolUse should run checker for TASKS.md"

  $compactInput = '{"hook_event_name":"PreCompact","trigger":"manual"}'
  $compactOutput = $compactInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreCompact -Root $Root
  $compactJson = $compactOutput | ConvertFrom-Json
  Assert-True (($compactJson.continue -eq $true) -and ($compactJson.systemMessage -match "状态.md")) "Claude PreCompact bad"

  $fakeKey = "sk-ant-" + ("A" * 24)
  $preInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "notes.md"; content = $fakeKey }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudePreOutput = $preInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root
  $claudePreJson = $claudePreOutput | ConvertFrom-Json
  Assert-True ($claudePreJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse ask bad"

  $preEnvSuffixInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "notes.env"; content = $fakeKey }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudePreEnvSuffixOutput = $preEnvSuffixInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root
  $claudePreEnvSuffixJson = $claudePreEnvSuffixOutput | ConvertFrom-Json
  Assert-True ($claudePreEnvSuffixJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for notes.env"

  $preEnvExampleInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = "{{APP_REPO_DIR}}/.env.local.example"; content = $fakeKey }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudePreEnvExampleOutput = $preEnvExampleInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root
  $claudePreEnvExampleJson = $claudePreEnvExampleOutput | ConvertFrom-Json
  Assert-True ($claudePreEnvExampleJson.hookSpecificOutput.permissionDecision -eq "ask") "Claude PreToolUse should ask for tracked env examples"

  $preEnvLocalInput = [ordered]@{
    hook_event_name = "PreToolUse"
    tool_input = [ordered]@{ file_path = ".env.local"; content = $fakeKey }
  } | ConvertTo-Json -Depth 5 -Compress
  $claudePreEnvLocalOutput = $preEnvLocalInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePreWrite -Root $Root
  $claudePreEnvLocalJson = $claudePreEnvLocalOutput | ConvertFrom-Json
  Assert-True ($claudePreEnvLocalJson.continue -eq $true) "Claude PreToolUse should allow .env.local"

  $readOnlyStopInput = [ordered]@{
    hook_event_name = "Stop"
    stop_hook_active = $false
    last_assistant_message = "只读审计完成，未修改文件。`n① 交接区/待接手`n② 测试与 PM 切换轨迹。"
  } | ConvertTo-Json -Depth 5 -Compress
  $readOnlyStopOutput = $readOnlyStopInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudeStop -Root $Root
  $readOnlyStopJson = $readOnlyStopOutput | ConvertFrom-Json
  Assert-True ($readOnlyStopJson.continue -eq $true) "Claude Stop allow read-only line-start circled numbers"

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
