---
name: 项目pm-咪咪-readme
scope: pm-workspace
pm: 项目PM-咪咪
type: semantic
loaded: on-demand
description: "Project PM \"Mimi\" workspace entry point: quick references, self-corrections, and practice reviews; lead PM and sole external identity under ADR-031."
---

# Project PM "Mimi": Meta-Memory Center

> ⭐ PROP-023 v1, 2026-05-15 / issue BE: the PM's own meta-memory center addresses framework complexity exceeding what one conversation can manage.
> ⭐ PROP-023 v2 path update, 2026-05-21 / issue CM: moved `项目PM/` to `PM工作区/项目PM-咪咪/`, alongside the other private PM workspaces; see the [workspace index](../README.md).
> **Mandatory rule**: before switching PM roles, writing a handoff, or drafting a PROP, **search this directory first**.

## Thirty-second startup before Project PM work, handoffs, PROPs, or chat summaries

1. New sessions still begin with the [operating system entry point](../../操作系统/00_总入口.md). This file is not the first entry point for every session.
2. For Project PM orchestration, handoffs, PROPs, or short chat handoffs, first search `速查表/` for relevant meta-rules to prevent repeated self-corrections.
3. Read `状态.md` for progress and pending handoffs. The PM transition table at its end is the single tracking source.
4. Run the defensive checks in `速查表/` before writing a handoff, PROP, or short chat handoff.

## Directory reference

| Subdirectory | Contents | When to read |
|---|---|---|
| ⭐ [Quick references](速查表/) | Meta-rule pitfalls and defensive checklists | Required before handoffs, PROPs, or chat summaries |
| [Practice reviews](实战回顾/) | Full sprint-feature timelines and accumulated self-corrections | Check matching patterns before starting a similar feature |
| [PM self-corrections](PM自纠/) | Self-corrections by type and date | Recognize repeated patterns across sprints |

## Quick-reference checklist: review before switching roles

| File | Protection | Source |
|---|---|---|
| [ADR-022 decision 5: four role boundaries](速查表/ADR-022决定5-4类角色铁律.md) | Distinguish framework, application code, test code, and release verification by path | Self-corrections #41/#42 |
| [Capacitor version verification](速查表/Capacitor版本核对.md) | Read package.json and confirm the major version before adding dependencies | #46 |
| [Plugin integration safeguards](速查表/plugin集成防御.md) | Static import, NotificationChannel, and cap sync | #47 |
| [Chat handoff deduplication](速查表/chat简版去重检查.md) | Check code blocks for duplicated output before sending | #48 |
| [Issue AT matrix reference](速查表/议题AT矩阵速查.md) | Consult `能力资产/rules/web-api-信源选型.md` before selecting a Web API | #45 |
| [PROP status semantics](速查表/PROP状态字段语义.md) | Code completion is not PROP completion; Codex must push | #44 |
| [CHANGELOG header rule](速查表/CHANGELOG-header规则.md) | Application code changes do not belong in `操作系统/00_变更记录/CHANGELOG.md` | #43 |

## Practice review inventory

| Case | Feature | Key issues | File |
|---|---|---|---|
| #1 | F-SYSCHECK-1, v3.5.8 | Issue AJ case #1, issue G P0, and issue AT made permanent | [F-SYSCHECK-1 review](实战回顾/实战-1-F-SYSCHECK-1.md) |
| #2 | F-ALARM-1, v3.5.9 ⏳ | Issue AJ case #2, plugin integration bug, time zones, and low battery | [F-ALARM-1 review](实战回顾/实战-2-F-ALARM-1.md) |

## Relationship to other framework files

| Role | File | Distinction |
|---|---|---|
| Role definition | Nine role documents such as `操作系统/02_智能体/项目PM-咪咪.md` | What the Project PM position does; PROP-020 path D |
| Meta-rule constraints | `能力资产/rules/*` + `操作系统/07_完整工作流/*` | How work should be done and in what order |
| This PM's work center | `PM工作区/项目PM-咪咪/` | What the PM actually records and the mistakes they have encountered |
| Project-wide startup memory | `操作系统/05_记忆/INDEX.md` | Current entry point for preferences, behavioral reflections, and project-history pointers |
| Project snapshot | `状态.md` | Current progress, pending handoffs, and history |

This directory is the PM's own working notebook. The other categories contain rules, identity, shared memory, and project status; this directory contains PM work products.

## Maintenance rules

- **Quick-reference length**: keep entry points short, preferably one screen. Above approximately 2KB, first assess whether the file remains easy to scan, then decide whether to split it.
- **Practice review names**: `实战#N-feature名.md`, using issue AJ's practice sequence number.
- **Pending decision / backlog names**: if this PM's private backlog is restored, use `议题XX-标题.md`, with letter-based IDs.
- Migrate gradually across sprints; avoid a single broad reorganization.

## Issue AR candidate dimension Q4.g

Candidate extension to PROP-020 path D's decision-checkpoint Q4:

- Q4.g: **search `PM工作区/项目PM-咪咪/速查表/` before any handoff, PROP, or chat summary**, supporting issue BE.

Implement alongside the issue AR decision-checkpoint upgrade when RETRO-009 closes.

## Related

- [ADR-029: PM workspace meta-memory centers](../../Docs/3-开发文档/adr/ADR-029-议题BE永久化-PM工作区元记忆中枢化.md).
- [ADR-023: PM role specialization](../../Docs/3-开发文档/adr/ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md).
- [Nine PM role documents](../../操作系统/02_智能体/).
- [Meta-rules](../../能力资产/rules/).
- [Decision checkpoint](../../操作系统/07_完整工作流/decision-checkpoint.md): proposed Q4 extension.
- [Project snapshot](../../状态.md).
