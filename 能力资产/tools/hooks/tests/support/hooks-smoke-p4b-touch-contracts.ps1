$ErrorActionPreference = "Stop"

function New-HooksSmokeP4bFixture {
  param([string]$Root)

  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-hooks-p4b-" + [guid]::NewGuid().ToString("N"))
  $helperDir = Join-Path $tempRoot "能力资产\tools\hooks\shared"
  $srcDir = Join-Path $tempRoot "{{APP_REPO_DIR}}\src\features\demo"
  New-Item -ItemType Directory -Force -Path $helperDir, $srcDir | Out-Null
  Copy-Item -LiteralPath (Join-Path $Root "能力资产\tools\hooks\shared\p4b-touch-warning.ps1") -Destination (Join-Path $helperDir "p4b-touch-warning.ps1")
  Set-Content -LiteralPath (Join-Path $srcDir "large.js") -Encoding UTF8 -Value ("x" * 7000)
  Set-Content -LiteralPath (Join-Path $srcDir "small.js") -Encoding UTF8 -Value "ok"
  return $tempRoot
}

function Remove-HooksSmokeP4bFixture {
  param([string]$FixtureRoot)
  if ($FixtureRoot -and (Test-Path -LiteralPath $FixtureRoot)) {
    Remove-Item -LiteralPath $FixtureRoot -Recurse -Force
  }
}

function Invoke-HooksSmokeP4bTouchContracts {
  param(
    [string]$Root,
    [object]$Paths
  )

  function New-PostJson([object]$ToolInput) {
    [ordered]@{ hook_event_name = "PostToolUse"; tool_input = $ToolInput } | ConvertTo-Json -Depth 8 -Compress
  }

  $fixtureRoot = New-HooksSmokeP4bFixture -Root $Root
  try {
    $largeInput = [ordered]@{ file_path = "{{APP_REPO_DIR}}/src/features/demo/large.js" }
    $smallInput = [ordered]@{ file_path = "{{APP_REPO_DIR}}/src/features/demo/small.js" }
    $codexLarge = (New-PostJson $largeInput) | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexPost -Root $fixtureRoot | ConvertFrom-Json
    Assert-True ($codexLarge.continue -eq $true) "Codex P4b large should continue"
    Assert-True ($codexLarge.hookSpecificOutput.additionalContext -match "触碰业务大文件") "Codex P4b large missing additionalContext"

    $codexSmall = (New-PostJson $smallInput) | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexPost -Root $fixtureRoot | ConvertFrom-Json
    Assert-True (-not $codexSmall.systemMessage) "Codex P4b small should stay quiet"

    $patch = "*** Begin Patch`n*** Update File: {{APP_REPO_DIR}}/src/features/demo/large.js`n+touch`n*** End Patch`n"
    $codexPatch = (New-PostJson ([ordered]@{ patch = $patch })) | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.CodexPost -Root $fixtureRoot | ConvertFrom-Json
    Assert-True ($codexPatch.hookSpecificOutput.additionalContext -match "触碰业务大文件") "Codex P4b apply_patch missing warning"

    $claudeLarge = (New-PostJson $largeInput) | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $fixtureRoot | ConvertFrom-Json
    Assert-True ($claudeLarge.systemMessage -match "触碰业务大文件") "Claude P4b large missing systemMessage"

    $claudeSmall = (New-PostJson $smallInput) | powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ClaudePost -Root $fixtureRoot | ConvertFrom-Json
    Assert-True (-not $claudeSmall.systemMessage) "Claude P4b small should stay quiet"
  } finally {
    Remove-HooksSmokeP4bFixture -FixtureRoot $fixtureRoot
  }
}
