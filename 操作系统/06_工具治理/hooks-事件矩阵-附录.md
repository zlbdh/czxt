---
name: hooks-event-matrix-appendix
scope: project
type: semantic
loaded: on-demand
description: Hook event matrix appendix — watch/scheduled details, runtime differences, and events not yet connected.
---

# Hook Event Matrix Appendix

> See the [main matrix](hooks-事件矩阵.md). This appendix provides occasional explanations, not the source of truth.

## Watch / scheduled details

`能力资产/tools/hooks/scheduled/install-scheduled-task.ps1` checks, installs, and removes the Windows scheduled task. The default name is `CZXT-Framework-Hooks-Daily`. Its local generated configuration belongs to Windows Task Scheduler and is not the authoritative rule source.

`能力资产/tools/hooks/watch/install-adr-watch-task.ps1` checks, installs, and removes the ADR README watcher. The default task name is `CZXT-ADR-README-Watch`. At login it starts `adr-readme-watch.ps1 -Apply`, which handles only deterministic ADR README index updates.

## Codex adapter differences

Codex `PostToolUse` and `PreToolUse` mirror the Claude scripts `claude/{post-edit-framework-check,pre-write-guard}.ps1` as part of PROP-038 completion. They share logic with three Codex adaptations:

- Deliver reminders through both `hookSpecificOutput.additionalContext`, verified as reliably read by Codex as with SessionStart, and `systemMessage`.
- `PreToolUse` gives a soft warning rather than a hard ask/deny. The Codex permission-decision format was not verified, so additionalContext asks the model to reassess the boundary.
- The Codex desktop commonly uses `apply_patch`; the adapter supports extracting paths from patch headers.

`PreToolUse` recognizes only apparent secret structures. It is not a complete C/B classifier. `baseUrl`, user-data deletion, external transmission of real secrets, and irreversible destructive actions remain governed by `操作系统/01_架构/三类行为铁律.md`.

The `file_path` and `content` readers support multiple field names to accommodate runtime differences. Both include BOM stripping and fail-safe behavior: continue/allow when uncertain. Independent stdin testing in the actual environment covered temporary ADR drift alerts, real-looking and false secret examples, and `.env` exemptions.

## Claude Code adapter details

All three root-cause additions on the Claude side (PROP-038 / 2026-06-14) are fail-safe: continue/allow when uncertain and never block incorrectly; `PreToolUse` asks and never denies. Independent stdin pipe tests and positive/negative runtime checks verified temporary ADR-drift alerts in `PostToolUse`, plus secret/false-secret cases and ellipsis false positives in `PreToolUse`. All stdin readers strip BOMs to prevent host-inserted BOMs from breaking JSON parsing.

Codex `PostToolUse` and `PreToolUse` have been mirrored and registered in `.codex/hooks.json`. The current Codex entry has no corresponding `PreCompact` or `SessionEnd` integration.

## Claude-supported events not connected in this project

The Claude Code hooks reference also lists events such as `FileChanged`, `Notification`, and `SessionEnd`. This project currently connects only 6 high-value events:

- `FileChanged`: no equivalent general fallback for external disk changes. The Windows watcher synchronizes only the ADR README deterministically; the daily scheduled task performs health checks only.
- `Notification`: no project-governance action.
- `SessionEnd`: fallback for abnormal completion, deferred because its expected value was low.

To pursue one configuration with full equivalence across both runtimes, first add the missing Claude-side events here, then evaluate whether Codex provides equivalent entry points.

## Stop adapter differences

Codex passes `last_assistant_message` directly to Stop. Claude Code passes `transcript_path`, pointing to session JSONL. `claude/stop-chat-summary.ps1` accepts both: prefer `last_assistant_message`; otherwise read backward from `transcript_path` to the last assistant `text` block. Reuse the same `run-hooks chat-output` check. The entire flow is fail-safe: continue when uncertain and never block incorrectly.

The Claude configuration uses exec form, `command:"powershell.exe"` with an `args` array, to avoid shell parsing problems with Chinese paths.
