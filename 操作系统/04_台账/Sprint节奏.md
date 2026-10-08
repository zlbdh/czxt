---
name: sprint-rhythm
scope: project
type: episodic
loaded: on-demand
description: Sprint rhythm from RETRO and git log — historical Sprint-1~7 details; full Sprint-8~12 records in 状态.md / RETRO.
---

# Sprint Rhythm (periodic snapshot / details through 2026-05-21; current **{{CURRENT_SPRINT}}**; full Sprint-8~12 records:  [状态.md](../../状态.md))

> Sources: Docs/7-复盘/RETRO-*.md + git log. Read the corresponding RETRO for a detailed retrospective.

---

## Sprint-7(v3.8.0 → v3.8.2)✅ 3/3 complete

- **Dates**: 2026-05-20 → 2026-05-21(1.5 days)
- **Theme**: Engineering-debt cleanup, habit-preference completion, and framework governance upgrades
- **Work items**: 
  - Item 1: PROP-025 database/ split(v3.8.0)— issue BW permanently closed
  - Item 2: W-3 habit preferences integrated with the LLM(v3.8.1)— issue BU verified on device
  - Item 3: W-4 small-item bundle BV+BX+BZ(v3.8.2)— three issues verified on device
- **vitest**: 894 → 920(+26)
- **Issues completed**: 5(BU/BV/BW/BX/BZ)/ backlog 30+ → 27
- **PM self-corrections**: #54-#58(5 cumulative instances)
- **Retrospective**: [RETRO-012](../../Docs/7-复盘/RETRO-012-2026-05.md) + [RETRO-011](../../Docs/7-复盘/RETRO-011-2026-05.md)(mid-Sprint focused review)

## Sprint-6(v3.6.4 → v3.7.0)✅ 3/3 complete

- **Dates**: 2026-05-19 → 2026-05-20(1.5 days)
- **Theme**: Close gaps directly related to v3.0 pain points: habit personalization, exercise instruction, and early-morning protection
- **Work items**: 
  - Item 1: F-HABIT-1(v3.6.4)— drink, smoking/alcohol, and spicy-food preference fields; safeguards against AI boilerplate
  - Item 2: F-TRAIN-2(v3.6.5)— exercise instruction and follow-along video
  - Item 3: F-NIGHT-1(v3.7.0 / v1→v2→v3)— early-morning protection (PM self-corrections #51+#52+#53)
- **vitest**: 821 → 894(+73)
- **Issue escalation**: BW nearing the limit (database.js only 442B below 16KB)
- **Retrospective**: [RETRO-010](../../Docs/7-复盘/RETRO-010-2026-05.md)

## Sprint-5(v3.5.8 → v3.6.3)✅ 5/5 complete + PROP-024 architecture-debt governance

- **Dates**: 2026-05-14 → 2026-05-19(5 days)
- **Theme**: Activate Mimi's proactive mode; two framework-asset upgrades
- **Work items**: 
  - F-SYSCHECK-1(v3.5.8)— system-status awareness + Capacitor Network + navigator matrix
  - F-ALARM-1(v3.5.9)— basic alarms + Capacitor LocalNotifications
  - F-REMIND-1(v3.6.0)— task-reminder notifications; issue AJ closure milestone
  - F-DEVIATION-3(v3.6.1)— deviation adjustment suggestions
  - F-WEEKLY-1(v3.6.2)— weekly-report foundation (Sprint-5 final work item)
  - PROP-024(v3.6.3)— architecture-debt governance v4 (issues AY/BO/BG/BH/BQ archived)
- **vitest**: 577 → 821(+244)
- **Permanently effective ADRs**: ADR-022/023/024/025(issues AY/AJ/P/BK)
- **Permanent meta-rules**: 8 → 9(+ issue BK)
- **Retrospective**: [RETRO-009](../../Docs/7-复盘/RETRO-009-2026-05.md)(includes a 14-issue review)

## Sprint-4(v3.5.1 → v3.5.7)✅ 5/5 complete

- **Theme**: v3.0 proactive-mode launch: today tolerance, midnight rollover, morning briefings, and LLM integration
- **Work items**: F-DAY-2 + F-DAY-3 + F-PREP-1 + F-BRIEFING-1 + F-DEVIATION-2
- **Retrospective**: [RETRO-008](../../Docs/7-复盘/RETRO-008-2026-05.md)

## Sprint-3(v3.3 → v3.5)✅ 5/5 complete

- **Theme**: v3.0 launch: timeline, task details, posture correction, body clock, and proactive Mimi suggestions
- **Work items**: F-PLAN-1 + F-DAY-1 + F-POSE-1 + F-SLEEP-1 + F-CHAT-4
- **Retrospective**: [RETRO-007](../../Docs/7-复盘/RETRO-007-2026-05.md)

## Sprint-2(v3.0 → v3.1)✅ complete

- **Theme**: v3.0 launch: user profiles, chat, and deviation detection
- **Work items**: F-PROFILE-1/2 + F-CHAT-2/3 + F-DEVIATION-1
- **Retrospective**: [RETRO-006](../../Docs/7-复盘/RETRO-006-2026-05.md) + [RETRO-005](../../Docs/7-复盘/RETRO-005-2026-05.md)

## Sprint-1(v2.6 → v2.9)✅ 10/10 complete

- **Theme**: basic calendars, layout, and UI feedback
- **Work items**: F-001/002/003/006 + F-LAYOUT-1/2 among ten work items
- **Retrospective**: [RETRO-001](../../Docs/7-复盘/RETRO-001-2026-05.md) → [RETRO-004](../../Docs/7-复盘/RETRO-004-2026-05.md)

---

## Milestones across Sprints

| Milestone | Sprint | Date |
|---|---|---|
| Project initialization (v2.0)| — | Early 2026-05 |
| Sprint-1 10/10 complete | Sprint-1 | 2026-05-11 |
| v3.0 PRD launch | Sprint-2 | 2026-05-12 |
| **Issue AJ permanently closed**(ADR-023)| Sprint-5 | 2026-05-15 |
| **Issue P made permanent**(ADR-024)| Sprint-5 | 2026-05-19 |
| **Issue BK made permanent**(ADR-025)| Sprint-5 | 2026-05-19 |
| **Permanent pool of nine meta-rules established** | Sprint-5 | 2026-05-19 |
| **Issue BW permanently closed**(database split)| Sprint-7 | 2026-05-20 |
| **Issue BU verified on device**(habit-preference integration)| Sprint-7 | 2026-05-21 |
| **Issues BV/BX/BZ verified on device** | Sprint-7 | 2026-05-21 |
| **Issue BK: ten real-work instances, zero anomalies**(meets ADR-025 downgrade criteria)| Sprint-7 | 2026-05-21 |
| **First framework-governance self-check: PROP-026** | Sprint-7 | 2026-05-20 |
| **PROP-028 ledger and tool governance implemented** | Sprint-7 | 2026-05-21(this ledger is the resulting artifact) |

---

## Sprint-8 Preview (historical snapshot / archived; project has reached {{CURRENT_SPRINT}})

- **Item 1**: W-1 meal module (v3.0 PRD pain point / highest user impact)
- **Candidates**: issue CA Chat.jsx split / issue BI Operations Mimi v0.1 / public-release prerequisites P0
- **Maintenance mode**: lock one work item by default; do not preset the rest

→ Sprint route decided in RETRO-012, “Sprint-8 Route Lock.”
