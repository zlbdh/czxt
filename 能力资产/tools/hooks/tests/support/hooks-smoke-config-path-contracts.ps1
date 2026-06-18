$ErrorActionPreference = "Stop"

function Invoke-HooksSmokeConfigPathContracts {
  param([object]$Paths)

  $requiredPaths = @(
    @{ Value = $Paths.Manifest; Label = "missing manifest.json" },
    @{ Value = $Paths.Runner; Label = "missing run-hooks.ps1" },
    @{ Value = $Paths.ReadmeCheck; Label = "missing README check" },
    @{ Value = $Paths.AdrUpdate; Label = "missing ADR updater" },
    @{ Value = $Paths.HandoffCheck; Label = "missing handoff" },
    @{ Value = $Paths.PreRelease; Label = "missing pre-release check" },
    @{ Value = $Paths.ChatOutput; Label = "missing chat-output check" },
    @{ Value = $Paths.ScheduledInstall; Label = "missing scheduled installer" },
    @{ Value = $Paths.WatchInstall; Label = "missing watch installer" },
    @{ Value = $Paths.CodexHooks; Label = "missing .codex/hooks.json" },
    @{ Value = $Paths.ClaudeSettings; Label = "missing .claude/settings.json" },
    @{ Value = $Paths.CodexSessionStart; Label = "missing Codex SessionStart hook" },
    @{ Value = $Paths.CodexUserPrompt; Label = "missing Codex UserPromptSubmit hook" },
    @{ Value = $Paths.CodexStop; Label = "missing Codex Stop hook" },
    @{ Value = $Paths.CodexPost; Label = "missing Codex PostToolUse hook" },
    @{ Value = $Paths.CodexPreWrite; Label = "missing Codex PreToolUse hook" },
    @{ Value = $Paths.ClaudeStop; Label = "missing Claude Stop hook" },
    @{ Value = $Paths.ClaudePost; Label = "missing Claude PostToolUse hook" },
    @{ Value = $Paths.ClaudePreCompact; Label = "missing Claude PreCompact hook" },
    @{ Value = $Paths.ClaudePreWrite; Label = "missing Claude PreToolUse hook" }
  )

  foreach ($entry in $requiredPaths) {
    Assert-True (Test-Path -LiteralPath $entry.Value) $entry.Label
  }
}
