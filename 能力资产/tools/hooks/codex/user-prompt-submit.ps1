$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {
  # Best effort for older PowerShell hosts.
}

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) {
  exit 0
}

try {
  $event = $raw | ConvertFrom-Json
} catch {
  exit 0
}

$prompt = if ($event.prompt) { [string]$event.prompt } else { "" }
if ([string]::IsNullOrWhiteSpace($prompt)) {
  exit 0
}

$projectPattern = 'hooks?|钩子|操作系统|framework|README|ADR|交接|状态\.md|PM|继续|commit|push|version|API key|baseUrl|用户数据'
if ($prompt -notmatch $projectPattern) {
  exit 0
}

$lines = @(
  "This user request triggered a {{PROJECT_NAME}} project governance reminder.",
  "For hooks, operating-system, or framework work: executable scripts belong in 能力资产/tools/hooks, governance design belongs in 操作系统, and Project PM Mimi retains final responsibility.",
  "For commit/push/version/API key/baseUrl/user-data deletion or _framework files, check the sensitive-action list in the role boundaries first."
)

[ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = "UserPromptSubmit"
    additionalContext = ($lines -join "`n")
  }
} | ConvertTo-Json -Depth 6 -Compress
