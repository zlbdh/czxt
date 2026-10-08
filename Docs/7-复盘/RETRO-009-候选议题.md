# RETRO-009 Candidate Backlog: Notes During Sprint 5

> **This is not the formal RETRO-009.** It collects candidate topics and consecutive trial records during Sprint 5. At sprint closure, develop it into the formal retrospective using `_模板.md`.
>
> **Historical links:** agent/... links below describe the May 2026 layout. Current authoritative sources moved to `操作系统/` and `能力资产/`. Do not use these historical links as current execution entry points.
>
> **Drafted**: 2026-05-14, after PROP-020 path D and F-SYSCHECK-1 shipped.
> **Expected closure**: Sprint 5 completes 5/5.
> **Drafting role**: Operating System PM "Framework Steward", AJ trial 4, with decision-checkpoint Q1/Q2/Q3 passed.

## Backlog by priority and reverse chronology

### P0: required or blocking

#### G: split useAppData.js, promoted to P0 and closed through PROP-021

Evidence:

- F-SYSCHECK-1 trial 1 increased useAppData.js from 9593 to 10,449 B, +856 B, described as 215% of the handoff's ≤400 B target.
- Claude Code saved 190 B by merging online/offline handling into F-DAY-2's useEffect, reducing growth from 1046 to 856 B.
- The remaining 856 B represented the feature's irreducible cost.

The file handled today calculation, task/inventory actions, system-state detection, hydration, completedDates, profile patches, and more. It could not sustainably absorb the four remaining Sprint-5 stages: F-ALARM-1, F-REMIND-1, F-DEVIATION-3, and F-WEEKLY-1.

Proposed PROP-021 split:

- useTodayTick.js: today, midnight rollover, and F-DAY-2/3 tolerance.
- useTaskActions.js: setTask, undo, and issue K taskBinding.
- useSystemState.js: F-SYSCHECK-1 systemSense and online/offline listeners.
- useInventoryActions.js: F-PREP-1 inventory CRUD and issue K linkage.
- useAppData.js: composition and top-level data state only.

Priority P0, preferably before Sprint-5 task 2, F-ALARM-1. Estimate: L3, two to three hours in Claude Code plus half an hour for Codex closure.

**Completed:** PROP-021, v3.5.8 device smoke, and push reduced useAppData.js from 10,449 to 6202 B, extracting useTodayTick, useSystemState, useTaskActions, and useRecordActions. The final split differed from the initial candidate list and is recorded explicitly.

### P1: strongly recommended

#### AM: third successful CHANGELOG archive trial

At 14:05 on 2026-05-14, issue A's early-trigger rule archived three PROP-019 entries into H1, reducing CHANGELOG.md from 8004 B to below 4 KB. The mechanism had three practical examples. Candidate follow-up: ADR-022 decision 6 on archive thresholds/process, or an AM section associated with ADR-023. Recommend formalizing it during RETRO-009.

#### AN: distinguish framework-housekeeping subtypes

PROP-020 P0 blocker 1 showed Cowork's sandbox denied Write to .claude/agents/ even though the PM path allowlist permitted it. ADR-022 decision 5's broad "framework housekeeping belongs to PM" category did not distinguish Markdown drafting from physical changes in tool-private directories. Add subtype a, pure Markdown directly authored by PM, and subtype b, PM drafts while Claude Code applies files in tool-private directories. Priority P1 for clearer future routing.

#### AO: .claude ownership and ignore rules, implemented

PROP-020's P0 experiment left .claude/agents/_pingtest.md, 1411 B. PM added .claude/ and .cursor/ to `{{APP_REPO_DIR}}/.gitignore`, included in Codex's commit. Candidate ADR-022 decision 7 would define version-control treatment of private AI-tool directories, relevant to future Cursor/Copilot additions. Priority P1.

#### AP: single-tool enforcement versus cross-tool consistency

PROP-020 switched from path C to D because hard runtime blocking in one tool and consistent Markdown governance across tools could not both be achieved. AJ-like decisions need an explicit comparison. During RETRO-009, write a decision table in agent/rules/ or candidate ADR-024 on cross-tool collaboration architecture. Priority P1, reusable for L4/L5 decisions.

#### AR: extend decision-checkpoint to Q4 rule validation

PM's F-SYSCHECK-1 handoff instructed adding a business-change entry to agent/CHANGELOG.md, violating its header rule that business changes belong in `{{APP_REPO_DIR}}/` Git history. Claude Code caught it through PROP-014's three-level triage. Q1/Q2/Q3 checked paths but not a rule-inconsistent instruction.

Add Q4: "Does my instruction comply with current framework meta-rules?" Extend pre-action rule searching to relevant files before writing a handoff or proposal, analogous to checking AI boundaries before Class C-sensitive actions; alternatively add a prerelease-rule-check subworkflow. Priority P1, a PROP-020 path-D v1 candidate. PM correction 43 exposed a rule-memory error caught by development rather than PM self-checking.

### P2: consider

