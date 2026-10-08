param(
  [ValidateSet("Check", "Apply", "Remove")]
  [string]$Mode = "Check",
  [string]$TaskName = "CZXT-ADR-README-Watch",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path,
  [switch]$StartNow
)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

$watchPath = Join-Path $Root "能力资产\tools\hooks\watch\adr-readme-watch.ps1"
if (-not (Test-Path -LiteralPath $watchPath)) {
  throw "ADR watcher entry script not found: $watchPath"
}

function Get-TaskOrNull {
  param([string]$Name)
  Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
}

$task = Get-TaskOrNull -Name $TaskName

if ($Mode -eq "Check") {
  Write-Host "🔎 ADR watch task check"
  Write-Host "  task: $TaskName"
  if (-not $task) {
    Write-Host "  🟡 ADR watch scheduled task is not registered"
    exit 5
  }
  $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
  $issues = @()
  Write-Host "  ✅ Registered: $($task.State)"
  if ($info) {
    Write-Host "  last run: $($info.LastRunTime)"
    Write-Host "  last result: $($info.LastTaskResult)"
    if ($info.LastTaskResult -eq 267009) {
      Write-Host "  last result meaning: 0x41301 / watcher is running"
    }
    Write-Host "  next run: $($info.NextRunTime)"
    if ($info.LastTaskResult -notin @(0, 267009)) {
      $issues += "LastTaskResult=$($info.LastTaskResult)"
    }
  }
  $actions = @($task.Actions)
  if ($actions.Count -eq 0) {
    $issues += "missing action"
  } else {
    $action = $actions[0]
    $args = [string]$action.Arguments
    if ([string]$action.Execute -notmatch 'powershell(\.exe)?$') {
      $issues += "action execute is not powershell.exe: $($action.Execute)"
    }
    if ($args -notmatch [regex]::Escape($watchPath) -or $args -notmatch [regex]::Escape($Root)) {
      $issues += "action args drift from current Root/watch script"
    }
  }
  if ($issues.Count -gt 0) {
    Write-Host "  🟡 ADR watch scheduled task must be reinstalled: $($issues -join '; ')" -ForegroundColor Yellow
    exit 5
  }
  exit 0
}

if ($Mode -eq "Remove") {
  if (-not $task) {
    Write-Host "🟡 Scheduled task does not exist: $TaskName"
    exit 0
  }
  Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  Write-Host "✅ Scheduled task removed: $TaskName"
  exit 0
}

if ($task) {
  Write-Host "🟡 Scheduled task already exists; remove it before recreating: $TaskName"
  Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$actionArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchPath`" -Root `"$Root`" -Apply"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $actionArgs
$user = "$env:USERDOMAIN\$env:USERNAME"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $action `
  -Trigger $trigger `
  -Settings $settings `
  -Principal $principal `
  -Description "{{PROJECT_NAME}} ADR README file watcher" | Out-Null

if ($StartNow) {
  Start-ScheduledTask -TaskName $TaskName
}

Write-Host "✅ Scheduled task registered: $TaskName"
Write-Host "  Trigger: user logon"
Write-Host "  Script: $watchPath"
if ($StartNow) { Write-Host "  Current state: started" }
exit 0
