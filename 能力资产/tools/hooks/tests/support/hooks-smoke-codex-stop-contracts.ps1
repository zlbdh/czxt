$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeCodexStopContracts {
  param(
    [string]$Root,
    [object]$Paths,
    [object]$Fixture
  )

  $stopInput = [ordered]@{
    hook_event_name = "Stop"
    turn_id = "t1"
    stop_hook_active = $false
    last_assistant_message = $Fixture.Card
  } | ConvertTo-Json -Depth 5 -Compress
  $stopOutput = $stopInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexStop -Root $Root
  $stopJson = $stopOutput | ConvertFrom-Json
  Assert-True ($stopJson.continue -eq $true) "Stop bad"

  $badStopInput = [ordered]@{
    hook_event_name = "Stop"
    turn_id = "t2"
    stop_hook_active = $false
    last_assistant_message = "文件变更：1 修改`n测试：hooks-smoke ✅`nPM 切换轨迹：状态.md L$($Fixture.StateLineNumber)"
  } | ConvertTo-Json -Depth 5 -Compress
  $badStopOutput = $badStopInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexStop -Root $Root
  $badStopJson = $badStopOutput | ConvertFrom-Json
  Assert-True ($badStopJson.decision -eq "block") "Stop should block closeout without ①-⑦"

  $readonlyStopInput = [ordered]@{
    hook_event_name = "Stop"
    turn_id = "t3"
    stop_hook_active = $false
    last_assistant_message = "只读审计：未改文件。"
  } | ConvertTo-Json -Depth 5 -Compress
  $readonlyStopOutput = $readonlyStopInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexStop -Root $Root
  $readonlyStopJson = $readonlyStopOutput | ConvertFrom-Json
  Assert-True ($readonlyStopJson.continue -eq $true) "Stop should allow pure read-only no-change note"

  $readonlyCloseoutInput = [ordered]@{
    hook_event_name = "Stop"
    turn_id = "t4"
    stop_hook_active = $false
    last_assistant_message = "只读审计：未改文件。报告里提到 PM 切换轨迹、交接区/待接手、①-⑦ 和测试风险，但没有实施收尾。"
  } | ConvertTo-Json -Depth 5 -Compress
  $readonlyCloseoutOutput = $readonlyCloseoutInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexStop -Root $Root
  $readonlyCloseoutJson = $readonlyCloseoutOutput | ConvertFrom-Json
  Assert-True ($readonlyCloseoutJson.continue -eq $true) "Stop should allow read-only audit reports even when they mention closeout vocabulary"

  $readonlyNumberedInput = [ordered]@{
    hook_event_name = "Stop"
    turn_id = "t4b"
    stop_hook_active = $false
    last_assistant_message = "只读审计完成，未修改文件。`n① 范围：交接区/待接手 规则文本`n② 验证：提到测试和 PM 切换轨迹，但不是实施收尾。"
  } | ConvertTo-Json -Depth 5 -Compress
  $readonlyNumberedOutput = $readonlyNumberedInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexStop -Root $Root
  $readonlyNumberedJson = $readonlyNumberedOutput | ConvertFrom-Json
  Assert-True ($readonlyNumberedJson.continue -eq $true) "Stop should allow read-only audit reports with line-start circled numbers"

  $modifiedVerifyInput = [ordered]@{
    hook_event_name = "Stop"
    turn_id = "t5"
    stop_hook_active = $false
    last_assistant_message = "已修改 hooks 脚本。`n验证：hooks-smoke PASS"
  } | ConvertTo-Json -Depth 5 -Compress
  $modifiedVerifyOutput = $modifiedVerifyInput | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexStop -Root $Root
  $modifiedVerifyJson = $modifiedVerifyOutput | ConvertFrom-Json
  Assert-True ($modifiedVerifyJson.decision -eq "block") "Stop should block modified+verification closeout without ①-⑦"
}
