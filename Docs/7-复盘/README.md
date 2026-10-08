---
name: retro-index
scope: project
type: semantic
loaded: on-demand
description: Sprint and framework retrospective document index.
---
# Retrospectives

These notes look back after a period of work. They are for zlbdh and Mimi to evaluate the framework itself, rather than product documentation for end users.

> **Historical safety override:** RETRO bodies record facts at the time; they are not current operating procedures. Early preapproval of git reset --hard HEAD, git push origin master, three-question decision-checkpoints, and short-chat sections ①–⑥ have been superseded. Destructive recovery follows the [three-class behavior rules](../../操作系统/01_架构/三类行为铁律.md) and [post-push defense rules](../../能力资产/rules/codex-push后防御.md). Use the single main branch, Q1–Q7 decision checks, and seven-part chat closure ①–⑦.

## Why hold retrospectives?

Any process can drift. Rules established six months ago may now obstruct efficiency, be ignored in practice, or have better alternatives. Regular review keeps the framework useful instead of turning it into ceremony.

## Two retrospective tracks

**Business-batch track:** review after every N completed L3+ changes; the current provisional N is 3. After three new features, excluding small bug fixes, pause to write a RETRO.

**Framework-trigger track:** also write a RETRO or a focused section in the latest one after implementing a framework PROP, permanently closing an issue, changing the nine-PM/agent scheduling model, changing the meta-rule pool, or significantly changing hooks or health guards.

These triggers follow actual work more closely than a monthly schedule, which could force artificial reviews in quiet months and miss busy periods.

## Naming

Use increasing identifiers such as `RETRO-001-2026-05.md` and `RETRO-002-2026-07.md`. The date assists identification; the sequence number increases.

## How to write

Use `_模板.md`. Four core sections are sufficient:

1. Work completed, compared with the PRD.
2. What worked and should continue.
3. Problems, inefficiencies, and unnecessary steps.
4. Whether the framework should change, with concrete actions.

Spend 15–30 minutes, not an entire afternoon.

## Turning observations into changes

1. If a process needs to change, write a PROPOSAL under `确认改动/待审批/`.
2. After zlbdh approves, follow L4 because it changes governing rules.
3. Update the actual rule under `操作系统/` or `能力资产/`, such as `操作系统/07_完整工作流/`, `操作系统/03_交接/`, or `能力资产/rules/`.
4. In the next RETRO, report whether the previous action was completed.

Do not change rules through a retrospective itself. A RETRO records observations; rule changes follow the approval workflow.

## RETRO index

