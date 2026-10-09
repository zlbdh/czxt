---
name: changelog-2026h1
scope: project
type: episodic
loaded: on-demand
description: Historical archive — framework evolution in the first half of 2026 (early snapshots including PROP-017/018/019)
---

# agent/ Evolution Log · 2026 H1 Archive

⚠️ This file is a **snapshot archive of early framework evolution in the first half of 2026 (months 1–6)**. Old paths such as `agent/`, `../Docs`, and `../确认改动` retain their historical context and may not resolve. Current entry points are [`README.md`](README.md) and the main [`CHANGELOG.md`](CHANGELOG.md). Do not rewrite historical narrative merely to improve current link checks.
⚠️ **Historical safety boundary**: this text is for traceability only; it is neither a current backlog nor a current execution procedure; **Do not copy and execute directly**. Reassess old paths, commands, `.env.local`, API keys, tags/pushes, and related actions against the current `操作系统/01_架构/三类行为铁律.md`, ADR-016, ADR-022, and `操作系统/00_总入口.md`.

> **Archive date**: 2026-05-13 (Sprint-4 completed and PROP-018 P1 started; the 2nd archival pass occurred at PROP-019 P3 closeout—the 2nd application of issue A, English summary: trigger early instead of waiting for the calendar date, prompted by issue AM).
> **Related**: [PROP-018 issue A](../确认改动/已审批/已完成/PROP-018-2026-05-13-架构治理债清理v2.md)—CHANGELOG archival policy; [issue AM]—after PROP-019 P3, CHANGELOG reached 12635B, far above the threshold, triggering early archival.
> **Next archival trigger (obsolete historical policy, English summary)**: the next archive was then due when the main `agent/CHANGELOG.md` approached 6500B or H2 began on 2026-07-01. Consult this directory's README and main CHANGELOG for current archival entry points.

---

## 2026-05-13 / 14 (PROP-018a operating system + PROP-019 business-code governance)

### PROP-019 P3 — taskBinding completion integration (issue K implemented; Sprint-4 PRD ② debt resolved)

- **Changes**: Dexie schema v5→v6 added `taskBinding` to inventory items, backfilled null for existing users, and added try/catch fallback. `inventoryMonitor.js` gained `normalizeTaskBinding` (issue P three-state rejection) and `consumeForTaskCompletion` (completion-driven consumption). `useAppData.setTask` prevents duplicate deductions (deduct only when prevStatus !== 'done') and does not roll inventory back on undo. New independent component `InventoryBindingRow.jsx` (4215B, keeping InventoryCard below the 8KB soft limit) provides a task selector, step-size input, save/unbind controls, and a UI hint (English rendering: "Undo does not restore inventory"). `inventory.taskBinding.test.js` added 20 tests across 4 dimensions: normalize three-state handling / consumption boundaries / non-idempotency / v5→v6 compatibility.
- **Trigger**: PROP-019 P3 / RETRO-008 issue K P1 resolved Sprint-4 F-PREP-1 PRD ② acceptance debt (English rendering: "Completing a task reduces remaining inventory"). F-PREP-1 had shipped only manual +/-, without task→inventory binding. This was the 3rd correct application of ADR-022 decision 5 role boundaries: {{APP_REPO_DIR}}/src, tests, and UI all assigned to Claude Code.
- **Acceptance**: vitest 589 → **609/609** ✅ (+20 tests); esbuild and vite build passed with exactly 2289 modules. Issue P three-state rejection tests cover empty string/null/0/negative/NaN → null. prevStatus checks and targeted cases prevent duplicate deductions; v5→v6 migration backfills old item fields with null. After extracting the UI component, InventoryCard remained manageable at 7168B.
- **Consequences**: 1) After users set bindings in the Me Tab (English rendering: "Breakfast -2 eggs"), task completion deducts inventory automatically. 2) Undoing done does not restore inventory; the UI hint states this explicitly alongside issue P three-state handling. 3) PROP-019 P4 remained for Codex closeout of v3.5.7: bump + APK + smoke + commit + push. 4) ⚠️ Issue AM entered RETRO-009 because CHANGELOG.md far exceeded issue A's 6500B archival threshold; the PROP-018 section was archived the same day.

### PROP-019 P2 — Split 4 test files and add mock LLM anomaly templates (issue AD implemented)

