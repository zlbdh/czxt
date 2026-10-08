---
name: hooks-design
scope: project
type: semantic
loaded: on-demand
description: Operating-system hook design — Layer 4 automation v0 and the PROP-038 implementation entry.
---

# Hook Design · Layer 4 Automation v0

> Goal: turn rules that depend on PM memory into hooks stored and versioned inside the project, runnable manually or through Git, watch, and scheduled triggers.

This file covers design decisions, layers, write boundaries, and verification entry points. See the [event matrix](hooks-事件矩阵.md) and [runtime appendix](hooks-事件矩阵-附录.md).

## Design decision

The operating system needs hooks: PROP-038 identified Hooks / Watch / Cron / MCP events as the Layer 4 root-cause solution for issue CK; PM self-correction #76 showed that a short chat handoff cannot prove an actual write; and ADR-032 made list-README consistency a permanent procedure.

## Layers

| Layer | Location | Responsibility |
|---|---|---|
| Rules | `操作系统/` | Why and when checks must run, and how to classify failures. |
| Execution | `能力资产/tools/hooks/` | Trigger wrappers, manifest, and watch/scheduled/Git entries. |
| Scripts | `能力资产/tools/scripts/` | Reusable deterministic scripts. |
| Native Codex entry | `.codex/hooks.json` | Lifecycle adaptation, without application logic. |
| Native Claude Code entry | `.claude/settings.json` | Lifecycle adaptation; scripts remain in `能力资产/tools/hooks/`. |
| Local installation | `{{APP_REPO_DIR}}/.git/hooks/` and Windows Task Scheduler | Generated artifacts, not sources of truth. |

## Current v0 hooks

`能力资产/tools/hooks/manifest.json` is authoritative for the 9 project hooks. Native Codex connects 5 events, and native Claude Code connects 6 events.

The event tables, script paths, and scheduled/watch/Git wrapper details live in the [event matrix](hooks-事件矩阵.md) and [appendix](hooks-事件矩阵-附录.md). The matrix is a readable mirror, not a fourth source of truth.

## Native Codex lifecycle adapters

The Codex desktop Hooks page reads native Codex configuration; it does not automatically read the project's `manifest.json` or `.git/hooks`.

Project-level `.codex/hooks.json` connects 5 lifecycle events. The adapter only bridges events; governance scripts remain in `能力资产/tools/hooks/`. Project-level Codex hooks execute only after Codex UI review/trust.

See the [complete Codex matrix](hooks-事件矩阵.md#native-codex-lifecycle-adapters) and [PostToolUse / PreToolUse compatibility details](hooks-事件矩阵-附录.md#codex-adapter-differences).

`PreToolUse` only warns about apparent secret structures: a soft reminder in Codex and `ask` in Claude. It is not a complete Class C classifier. Manually reassess `baseUrl`, user-data deletion, external transmission of real secrets, and irreversible destructive actions under the three-class behavior rules.

## Native Claude Code lifecycle adapters (PROP-038, issue CK / 2026-06-14)

Project-level `.claude/settings.json` connects 6 lifecycle events.

A newly created `.claude/settings.json` is not loaded automatically in the same session. Open `/hooks` once in Claude Code to reload the configuration, or restart the session.

See the event matrix and appendix for Claude events and Stop differences.

## Automated-write boundaries

✅ May write automatically:
- Index tables generated deterministically from the filesystem.
- README tables that only add missing entries, remove excess entries, or reorder rows.

🟡 Report for manual action; do not include in automated writes:
- Semantic content requiring PM judgment, such as the root README's current-version summary, the top three-second status snapshot, and the issue-overview semantic table.

❌ Do not write automatically:
- API keys, baseUrl, or user data.
- Application code in `{{APP_REPO_DIR}}/src/**`.
- Historical summaries requiring PM interpretation.
- Semantic documents such as the seven-part closing chat handoff, PM transitions, handoff-card content, or the top status summary.

## Why semantic documents are not synchronized automatically

Automatic hook writes cover only indexes determined by the filesystem, such as the ADR README table. Other documents receive checks or reminders:

- Codex `PostToolUse` runs `check-readme-indexes.ps1` after Edit/Write/apply_patch changes to framework files, PM workspaces, or governance entries. For large application files under `{{APP_REPO_DIR}}/src` in the red or soft-warning range, it only reminds the Development PM to assess splitting by function. It extracts apply_patch target paths from patch headers.
- Claude Code `PostToolUse` runs the same check after Edit/Write changes to those areas and only warns for large application files. It reports drift without generating patches.
- `PreToolUse` only warns about apparent secret structures. It does not automatically determine full C/B boundaries for baseUrl, user-data deletion, or external transmission of real secrets.
- `Stop` / `chat-output` checks and blocks apparent implementation-completion output that lacks the seven parts, a readable handoff-card path, or status line numbers. It does not rewrite the agent's reply or fill in a card.
- `handoff-zone-check` only alerts; it does not move cards automatically from `待接手` to `已接手`.
- The Windows ADR watcher handles deterministic indexes such as the ADR README, not historical summaries, handoff areas, PM transitions, or status summaries.

## Verification

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/tests/hooks-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-readme-indexes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-operating-system.ps1
```

`hooks-smoke.ps1` is the public verification entry. `tests/support/*.ps1` only splits internal contracts for configuration, chat output, Codex, Claude, and lifecycle coordination; these files are not independently registered as hooks in `manifest.json`.
