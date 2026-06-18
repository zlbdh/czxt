$ErrorActionPreference = "Stop"

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )
  if (-not $Condition) {
    throw $Message
  }
}

function Run-Checked {
  param([string[]]$Command)
  # PS5.1: 原生命令 stderr 经 2>&1 会被包成 NativeCommandError；
  # 真实成败只看 $LASTEXITCODE，避免良性 stderr 误红。
  $prevEAP = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = & $Command[0] @($Command | Select-Object -Skip 1) 2>&1
    $code = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $prevEAP
  }
  if ($code -ne 0) {
    throw "Command failed ($code): $($Command -join ' ')`n$output"
  }
  return ($output -join "`n")
}

function Assert-EventSet {
  param(
    [object]$Hooks,
    [string[]]$Expected,
    [string]$Label
  )
  $names = @($Hooks.PSObject.Properties.Name)
  foreach ($eventName in $Expected) {
    Assert-True ($names -contains $eventName) "$Label missing event $eventName"
  }
  $extra = @($names | Where-Object { $Expected -notcontains $_ })
  Assert-True ($extra.Count -eq 0) "$Label has undocumented extra events: $($extra -join ', ')"
}

function Assert-ConfigScriptsExist {
  param(
    [object]$Hooks,
    [string]$Label
  )
  foreach ($prop in @($Hooks.PSObject.Properties)) {
    foreach ($entry in @($prop.Value)) {
      foreach ($hook in @($entry.hooks)) {
        $scriptPath = $null
        if ($hook.args) {
          $args = @($hook.args)
          for ($i = 0; $i -lt $args.Count - 1; $i++) {
            if ([string]$args[$i] -eq "-File") {
              $scriptPath = [string]$args[$i + 1]
              break
            }
          }
        }
        if (-not $scriptPath -and $hook.commandWindows -and ([string]$hook.commandWindows -match '-File\s+"([^"]+\.ps1)"')) {
          $scriptPath = $matches[1]
        }
        if (-not $scriptPath -and $hook.command -and ([string]$hook.command -match '-File\s+"([^"]+\.ps1)"')) {
          $scriptPath = $matches[1]
        }
        if ($scriptPath) {
          if ($script:HooksSmokeRoot) {
            $rootWin = [System.IO.Path]::GetFullPath($script:HooksSmokeRoot)
            $rootPosix = $rootWin -replace '\\','/'
            $scriptPath = $scriptPath.Replace("{{PROJECT_ROOT_POSIX}}", $rootPosix).Replace("{{PROJECT_ROOT}}", $rootWin)
          }
          Assert-True (Test-Path -LiteralPath ($scriptPath -replace '/', '\')) "$Label $($prop.Name) script missing: $scriptPath"
        }
      }
    }
  }
}

function Assert-HooksSmokeSupportFiles {
  param([string]$SupportRoot)

  $expected = @(
    "hooks-smoke-chat-output-accepted-contracts.ps1",
    "hooks-smoke-chat-output-contracts.ps1",
    "hooks-smoke-claude-contracts.ps1",
    "hooks-smoke-codex-contracts.ps1",
    "hooks-smoke-codex-stop-contracts.ps1",
    "hooks-smoke-codex-tool-contracts.ps1",
    "hooks-smoke-config-contracts.ps1",
    "hooks-smoke-config-map.ps1",
    "hooks-smoke-config-manifest-contracts.ps1",
    "hooks-smoke-config-path-contracts.ps1",
    "hooks-smoke-config-runner-contracts.ps1",
    "hooks-smoke-config-runtime-contracts.ps1",
    "hooks-smoke-core.ps1",
    "hooks-smoke-lifecycle-contracts.ps1"
    "hooks-smoke-p4b-touch-contracts.ps1"
  )
  $actual = @(Get-ChildItem -LiteralPath $SupportRoot -Filter "*.ps1" | Select-Object -ExpandProperty Name | Sort-Object)

  foreach ($name in $expected) {
    Assert-True ($actual -contains $name) "hooks-smoke support missing: $name"
  }
  $extra = @($actual | Where-Object { $expected -notcontains $_ })
  Assert-True ($extra.Count -eq 0) "hooks-smoke support has undocumented files: $($extra -join ', ')"
}

function Get-HooksSmokePaths {
  param([string]$Root)

  $script:HooksSmokeRoot = [System.IO.Path]::GetFullPath($Root)

  [PSCustomObject]@{
    Manifest = Join-Path $Root "能力资产\tools\hooks\manifest.json"
    Runner = Join-Path $Root "能力资产\tools\hooks\run-hooks.ps1"
    InstallHooks = Join-Path $Root "能力资产\tools\hooks\install-hooks.ps1"
    ReadmeCheck = Join-Path $Root "能力资产\tools\scripts\check-readme-indexes.ps1"
    AdrUpdate = Join-Path $Root "能力资产\tools\scripts\update-adr-readme.ps1"
    HandoffCheck = Join-Path $Root "能力资产\tools\scripts\check-handoff-zone.ps1"
    PreRelease = Join-Path $Root "能力资产\tools\scripts\check-pre-release.ps1"
    ChatOutput = Join-Path $Root "能力资产\tools\hooks\chat-output\check-chat-summary.ps1"
    ScheduledInstall = Join-Path $Root "能力资产\tools\hooks\scheduled\install-scheduled-task.ps1"
    WatchInstall = Join-Path $Root "能力资产\tools\hooks\watch\install-adr-watch-task.ps1"
    CodexHooks = Join-Path $Root ".codex\hooks.json"
    ClaudeSettings = Join-Path $Root ".claude\settings.json"
    CodexSessionStart = Join-Path $Root "能力资产\tools\hooks\codex\session-start.ps1"
    CodexUserPrompt = Join-Path $Root "能力资产\tools\hooks\codex\user-prompt-submit.ps1"
    CodexStop = Join-Path $Root "能力资产\tools\hooks\codex\stop-chat-summary.ps1"
    CodexPost = Join-Path $Root "能力资产\tools\hooks\codex\post-edit-framework-check.ps1"
    CodexPreWrite = Join-Path $Root "能力资产\tools\hooks\codex\pre-write-guard.ps1"
    ClaudeStop = Join-Path $Root "能力资产\tools\hooks\claude\stop-chat-summary.ps1"
    ClaudePost = Join-Path $Root "能力资产\tools\hooks\claude\post-edit-framework-check.ps1"
    ClaudePreCompact = Join-Path $Root "能力资产\tools\hooks\claude\pre-compact-snapshot.ps1"
    ClaudePreWrite = Join-Path $Root "能力资产\tools\hooks\claude\pre-write-guard.ps1"
  }
}