- **Changes**: split 4 *-llm.test.js files above 10KB into 11 cohesive child files grouped by describe block. Added `_mockLLMAnomalies.js` with 5 mock helpers for thinking-model token exhaustion / stop_reason=max_tokens / empty responses / non-object responses / API errors / whitespace-only strings. Added 2 thinking-model suites (dailyBriefing-llm + deviation-llm), recorded here as 13 regression tests verifying automatic fallback on LLM anomalies.
- **Trigger**: PROP-019 P2 / RETRO-008 issue AD P1: each of 4 *-llm.test.js files exceeded 10KB. F-DEVIATION-2 smoke #1 exposed a missing mock for real thinking-model `stop_reason=max_tokens` behavior that vitest had not detected; a utility template was needed to prevent recurrence.
- **Acceptance**: vitest 577 → **589/589** ✅ (+12 tests: 11 thinking-model + 1 maxTokens constraint); test files 41 → 48. The historical accounting reports +7 as 11 split - 4 removed + 1 utility = +7 net. esbuild and vite build passed; no business regressions.
- **Consequences**: 1) Cohesive test scope lets happy-path and fallback files change independently. 2) `_mockLLMAnomalies.js` provides a utility for Sprint-5 F-DEVIATION-3 and later LLM integrations. 3) Issue AD advances to a meta-rule: mock anomaly templates become standard test infrastructure, with a RETRO-009 issue attached at PROP-019 P4 archival.

### PROP-019 P1 — Split llmBriefing.js into 3 modules (issue S implemented with correct role routing)

- **Changes**: `{{APP_REPO_DIR}}/src/shared/llmBriefing.js` shrank from 9128B to **3177B** (-65%). Extracted `llmBriefing.context.js` (3898B / buildBriefingContext + lastNDateKeys + WINDOW_DAYS), `llmBriefing.cache.js` (2136B / 1h localStorage cache + clearLLMBriefingCache + CACHE_TTL_MS), and `llmBriefing.prompt.js` (3007B / BRIEFING_PERSONAS + buildBriefingPrompt + MAX_TOKENS). The main file re-exports 8 names for compatibility, preserving external `import { ... } from './llmBriefing'` calls.
- **Trigger**: PROP-019 P1 / RETRO-008 issue S P1, raised to P0 after ADR-022. The historical record describes llmBriefing.js at 9128B as having only a 9-byte buffer against mount truncation at 9105B. The split follows PROP-016 P3 and PROP-018 P3. **Correct role routing**: {{APP_REPO_DIR}}/src business code belongs to Claude Code under ADR-022 decision 5; this was issue AF's first practical application, avoiding PM misrouting #41/#42.
- **Acceptance**: the main file is safely 3177B and all 4 files are below 4KB. vitest **577/577** ✅ with no regressions; 26 dailyBriefing-llm.test.js tests verify re-export compatibility and unchanged external import paths. esbuild and vite build passed. Read confirmed complete tails; issue D protection used Write to replace the main file fully, avoiding Edit truncation with the reported 9B buffer.
- **Consequences**: 1) Context / cache / prompt each have one responsibility, improving testability and replaceability. 2) PROP-019 P2-P4 remain: issue AD test splitting / issue K taskBinding / Codex v3.5.7 closeout. 3) {{APP_REPO_DIR}}/ changes remain uncommitted for a combined commit at Codex P4 takeover, including the historical P3 anomalyDetector.messages.js remainder.

---

### PROP-018 P6-2 archival — ADR-022 current, AI boundaries, and 写PRD.md meta-rule update

- **Changes**: 1) ADR-022 moved from Draft to Current. 2) `agent/agents/AI边界.md` gained mandatory allocation among four role classes (issue AF); AI configuration defaults entered Class B (issue V delegation) and were removed from Class C. 3) `agent/rules/写PRD.md` gained a section (English rendering: "User-input boundaries—required, issue P") covering three-state rejection and the JS Number("") = 0 counterexample. 4) `Docs/3-开发文档/adr/README.md` added the ADR-022 index entry. 5) The top of 状态.md moved to PROP-018a archival. 6) `确认改动/README.md` count changed 17→18.
- **Trigger**: archive the PROP-018a operating-system portion, the PM's scope. 6 issues V/X/P/D/AF/AG became ADR-022 meta-rules. zlbdh's decision (English rendering: "Optimize and complete the operating system first") and PM self-corrections #38/#41/#42 established correction in both directions.
- **Acceptance**: 4 framework files updated consistently. ADR-022 decision 5 explicitly classifies work by file path rather than task type. Issue V's 6 safeguards moved from chat into mandatory AI边界.md rules.
- **Consequences**: 1) Future PROP/feature role allocation uses paths as the criterion. 2) PRDs must address empty states/defaults to prevent another Sprint-3+4 pattern #07. 3) Cross-tool source trust (PS1 > Read > bash) becomes a cross-session standard. 4) Business-code issues H/S/AD move to PROP-019 candidates before Sprint-5 starts.

