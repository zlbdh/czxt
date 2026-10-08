---
name: qa-role-legacy
scope: project
type: semantic
loaded: on-demand
description: "Historical QA role: three-layer vitest/build/Capacitor verification and a regression matrix. Superseded by the Test PM and Test and Release PM playbooks."
---

# QA Playbook: Testing Role

> Historical archive: current testing entries are [Test PM](测试PM-质量门户.md) and [Test and Release PM](测试发布PM-闭环者.md). This file preserves the former QA role, not current execution rules. Do not copy its commands or QA procedures directly into execution.

Mimi used this role to verify code and catch bugs before zlbdh received a broken APK.

## Trigger

The old Dev workflow required full QA after step 4. Under current responsibilities, the Test PM sets strategy and the Test and Release PM performs release completion.

## Historical example: three verification layers — do not copy into execution

### Layer 1: vitest unit tests

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
npm test -- --run
# Expected: all test files passed; total tests >= last_known_count.
```

If tests fail:

- Fix them before marking the PRD complete.
- If a new feature breaks an old test, fix the code or test according to the new acceptance criteria.
- If a new test is incorrect, fix the test.
- Common causes include incorrect import names, unclosed JSX tags, and outdated test contracts.

### Layer 2: vite production build

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
npm run build
# Expected: built in X seconds, with no errors.
```

Warnings:

- `Some chunks are larger than 500 kB`: a known consequence of heavy chart dependencies in this historical example; it could be ignored.
- `Module not found`: must be fixed.

### Layer 3: historical Capacitor sync and APK example — now owned by the Test and Release PM

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
npx cap sync android
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-apk.ps1
```

The Test and Release PM “Closer” continues release completion with installation on a physical device, CDP smoke tests, and logcat.

Optional layer 4: manual smoke testing.

After starting `npm run dev`, exercise these five tabs:

1. Home: check in, increment water intake, open a task dialog, generate an AI briefing, and send a chat message.
2. Health: enter weight, record a meal and workout, and run AI analysis, which requires a key.
3. Accounting: enter “Lunch 35,” inspect the pie chart, and edit the budget.
4. Timeline: write a note or link, star an item, and run AI organization.
5. Profile: edit the profile, copy the AI key, export a backup, and simulate a device.

## Test report template

Output after each QA run:

```markdown
## QA Report v3.X

- Modified files: N
- New tests: M
- Layer 1 vitest: N/N passed
- Layer 2 vite build: completed in X seconds
  - JS bundle: XXX KB / gzip XXX KB
  - Size change: ΔX KB
- Layer 3 Capacitor sync / APK: passed / skipped with reason
- Manual smoke: passed / skipped

Risks and known issues:
- ...
```

## Regression matrix

The historical workflow required this matrix after major changes:

| Flow | Input | Expected result |
|---|---|---|
| First launch | Empty IndexedDB | Default habits and primary ledger appear |
| Legacy migration | Existing v1 localStorage | Profile, tasks, and chat migrate to IndexedDB |
| Offline check-in | Airplane mode | All local actions work |
| Missing AI key | Remove LLM_STORAGE_KEY | Friendly error without a crash |
| Backup export | Select Export | JSON download contains all tables |
| Backup import | Paste JSON | All data is restored |

## Checks not to skip

> These reminders belong to the historical QA example, not current responsibility assignments. Local development self-tests now belong to the Development PM; release and ship gates belong to the Test and Release PM.

- Do not skip vitest because a change “only affects styling.”
- Do not skip vite build because the previous build passed.
- Do not mark a PRD complete solely because tests pass: every acceptance criterion must also be checked.
