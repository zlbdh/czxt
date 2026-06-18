param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"
$adrDir = Join-Path $Root "Docs\3-开发文档\adr"
$runner = Join-Path $Root "能力资产\tools\hooks\run-hooks.ps1"
$mode = if ($Apply) { "Apply" } else { "Check" }

if (-not (Test-Path -LiteralPath $adrDir)) {
  throw "找不到 ADR 目录：$adrDir"
}

Write-Host "👀 Watching ADR directory: $adrDir"
Write-Host "   Mode=$mode. Press Ctrl+C to stop."

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $adrDir
$watcher.Filter = "ADR-*.md"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$action = {
  $root = $Event.MessageData.Root
  $runner = Join-Path $root "能力资产\tools\hooks\run-hooks.ps1"
  $mode = $Event.MessageData.Mode
  powershell -NoProfile -ExecutionPolicy Bypass -File $runner -Trigger file-watch -Mode $mode -Hook adr-readme-dry-run -Root $root
}

$message = @{ Root = $Root; Mode = $mode }
$created = Register-ObjectEvent $watcher Created -Action $action -MessageData $message
$changed = Register-ObjectEvent $watcher Changed -Action $action -MessageData $message
$renamed = Register-ObjectEvent $watcher Renamed -Action $action -MessageData $message

try {
  while ($true) { Start-Sleep -Seconds 2 }
} finally {
  Unregister-Event -SubscriptionId $created.Id -ErrorAction SilentlyContinue
  Unregister-Event -SubscriptionId $changed.Id -ErrorAction SilentlyContinue
  Unregister-Event -SubscriptionId $renamed.Id -ErrorAction SilentlyContinue
  $watcher.Dispose()
}
