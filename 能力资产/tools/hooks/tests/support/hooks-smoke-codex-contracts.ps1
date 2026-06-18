$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeCodexContracts {
  param(
    [string]$Root,
    [object]$Paths,
    [object]$Fixture
  )

  $sessionInput = '{"hook_event_name":"SessionStart","source":"startup","cwd":"D:\\WGKJ\\{{PROJECT_NAME}}","model":"gpt-5"}'
  $sessionOutput = $sessionInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexSessionStart -Root $Root
  $sessionJson = $sessionOutput | ConvertFrom-Json
  Assert-True ($sessionJson.hookSpecificOutput.hookEventName -eq "SessionStart") "SessionStart bad"

  $promptInput = '{"hook_event_name":"UserPromptSubmit","turn_id":"t1","prompt":"继续检查 hooks","cwd":"D:\\WGKJ\\{{PROJECT_NAME}}","model":"gpt-5"}'
  $promptOutput = $promptInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexUserPrompt
  $promptJson = $promptOutput | ConvertFrom-Json
  Assert-True ($promptJson.hookSpecificOutput.hookEventName -eq "UserPromptSubmit") "Prompt bad"

  Invoke-HooksSmokeCodexStopContracts -Root $Root -Paths $Paths -Fixture $Fixture
  Invoke-HooksSmokeCodexToolContracts -Root $Root -Paths $Paths
}
