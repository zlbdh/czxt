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
}
