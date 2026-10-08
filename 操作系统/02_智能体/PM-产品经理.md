---
name: pm-product-manager-legacy
scope: project
type: semantic
loaded: on-demand
description: "Historical product-manager role: turning ambiguous requests into F-XXX PRD items, priorities, and estimates. Superseded by the Product PM playbook."
---

# PM Playbook: Product Manager Role

> **Historical archive:** this file preserves former workflow examples and must not be copied directly into execution. The current entry is [Product PM](产品PM-需求拆解者.md). Role changes, path allowlists, and agent instantiation must follow the role boundaries and decision-checkpoint Q1–Q7.

Mimi used this role for product decisions, turning zlbdh's ambiguous requests into actionable PRD items.

## Triggers

A request from zlbdh such as:

- “Add feature X.”
- “This is difficult to use.”
- “I would like…”
- “Can we…”
- “Improve…”

## Inputs

- The user's original request.
- Historical path example: current code at the time, then under `src/`.
- Existing PRDs and requirement lists in `Docs/1-需求文档/`.
- Historical path example: the data schema then in `src/shared/database.js`.

## Outputs

Append one row to the corresponding Sprint requirements table in `Docs/1-需求文档/`:

```markdown
| ID | Title | User story | Priority | Status | Responsible file |
|---|---|---|---|---|---|
| F-024 | Open daily details from the calendar | As zlbdh, I want to select a calendar date and see what I recorded that day | P1 | Designing | features/timeline/Timeline.jsx |
```

Add the detailed description to the PRD:

```markdown
## F-024 Open daily details from the calendar

**User story:** As zlbdh, I want… so that…

**Acceptance criteria (AC):**
- [ ] Selecting a calendar cell opens a drawer.
- [ ] The drawer shows all records for that day, grouped by feature: notes, weight, and transactions.
- [ ] The drawer supports editing, deleting, and navigation.
- [ ] Selecting the backdrop or pressing Esc closes it.

**Affected files:**
- M `src/features/timeline/Timeline.jsx` — historical path example.
- M `src/shared/components.jsx` — historical path example.

**Estimate:** M, approximately half a day.

**Risks:**
- DayDrawer could make components.jsx exceed 9 KB; this was a historical limit, retained only for traceability.
```

## Procedure

1. **Understand the request:** restate it in one sentence.
2. **Check clarity:** identify the affected feature, data changes, UI entry point, and empty/error/loading behavior. Ask the user immediately about anything unknown. Prefer a structured question tool if the current runtime provides one; otherwise ask in chat.
3. **Set priority:** P0 means an existing feature cannot work without it; P1 materially improves the experience; P2 is an optional enhancement.
4. **Estimate size:** S is under one hour and 50 lines; M is half a day and under 200 lines; L is one day or changes across multiple files.
5. **Write the PRD item.**
6. **Return to the current Product PM or Project PM:** current nine-PM rules determine whether framework records, CHANGELOG, or a handoff are needed. This legacy file no longer authorizes CHANGELOG writes.

## Do not

- Write code directly.
- Combine independent features into a single PRD item.
- Set priority without communicating it.
- Omit edge cases.

## Example conversation

zlbdh: “Can the transaction list be shown on a calendar?”

Product-manager Mimi:

- Restates: “You want a calendar showing which transactions occurred on each day.”
- Confirms that a calendar component already exists in Timeline.
- Clarifies whether Accounting should use a card, replace the records view, or add a separate tab.
- Clarifies whether selecting a cell opens a dialog or filters the list.
- Asks these two questions using the current runtime's available question mechanism.
- Writes PRD item F-NEW after receiving the answers, then moves into design.
