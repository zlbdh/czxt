param(
  [ValidateSet("Check", "Apply", "Remove")]
  [string]$Mode = "Check",
  [string]$TaskName = "CZXT-Framework-Hooks-Daily",
  [string]$At = "09:30",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {
  # Best effort for older PowerShell hosts.
}

$scriptPath = Join-Path $Root "能力资产\tools\hooks\scheduled\daily-framework-check.ps1"
if (-not (Test-Path -LiteralPath $scriptPath)) {
  throw "Scheduled entry script not found: $scriptPath"
}

function Get-TaskOrNull {
  param([string]$Name)
  Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
}

$task = Get-TaskOrNull -Name $TaskName

if ($Mode -eq "Check") {
  Write-Host "🔎 scheduled task check"
  Write-Host "  task: $TaskName"
  if (-not $task) {
    Write-Host "  🟡 Windows scheduled task is not registered"
    exit 5
  }
  $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
  $issues = @()
  Write-Host "  ✅ Registered: $($task.State)"
  if ($info) {
    Write-Host "  last run: $($info.LastRunTime)"
    Write-Host "  last result: $($info.LastTaskResult)"
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
    if ($args -notmatch [regex]::Escape($scriptPath) -or $args -notmatch [regex]::Escape($Root)) {
      $issues += "action args drift from current Root/scheduled script"
    }
  }
  if ($issues.Count -gt 0) {
    Write-Host "  🟡 Scheduled task must be reinstalled: $($issues -join '; ')" -ForegroundColor Yellow
    exit 5
  }
  exit 0
}

if ($Mode -eq "Remove") {
  if (-not $task) {
    Write-Host "🟡 Scheduled task does not exist: $TaskName"
    exit 0
  }
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  Write-Host "✅ Scheduled task removed: $TaskName"
  exit 0
}

if ($task) {
  Write-Host "🟡 Scheduled task already exists; remove it before recreating: $TaskName"
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$actionArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Root `"$Root`""
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $actionArgs
$trigger = New-ScheduledTaskTrigger -Daily -At ([DateTime]::ParseExact($At, "HH:mm", $null))
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $action `
  -Trigger $trigger `
  -Settings $settings `
  -Principal $principal `
  -Description "{{PROJECT_NAME}} operating system hooks daily framework check" | Out-Null

Write-Host "✅ Scheduled task registered: $TaskName"
Write-Host "  Daily time: $At"
Write-Host "  Script: $scriptPath"
exit 0
