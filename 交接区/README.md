---
name: handoff-zone-index
scope: project
type: semantic
loaded: on-demand
description: Cross-role handoff records; pending, accepted, cross-branch, and historical cards.
---
# Handoff Area: Events Across Sessions and PM Roles

Store a handoff card whenever responsibility changes, such as Development PM to Test and Release PM, or Operating System PM to Project PM. When relevant, name the execution tool—Cowork, Claude Code, or Codex—in the body.

`状态.md` records the current snapshot: where work stands now. `交接区/` records the event stream: what happened during previous transitions. Both are needed and serve distinct purposes.

## Directory structure

| Path | Purpose |
|---|---|
| `README.md` | This guide |
| `待接手/` | Cards written after a role completes implementation |
| `已接手/` | Cards moved here when the recipient completes the work; temporary storage for accepted/completed handoffs |
| `分支间/项目PM→运营咪咪/待处理/` | Pending Project PM to Operations handoffs |
| `分支间/项目PM→运营咪咪/已处理/` | Processed Project PM to Operations handoffs |
| `分支间/运营咪咪→项目PM/待处理/` | Pending Operations to Project PM handoffs |
| `分支间/运营咪咪→项目PM/已处理/` | Processed Operations to Project PM handoffs |
| `历史归档/` | Long-term history, grouped by month |

Historical cards retain their original form. They may contain obsolete paths, tool names, tasks, commands, or sensitive-incident records. Use them for historical tracing, not as current instructions or copy-and-run commands.

## Naming

Use `YYYY-MM-DD-HHMM-task-from-role-to-role.md`, for example:

- `2026-06-16-0930-F-002-product-pm-to-development-pm.md`
- `2026-06-16-1100-F-002-development-pm-to-test-and-release-pm.md`
- `2026-06-16-1430-F-002-test-and-release-pm-to-project-pm.md`
- `2026-06-16-1608-capability-tool-script-entry-points-os-pm-to-project-pm.md`

This sorts chronologically and identifies the task and recipient immediately. Prefer responsibility-role names for new cards; identify tools separately in the body, such as "Execution tool: Codex." Historical tool-flow names such as `Codex到Cowork` and `ClaudeCode到Codex` may remain; do not rewrite the historical event stream merely to rename it. Separate sequence numbers are unnecessary because timestamps are unique.

## Card format

Use all six sections in the [handoff format](../操作系统/03_交接/交接卡格式.md). Historical context is in its [appendix](../操作系统/03_交接/交接卡格式-附录.md).

1. ① Time and role transition.
2. ② Changed files.
3. ③ Test status, with execution-environment capabilities.
4. ④ Recipient actions as a concrete checklist.
5. ⑤ Cautions, including `Status: <DONE / BLOCKED / HANDOFF / RISK / OBSERVE>`.
6. ⑥ Follow-up questions. Keep the heading even when the answer is "None."

## Workflow

### Delivering role completes implementation

1. Move the card you previously accepted, if any, from `待接手/` to `已接手/`, indicating that your assigned work is complete.
2. Write a new card in `待接手/YYYY-MM-DD-HHMM-task-from-me-to-next-role.md`.
3. Update the latest-handoff summary and link at the top of `状态.md`.
4. Give zlbdh the short handoff format for copying and pasting.

### Receiving role starts

1. Read the progress summary in `状态.md`.
2. Read the newest card in `交接区/待接手/`, or the card specified by the user.
3. Begin work without modifying or moving that card. It remains pending during implementation.
4. On completion, follow the delivering-role process above.

### zlbdh confirms receipt

When Codex or Claude Code creates a card addressed to zlbdh in `待接手/`, zlbdh reads and accepts it. The AI then moves it to `已接手/`, recording receipt.

## Who moves a card, and when?

| State | Meaning | Who moves it | When |
|---|---|---|---|
| In `待接手/` | Waiting for the next PM or zlbdh's confirmation | No one yet | Remains here while pending |
| Moved to `已接手/` | Recipient finished the work or zlbdh accepted it | Recipient/current session | At implementation completion or confirmation |
| Moved to `历史归档/yyyy-mm/` | Long-term history | Any session performing the archive task | After a health check identifies accepted cards older than 30 days and a person confirms the move |

Existing hooks warn or block; they do not silently move files. The recipient or current session must explicitly perform the move.

## Avoiding conflicts between sessions

Each session writes a distinct timestamped file, preventing simultaneous edits to one card. If two sessions may be moving the same card, inspect the actual directories with `ls` first.

## Do not

- Delete any card; accepted and archived cards are historical records.
- Skip the handoff and immediately begin unrelated work.
- Modify cards in `已接手/`; they are historical records.
- Paste large volumes of screenshots into chat; save them in `Docs/4-测试文档/smoke截图/`.

## Archiving cadence

Once per month, zlbdh reviews accepted cards older than 30 days for movement to `历史归档/yyyy-mm/`. The project health check monitors this, implemented under PROP-011.

## Current state

Do not manually maintain counts in this README. Use current command output:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-handoff-zone.ps1
```

## References

- [Handoff format](../操作系统/03_交接/交接卡格式.md): six document sections and seven-part short chat format.
- [Handoff appendix](../操作系统/03_交接/交接卡格式-附录.md): historical triggers, failures, required matrix, and automatic-alignment limits.
- [Implementation DoD](../操作系统/07_完整工作流/实施循环-DoD.md): proposal-archiving step references this mechanism.
- [Cross-session state inference](../能力资产/skills/状态推断-跨session监控.md), inference 5: start with the newest pending handoff.
- [ADR-015](../Docs/3-开发文档/adr/ADR-015-交接区机制.md): decision record.
- [Current state](../状态.md): snapshot, top summary, and quick progress view.