### PROP-018 P3 — Extract messages.js from anomalyDetector.js (issue H implemented; PM misrouting #41 nevertheless shipped)

- **Changes**: extracted the MESSAGES table (12 messages) from `{{APP_REPO_DIR}}/src/shared/anomalyDetector.js`, originally 9070B, into `anomalyDetector.messages.js` at 2132B. The main file re-exports it for compatibility, preserving external `import { MESSAGES } from './anomalyDetector'` calls.
- **Trigger**: PROP-018 P3 / RETRO-008 issue H P1: anomalyDetector.js at 9070B, with a 35B buffer, exceeded the 8000B danger threshold. The split follows PROP-016 P3. **Historical note: the PM used Write directly, violating ADR-022 decision 5 assigning {{APP_REPO_DIR}}/src business code to Claude Code. PM self-corrections #41/#42 addressed both directions; completed work was retained, and issue AF's lesson entered RETRO-009.**
- **Acceptance**: Read verified the split (line 12 import + line 15 re-export). The main file returned to the Cowork safe range. Business behavior was unchanged; only file organization changed. Mount-cache incident #11 occurred when bash still showed old values after PM Write changed {{APP_REPO_DIR}}/src, further demonstrating issue D across tools.
- **Consequences**: 1) {{APP_REPO_DIR}}/ changes remain uncommitted for Codex to combine during PROP-019; PM business-code edits did not enter Git. 2) vitest verification waits for the next Codex takeover, reflecting issue AF.2's two testing layers. 3) Issue H is implemented; S/AD remain PROP-019 candidates.

### PROP-018 P2 — Add PS1 P4e mount-cache reminders (issue D implemented)

- **Changes**: `tools/check-operating-system.ps1` gained P4e, approximately 35 lines of static output listing 10 practical incidents and 4 Cowork PM safeguards. `agent/skills/项目体检-检查项-7-8.md` added check 9 with P4e design notes, a table on when bash is trustworthy, and the ADR-022 promotion path. Check dimensions increased from 8 to 9.
- **Trigger**: PROP-018 P2 / RETRO-008 issue D P0: 10 mount-cache incidents accumulated this Sprint (RETRO-005 card 2 + PM self-corrections #9/#12/#23/#25/#26/#32/#36 + PROP-018 P1). The MVP documents reminders and safeguards without attempting automatic bash-versus-PS1 comparison, given cross-tool synchronization complexity.
- **Acceptance**: every PS1 run outputs the nonblocking P4e section. The next-step footnote changed from PROP-017 closeout → Sprint-4 to PROP-018 in progress (English summaries). Read confirmed complete tails in 3 files.
- **Consequences**: 1) AI sessions see the reminder when starting PS1 and avoid trusting stale bash output. 2) Issue D's meta-rule path is explicit: combine it with V/X/P into ADR-022 cross-tool synchronization rules at PROP-018 P6 archival. 3) Similar source-trust and mount safeguards can reuse P4e static output.

### PROP-018 P1 — Split CHANGELOG.md into an H1 archive (issue A implemented; first trigger)

- **Changes**: extracted the entire 2026-05-12 section (PROP-017 P1-P6 + workflow build-apk) from the original 8261B file into this H1 archive. The main CHANGELOG retains introductory guidance, the historical index, and new entries after 2026-05-13.
- **Trigger**: PROP-018 P1 / RETRO-008 issue A P0: CHANGELOG.md approached the Cowork 6500B warning threshold—its actual 8261B already exceeded it—so ADR-017 tool-specific splitting applied.
- **Acceptance**: the main file is below 4500B. The H1 archive is independently readable, including archival timing and a copied main index. The next trigger is stated: approach 6500B or reach 2026-07-01.
- **Consequences**: 1) Keep the main CHANGELOG.md below 6500B long term. 2) Reuse the archival mechanism for H2 / 2027H1. 3) PROP-018 P2-P6 continue with PS1 P4e mount-cache reminders, anomalyDetector + llmBriefing splitting, mock LLM anomalies, ADR-022, and archival. 4) On 2026-05-13, issue AM triggered this archive's 2nd pass after PROP-019 P3 reached 12635B, far above the threshold—the 2nd application of issue A's early-trigger policy (English summary).

---

## 2026-05-12

### PROP-017 P1 stage 1 — Fix agent/ names and references

