---
name: real-device-smoke-checklist
description: Required physical-device smoke checks under ADR-030 and meta-rule 13; five lessons across Sprints 6 and 7 show that unit tests do not prove device behavior.
trigger: Before Test and Release PM completion; Development PM may reference it only for handoff risk checks; lessons include W-3 and F-NIGHT v1-to-v2.
loaded: on-demand
---

# Required Physical-Device Smoke Checklist

> The execution owner is Test and Release PM “Closer.” Development PM may reference this checklist before handoff to assess risk; it does not execute physical-device smoke, commit, tag, APK, or release completion.

## Why this exists — permanent issue CC rule

**Passing unit tests does not prove physical-device behavior.** Five cross-Sprint lessons:

- F-NIGHT-1 v1: 879 unit tests passed, but device AC2 failed because 70 characters exceeded a 50-character limit.
- W-3 v1: 900 passed, but ordinary chat did not use buildPersonaPrompt on the device.
- F-DEVIATION-3: 771 passed, followed by emergency Git index recovery under BK v1.
- F-WEEKLY-1: 820 passed, but Recharts rendered incorrectly on the device.
- Issue BV W-4: device verification of breakfast/dinner display in timelineBuilder.

## Seven required checks

### 1. Align three acceptance layers

- [ ] Design: PRD AC #N.
- [ ] Tests: vitest covers the actual path, not just a helper.
- [ ] UI: physical-device smoke exercises the end-to-end user flow.
- Acceptance requires consistency across all three.

### 2. Exercise critical paths manually

- [ ] Main user flows such as chat, accounting, and training.
- [ ] Issue P's three-state boundaries, empty states, and settings toggles.
- Searching code alone does not replace these checks.

### 3. Issues BG/BH

- [ ] BOM-free commit message using `git commit -F`.
- [ ] No incorrect CRLF/LF handling in .bat files.

### 4. Issue BK stale-mount startup check

- [ ] Clean `git status --short`.
- [ ] HEAD matches Test and Release PM's completion report.

### 5. Issue BR AI-model verification

- [ ] LLM calls work and content meets the recorded project requirements, including the MiMo / domestic-market context.

### 6. One APK path

- [ ] `{{APP_REPO_DIR}}/apk/` remains the single source under permanently closed issue BQ.

### 7. Regression across the Sprint

- [ ] Previously shipped work still functions.
- [ ] Actual vitest N/N pass.

## Authoritative sources

- ADR-030 and meta-rule 13: issue CC is permanent; this checklist is the execution SOP.
- RETRO-010/011 self-correction cases #51/#52/#54.
- Status role-transition records from May 19–21.