| ID | Window | Trigger | Main points |
|---|---|---|---|
| [RETRO-001](RETRO-001-2026-05.md) | 2026-05-08 | Six framework additions, F-205, and L4 {{APP_REPO_DIR}} migration | First retrospective; initial framework stability |
| [RETRO-002](RETRO-002-2026-05.md) | 2026-05-09 | Three early Sprint-1 L3+ changes: F-205, ADR-004, PROP-003 | Business implementation begins |
| [RETRO-003](RETRO-003-2026-05.md) | 2026-05-09 | PROP-004/005/006, three L3+ framework upgrades | rules→agent refactor; reported automation 95% |
| [RETRO-004](RETRO-004-2026-05.md) | 2026-05-11 | PROP-007/008/009/010, four L3+ refinements | Historical mandatory 6500 B split, now layered by ADR-017; handoffs and self-correction |
| [RETRO-005](RETRO-005-2026-05.md) | 2026-05-12 | F-002/F-003/F-LAYOUT-12 and PROP-012: four L3+ plus one L4 | Sprint 1 10/10; first ADR-016 Git-authority trial; PROP-013 tool-specific size guidance in backlog |
| [RETRO-006](RETRO-006-2026-05.md) | 2026-05-12 | PROP-013/014, F-PROFILE-12, F-CHAT-23-DEVIATION: seven L3+ | Sprint 2 5/5; ADR-017/018 applied; PROP-014 mandatory short handoff first aligned Claude Code; RETRO-005 actions 6/6 |
| [RETRO-007](RETRO-007-2026-05.md) | 2026-05-12 | PROP-015 plus F-PLAN-1/F-DAY-1/F-POSE-1/F-SLEEP-1/F-CHAT-4: six L3+ | Sprint 3 5/5; four APKs v3.2–3.5; +188 tests; first quality-gate return; PM corrections 4→6 |
| [RETRO-008](RETRO-008-2026-05.md) | 2026-05-13 | Sprint 4 5/5, v3.5.1→v3.5.6 | Five stages shipped in one day; 34 reported issues; issue V's conditional Class B change |
| [RETRO-009](RETRO-009-2026-05.md) | 2026-05-19 | Sprint-5 closure and PROP-024, v3.5.8→v3.6.3 | Sprint 5 5/5; AJ/P permanent; 14-issue assessment |
| [RETRO-010](RETRO-010-2026-05.md) | 2026-05-20 | Sprint-6 closure, v3.6.4→v3.7.0 | Sprint 6 3/3; critical BW escalation; PM corrections 51–53 |
| [RETRO-011](RETRO-011-2026-05.md) | 2026-05-20 | Focused review after Sprint-7 task 1, PROP-025 | BW closure assessment and PM correction 54 |
| [RETRO-012](RETRO-012-2026-05.md) | 2026-05-21 | Sprint-7 closure, v3.8.0→v3.8.2 | Five BW/BU/BV/BX/BZ closure decisions and framework governance |
| [RETRO-013](RETRO-013-2026-05.md) | 2026-05-22–28 | First tasks of Sprints 8/9, v3.9.0/v3.10.0 | Two complete release trials of v4.0 roles; CC promoted to ADR-030 |
| [RETRO-014](RETRO-014-2026-05.md) | 2026-05-28 | Sprint-10 governance, tasks 117–122 | Six tasks in one day; four ADRs 029–032; meta-rules 12→15 |
| [RETRO-015](RETRO-015-2026-05.md) | 2026-05-29–30 | Mixed Sprint 11: verification repair and v3.10.1 | Verify repair, CA+CB shipped, first complete nine-PM workflow |
| [RETRO-016](RETRO-016-2026-06.md) | 2026-06-03–04 | Six closures in one Cowork session, v3.19–v3.22: all recurrence frequencies, two A→G skincare changes, v3.20 parse blocker, and residual tags | Six changes over two days; tests 1211→1286 green; correction 95 source-search pattern as meta-rule candidate; deterministic LLM-path testing candidate; four mount defenses for possible ADR-025 update |
| [RETRO-017](RETRO-017-2026-06.md) | 2026-06-04–06 | Nine closures, v3.23–v3.31: A→G/A→E/F safety paths, three debt-repayment trials, H cleared | Tests 1295→1392 green; profile area A 100% closed; first ultracode adversarial review caught Class C violations and disproved PM assumptions; three debt-pattern trials; limits of skipping exploration; review-driven scope expansion; P1 intelligent-core direct-small-change category cleared |
| [RETRO-018](RETRO-018-2026-06.md) | 2026-06-06–07 | v3.32/33/34: Home summary, skincare closure, and F sodium after four smoke rounds | Tests 1402→1454 green; define visible output-marker acceptance in the first LLM-behavior change; prompt verbs act as API; path-dependent token evidence, including thinking consuming 4000; output-contract shift; second healthy example of subordinate evidence challenging assumptions |
| [RETRO-019](RETRO-019-2026-06.md) | 2026-06-07–08 | v3.35/36/37/38: G-F5 posture, five-round G-F6 recurring appointments and G closure, HIIT wall clock, B multiday view | Tests 1454→1533 green; changing any gate requires full-path same-word verification; canonical machine-input regex with LLM fallback; deterministic solution to Node-pass/device-fail tails; alternate long LLM cycles with deterministic changes, three first-pass successes; repay size debt before gates |
| [RETRO-020](RETRO-020-2026-06.md) | 2026-06-08–09 | v3.39/40/41/42: packed-meal safety, travel supplies, weight curve, and M deviation records; two schema changes | Tests 1549→1623 green; migration pattern with no device data loss, four-location checklist, no upgrade callback, v140→v160; privacy review for truncation/local storage/deletion/nonjudgment; record before learning in M; actual Bacillus cereus risk in packed rice addressed |
| [RETRO-021](RETRO-021-2026-06.md) | 2026-06-14 | PROP-044 AC3/AC4 first controlled framework-parallelism pilot: 26 frontmatter files, three workers | B-lite zero overreach, exact 61−26 scope; health exit 0; disjoint dispatch fields effective; barrier waste, B 305 seconds versus A 79/C 55; candidates DU workload balance and DV boundary probes; ADR promotion deferred for one or two more trials |
| [RETRO-022](RETRO-022-2026-06.md) | 2026-06-14 | Large governance batch: 11 pointer files, P4h anchors, two B-lite pilots, two release/state-partition P0 fixes, and all nine PMs as agents | Hooks caught their author's false green immediately; P4h blocked drift; B-lite spread 5.5×→1.5×; npm.ps1 shim fixed with cmd /c; state size −68% with byte conservation; ADR-038 formalized agents, single-point Project PM scheduling/acceptance, no nesting, and single-source writes; DU/DV/DW retained as candidates |
| [RETRO-023](RETRO-023-2026-06.md) | 2026-06-22 | Three czxt dogfood changes: recursive-instantiation fix 2d216a8, README/health scope 6abddc8, path soft gate 96e82cf; first native czxt PROP lifecycle | Real dogfood found a severe recursion bug missed by five explorers; framework guards caught three author mistakes; author violated ADR-038 twice before proper worker dispatch for PROP-001; third DW timestamp recurrence suggested a proposal; audit remaining self-hosted-instance exclusions |
| [RETRO-024](RETRO-024-2026-07.md) | 2026-07-10 | PROP-003 template truth and significant hooks/P4s changes, then local/uncommitted | Smoke PASS still leaked temp 9→10; prefix-difference cleanup deleted concurrent sentinels, fixed through unique TempRoot/exact ownership; independent review restored overbroad role edits; P1 complete, P2 incomplete; no fetch/commit/push at that checkpoint |

The supplementary [RETRO-009 candidate file](RETRO-009-候选议题.md) is not a formal RETRO and does not count toward the numbered series.

**Index synchronization rule**, from RETRO-005 problem 4: update this table immediately after writing a new RETRO. State inference, P4i, and README-index checks jointly compare this index with actual RETRO files.