#### AQ: estimate Vite build modules more accurately

PM predicted +1–3 modules for F-SYSCHECK-1; actual growth was +7, described as a +4 / +57% deviation. The one-file/one-module intuition ignored import-chain expansion. Build an empirical baseline for one .jsx, one .js, and one .test.js addition. Priority P2: estimation quality, without business impact.

### Completed records

- AM: third CHANGELOG archive trial completed 2026-05-14.
- AO: .claude added to ignore rules on 2026-05-14.
- G: hook split and structural F-SYSCHECK-1 race repair completed in v3.5.8 on 2026-05-15.

## Consecutive correct ADR-022 decision 5 trials

| Number | Time | Work and ownership | Boundary passed? |
|---|---|---|---|
| 1 | 2026-05-13, PROP-019 P1 | Split llmBriefing into three modules, issue S; Claude Code alone in application src | Yes |
| 2 | 2026-05-13, PROP-019 P2 | Split four tests into 11 and add LLM-error mock utilities, AD; Claude Code owns tests | Yes |
| 3 | 2026-05-13, PROP-019 P3 | taskBinding check-in linkage, K, repaying Sprint-4 PRD item ②; Claude Code owns src/tests/UI | Yes |
| 4 | 2026-05-14, F-SYSCHECK-1 | System-state awareness, first Sprint-5 task; Claude Code owns src/tests/UI | Yes |
| 5 | 2026-05-14, PROP-021 | useAppData split and structural systemState race repair; Claude Code owns src | Yes |
| 6 | 2026-05-15, PROP-022 | Capacitor Network source repair and AT documentation tests; Claude Code owns src/npm dependencies | Yes |

Six consecutive correct trials, with no recurrence of the pattern in PM corrections 41/42.

## AJ trial accumulation

| Number | Time | Work | Q1/Q2/Q3 | Path violations |
|---|---|---|---|---|
| 1 | 2026-05-14 13:35–14:10 | F-SYSCHECK-1 PRD review, handoff, Codex shipping card, and issue A's third archive | All four role transitions passed | Zero |
| 2 | Pending Sprint-5 task 2, such as F-ALARM-1/F-DEVIATION-3 | Evidence pending | — | — |
| 3 | Pending Sprint-5 task 3 | Evidence pending | — | — |

Closure condition: 3/3 trials without recurrence of corrections 38/41/42, then close AJ and write ADR-023.

## PM correction recorded that day

Correction 43, 2026-05-14 13:45: the F-SYSCHECK-1 handoff requested a forbidden business entry in agent/CHANGELOG.md. This was rule-memory drift, not a path violation. Claude Code's PROP-014 nonblocking triage caught it. Track AR as RETRO-009's Q4 candidate.

## Mount-cache issue D trial history

The original notes carried forward trials 1–11 from RETRO-008, then added:

- 12, PROP-019 P3 / Claude Code: incorrect INVENTORY_DEFAULTS import before Vite build; Read verification prompted immediate repair.
- 13, PROP-020 P0 / Cowork: Bash showed anomalyDetector.js's stale 9070 B value instead of Read truth.
- 14, PROP-020 P0 / Cowork: Bash reported .claude/agents/_pingtest.md missing although Claude Code had written it.
- 15, PROP-020 P2-prime / Cowork: Bash showed AI边界.md's stale 7462 B value; Read confirmed the upgrade.
- 16, PROP-020 / third issue-A archive / Cowork: Bash showed stale CHANGELOG.md at 8261 B; Read confirmed cleanup.

Sixteen trials were recorded in total; PowerShell P4e reminders remained useful.

## Suggested formal-RETRO drafting sequence

1. Work completed: five Sprint-5 F-XXX features plus PROP-020 path D.
2. What worked: AJ defenses, decision-checkpoint, the then-recorded four consecutive ADR-022 decision 5 trials, and three issue-A archives. The detailed table later reached six.
3. Problems: G's P0 escalation, AR's Q4 extension, AQ's estimation error, and PM correction 43.
4. Framework changes: explicit actions for ADR-023 AJ closure, PROP-021's split, and candidate ADR-024's cross-tool decision framework.

## References

- [RETRO template](_模板.md): four core sections.
- [RETRO index](README.md): cadence, naming, and writing guidance.
- [RETRO-008](RETRO-008-2026-05.md): previous Sprint-4 review.
- [Historical CHANGELOG](../../agent/CHANGELOG.md) and [H1 archive](../../agent/CHANGELOG-2026H1.md): framework evolution.
- [PROP-020 main proposal](../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md): AJ implementation.
- [PROP-020 path D v0](../../确认改动/已审批/进行中/PROP-020-路径D-方案v0.md): design basis.
- [Historical AI boundaries](../../agent/agents/AI边界.md): five PM subroles.
- [Historical decision-checkpoint](../../agent/workflows/decision-checkpoint.md): AJ's direction-error defense.
- [Historical Project PM definition](../../agent/agents/项目PM-咪咪.md), one of five PROP-020 P1-prime role documents.
