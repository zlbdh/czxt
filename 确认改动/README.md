---
name: changes-approval-index
scope: project
type: semantic
loaded: on-demand
description: Proposal governance; pending approval, approved work, completed or abandoned records, and rejected proposals.
---
# Proposals

This archive records every change proposal throughout its lifecycle, from the initial idea to its final disposition.

Ideas not recorded here must not enter `Docs/1-需求文档/`. This prevents Mimi from independently adding requirements and contaminating the PRD.

## Directory structure and stages

| Stage | Path | Who may place a proposal here | Next step |
|---|---|---|---|
| Pending approval | `待审批/` | zlbdh may propose; Product PM or Operating System PM records proposals within the path allowlist | zlbdh reviews |
| Approved · Open | `已审批/进行中/` | Move here after approval | Responsible PM completes the DoD; work may await scheduling, rereview, external capability tracking, or reassessment |
| Approved · Completed | `已审批/已完成/` | All DoD checks pass and the ADR is written | Permanent archive |
| Approved · Abandoned | `已审批/已弃用/` | An approved approach is abandoned during implementation | Permanent archive, including the reason |
| Rejected | `拒绝/` | Rejected during review | Permanent archive, including the reason; retain to avoid repeated work |

All status transitions are defined in [approval and archiving](../操作系统/07_完整工作流/审批与归档.md). Follow that workflow after receiving zlbdh's approval signal.

## Proposal header status field

```text
- **Status**: Pending approval
- **Status**: Approved · Open / Awaiting scheduling (since YYYY-MM-DD; ADR-XXX pending)
- **Status**: Approved · Completed (implemented YYYY-MM-DD; ADR-XXX)
- **Status**: Approved · Abandoned (YYYY-MM-DD; reason: ...)
- **Status**: Rejected (YYYY-MM-DD; reason: ...)
```

When moving a file to its corresponding directory, update this line at the same time. The directory and header must agree.

## Naming

Use `PROP-XXX-YYYY-MM-DD-one-sentence-title.md`, for example `PROP-007-2026-05-15-weight-chart-x-axis-overlap.md`.

Numbers increase without reuse or gaps. **Run `ls` to find the highest existing number before assigning a new one.** See [approval and archiving](../操作系统/07_完整工作流/审批与归档.md), section C.

## Template

See `_模板.md`.

## Complete workflow

1. Record an idea in `待审批/PROP-XXX-...md`.
2. zlbdh reviews it.
3. If rejected, set the status to Rejected and move it to `拒绝/` for permanent archiving.
4. If approved, set the status to Approved · Open and its applicable substatus, then move it to `已审批/进行中/`.
5. The responsible PM implements, schedules, rereviews, tracks external capabilities, or reassesses it.
6. When all DoD checks pass, set the status to Approved · Completed and move it to `已审批/已完成/`. If abandoned during implementation, set the status to Approved · Abandoned and move it to `已审批/已弃用/`.
7. Retain the final record permanently.

## Prohibited shortcuts

- Do not bypass a PROP and edit the PRD directly.
- Do not move an AI-authored proposal to `已审批/` without notifying zlbdh and receiving approval.
- Do not create duplicate proposals; search `已完成/`, `已弃用/`, and `拒绝/` first.
- Do not make a proposal excessively long. This stage evaluates whether the idea deserves further work; it is not the final specification.
- **Do not delete any PROP.** Rejected, abandoned, and completed proposals are all historical decision records.
- Do not guess the next number from memory; run `ls`.

## Current counts: template root

| Pending approval | In progress | Completed | Abandoned | Rejected |
|---:|---:|---:|---:|---:|
| 1 | 0 | 3 | 0 | 0 |

The recorded `D:\WGKJ\操作系统` directory is the productized template root. Historical proposals from the source project remain with that project. The template root retains the proposal state machine, naming rules, directory structure, `_模板.md`, and proposals created for czxt's own productization, with a fresh numbering sequence beginning at PROP-001.

### Pending approval

- [PROP-002](待审批/PROP-002-2026-06-22-演化收敛闸.md): evolution convergence gate, a lightweight metrics view and convergence rule addressing unchecked growth — 2026-06-22 / L3 / Operating System PM "Framework Steward", supervised by Knowledge PM.

### In progress: approved and open

None.

### Completed: approved and completed

- [PROP-001](已审批/已完成/PROP-001-2026-06-22-路径C类铁律加PreToolUse软门禁.md): PreToolUse soft gates for path allowlists and Class C rules, asking rather than denying — 2026-06-22 / L3 / Operating System PM "Framework Steward".
- [PROP-003](已审批/已完成/PROP-003-2026-07-10-模板真值与hooks自清理收敛.md): template truth boundaries, P4s semantic guards, and hook-fixture cleanup — committed 2026-08-24; archive closure completed 2026-09-04 / L3 / Operating System PM "Framework Steward".
- [PROP-004](已审批/已完成/PROP-004-2026-07-18-完整借鉴闭环.md): unified borrowing area, source capture cards, borrowing cards, and the offline P4t guard — 2026-07-18 / L4 / Operating System PM "Framework Steward".

### Abandoned

None.

### Rejected

None.

## Source-project history

This template was extracted from real project practice. Historical ADRs and RETROs explain where rules came from. Proposal bodies are not copied as mandatory template assets, preventing false reports of missing project-instance history. Public templates should favor abstract rules and sanitized examples and should not include concrete project configurations by default.
