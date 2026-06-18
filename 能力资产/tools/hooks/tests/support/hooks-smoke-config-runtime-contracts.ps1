$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeConfigRuntimeContracts {
  param([object]$Paths)

  $codexHooks = Get-Content -LiteralPath $Paths.CodexHooks -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-EventSet $codexHooks.hooks @("SessionStart", "UserPromptSubmit", "Stop", "PostToolUse", "PreToolUse") "Codex hooks"
  Assert-ConfigScriptsExist $codexHooks.hooks "Codex hooks"
  Assert-HookMapsTo $codexHooks.hooks "SessionStart" $Paths.CodexSessionStart "Codex hooks" "startup|resume|clear|compact" 15 "加载{{PROJECT_NAME}}项目治理上下文" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "UserPromptSubmit" $Paths.CodexUserPrompt "Codex hooks" "" 10 "检查用户输入的项目治理上下文" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "Stop" $Paths.CodexStop "Codex hooks" "" 15 "检查实施收尾交接卡格式" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "PostToolUse" $Paths.CodexPost "Codex hooks" "Edit|Write|apply_patch" 20 "改 framework 后快检索引一致性" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "PreToolUse" $Paths.CodexPreWrite "Codex hooks" "Edit|Write|apply_patch" 10 "敏感写入(密钥)前置确认" "Codex"
  $codexDrift = $codexHooks | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $codexPost = @($codexDrift.hooks.PostToolUse)[0]
  $codexPostHook = @($codexPost.hooks)[0]
  $codexPostHook.commandWindows = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$($Paths.CodexUserPrompt)`""
  $codexDriftCaught = $false
  try {
    Assert-HookMapsTo $codexDrift.hooks "PostToolUse" $Paths.CodexPost "Codex hooks drift fixture" "Edit|Write|apply_patch" 20 "改 framework 后快检索引一致性" "Codex"
  } catch {
    if ($_.Exception.Message -match "script drift") { $codexDriftCaught = $true } else { throw }
  }
  Assert-True $codexDriftCaught "Codex hooks PostToolUse drift fixture should fail"
  $codexCommandDrift = $codexHooks | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $codexCommandPost = @($codexCommandDrift.hooks.PostToolUse)[0]
  $codexCommandHook = @($codexCommandPost.hooks)[0]
  $codexCommandHook.command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$($Paths.CodexUserPrompt)`""
  $codexCommandDriftCaught = $false
  try {
    Assert-HookMapsTo $codexCommandDrift.hooks "PostToolUse" $Paths.CodexPost "Codex hooks command drift fixture" "Edit|Write|apply_patch" 20 "改 framework 后快检索引一致性" "Codex"
  } catch {
    if ($_.Exception.Message -match "script drift") { $codexCommandDriftCaught = $true } else { throw }
  }
  Assert-True $codexCommandDriftCaught "Codex hooks PostToolUse command drift fixture should fail"

  $claudeSettings = Get-Content -LiteralPath $Paths.ClaudeSettings -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-EventSet $claudeSettings.hooks @("SessionStart", "UserPromptSubmit", "Stop", "PostToolUse", "PreCompact", "PreToolUse") "Claude hooks"
  Assert-ConfigScriptsExist $claudeSettings.hooks "Claude hooks"
  Assert-HookMapsTo $claudeSettings.hooks "SessionStart" $Paths.CodexSessionStart "Claude hooks" "" 15 "加载{{PROJECT_NAME}}项目治理上下文" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "UserPromptSubmit" $Paths.CodexUserPrompt "Claude hooks" "" 10 "检查用户输入的项目治理上下文" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "Stop" $Paths.ClaudeStop "Claude hooks" "" 15 "检查实施收尾交接卡格式" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "PostToolUse" $Paths.ClaudePost "Claude hooks" "Edit|Write" 20 "改 framework 后快检索引一致性" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "PreCompact" $Paths.ClaudePreCompact "Claude hooks" "auto|manual" 15 "压缩前留存 PM 轨迹" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "PreToolUse" $Paths.ClaudePreWrite "Claude hooks" "Edit|Write" 10 "敏感写入(密钥)前置确认" "Claude"
  $claudeDrift = $claudeSettings | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $claudeStop = @($claudeDrift.hooks.Stop)[0]
  $claudeStopHook = @($claudeStop.hooks)[0]
  $claudeArgs = @($claudeStopHook.args)
  for ($i = 0; $i -lt $claudeArgs.Count - 1; $i++) {
    if ([string]$claudeArgs[$i] -eq "-File") { $claudeStopHook.args[$i + 1] = $Paths.CodexStop; break }
  }
  $claudeDriftCaught = $false
  try {
    Assert-HookMapsTo $claudeDrift.hooks "Stop" $Paths.ClaudeStop "Claude hooks drift fixture" "" 15 "检查实施收尾交接卡格式" "Claude"
  } catch {
    if ($_.Exception.Message -match "script drift") { $claudeDriftCaught = $true } else { throw }
  }
  Assert-True $claudeDriftCaught "Claude hooks Stop drift fixture should fail"

  Write-Host "  ✅ Codex/Claude 原生 hooks 事件到脚本映射对齐（含负向漂移 fixture）"
}
