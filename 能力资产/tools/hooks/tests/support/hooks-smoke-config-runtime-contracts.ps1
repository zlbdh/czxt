$ErrorActionPreference = "Stop"

function Invoke-CodexConfiguredHookCommand {
  param([string]$Command, [string]$Payload, [string]$WorkingDirectory)
  $stderrPath = Join-Path ([IO.Path]::GetTempPath()) `
    ('czxt-hook-stderr-' + [guid]::NewGuid().ToString('N') + '.txt')
  Push-Location -LiteralPath $WorkingDirectory
  try {
    $output = @($Payload | & cmd.exe /d /s /c $Command 2> $stderrPath)
    $code = $LASTEXITCODE
    $stderr = if (Test-Path -LiteralPath $stderrPath) {
      [IO.File]::ReadAllText($stderrPath)
    } else { '' }
  }
  finally {
    Pop-Location
    if (Test-Path -LiteralPath $stderrPath) {
      Remove-Item -LiteralPath $stderrPath -Force
    }
  }
  return [pscustomobject]@{
    ExitCode = $code; Output = ($output -join "`n"); StdErr = $stderr
  }
}

function Test-CodexBenignPowerShellStderr {
  param([string]$StdErr)
  if ([string]::IsNullOrWhiteSpace($StdErr)) { return $true }
  if (-not $StdErr.StartsWith('#< CLIXML', [StringComparison]::Ordinal)) {
    return $false
  }
  $xmlStart = $StdErr.IndexOf('<Objs ', [StringComparison]::Ordinal)
  if ($xmlStart -lt 0) { return $false }
  try { [xml]$document = $StdErr.Substring($xmlStart) }
  catch { return $false }
  $activities = @($document.SelectNodes("//*[local-name()='AV']"))
  return $activities.Count -gt 0 -and @($activities | Where-Object {
      $_.InnerText -cne 'Preparing modules for first use.'
    }).Count -eq 0
}

function New-CodexBootstrapFixture {
  param([string]$Root, [string]$Label, [string]$DispatcherSource)
  foreach ($relative in @('.codex', 'child', '能力资产\tools\hooks\codex')) {
    [void][IO.Directory]::CreateDirectory((Join-Path $Root $relative))
  }
  [IO.File]::WriteAllText((Join-Path $Root '.czxt-project-root'),
    "czxt-root-mode=project`nschema=1`n", (New-Object Text.UTF8Encoding($false)))
  [IO.File]::WriteAllText((Join-Path $Root '.codex\hooks.json'), "{}`n",
    (New-Object Text.UTF8Encoding($false)))
  [IO.File]::Copy($DispatcherSource, (Join-Path $Root '.codex\invoke-hook.ps1'))
  $probe = @"
`$null = [Console]::In.ReadToEnd()
[ordered]@{ selected = '$Label' } | ConvertTo-Json -Compress
"@
  [IO.File]::WriteAllText((Join-Path $Root `
      '能力资产\tools\hooks\codex\session-start.ps1'), $probe,
    (New-Object Text.UTF8Encoding($true)))
}

