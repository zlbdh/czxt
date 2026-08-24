[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Hook)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$scriptName = switch -CaseSensitive ($Hook) {
  'session-start' { 'session-start.ps1' }
  'user-prompt-submit' { 'user-prompt-submit.ps1' }
  'stop-chat-summary' { 'stop-chat-summary.ps1' }
  'post-edit-framework-check' { 'post-edit-framework-check.ps1' }
  'pre-write-guard' { 'pre-write-guard.ps1' }
  default { exit 64 }
}

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$target = Join-Path $root ('能力资产\tools\hooks\codex\' + $scriptName)
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { exit 66 }
& $target
if ($?) { exit 0 }
exit 1
