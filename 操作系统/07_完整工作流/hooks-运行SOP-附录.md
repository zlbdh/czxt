---
name: hooks-run-sop-appendix
scope: project
type: procedural
loaded: on-demand
description: Hooks procedure appendix — less frequent installation commands, event tables, watcher health codes, and troubleshooting.
---

# Hooks Operating Procedure — Appendix

> Primary entry point: [hooks procedure](hooks-运行SOP.md). This file contains less frequent details only.

## Git hook installation and removal

`install-hooks.ps1` installs both pre-commit and pre-push wrappers. `git/pre-commit.ps1` is an early standalone wrapper example; it does not maintain the pre-push gate.

```powershell
# Enable local Git hooks.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Apply

# Check installation status only.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
```

Execution sources of truth:

```text
能力资产/tools/hooks/install-hooks.ps1
能力资产/tools/hooks/run-hooks.ps1
能力资产/tools/hooks/manifest.json
```

## Native Codex event table

Project-level Codex hook entry point: `.codex/hooks.json`.

| Codex event | Purpose |
|---|---|
| `SessionStart` (startup\|resume\|clear\|compact) | Inject project governance context on session start, resume, clear, or compact |
| `UserPromptSubmit` | Add governance reminders for prompts about hooks, the operating system, or sensitive actions |
| `Stop` | Check handoff sections ①–⑦ and PM transitions when implementation appears to be closing |
| `PostToolUse` (Edit\|Write\|apply_patch) | Automatically run the readme-index quick check after framework/PM workspace edits; parse apply_patch paths from patch headers |
| `PreToolUse` (Edit\|Write\|apply_patch) | Soft reminder when suspected secrets are written outside `.env`; parse apply_patch target paths from patch headers |

After initial loading, refresh the Codex Hooks page and review/trust the project hooks. Before trust, Codex discovers configuration but does not execute unmanaged hooks.

## Native Claude Code event table

Project-level Claude Code hook entry point: `.claude/settings.json`.

| Claude event | Adapter script | Purpose |
|---|---|---|
| `SessionStart` | `能力资产/tools/hooks/codex/session-start.ps1`, shared with Codex | Inject project governance context |
| `UserPromptSubmit` | `能力资产/tools/hooks/codex/user-prompt-submit.ps1`, shared | Governance reminders for sensitive actions |
| `Stop` | `能力资产/tools/hooks/claude/stop-chat-summary.ps1`, Claude-specific | Check handoff sections ①–⑦ and PM transitions when work appears to be closing |
| `PostToolUse` (Edit\|Write) | `能力资产/tools/hooks/claude/post-edit-framework-check.ps1` | readme-index quick check after framework/PM workspace edits; nonblocking `systemMessage` only |
| `PreCompact` (auto\|manual) | `能力资产/tools/hooks/claude/pre-compact-snapshot.ps1` | Snapshot the latest PM transition before compaction and remind about unsent handoffs |
| `PreToolUse` (Edit\|Write) | `能力资产/tools/hooks/claude/pre-write-guard.ps1` | `ask` confirmation when suspected secrets are written outside `.env` |

A newly created `.claude/settings.json` does not load automatically in the current session. Open `/hooks` once in Claude Code or restart the session to activate it initially.

## Less frequent watch / scheduled commands

Watch the ADR directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/adr-readme-watch.ps1
```

Local logon-start task:

```powershell
# Install and start immediately.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Apply -StartNow

# Stop and remove.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Remove
```

Health interpretation:

- `State=Running` and `LastTaskResult=267009` (`0x41301`) mean the watcher is running.
- `LastTaskResult=2147943467` (`0x8007042B`, low-order code 1067) means the process terminated unexpectedly. Rebuild and start with `-Mode Apply -StartNow`.
- The watcher automatically applies only the ADR README index. PMs still write handoff cards, PM transitions, the `状态.md` summary, and historical summaries; hooks only check or remind.

Windows scheduled task:

```powershell
# Install or rebuild; defaults to 09:30 daily.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Apply

# Remove.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Remove
```

## Troubleshooting details

| Failure | Troubleshooting |
|---|---|
| Inconsistent README index | Locate the issue with `check-readme-indexes.ps1`, then run the appropriate updater with `-Mode Check`. Use `-Mode Apply` only for deterministic index differences. |
| chat-output failure | Add sections ①–⑦, the section ⑥ `交接区/待接手/...md` path, and section ⑦ `状态.md L<line>` as reported. A simple conversation may have no handoff in ⑥ and `N=0` with no PM role transition this session in ⑦. A summary paragraph must not replace the required sections. |
| PM transition timeout | Find the line with `Select-String 状态.md -Pattern 'YYYY-MM-DD HH:mm'`. Add the actual transition; do not fabricate one. |
| Framework health failure | Fix each P4a–P4t item. P4b soft warnings may be handed off; hard failures must be fixed first. |
| Incorrect watch trigger | Pause the watcher and manually verify with `update-adr-readme.ps1 -Mode Check` and `check-readme-indexes.ps1`. |
