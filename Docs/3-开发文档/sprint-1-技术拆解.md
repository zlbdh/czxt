# Sprint 1 Technical Breakdown

This PM-to-Development handoff contains technical details, file lists, estimates, and risks. The corresponding business PRD is `Docs/1-需求文档/Sprint-1需求清单.md`.

## F-205: ErrorBoundary for graceful failure ⭐ P0

**Level**: L3, a new feature spanning multiple files and requiring the full three-part process.
**Business PRD**: F-205 in `Docs/1-需求文档/Sprint-1需求清单.md`.
**Status**: Completed on 2026-05-08, verified on Windows and with device smoke tests.

### Data layer

- Reuse the existing `db.deviceEvents` table. **No schema change**, which makes this L3 rather than L4.
- New event type:

  ```js
  {
    type: 'error',
    raw: null,
    parsed: null,
    payload: {
      tab: 'health' | 'accounting' | 'timeline' | 'profile' | 'home',
      message: string,
      stack?: string,
      componentStack?: string,
      url: string,        // location.hash
      ts: ISO string,
    },
    status: 'caught',
    createdAt: ISO,
  }
  ```

- Reuse the existing useAppData action `addRecord('deviceEvents', {...})`.

### UI layer

#### New component: `src/shared/ErrorBoundary.jsx`

- **Must be a class component**; React hooks do not support `componentDidCatch`.
- Props:
  - `children`.
  - `tabName`, identifying the failed tab in error logs.
  - Optional `onError(payload)`, for writing deviceEvents.
- Fallback UI:
  - Centered off-white card.
  - Message: “Mimi had a hiccup 🫧 Try another tab?”
  - “Return Home” button, clearing error state and remounting Home.
  - A collapsed developer section showing message + stack.

#### Integration: `src/app/AppShell.jsx`

Wrap every Route in an ErrorBoundary:

```jsx
<Route path="/" element={
  <ErrorBoundary tabName="home" onError={logError}>
    <HomePage store={store} />
  </ErrorBoundary>
} />
```

`logError` uses `store.actions.addRecord('deviceEvents', { type: 'error', payload })`.

#### Profile: `src/features/profile/Profile.jsx`

Add a “Recent Issues” card:

- Place it below the Device Extensions card.
- Display `data.deviceEvents.filter(e => e.type === 'error').slice(0, 5)`.
- Each entry shows the date, tab name, and a short message.
- Empty state: “Everything has been running smoothly 🌿”.
- Keep the stack hidden or collapsed to avoid alarming zlbdh.

### Files

```text
+ src/shared/ErrorBoundary.jsx          New, approximately 70 lines
+ src/shared/ErrorBoundary.test.js      New, approximately 30 lines
M src/app/AppShell.jsx                  +10 lines: import, five Route wrappers, logError closure
M src/features/profile/Profile.jsx      +20 lines: new card for the five most recent errors
```

Do not change the database schema, useAppData, or the actions in useAppData.js.

### Estimate

| Dimension | Estimate |
|---|---|
| Effort | M, half a day |
| Affected files | 4 |
| Schema change | No |
| Cross-feature change | No: components, one integration point, and one UI entry point |

### Risks

| Risk | Mitigation |
|---|---|
| Class component behaves unexpectedly with Vite Fast Refresh | Add `// @refresh reset` at the top, or ignore because classes do not participate in HMR |
| Async `actions.addRecord` in `componentDidCatch` loses the error | Decouple from rendering with `setTimeout(() => actions.addRecord(...), 0)` |
| Child continues failing after reset | Reset with a key on the fallback Return Home action and Hash navigation to /, forcing unmount |
| ErrorBoundary itself fails | The original plan considered this impossible; keep the fallback to basic div + style and avoid components such as Card that could fail |

### Test coverage: vitest

`src/shared/ErrorBoundary.test.js`:

- Normal child → renders children ✓.
- Throwing child → renders fallback ✓.
- Throwing child → calls `onError` ✓.
- Return Home click → resets state ✓.

### Acceptance

Reuse the five F-205 acceptance criteria in `Docs/1-需求文档/Sprint-1需求清单.md`.

Add later technical breakdowns for F-203 / F-001 / F-006 / F-002 / F-003 / F-LAYOUT-1 / F-LAYOUT-2 when work starts. This document grows with the sprint.

## SPLIT-001: Split large files, PROP-001 B3 implementation

**Proposal**: `确认改动/已审批/PROP-001-2026-05-08-拆分大文件.md`.
**Level**: L3, multiple files with no schema or architecture change.
**Approach**: B3, split all five files in stages, selected by zlbdh on 2026-05-08.

### Scope: five source files at least 8KB

- `{{APP_REPO_DIR}}/src/shared/components.jsx`: 12137B.
- `{{APP_REPO_DIR}}/src/features/home/Home.jsx`: 13208B.
- `{{APP_REPO_DIR}}/src/features/timeline/Timeline.jsx`: 9594B.
- `{{APP_REPO_DIR}}/src/features/health/Health.jsx`: 9133B.
- `{{APP_REPO_DIR}}/src/features/profile/Profile.jsx`: 8579B.

### Stage 1: components.jsx split into six files, completed

| New file | Components | Estimated size | Imports |
|---|---|---:|---|
| `components.jsx`, core | Card / PageHeader / SectionTitle / EmptyState | ~1.9KB | C |
| `buttons.jsx` | PillButton / PrimaryButton / GhostButton | ~1.1KB | C |
| `inputs.jsx` | TextInput / TextArea | ~0.6KB | C |
| `stats.jsx` | StatRow / Stat | ~1.3KB | C |
| `MonthCalendar.jsx` | MonthCalendar and internal helpers | ~3.8KB | useMemo, useState, ChevronLeft/Right, C |
| `TaskDetailModal.jsx` | TaskDetailModal | ~2.7KB | useEffect, X, C |

### Import impact

Update `from '../shared/components.jsx'` in all `features/*` files according to the components used:

- Five feature files and possibly AppShell.jsx.
- TaskDetailModal is used only in Home.
- MonthCalendar is used in Health / Timeline / Profile.

### Verification

- Sandbox: balanced brackets, import path resolution, and each file below 6KB.
- Windows: `npm test`, all 33 tests pass; `npm run build`, 0 errors.

### Stages 2–6

Completed in order: Home.jsx → Timeline → Health → Profile → Accounting.jsx. Run independent static checks after each split, then a combined `npm test` and `npm run build`.

Final status recorded here: no source file under `{{APP_REPO_DIR}}/src/` is at least 6500B; the largest is approximately 6.3KB.
