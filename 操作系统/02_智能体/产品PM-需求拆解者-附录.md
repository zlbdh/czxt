---
name: product-pm-requirement-decomposer-appendix
scope: agent
agent: 产品PM-需求拆解者
type: semantic
loaded: on-demand
description: Product PM appendix with the full PRD template, counterexamples, examples, and relationship to the historical product-manager role.
---

# Product PM “Requirements Analyst”: Appendix

> Main entry: [Product PM](产品PM-需求拆解者.md). These occasional-use templates and examples do not replace its path allowlist or boundaries.

## Standard PRD template

Add a requirements-table row and detail section to the current Sprint's `Docs/1-需求文档/Sprint-N需求清单.md`:

```markdown
| ID | Title | User story | Priority | Status | Responsible file |
|---|---|---|---|---|---|
| F-024 | Open daily details from the calendar | As zlbdh, ... | P1 | Designing | features/timeline/Timeline.jsx |

## F-024 Open daily details from the calendar

**User story:** As zlbdh, I want… so that…

**Acceptance criteria (AC):**
- [ ] Selecting a calendar cell opens a drawer.
- [ ] ...

**Affected files:**
- M `src/features/timeline/Timeline.jsx`
- ...

**Estimate:** M, approximately half a day.

**Risks:**
- ...

**User-input boundaries — required by issue P, PROP-018 / ADR-022 decision 4:**
- Three-state handling: empty -> null; valid -> actual value; missing field -> null.
- Counterexample: the JavaScript `Number("") === 0` trap.
- Explicit empty states and defaults.
- Undo does not reverse a physical consumption action, where applicable.
```

## Counterexamples

- Writing `{{APP_REPO_DIR}}/src/features/...jsx` directly, even when the fix is known.
- Writing PRD ideas into `能力资产/skills/...` instead of the PRD.
- Omitting issue P's three-state handling section, mandatory since PROP-018 P6-2.
- Assigning a new F-XXX without checking the current Sprint list, risking collisions, duplication, or mixed scope.
- Estimating one day for an L4 change without applying the change-classification rules.

## Example 1: a business requirement

zlbdh asks whether the transaction list can be viewed on a calendar. The Project PM routes this business requirement to Product PM after the complete decision-checkpoint Q1–Q7. The abbreviated example shows Q1–Q3 only: Product PM, allowlisted `Docs/1/`, no boundary violation.

1. Restate: “You want a calendar showing which transactions occurred on each day.”
2. Confirm the existing Timeline calendar component. Clarify whether Accounting needs a card, a records view, or a separate tab, and whether selecting a cell opens a dialog or filters the list.
3. Ask one to three questions using the current runtime's available mechanism.
4. Write F-024 after receiving the answers.
5. Include issue P's input boundaries, such as an empty date selection.
6. Return to the Project PM.

## Example 2: drafting Sprint-5 F-ALARM-1

zlbdh requests alarms and reminder notifications for Sprint-5. The Project PM runs the checkpoint and routes the feature to Product PM.

1. Split it into five items: F-ALARM-1, F-REMIND-1, F-SYSCHECK-1, F-DEVIATION-3, and F-WEEKLY-1.
2. Include issue P input boundaries in each. An empty alarm time defaults to null, not zero.
3. Add estimates, L levels, and risk assessments.
4. Mark the new `@capacitor/local-notifications` dependency as Class B, requiring zlbdh's approval.
5. Return to Project PM and wait for approval of the PRD and dependency.

## Relationship to the historical product-manager file

The main entry absorbs all former responsibilities: triggers, inputs, outputs, procedures, counterexamples, and examples. It adds a path allowlist, explicit boundaries, the checkpoint protocol, and mandatory three-state input handling.

`PM-产品经理.md` remains a historical archive under PROP-004 / ADR-007:

- Its historical supersession note points to [Product PM](产品PM-需求拆解者.md), under PROP-020 path D, May 14, 2026.
- Do not delete the old decision record.
- For new PRD drafting, read the current main entry rather than the old archive.
