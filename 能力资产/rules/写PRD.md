---
name: write-prd
scope: project
type: semantic
loaded: on-demand
description: Business-language PRD template, terminology, four input boundaries, effort, priority, splitting decisions, and review checklist.
---

# Rule: Writing a PRD in Business Language

**Core principle: sections written for zlbdh must use business language without technical jargon.**

## Business-language template

Before creating an `F-XXX`, scan existing IDs using the [feature numbering rule](F编号规则.md) to prevent collisions.

```markdown
## F-XXX · <Plain-language title>

### What this is
Explain the work in one or two sentences, without React, Component, Route, or Hook terminology.
Use familiar product terms: page, card, dialog, button, list.

### What you will see when you open the app
Describe what the user sees and does, as if describing a scene:
- Page X displays Y.
- Tap Y to show Z.
- Z has buttons A, B, and C.
- Tap A to open D. A sketch may help.

### Acceptance criteria
The work is complete when the user can verify all these behaviors:
- [ ] Behavior 1
- [ ] Behavior 2
- [ ] Empty state: display ...
- [ ] Error state: display ...

### User input boundaries (issue P / ADR-022 decision 4; required)

Every user-editable field must specify all four boundaries. Omitting them makes the PRD incomplete.

- **Blank → default**: count values, such as an egg threshold, default to 5; decimal values, such as a protein powder threshold, default to 0.2; strings default to an empty string.
- **Explicit 0 → actual 0**: entering 0 intentionally means zero. Distinguish blank from explicit zero; beware JavaScript's `Number("") === 0`.
- **Handle null / undefined / "" separately**: use an `isMissing` helper or the `??` operator as appropriate; never rely on `!v`.
- **Numeric strings**: parse to the corresponding number, such as `"5"` → `5`; invalid strings use the default.

Counterexample (RETRO-007 card 1 + F-PREP-1 #07: the same failure occurred twice):
- Incorrect: the PRD says a decimal threshold defaults to 0.2, but `value ?? DEFAULT` lets `""` through; `Number("") === 0` changes the threshold to 0.
- Correct: first check `if (v === null || v === undefined || v === '') return DEFAULT`, then parse with `Number(v)`.

### Out of scope
State exclusions explicitly to prevent misunderstandings:
- X is excluded.
- Y is excluded.
```

## Business-language alternatives

| Avoid | Use |
|---|---|
| ErrorBoundary | “Show a helpful message if something goes wrong” |
| Route / Routes | “Page / tab” |
| Component / Hook | “Card / module” or “page” |
| Modal / Drawer | “Dialog” or “card that slides up from the bottom” |
| State / setState | “Update immediately after the change” |
| Lazy loading | “Load it when needed” |
| Refactor | “Organize the code without visible changes” |
| Debounce | “Prevent repeated rapid taps” |
| LocalStorage / IndexedDB | “Local storage” or “on the phone” |
| API / endpoint | “Interface,” or simply “AI call” |
| Schema migration | “Automatically transfer existing data during the upgrade” |
| Validation | “Check whether the input is valid” |

## Effort

- **Small (S)**: under one hour / one file / visual adjustment.
- **Medium (M)**: half a day / multiple files / new component.
- **Large (L)**: one day / multiple modules / data schema change / new native plugin.

## Priority

- **P0**: existing functionality cannot work without it, or a security risk exists; must have.
- **P1**: clear user experience improvement or a real pain point; should have.
- **P2**: an enhancement; nice to have.

## Deciding when to split a PRD

Each entry should represent **the smallest independently deliverable user value**.

Split oversized entries. “F-001: add a calendar” is too broad. Use separate feature IDs or subcriteria under one feature:

- F-101: basic calendar capability.
- F-102: calendar in Health.
- F-103: calendar in Timeline.
- F-104: calendar in Profile.

Combine undersized entries. Hover feedback for `PillButton` and `PrimaryButton` can become “F-LAYOUT-X: subtle feedback when tapping a list.”

## Counterexamples

Poor: “Wrap each AppShell Route with a React `ErrorBoundary`.” The user cannot understand the implementation jargon.

Better: “The app must no longer crash to a blank screen. If one page fails, show a brief error message and let the user continue using other tabs.” This explains the user value.

Poor: “Refactor useAppData to memoize database calls and reduce re-renders.” This is technical optimization, not a user-visible requirement. Put it in the developer's task list instead of the PRD.

## Optional user story

For an abstract requirement, add a user story:

> As zlbdh, I want to tap a calendar date to see that day's details, so I can review them quickly without switching between tabs.

## Review checklist

- [ ] No technical jargon in user-facing prose; verify with a text search.
- [ ] Acceptance criteria describe what a user can see, rather than merely whether code runs.
- [ ] Exclusions are explicit.
- [ ] Empty, error, and loading states are covered.
- [ ] Effort and priority are marked.
- [ ] Affected pages and modules use business names.
