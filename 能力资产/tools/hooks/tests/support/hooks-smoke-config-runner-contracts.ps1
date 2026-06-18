$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeConfigRunnerContracts {
  param([object]$Paths)

  $runnerOutput = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.Runner, "-Trigger", "manual", "-Mode", "Check")
  Assert-True ($runnerOutput -match "readme-index-check") "runner missing readme-index-check"
  Assert-True ($runnerOutput -match "adr-readme-dry-run") "runner missing adr-readme-dry-run"

  $installOutput = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.InstallHooks, "-Mode", "Check")
  Assert-True ($installOutput -match "hooks installer check") "install hook check missing report"

  $installViaRunner = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.Runner, "-Trigger", "manual", "-Mode", "Check", "-Hook", "hook-install-check")
  Assert-True ($installViaRunner -match "hook-install-check") "runner missing hook-install-check report"

  $chatOutputNoTextPath = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.Runner, "-Trigger", "chat-output", "-Mode", "Check")
  Assert-True ($chatOutputNoTextPath -match "chat-output hook ready") "runner should omit empty TextPath args for chat-output"

  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{{APP_REPO_DIR}}-hooks-install-check-" + [guid]::NewGuid().ToString("N"))
  $tempHooks = Join-Path $tempRoot "{{APP_REPO_DIR}}\.git\hooks"
  try {
    New-Item -ItemType Directory -Path $tempHooks -Force | Out-Null
    $missingWrapperOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.InstallHooks -Mode Check -Root $tempRoot 2>&1
    $missingWrapperText = $missingWrapperOutput -join "`n"
    Assert-True ($LASTEXITCODE -eq 10) "install hook check should fail when wrappers are missing"
    Assert-True ($missingWrapperText -match "尚未安装|not installed|missing") "install hook check should explain missing wrappers"
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
  }

  $badHookOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.Runner -Trigger manual -Mode Check -Hook "__typo__" 2>&1
  Assert-True ($LASTEXITCODE -eq 2) "runner should fail explicit unknown hook"

  $preReleaseMissingRoot = Join-Path ([System.IO.Path]::GetTempPath()) "{{APP_REPO_DIR}}-hooks-missing-root"
  $preReleaseMissingOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.PreRelease -Root $preReleaseMissingRoot 2>&1
  Assert-True ($LASTEXITCODE -eq 1) "pre-release should fail closed when {{APP_REPO_DIR}}/package.json is missing"

  $readmeOutput = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.ReadmeCheck)
  Assert-True ($readmeOutput -match "ADR README") "README check bad"
  Assert-True ($readmeOutput -match "PM 工作区入口对齐") "README check missing PM workspace anchor"

  $adrOutput = Run-Checked @("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Paths.AdrUpdate, "-Mode", "Check")
  Assert-True ($adrOutput -match "ADR README") "ADR update bad"

  $scheduledOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.ScheduledInstall -Mode Check 2>&1
  Assert-True ((0, 5) -contains $LASTEXITCODE) "scheduled check bad exit"
  $scheduledOutput = $scheduledOutput -join "`n"
  Assert-True ($scheduledOutput -match "scheduled task check") "scheduled check missing report"

  $watchOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $Paths.WatchInstall -Mode Check 2>&1
  Assert-True ((0, 5) -contains $LASTEXITCODE) "watch check bad exit"
  $watchOutput = $watchOutput -join "`n"
  Assert-True ($watchOutput -match "ADR watch task check") "watch check missing report"
}
