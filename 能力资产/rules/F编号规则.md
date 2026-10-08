---
name: f-number-namespace-rule
scope: project
type: semantic
loaded: on-demand
description: F-XXX feature namespaces, numeric module ranges, sequential IDs, and commands to prevent collisions.
---

# Rule: F-XXX Feature Numbering

Prevent duplicate IDs, mixed usage, and namespace collisions.

## Namespaces

| Namespace | Prefix | Purpose | Examples |
|---|---|---|---|
| Numeric core features | `F-XXX` (three digits) | Core features in Sprint PRDs | F-001 / F-006 / F-205 |
| Navigation / architecture | `F-NAV-X` | Navigation features | F-NAV-1 |
| Chat | `F-CHAT-X` | Chat features | F-CHAT-1 |
| Layout / UI refinements | `F-LAYOUT-X` | Microinteractions, animation, UI details | F-LAYOUT-1 / F-LAYOUT-2 |

## Numeric ranges

Assign ranges by **module meaning**, without mixing unrelated modules.

| Range | IDs | Module |
|---|---|---|
| 0xx | F-001–F-099 | General or cross-module features, such as F-001 calendar date selection |
| 1xx | F-100–F-199 | Health: diet, training, weight |
| 2xx | F-200–F-299 | System / safeguards, such as F-205 ErrorBoundary or F-203 chat archiving |
| 3xx | F-300–F-399 | Timeline: moments and memories |
| 4xx | F-400–F-499 | Accounting |
| 5xx | F-500–F-599 | Habit tracking |
| 6xx | F-600–F-699 | Profile and settings |
| 9xx | F-900–F-999 | Experimental or removable features |

## Sequential namespace IDs

Use consecutive numbers for `F-NAV-X`, `F-CHAT-X`, `F-LAYOUT-X`, and similar namespaces:

- F-NAV-1 (used) → F-NAV-2 ...
- F-CHAT-1 (used) → F-CHAT-2 ...
- F-LAYOUT-1 (used) → F-LAYOUT-2 (used) → F-LAYOUT-3 ...

## Choosing a namespace

- Core feature: numeric range, such as F-006 habit calendar.
- Iteration within a domain: named namespace, such as F-NAV-2 for another navigation change.
- General cross-module feature: 0xx, such as F-001 calendar date details.

## Required ID lookup

Run before creating a new F-XXX:

```powershell
cd {{PROJECT_ROOT}}

# Find every existing feature ID in the current requirements source of truth.
rg -o "F-[A-Z0-9-]+" Docs/1-需求文档 -g "*.md" |
  ForEach-Object { ($_ -split ':')[-1] } |
  Sort-Object -Unique
```

The new ID is **the highest existing number in the corresponding namespace plus one**. Explain any skipped number in a PROP.

## Historical examples, not the current allocation source

```text
F-001     Calendar date details (0xx general)
F-002     Health diet/training calendar (1xx health)
F-003     Accounting calendar (4xx accounting)
F-006     Habit calendar and backdated check-ins (5xx habits)
F-205     ErrorBoundary (2xx system)
F-203     Chat history archiving (2xx system)
F-NAV-1   Profile entry at upper right and rearrangement of five tabs
F-CHAT-1  Separate Chat tab
F-LAYOUT-1  Tab transition fade-in
F-LAYOUT-2  Subtle feedback when tapping a list
```

These are early examples from around May 9, 2026, not a complete allocation list. Always run the command above for current IDs. The historical F-006 classification is 5xx habits, although its calendar semantics lean toward cross-module 0xx. Preserve its historical name; apply this rule to new IDs.

## References

- [Approval and archiving](../../操作系统/07_完整工作流/审批与归档.md), section C: general ID lookup commands.
- [Status inference](../skills/状态推断.md): reconcile IDs alongside PROP, ADR, and RETRO numbers.
