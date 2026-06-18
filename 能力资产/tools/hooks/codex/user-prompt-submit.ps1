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
  "本轮用户输入触发{{PROJECT_NAME}}项目治理提醒。",
  "涉及 hooks/操作系统/framework 时：可执行脚本归 能力资产/tools/hooks，治理设计归 操作系统，最终责任归项目 PM「咪咪」。",
  "涉及 commit/push/version/API key/baseUrl/用户数据删除/_framework 文件时，先按角色边界敏感清单判断。"
)

[ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = "UserPromptSubmit"
    additionalContext = ($lines -join "`n")
  }
} | ConvertTo-Json -Depth 6 -Compress
