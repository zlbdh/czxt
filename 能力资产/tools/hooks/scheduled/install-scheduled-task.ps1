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
  throw "找不到 scheduled 入口脚本：$scriptPath"
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
    Write-Host "  🟡 未注册 Windows 计划任务"
    exit 5
  }
  $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
  $issues = @()
  Write-Host "  ✅ 已注册：$($task.State)"
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
    Write-Host "  🟡 scheduled 计划任务需重装：$($issues -join '; ')" -ForegroundColor Yellow
    exit 5
  }
  exit 0
}

if ($Mode -eq "Remove") {
  if (-not $task) {
    Write-Host "🟡 计划任务不存在：$TaskName"
    exit 0
  }
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  Write-Host "✅ 已删除计划任务：$TaskName"
  exit 0
}

if ($task) {
  Write-Host "🟡 计划任务已存在，先删除后重建：$TaskName"
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
  -Description "{{PROJECT_NAME}}操作系统 hooks daily framework check" | Out-Null

Write-Host "✅ 已注册计划任务：$TaskName"
Write-Host "  每日时间：$At"
Write-Host "  脚本：$scriptPath"
exit 0