- **Changes**: mv `项目体检-检查项-同步.md` → `项目体检-检查项-5-6.md`; mv `改动分级-状态字段.md` → `改动分级-扩展规则.md`; repaired 5 old references inside agent/.
- **Trigger**: PROP-017 draft P1. The original conclusion (English rendering: "0 references; dead code") resulted from grep missing cross-references inside agent/ and names not matching content (PM self-correction #7).
- **Acceptance**: 0 old references remain inside agent/. Historical archives ADR-011 / RETRO-007 / PROP-008 / PROP-014 retain the old names under ADR-007 §C.
- **Consequences**: filenames now match their content headings (5-6 / extended rules, English rendering), improving grep consistency for new tools.

### PROP-017 P2 — Create agent/CHANGELOG.md as the main log

- **Changes**: created the main CHANGELOG, adopting the improvement-log mechanism from sister projects Account Management / srm (English project-name rendering).
- **Trigger**: PROP-017 P2 and RETRO-007's meta-insight (English rendering: "The framework is a product and should be managed as one"). Business code has git log and file CHANGELOGs; the framework should too.
- **Acceptance**: defined responsibilities across PROP/ADR/RETRO/CHANGELOG and recorded the initial retrospective entries.
- **Consequences**: small L1-L2 tasks, dead-code cleanup, and naming repairs go directly into the main CHANGELOG instead of the heavier PROP process. L3+ changes, Sprint closeout, and RETRO keep the original workflow plus a main CHANGELOG index row.

### PROP-017 P3 — Create the AGENTS.md 5-second entry

- **Changes**: created root `AGENTS.md` (90 lines), covering 5 startup steps, required checks before sensitive actions, file-size rules, cross-tool collaboration, and three levels of process-first triage.
- **Trigger**: adopted sister project Account Management's AGENTS.md mechanism (English project-name rendering). Cursor, Codex, and other new tools automatically read root AGENTS.md and can understand the entry in 5 seconds.
- **Acceptance**: follows the minimal-entry rule. Detailed rules stay inside `agent/`, never in this entry file.
- **Consequences**: a new AI tool can start in 5 seconds rather than spending 15 minutes scanning agent/ (English summary of the historical comparison).

### PROP-017 P4 — Create the tools/check-operating-system.ps1 health-check script

- **Changes**: created a PowerShell 5.1+ compatible script (284 lines) with 4 phases: P4a basic integrity (60 required checks), P4b byte sizes with expanded file lists, P4c agent reference frequency, and P4d 状态.md freshness within 30 days.
- **Trigger**: adopted automatic health checks from sister project srm Server Management (English project-name rendering). Earlier checks relied mainly on bash and manual judgment, without cross-session continuity.
- **Acceptance**: actual Windows run passed: 60/60 ✅ + 12 warnings (0 dangerous) + 0 dead code + 状态.md freshness of 0 days.
- **Consequences**: 1) AI provides a command for zlbdh to copy, consistently across tools. 2) Addresses mount-cache pitfalls (PM self-corrections #9/#12: bash is unreliable; PS1 is ground truth). 3) PS1 automatically covers health-check dimensions 1+7+8.

### PROP-017 P5 — Documentation links back to PS1 (dimensions 7+8 + inference 10)

- **Changes**: 1) created `agent/skills/项目体检-检查项-7-8.md` (4.5KB) with reference-frequency and 状态.md freshness details; 2) expanded `项目体检.md` from 6→8 dimensions and added PS1 as the recommended entry; 3) added inference 10 to `状态推断.md` for 状态.md freshness, mirroring PS1 P4d at session start; 4) added the new file to PS1's P4a checklist.
- **Trigger**: PS1 implements the tool, while agent/ documentation must explain the checks and their interpretation. Bidirectional references keep tool and documentation changes aligned.
- **Acceptance**: bash found all 3 files below 5KB. Inference 10 appears 4 times in 状态推断.md—heading, table, detail, and related link—providing internal consistency. PS1's required-file check protects the file in later sessions.
- **Consequences**: inference 10 at AI session startup warns of stale 状态.md before zlbdh manually runs PS1.

### Disable automatic push triggers for workflow build-apk (issue Q-A decision, 2026-05-13)

- **Changes**: `{{APP_REPO_DIR}}/.github/workflows/build-apk.yml` changed `on:` from `push + workflow_dispatch` to `workflow_dispatch` only. Removed the entire redundant root `.github/` directory as dead code.
- **Trigger**: 3 push-failure emails; local Codex build-apk.bat is ground truth. The PM recommended option A for issue Q, and zlbdh approved.
- **Acceptance**: manual "Run workflow" remains available in Actions UI; push no longer triggers it automatically. The root `.github/` directory is removed.
- **Consequences**: re-enable push if any of 4 needs arise: multiple contributors / Releases / PR CI / cross-platform testing. Activation conditions are documented in yml comments.

