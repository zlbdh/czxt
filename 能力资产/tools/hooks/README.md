---
name: hooks-index
scope: project
type: procedural
loaded: on-demand
description: Operating system hooks entry point — manifest, runner, Git wrappers, Codex, Claude, watchers, and scheduled tasks.
---

# Capability Tools — Operating System Hooks

> Execution entry point. Authoritative design: `操作系统/06_工具治理/hooks-设计.md`. Event matrix: `操作系统/06_工具治理/hooks-事件矩阵.md` and `操作系统/06_工具治理/hooks-事件矩阵-附录.md`. Command-level procedures: `操作系统/07_完整工作流/hooks-运行SOP.md` and `操作系统/07_完整工作流/hooks-运行SOP-附录.md`.

## Directory

| Path | Responsibility |
|---|---|
| `manifest.json` | Hook inventory: ID, trigger, script, and allowed exit codes |
| `run-hooks.ps1` | Shared runner that executes hooks by trigger |
| `install-hooks.ps1` | Install/check local `{{APP_REPO_DIR}}/.git/hooks/pre-commit` and `pre-push` wrappers; Check fails if they are missing or have drifted |
| `.codex/hooks.json` | Native Codex lifecycle hooks entry in the project root |
| `.codex/invoke-hook.ps1` | Codex command dispatcher: a quote-free `EncodedCommand` bootstrap searches upward for the nearest CZXT root marker, then calls a fixed allowlist of scripts |
| `.claude/settings.json` | Native Claude Code lifecycle hooks entry in the project root |
| `codex/` / `claude/` | Lifecycle adapters for the two runtimes |
| `chat-output/` | Compact chat-completion checks |
| `scheduled/` / `watch/` | Windows scheduled tasks and ADR README watcher |
| `tests/` | Hooks smoke tests; `tests/support/` contains internal contract modules. Smoke tests temporarily create and delete one `_hooks-smoke-*` handoff fixture |

## Quick commands

```powershell
# Lightweight checks after framework changes.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook readme-index-check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook handoff-zone-check

# Hook framework smoke test.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/tests/hooks-smoke.ps1

# Check local Git hooks, Windows scheduled tasks, and the ADR watcher.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Check
```

A full manual run triggers the heavier `pre-release-check` (`npm test` and `npm run build`). Run it when needed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
```

## Current hooks (9 total; source of truth: manifest.json)

This section retains count anchors to prevent README drift. Individual events, triggers, and write permissions are in `操作系统/06_工具治理/hooks-事件矩阵.md`; adapter details are in `操作系统/06_工具治理/hooks-事件矩阵-附录.md`.

| Category | Hook |
|---|---|
| Index/state | `readme-index-check` / `adr-readme-dry-run` / `pm-tracking-check` / `handoff-zone-check` / `chat-summary-check` |
| Installation/health | `hook-install-check` / `framework-health-check` |
| Release/knowledge retention | `pre-release-check` / `retro-cadence-check` |

The `hook-install-check` Check mode fails if local Git wrappers are missing or their content has drifted. Run `install-hooks.ps1 -Mode Apply` only when repair is needed.

## Native Codex hooks (5 events)

Project entry: `.codex/hooks.json`. The Codex Hooks UI reads this configuration. The project `.codex/` configuration layer must be trusted, and new or changed definitions require review/trust. A quote-free PowerShell bootstrap starts at the session cwd and finds the nearest root with exactly one `.czxt-template-root` or `.czxt-project-root` marker. It verifies `.codex/hooks.json` and `.codex/invoke-hook.ps1` belong to that root before dispatch. Conflicting dual markers stop execution silently and immediately; the search does not continue to an outer root. It depends on neither Git nor non-executable template path placeholders.

| Event | Purpose |
|---|---|
| `SessionStart` / `UserPromptSubmit` | Inject project governance context and sensitive-action reminders |
| `Stop` | Check the chat handoff when implementation appears to be concluding |
| `PostToolUse` / `PreToolUse` | Quick framework checks and advisory warnings for touching large business files / suspected secret writes |

## Native Claude Code hooks (6 events)

Project entry: `.claude/settings.json`. After additions or changes, reload with `/hooks` or restart the session.

| Event | Purpose |
|---|---|
| `SessionStart` / `UserPromptSubmit` | Share governance context injection with Codex |
| `Stop` | Adapt the Claude transcript and reuse the chat handoff check |
| `PostToolUse` / `PreToolUse` / `PreCompact` | Quick framework checks and large-business-file warnings / ask before suspected secret writes / remind the agent to record context before compaction |

## Boundaries

- `.git/hooks` is not the source of truth; it holds installed copies of this directory's wrappers.
- `.codex/hooks.json`, `.codex/invoke-hook.ps1`, and `.claude/settings.json` adapt runtime lifecycle events only; they contain no business logic.
- Stop / chat-output hooks check and block incomplete handoffs only. They do not rewrite the agent's final response, move handoff cards, or add PM tracking records.
- Automatic writes are limited to deterministic indexes, such as the ADR README table. Semantic summaries first produce a report or patch.
- `PreToolUse` only flags suspected secret structures. It does not replace Class B/C decisions about `baseUrl`, deleting user data, disclosing real secrets, or similar boundaries.
