---
name: hooks-run-sop
scope: project
type: procedural
loaded: on-demand
description: Operating system hooks procedure — manual, Git, Codex, Claude, watch, and scheduled entry points.
---

# Hooks Operating Procedure

> This document keeps daily commands, authoritative sources, and key boundaries. See the [appendix](hooks-运行SOP-附录.md) for less frequent commands, health codes, and troubleshooting; see [design](../06_工具治理/hooks-设计.md) and the [event matrix](../06_工具治理/hooks-事件矩阵.md) for supporting detail.

## Manual entry point

After framework changes, prefer lightweight hooks. The full manual run triggers heavier release gates: `npm test` and `npm run build`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook readme-index-check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook handoff-zone-check

# Run only when the full manual gate is needed; triggers pre-release-check.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
```

The deterministic ADR README index supports Apply:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/update-adr-readme.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/update-adr-readme.ps1 -Mode Apply
```

The handoff-area check reports warnings only; it does not move files automatically:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-handoff-zone.ps1
```

## Sources of truth and entry points

| Entry point | Authoritative path | Key requirement |
|---|---|---|
| Project hook inventory | `能力资产/tools/hooks/manifest.json` | Nine project hooks executed by `run-hooks.ps1` |
| Git hooks | `能力资产/tools/hooks/install-hooks.ps1` | Generates `{{APP_REPO_DIR}}/.git/hooks/pre-commit` and `pre-push` wrappers; `.git/hooks` is not versioned |
| Native Codex hooks | `.codex/hooks.json` | Five events; requires review/trust in the Codex UI before execution |
| Native Claude Code hooks | `.claude/settings.json` | Six events; initially requires `/hooks` reload or session restart |
| ADR watcher | `能力资产/tools/hooks/watch/adr-readme-watch.ps1` | Automatically applies only the deterministic ADR README index |
| Scheduled | `能力资产/tools/hooks/scheduled/daily-framework-check.ps1` | Windows Task Scheduler runs the scheduled runner: indexes, PM transitions, handoff area, framework health, and RETRO cadence |

## Git hook entry point

`install-hooks.ps1` generates the Git hook wrappers. Pre-push runs the release gate, `pre-release-check`: `npm test` and `npm run build`. Either failure exits 1 and blocks the push:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger pre-push -Mode Check
```

For routine use, only check installation drift:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
```

See [Git hook installation and removal](hooks-运行SOP-附录.md#git-hook-installation-and-removal) for pre-commit, Apply, and Remove details.

## Native lifecycle entry points

Codex connects five events; Claude Code connects six. See the event matrix. Key differences: Codex `PostToolUse` / `PreToolUse` for Edit|Write|apply_patch must parse paths from patch headers. Claude `PreToolUse` may return `ask`; `PostToolUse` emits only a nonblocking `systemMessage`. Claude also has a `PreCompact` record reminder.

`PreToolUse` only warns about suspected secret structures: a soft reminder in Codex and `ask` in Claude. It is not a complete Class C classifier. For `baseUrl`, user-data deletion, real-secret disclosure, or irreversible destructive actions, return to `操作系统/01_架构/三类行为铁律.md` for manual reassessment.

Per-event scripts and field compatibility are in the event matrix and appendix.

## Watch / scheduled

```powershell
# Check the ADR watcher.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Check

# Check the scheduled task.
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Check
```

See [less frequent watch/scheduled commands](hooks-运行SOP-附录.md#less-frequent-watch--scheduled-commands) for Apply, Remove, health codes, and rebuilding.

## Automatic-write boundaries

- Automatic writes cover only indexes determined by the filesystem, such as ADR README tables.
- `PostToolUse` provides quick-check reminders only; it does not generate patches. The current readme-index quick check includes P4o/P4q/P4r anchors. Scheduled/watch runtime state still uses the full P4r check.
- `PreToolUse` only warns about suspected secret structures. It does not replace Class B/C assessments for `baseUrl`, user-data deletion, real-secret disclosure, or similar actions.
- `Stop` / `chat-output` checks sections ①–⑦, the handoff path, and `状态.md` line numbers only when implementation appears to be closing. Read-only audits and sessions without file changes are exempt. Simple conversations may use section ⑥ with no handoff and section ⑦ with `N=0`, stating that no PM role changed this session. Hooks do not rewrite the agent's response.
- `handoff-zone-check` only warns; it does not automatically move cards from `待接手` to `已接手`.
- Handoff cards, PM transition records, the top summary of `状态.md`, and historical summaries are still written after PM judgment.

## Failure handling

For README indexes, run `Check` before `Apply`. For PM transitions, add the actual row and line number in `状态.md`. Address framework health output item by item. If watch triggers incorrectly, stop it before checking with the manual runner. See the appendix for less frequent troubleshooting.

## Completion criteria

- `能力资产/tools/hooks/tests/hooks-smoke.ps1` passes. `tests/support/*.ps1` only separates internal contracts; these files must not enter the manifest individually.
- `run-hooks.ps1 -Trigger manual -Mode Check` passes, or explicitly state the lightweight hook scope used in this batch.
- hooks-smoke locks the scheduled-entry contract for `framework-health-check`: the manifest continues to target the `能力资产/tools/scripts/check-operating-system.ps1` facade; internal P4 modules must not enter the manifest individually.
- After hook-documentation or runtime changes, run `能力资产/tools/scripts/check-operating-system.ps1` and confirm that P4r hook configuration and runtime anchors pass.
- README / INDEX consistency output is explicit.
- The ADR README updater reports no differences in `Check` mode against current state.
