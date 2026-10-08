$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeCodexToolContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  function New-HookJson([string]$Event, [object]$ToolInput) {
    [ordered]@{ hook_event_name = $Event; tool_input = $ToolInput } | ConvertTo-Json -Depth 8 -Compress
  }

  function Invoke-CodexJson([string]$Script, [string]$InputJson, [string]$RunRoot = $Root) {
    $out = $InputJson | powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Root $RunRoot
    return ($out | ConvertFrom-Json)
  }

  function Assert-CodexPostCheckerTriggered([object]$ToolInput, [string]$Label, [string]$RunRoot) {
    $json = Invoke-CodexJson $Paths.CodexPost (New-HookJson "PostToolUse" $ToolInput) $RunRoot
    Assert-True ($json.continue -eq $true) "$Label should continue"
    Assert-True ($json.systemMessage -match "fake pm-workspace drift") "$Label should run checker"
    Assert-True ($json.hookSpecificOutput.hookEventName -eq "PostToolUse") "$Label missing PostToolUse context"
    Assert-True ($json.hookSpecificOutput.additionalContext -match "fake pm-workspace drift") "$Label missing additionalContext"
  }

  function Assert-CodexSoftWarning([object]$Payload, [string]$Label) {
    $json = Invoke-CodexJson $Paths.CodexPreWrite $Payload
    Assert-True ($json.continue -eq $true) "$Label should continue"
    Assert-True ($json.systemMessage -match "Suspected key") "$Label missing systemMessage warning"
    Assert-True ($json.hookSpecificOutput.hookEventName -eq "PreToolUse") "$Label missing PreToolUse context"
    Assert-True ($json.hookSpecificOutput.additionalContext -match "Suspected key") "$Label missing additionalContext"
  }

  function Assert-CodexNoWarning([object]$Payload, [string]$Label) {
    $json = Invoke-CodexJson $Paths.CodexPreWrite $Payload
    Assert-True ($json.continue -eq $true) "$Label should continue"
    Assert-True (-not $json.systemMessage) "$Label should not emit systemMessage"
    Assert-True (-not $json.hookSpecificOutput) "$Label should not emit hookSpecificOutput"
  }

  $absHookDoc = Join-Path $Root "操作系统\06_工具治理\hooks-设计.md"
  $absPost = Invoke-CodexJson $Paths.CodexPost (New-HookJson "PostToolUse" ([ordered]@{ file_path = $absHookDoc }))
  Assert-True ($absPost.continue -eq $true) "Codex PostToolUse absolute path bad"

  $relPost = Invoke-CodexJson $Paths.CodexPost (New-HookJson "PostToolUse" ([ordered]@{ file_path = "操作系统/06_工具治理/hooks-设计.md" }))
  Assert-True ($relPost.continue -eq $true) "Codex PostToolUse relative path bad"

  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("czxt-hooks-codex-pm-" + [guid]::NewGuid().ToString("N"))
  try {
    $tempScriptDir = Join-Path $tempRoot "能力资产\tools\scripts"
    New-Item -ItemType Directory -Force -Path $tempScriptDir | Out-Null
    Set-Content -LiteralPath (Join-Path $tempScriptDir "check-readme-indexes.ps1") -Encoding UTF8 -Value "param([string]`$Root)`nWrite-Host 'fake pm-workspace drift hooks SOP event matrix P4r'`nexit 10`n"

    Assert-CodexPostCheckerTriggered ([ordered]@{ file_path = "PM工作区/项目PM-咪咪/README.md" }) "Codex PostToolUse PM workspace" $tempRoot
    Assert-CodexPostCheckerTriggered ([ordered]@{ file_path = "Docs/7-复盘/README.md" }) "Codex PostToolUse Docs/7" $tempRoot
    Assert-CodexPostCheckerTriggered ([ordered]@{ file_path = "TASKS.md" }) "Codex PostToolUse TASKS" $tempRoot

    $patch = @"
*** Begin Patch
*** Add File: 操作系统/06_工具治理/tmp.md
+new
*** Update File: 能力资产/tools/tmp.md
@@
-old
+new
*** Move to: 操作系统/06_工具治理/tmp-moved.md
*** Delete File: 操作系统/06_工具治理/old.md
*** End Patch
"@
    Assert-CodexPostCheckerTriggered ([ordered]@{ patch = $patch }) "Codex PostToolUse apply_patch" $tempRoot
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
  }

  $fakeKey = "sk-ant-" + ("A" * 24)
  Assert-CodexSoftWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "notes.md"; content = $fakeKey })) "Codex PreToolUse content"
  Assert-CodexSoftWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "notes.md"; new_string = $fakeKey })) "Codex PreToolUse new_string"
  Assert-CodexSoftWarning ([ordered]@{
    hook_event_name = "PreToolUse"
    arguments = [ordered]@{ file_path = "notes.md"; content = $fakeKey }
  } | ConvertTo-Json -Depth 8 -Compress) "Codex PreToolUse arguments.content"
  Assert-CodexSoftWarning (New-HookJson "PreToolUse" ([ordered]@{
    patch = "*** Begin Patch`n*** Update File: notes.md`n+token=$fakeKey`n*** End Patch`n"
  })) "Codex PreToolUse apply_patch"
  Assert-CodexSoftWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "notes.env"; content = $fakeKey })) "Codex PreToolUse notes.env"
  Assert-CodexSoftWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "{{APP_REPO_DIR}}/.env.local.example"; content = $fakeKey })) "Codex PreToolUse env example"
  Assert-CodexNoWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = ".env.local"; content = $fakeKey })) "Codex PreToolUse .env.local"

  # PROP-001 Class C path warnings: Codex uses additionalContext under its own contract, not permissionDecision.
  function Assert-CodexPathWarning([object]$Payload, [string]$Expect, [string]$Label, [string]$RunRoot = $Root) {
    $json = Invoke-CodexJson $Paths.CodexPreWrite $Payload $RunRoot
    Assert-True ($json.continue -eq $true) "$Label should continue"
    Assert-True ($json.systemMessage -match $Expect) "$Label missing systemMessage ($Expect)"
    Assert-True ($json.hookSpecificOutput.hookEventName -eq "PreToolUse") "$Label missing PreToolUse context"
    Assert-True ($json.hookSpecificOutput.additionalContext -match $Expect) "$Label missing additionalContext ($Expect)"
  }

  # Positive 1: writes under Docs/6-历史归档/ warn at any depth, without secrets, for both creation and modification.
  Assert-CodexPathWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "Docs/6-历史归档/x.md"; content = "Ordinary archive content" })) "historical archive" "Codex PreToolUse Docs/6-历史归档 content"
  Assert-CodexPathWarning (New-HookJson "PreToolUse" ([ordered]@{
    patch = "*** Begin Patch`n*** Update File: Docs/6-历史归档/2025/old.md`n+Update archive content`n*** End Patch`n"
  })) "historical archive" "Codex PreToolUse Docs/6-历史归档 apply_patch"

  # Positive 2 and negative 2b: warn on an existing APK, allow a new APK; only modifying an existing file warns.
  $apkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("czxt-hooks-codex-apk-" + [guid]::NewGuid().ToString("N"))
  try {
    $apkDir = Join-Path $apkRoot "apk"
    New-Item -ItemType Directory -Force -Path $apkDir | Out-Null
    Set-Content -LiteralPath (Join-Path $apkDir "old.apk") -Encoding UTF8 -Value "fake-apk-bytes"
    Assert-CodexPathWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "apk/old.apk"; content = "Overwrite historical APK" })) "APK" "Codex PreToolUse existing apk" $apkRoot

    $apkNew = Invoke-CodexJson $Paths.CodexPreWrite (New-HookJson "PreToolUse" ([ordered]@{ file_path = "apk/brand-new.apk"; content = "Create new APK" })) $apkRoot
    Assert-True ($apkNew.continue -eq $true) "Codex PreToolUse new apk should continue"
    Assert-True (-not $apkNew.systemMessage) "Codex PreToolUse new apk should stay quiet"
  } finally {
    if (Test-Path -LiteralPath $apkRoot) { Remove-Item -LiteralPath $apkRoot -Recurse -Force }
  }

  # Negative 1: ordinary framework content outside archives and apk/, without secrets, produces no warning.
  Assert-CodexNoWarning (New-HookJson "PreToolUse" ([ordered]@{ file_path = "操作系统/00_总入口.md"; content = "Ordinary framework documentation." })) "Codex PreToolUse normal framework file"
}