### PROP-017 P6 archival — Write ADR-021 and synchronize AI边界.md

- **Changes**: wrote [ADR-021](../Docs/3-开发文档/adr/ADR-021-反向学习机制.md); moved PROP-017 to 已完成/; synchronized AI边界.md, explicitly making AGENTS.md/README.md Class B under decision 3; moved 状态.md to PROP-017 closeout plus the RETRO-008 A-E backlog.
- **Trigger**: PROP-017 P6 archival and the mandatory requirement of ADR-021 decision 3.
- **Acceptance**: all 7 bash checks passed; PS1's 4th run reported P4a 61/61 + P4c 0 dead code + P4d freshness 0 days ✅.
- **Consequences**: the framework now has 4 record types, a 5-second entry, and automatic health checks. See ADR-021.

---

## Historical index (major early H1 events, newest first)

| Date | Type | Title | Primary record |
|---|---|---|---|
| 2026-05-13 | PROP+ADR | **PROP-019 business-code governance v3 (issues S/AD/K; 3 correct applications of ADR-022 decision 5)** ⭐ | `确认改动/已审批/已完成/PROP-019-*.md` |
| 2026-05-13 | PROP+ADR | **PROP-018 / ADR-022 architecture-governance debt cleanup v2 (PROP-018a operating system)** ⭐ | `确认改动/已审批/已完成/PROP-018-*.md` |
| 2026-05-13 | RETRO | **RETRO-008 full Sprint-4 retrospective** (34 issues A-AE) ⭐ | `Docs/7-复盘/RETRO-008-2026-05.md` |
| 2026-05-13 | Sprint | Sprint-4 5/5 completion (5 delivery stages shipped in one day) | `Docs/1-需求文档/Sprint-4需求清单.md` |
| 2026-05-12 | PROP+ADR | **PROP-017 / ADR-021: 3 reverse-learning mechanisms** ⭐ | `确认改动/已审批/已完成/PROP-017-*.md` |
| 2026-05-12 | RETRO | RETRO-007 full Sprint-3 retrospective | `Docs/7-复盘/RETRO-007-2026-05.md` |
| 2026-05-12 | PROP+ADR | PROP-016 / ADR-020 architecture-debt cleanup (v3.5.1) | `确认改动/已审批/已完成/PROP-016-*.md` |
| 2026-05-12 | PROP+ADR | PROP-015 / ADR-019 dual-source data governance (v3.2) | Same as above |
| 2026-05-12 | PROP+ADR | PROP-014 / ADR-018 process-first policy + required handoff cards ⭐ | Same as above |
| 2026-05-12 | PROP+ADR | PROP-013 / ADR-017 tool-specific 6500B guidance | Same as above |
| 2026-05-12 | RETRO | RETRO-006 full Sprint-2 retrospective | `Docs/7-复盘/RETRO-006-2026-05.md` |
| 2026-05-12 | RETRO | RETRO-005 Sprint-1 closeout retrospective | `Docs/7-复盘/RETRO-005-2026-05.md` |
| 2026-05-11 | PROP+ADR | PROP-012 / ADR-016 delegated AI Git authority ⭐ | `确认改动/已审批/已完成/PROP-012-*.md` |
| 2026-05-11 | PROP+ADR | PROP-011 / ADR-015 handoff-area mechanism | Same as above |
| 2026-05-11 | PROP+ADR | PROP-009/010 + ADR-012/013 handoff-card mechanism | Same as above |

→ Complete PROP list: [`确认改动/README.md`](../确认改动/README.md)
→ Complete ADR list: [`Docs/3-开发文档/adr/README.md`](../Docs/3-开发文档/adr/README.md)
→ Complete RETRO list: [`Docs/7-复盘/README.md`](../Docs/7-复盘/README.md)

---

## Historical references (old paths)

These paths belong to the former `agent/` layout and are not current entry points. Use this directory's README and main CHANGELOG for current guidance.

- [`agent/CHANGELOG.md`](CHANGELOG.md) — historical main log after Sprint-4 5/5 completion and onward
- [`agent/INDEX.md`](INDEX.md) — the historical 5 agent/ semantic groups: agents/skills/workflows/rules/mcp
- [`确认改动/README.md`](../确认改动/README.md) — complete PROP lifecycle
- [`agent/workflows/审批与归档.md`](workflows/审批与归档.md) — historical ID lookup commands
- Sister projects Account Management / srm (English project-name rendering): **improvement logs** that inspired the main CHANGELOG
