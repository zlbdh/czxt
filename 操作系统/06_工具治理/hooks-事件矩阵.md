---
name: hooks-event-matrix
scope: project
type: semantic
loaded: on-demand
description: Operating-system hook event matrix — readable mirrors of the manifest, Codex, and Claude configurations.
---

# Hook Event Matrix · Manifest / Codex / Claude

> This is a readable mirror, not a source of truth. Event counts come from `能力资产/tools/hooks/manifest.json`, `.codex/hooks.json`, and `.claude/settings.json`. See the [appendix](hooks-事件矩阵-附录.md) for runtime differences, verification history, unconnected events, and Stop details.

## Count anchors

- Project hooks: 9 project hooks; source: `能力资产/tools/hooks/manifest.json`.
- Native Codex: 5 lifecycle events; source: `.codex/hooks.json`.
- Native Claude Code: 6 lifecycle events; source: `.claude/settings.json`.

## Current v0 hooks

| Hook | Trigger | Write permissions |
|---|---|---|
| `readme-index-check` | manual / pre-commit / scheduled | Read-only. |
| `adr-readme-dry-run` | manual / pre-commit / file-watch | Check is read-only; Apply writes the ADR README. |
| `pm-tracking-check` | manual / chat-output / scheduled | Read-only. |
| `handoff-zone-check` | manual / scheduled | Read-only, nonblocking warnings. |
| `chat-summary-check` | chat-output | Read-only. |
| `hook-install-check` | manual | Check fails on missing or changed `.git/hooks` wrappers; Apply writes local `.git/hooks`. |
| `framework-health-check` | scheduled | Read-only. |
| `pre-release-check` | pre-push / manual | Read-only; test/build failure blocks push. |
| `retro-cadence-check` | scheduled / manual | Read-only; exit 5 is a nonblocking reminder. |

See [watch and scheduled details](hooks-事件矩阵-附录.md#watch--scheduled-details) for Windows task names and installation/removal procedures.

## Native Codex lifecycle adapters

Project-level `.codex/hooks.json` currently connects 5 lifecycle events:

| Codex event | Adapter script | Action |
|---|---|---|
| `SessionStart` | `能力资产/tools/hooks/codex/session-start.ps1` | Inject project governance context, PM boundaries, and hook sources of truth. |
| `UserPromptSubmit` | `能力资产/tools/hooks/codex/user-prompt-submit.ps1` | Add governance reminders for hook, operating-system, or sensitive-action requests. |
| `Stop` | `能力资产/tools/hooks/codex/stop-chat-summary.ps1` | Block apparent implementation-completion output missing the seven-part handoff. |
| `PostToolUse` (Edit\|Write\|apply_patch) | `能力资产/tools/hooks/codex/post-edit-framework-check.ps1` | Run a README/index check after framework or PM-workspace edits; only warn for large application files. |
| `PreToolUse` (Edit\|Write\|apply_patch) | `能力资产/tools/hooks/codex/pre-write-guard.ps1` | Soft warning for apparent secrets written outside `.env`; does not replace full C/B classification. |

See [Codex differences](hooks-事件矩阵-附录.md#codex-adapter-differences) for apply_patch path parsing, field compatibility, dual additionalContext delivery, and soft warnings.

## Native Claude Code lifecycle adapters

Project-level `.claude/settings.json` connects 6 lifecycle events (PROP-038, issue CK / 2026-06-14):

| Claude event | Adapter script | Action |
|---|---|---|
| `SessionStart` | `能力资产/tools/hooks/codex/session-start.ps1`, shared with Codex | Inject governance context, PM boundaries, and hook sources of truth. |
| `UserPromptSubmit` | `能力资产/tools/hooks/codex/user-prompt-submit.ps1`, shared | Add governance reminders for hook, operating-system, or sensitive-action input. |
| `Stop` | `能力资产/tools/hooks/claude/stop-chat-summary.ps1` | Block apparent completion output missing the seven-part handoff. |
| `PostToolUse` (Edit\|Write) | `能力资产/tools/hooks/claude/post-edit-framework-check.ps1` | Run a README/index check after framework or PM-workspace edits; only warn for large application files. |
| `PreCompact` (auto\|manual) | `能力资产/tools/hooks/claude/pre-compact-snapshot.ps1` | Snapshot the last PM-transition record before compaction and remind about unsent handoffs. |
| `PreToolUse` (Edit\|Write) | `能力资产/tools/hooks/claude/pre-write-guard.ps1` | Request `ask` confirmation for apparent secrets written outside `.env`; does not replace full C/B classification. |

See [Claude Code details](hooks-事件矩阵-附录.md#claude-code-adapter-details) for fail-safe behavior, BOM stripping, unconnected events, and Stop transcript handling.
