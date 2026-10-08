---
name: implementation-loop-dod
scope: project
type: procedural
loaded: on-demand
description: Definition-of-Done checklist for L1–L4 changes, cross-session synchronization, and failure fallback.
---

# Implementation Loop — Definition of Done

> Primary document: [implementation loop](实施循环.md). This file contains the L1–L4 DoD, cross-session synchronization package, and failure fallback.

Completion criteria vary by scale. L3/L4 use the full checklist; L1/L2 simplify as applicable. Keep the task `in_progress` until all required boxes are checked.

## L3 / L4 full checklist

> ⭐ **Six mandatory core items** — one missing item means incomplete.
> - [ ] **Decision checkpoint** Q1–Q7 completed, including Q7 agent instantiation.
> - [ ] **Code** implements the PRD, with no remaining TODOs.
> - [ ] **Tests**: all three layers pass—vitest, esbuild, and vite build.
> - [ ] **PRD** moves from in progress to completed; requirement history has an entry.
> - [ ] **PROP archival**: status changes to completed, move from the in-progress directory to the completed directory, and update README counts.
> - [ ] **Reconciliation skills**: [project health check](../../能力资产/skills/项目体检.md) and [status inference](../../能力资产/skills/状态推断.md) both pass.
>
> The following are **additional items**; apply them as needed, rather than requiring every item every time.

**Code: additional items**
- [ ] Fully implements the PRD with no remaining TODOs.
- [ ] No leftover `console.log`, `debugger`, or testing hardcodes.
- [ ] `wc -lc` and `tail -3` confirm no mount-related file truncation.

**Tests: three layers and additional items**
- [ ] esbuild syntax passes with 0 failures.
- [ ] vitest passes, including new tests; existing tests remain intact.
- [ ] vite build succeeds; warnings are tolerable, but errors must be 0.
- [ ] All five tabs pass smoke testing.
- [ ] **Runtime capability accounting**: state which tests ran in which runtime; see the [appendix](实施循环-附录.md).

**Documentation**
- [ ] PRD item status moves from in progress to completed.
- [ ] Add a new version entry to `Docs/1-需求文档/需求历史.md`.
- [ ] Synchronize relevant sections in `Docs/3-开发文档/`; for example, schema changes require an update to `数据库schema.md`.
- [ ] L4 requires an ADR in `Docs/3-开发文档/adr/`.

**PROP archival: required for L3/L4 so a PROP does not remain in the in-progress directory**
- [ ] Change the PROP header status to approved and completed, recording the `YYYY-MM-DD` implementation date and corresponding `ADR-XXX`.
- [ ] Move the PROP from `确认改动/已审批/进行中/` to `确认改动/已审批/已完成/`.
- [ ] Update the current list in `确认改动/README.md`: counts and in-progress/completed lists.

**PRD consistency across two sources**
- [ ] If a PRD has both a table and subsection headings, their statuses must agree.
- [ ] Completed sections must not contain pending, TBD, ⏳, pending APK, or pending smoke markers. If no APK has been built, the Sprint's top status column must show ⏳ rather than ✅.

**Project health check**
- [ ] Run all nine checks in the [project health skill](../../能力资产/skills/项目体检.md); all must pass.
- [ ] Report ✅ / 🟡 / 🔴. Resolve red failures before marking a task completed.

**Status inference reconciliation: automated cross-session protection**
- [ ] Run the ten inferences in the [status inference skill](../../能力资产/skills/状态推断.md).
- [ ] Check APK, code changes, RETRO triggers, ADR consistency, and cross-session state.
- [ ] For any status that should have changed but has not, obtain user confirmation, then update under the responsible PM's path allowlist, status rules, and recording requirements.

**APK**
- [ ] Development APK is built, by zlbdh on Windows or GitHub Actions.
- [ ] Copy to `{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-debug.apk`, using the handoff card's current naming rule: `{{PROJECT_NAME}}-vX.Y.Z-debug.apk`.
- [ ] zlbdh has installed it and completed the smoke checklist in `Docs/4-测试文档/手动测试用例.md`.

**Closeout**
- [ ] Task status = `completed`.
- [ ] Update the top-level README.md for any user-visible change.
- [ ] Report what changed, test results, and APK path to zlbdh; implementation closeout still uses chat ①–⑦.
- [ ] If this batch is the Nth L3+ change, trigger a retrospective in `Docs/7-复盘/RETRO-XXX.md`.

## L2 simplified checklist

- [ ] Code changes complete.
- [ ] vitest passes.
- [ ] Add a line to requirement history or the appropriate changelog.
- [ ] Synchronize affected sections of `Docs/3-开发文档/`.
- [ ] Task = `completed`.
- [ ] File changes or cross-role/cross-session work still require the full handoff card, chat ①–⑦, and `状态.md L<line>` under the handoff matrix.

## L1 simplified checklist

- [ ] Code changes complete.
- [ ] Add a line to requirement history or the appropriate changelog. A batch of L1 fixes may share one entry, such as “Fixed typos X, Y, and Z.”
- [ ] Task = `completed`.
- [ ] For implementation closeout, a one-sentence report must not replace chat ①–⑦.

## Cross-session synchronization package / handoff card

⭐ Complete template: [handoff format](../03_交接/交接卡格式.md).
⭐ Write to `交接区/待接手/YYYY-MM-DD-HHMM-任务-从到.md`. Source and recipient should primarily identify PM responsibilities; tool names only supplement the execution runtime.

Three-layer structure:
1. **`交接区/待接手/...md`**: a complete standalone file with sections ①–⑥; add file section ⑦ for framework / PM transition work.
2. **Top summary of `状态.md`**: minimal summary plus a link to that card.
3. **Abbreviated handoff text**: lets zlbdh copy the handoff to a session in another runtime.

Required at implementation completion; see the [handoff-area README](../../交接区/README.md):
1. Move the previous card you accepted to `交接区/已接手/`.
2. Write the new card to `交接区/待接手/`.
3. Update the top summary of `状态.md`.
4. Send zlbdh the chat summary handoff, sections ①–⑦.

At the next session's startup, read the `状态.md` summary and latest file in `交接区/待接手/`; see inference 5 in [cross-session monitoring](../../能力资产/skills/状态推断-跨session监控.md).
Old formats remain compatible, but **all new handoffs must use the handoff area** and include at least file sections ①–⑥.

## Failure fallback

If an item cannot be completed, such as an APK that cannot be built or a failing smoke test:
1. Record progress and the blocker in a PROP under `确认改动/待审批/`.
2. Keep the task `in_progress`.
3. For cross-session work, write a card in `交接区/待接手/` and send chat ①–⑦.
4. Let zlbdh review and decide whether to fix and continue, roll back, or change the plan.
