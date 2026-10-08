---
name: shared-skills-index
scope: project
type: procedural
loaded: on-demand
description: Conditional index of cross-PM SOPs, distinct from each PM's private quick references.
---

# Cross-PM Shared Skills

> PROP-032, May 21, 2026, task #85, improvement 4. Private quick references belong to one PM; shared skills provide reusable SOPs across roles.

## Five current shared skills

| Skill | Description | Trigger | PM roles |
|---|---|---|---|
| [git-recovery](git撤销恢复.md) | Emergency diagnosis for Git damage, index errors, or unexplained dirty state | Git damage or stale mounts | Project PM / Operating System PM / Technical PM |
| [mount-stale-defense](mount-stale防御.md) | Five-step Cowork stale-mount defense under ADR-025 | Inconsistent ls/cat/head or cross-tool work | Project PM / Technical PM |
| [real-device-smoke-checklist](真机smoke清单.md) | Required device checks; passing vitest does not prove device behavior, under ADR-030 and meta-rule 13 | Before Test and Release PM completion; Development PM references it only for handoff self-checks | Test and Release PM / Project PM |
| [verify-checklist-handoff](handoff卡-verify清单.md) | Seven checks for handoff/ship cards; issue CD candidate | Before writing a handoff or ship card | Product PM / Project PM / Operating System PM |
| [pm-self-correction-trigger](PM自纠-trigger.md) | Self-correction triggers and immediate durable records under PROP-030 | Any PM discovers an incorrect direction | All PMs |

## Private and shared references

| Dimension | Private quick references in `PM工作区/<X-PM>/速查表/` | Shared skills here |
|---|---|---|
| Scope | One PM's specific meta-rules | SOPs useful across PMs |
| Governance | Own PM's autonomy; self-correction #59 prohibits crossing boundaries | All PMs may read; Operating System PM maintains |
| Example | Project PM's short-chat duplication check | Git recovery and device-smoke checklist |
| Count limits | Seven to ten per PM | Five to fifteen globally |

## Progressive context loading

At decision-checkpoint Q4, match both Q4a private quick-reference triggers and Q4b shared-skill triggers. Load matched references; skip unmatched ones.

## Adding a shared skill

1. A pattern recurring across at least two PMs becomes a candidate.
2. Write Markdown with YAML frontmatter using PROP-031's format.
3. Add one index row.
4. Do not put it in a PM's private directory; respect the cross-boundary prohibition.

Issue CP's shared-skill mechanism remains a candidate after RETRO-013. See the [candidate meta-rule pool](../../01_架构/元规则池-候选.md) for current truth.
