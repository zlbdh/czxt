---
name: handoff-spec-index
scope: project
type: semantic
loaded: on-demand
description: Entry point for handoff-card formats across PM roles.
---
# 03 Handoffs · Collaboration Across PM Roles

> Handoffs connect responsibilities such as Project, Operating System, Product, Technical, Test, Development, and Test and Release PMs. Cowork, Claude Code, and Codex are execution tools. They may appear in the body, but are not the primary actors in new cards.

| File | Purpose |
|---|---|
| [Handoff format](交接卡格式.md) | Frequent-use template: full file requires ①-⑥ + optional file section ⑦ + short chat handoff ①-⑦. |
| [Format appendix](交接卡格式-附录.md) | Historical triggers, failure cases, mandatory-use matrix, and why automation does not silently rewrite content. |

## Actual card locations

- `交接区/待接手/`: current in-flight cards.
- `交接区/已接手/`: temporary storage for accepted/completed cards.
- `交接区/历史归档/yyyy-mm/`: long-term historical archive.

## Issue safeguards

- PROP-014's three-level classification requires the seven-part short chat handoff.
- PROP-029 v2 / O-1 requires `Status: <STATE>` with five states in section ⑤.
- Guard enhancement on 2026-06-15: `handoff-zone-check` validates pending cards' ordered headings `## ①` through `## ⑥` and the enum `DONE / BLOCKED / HANDOFF / RISK / OBSERVE`. For overdue accepted cards, prefer the date in the filename.

## Maintenance

- Owner: Project PM as coordinator.