function Invoke-HooksSmokeConfigRuntimeContracts {
  param([object]$Paths)

  $codexHooks = Get-Content -LiteralPath $Paths.CodexHooks -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-EventSet $codexHooks.hooks @("SessionStart", "UserPromptSubmit", "Stop", "PostToolUse", "PreToolUse") "Codex hooks"
  Assert-ConfigScriptsExist $codexHooks.hooks "Codex hooks"
  Assert-HookMapsTo $codexHooks.hooks "SessionStart" $Paths.CodexSessionStart "Codex hooks" "startup|resume|clear|compact" 15 "加载{{PROJECT_NAME}}项目治理上下文" "session-start" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "UserPromptSubmit" $Paths.CodexUserPrompt "Codex hooks" "" 10 "检查用户输入的项目治理上下文" "user-prompt-submit" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "Stop" $Paths.CodexStop "Codex hooks" "" 15 "检查实施收尾交接卡格式" "stop-chat-summary" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "PostToolUse" $Paths.CodexPost "Codex hooks" "Edit|Write|apply_patch" 20 "改 framework 后快检索引一致性" "post-edit-framework-check" "Codex"
  Assert-HookMapsTo $codexHooks.hooks "PreToolUse" $Paths.CodexPreWrite "Codex hooks" "Edit|Write|apply_patch" 10 "敏感写入(密钥)前置确认" "pre-write-guard" "Codex"
  $dispatchCases = [ordered]@{
    "session-start" = '{"hook_event_name":"SessionStart","source":"startup","cwd":"D:\\fixture","model":"gpt-5"}'
    "user-prompt-submit" = '{"hook_event_name":"UserPromptSubmit","turn_id":"t1","prompt":"检查 hooks","cwd":"D:\\fixture","model":"gpt-5"}'
    "stop-chat-summary" = '{"hook_event_name":"Stop","turn_id":"t1","response":"只读检查完成，无代码修改。","cwd":"D:\\fixture","model":"gpt-5"}'
    "post-edit-framework-check" = '{"hook_event_name":"PostToolUse","turn_id":"t1","tool_name":"apply_patch","tool_input":{"file_path":"notes.txt"},"cwd":"D:\\fixture","model":"gpt-5"}'
    "pre-write-guard" = '{"hook_event_name":"PreToolUse","turn_id":"t1","tool_name":"apply_patch","tool_input":{"file_path":"notes.txt","content":"safe"},"cwd":"D:\\fixture","model":"gpt-5"}'
  }
  foreach ($event in $codexHooks.hooks.PSObject.Properties) {
    $hook = @(@($event.Value)[0].hooks)[0]
    $dispatchName = Get-CodexHookDispatchName ([string]$hook.commandWindows)
    $result = Invoke-CodexConfiguredHookCommand `
      ([string]$hook.commandWindows) $dispatchCases[$dispatchName] `
      (Join-Path $script:HooksSmokeRoot '能力资产')
    Assert-True ($result.ExitCode -eq 0) `
      "Codex dispatcher $dispatchName exit drift: $($result.ExitCode)"
    Assert-True (-not [string]::IsNullOrWhiteSpace($result.Output)) `
      "Codex dispatcher $dispatchName returned no JSON"
    Assert-True (Test-CodexBenignPowerShellStderr $result.StdErr) `
      "Codex dispatcher $dispatchName returned unexpected stderr"
    Assert-True ($null -ne ($result.Output | ConvertFrom-Json)) `
      "Codex dispatcher $dispatchName returned invalid JSON"
  }
  & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File $Paths.CodexDispatcher -Hook unknown 1>$null 2>$null
  Assert-True ($LASTEXITCODE -eq 64) `
    'Codex dispatcher should reject an unknown hook name with exit 64'

  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('czxt-hooks-bootstrap-' + [guid]::NewGuid().ToString('N'))
  try {
    $standalone = Join-Path $tempRoot 'standalone'
    New-CodexBootstrapFixture $standalone 'standalone' $Paths.CodexDispatcher
    $sessionHook = @(@($codexHooks.hooks.SessionStart)[0].hooks)[0]
    $probePayload = '{"hook_event_name":"SessionStart","source":"startup","cwd":"D:\\fixture","model":"gpt-5"}'
    $standaloneResult = Invoke-CodexConfiguredHookCommand `
      ([string]$sessionHook.commandWindows) $probePayload `
      (Join-Path $standalone 'child')
    Assert-True ($standaloneResult.ExitCode -eq 0) `
      'Codex bootstrap failed in an independent non-Git project'
    Assert-True (Test-CodexBenignPowerShellStderr $standaloneResult.StdErr) `
      'Codex bootstrap emitted unexpected stderr in a non-Git project'
    Assert-True (($standaloneResult.Output | ConvertFrom-Json).selected -ceq `
        'standalone') 'Codex bootstrap selected the wrong non-Git project root'

    $outer = Join-Path $tempRoot 'outer'
    $inner = Join-Path $outer 'container\inner'
    New-CodexBootstrapFixture $outer 'outer' $Paths.CodexDispatcher
    New-CodexBootstrapFixture $inner 'inner' $Paths.CodexDispatcher
    & git -C $outer init --quiet
    Assert-True ($LASTEXITCODE -eq 0) 'nested fixture outer Git init failed'
    $nestedResult = Invoke-CodexConfiguredHookCommand `
      ([string]$sessionHook.commandWindows) $probePayload `
      (Join-Path $inner 'child')
    Assert-True ($nestedResult.ExitCode -eq 0) `
      'Codex bootstrap failed in a nested project'
    Assert-True (Test-CodexBenignPowerShellStderr $nestedResult.StdErr) `
      'Codex bootstrap emitted unexpected stderr in a nested project'
    Assert-True (($nestedResult.Output | ConvertFrom-Json).selected -ceq 'inner') `
      'Codex bootstrap escaped to the outer Git project'

    [IO.File]::WriteAllText((Join-Path $inner '.czxt-template-root'),
      "czxt-root-mode=template`nschema=1`n", (New-Object Text.UTF8Encoding($false)))
    $conflictResult = Invoke-CodexConfiguredHookCommand `
      ([string]$sessionHook.commandWindows) $probePayload `
      (Join-Path $inner 'child')
    Assert-True ($conflictResult.ExitCode -eq 0) `
      'Codex bootstrap conflict root should fail safe'
    Assert-True ([string]::IsNullOrWhiteSpace($conflictResult.Output)) `
      'Codex bootstrap executed a conflict root or escaped to its outer root'
  }
  finally {
    if (Test-Path -LiteralPath $tempRoot) {
      Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
  }
  $codexDrift = $codexHooks | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $codexPost = @($codexDrift.hooks.PostToolUse)[0]
  $codexPostHook = @($codexPost.hooks)[0]
  $codexPostHook.commandWindows = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$($Paths.CodexUserPrompt)`""
  $codexDriftCaught = $false
  try {
    Assert-HookMapsTo $codexDrift.hooks "PostToolUse" $Paths.CodexPost "Codex hooks drift fixture" "Edit|Write|apply_patch" 20 "改 framework 后快检索引一致性" "post-edit-framework-check" "Codex"
  } catch {
    if ($_.Exception.Message -match "dispatch drift") { $codexDriftCaught = $true } else { throw }
  }
  Assert-True $codexDriftCaught "Codex hooks PostToolUse drift fixture should fail"
  $codexCommandDrift = $codexHooks | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $codexCommandPost = @($codexCommandDrift.hooks.PostToolUse)[0]
  $codexCommandHook = @($codexCommandPost.hooks)[0]
  $codexCommandHook.command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$($Paths.CodexUserPrompt)`""
  $codexCommandDriftCaught = $false
  try {
    Assert-HookMapsTo $codexCommandDrift.hooks "PostToolUse" $Paths.CodexPost "Codex hooks command drift fixture" "Edit|Write|apply_patch" 20 "改 framework 后快检索引一致性" "post-edit-framework-check" "Codex"
  } catch {
    if ($_.Exception.Message -match "dispatch drift") { $codexCommandDriftCaught = $true } else { throw }
  }
  Assert-True $codexCommandDriftCaught "Codex hooks PostToolUse command drift fixture should fail"

  $claudeSettings = Get-Content -LiteralPath $Paths.ClaudeSettings -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-EventSet $claudeSettings.hooks @("SessionStart", "UserPromptSubmit", "Stop", "PostToolUse", "PreCompact", "PreToolUse") "Claude hooks"
  Assert-ConfigScriptsExist $claudeSettings.hooks "Claude hooks"
  Assert-HookMapsTo $claudeSettings.hooks "SessionStart" $Paths.CodexSessionStart "Claude hooks" "" 15 "加载{{PROJECT_NAME}}项目治理上下文" "" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "UserPromptSubmit" $Paths.CodexUserPrompt "Claude hooks" "" 10 "检查用户输入的项目治理上下文" "" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "Stop" $Paths.ClaudeStop "Claude hooks" "" 15 "检查实施收尾交接卡格式" "" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "PostToolUse" $Paths.ClaudePost "Claude hooks" "Edit|Write" 20 "改 framework 后快检索引一致性" "" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "PreCompact" $Paths.ClaudePreCompact "Claude hooks" "auto|manual" 15 "压缩前留存 PM 轨迹" "" "Claude"
  Assert-HookMapsTo $claudeSettings.hooks "PreToolUse" $Paths.ClaudePreWrite "Claude hooks" "Edit|Write" 10 "敏感写入(密钥)前置确认" "" "Claude"
  $claudeDrift = $claudeSettings | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $claudeStop = @($claudeDrift.hooks.Stop)[0]
  $claudeStopHook = @($claudeStop.hooks)[0]
  $claudeArgs = @($claudeStopHook.args)
  for ($i = 0; $i -lt $claudeArgs.Count - 1; $i++) {
    if ([string]$claudeArgs[$i] -eq "-File") { $claudeStopHook.args[$i + 1] = $Paths.CodexStop; break }
  }
  $claudeDriftCaught = $false
  try {
    Assert-HookMapsTo $claudeDrift.hooks "Stop" $Paths.ClaudeStop "Claude hooks drift fixture" "" 15 "检查实施收尾交接卡格式" "" "Claude"
  } catch {
    if ($_.Exception.Message -match "script drift") { $claudeDriftCaught = $true } else { throw }
  }
  Assert-True $claudeDriftCaught "Claude hooks Stop drift fixture should fail"

  Write-Host "  ✅ Codex/Claude 原生 hooks 事件到脚本映射对齐（含负向漂移 fixture）"
}
