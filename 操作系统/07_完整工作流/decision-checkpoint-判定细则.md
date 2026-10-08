---
name: decision-checkpoint-decision-details
scope: project
type: procedural
loaded: on-demand
description: Decision checkpoint Q4–Q7 details — triggers, scale, cross-PM coordination, and agent instantiation.
---

# Decision Checkpoint Details

> Primary entry point: [decision-checkpoint.md](decision-checkpoint.md). This file contains less frequent details to keep the main document concise.

## Q4: Quick-reference triggers

Q4 has two steps: first consult the PM's private quick reference, then the cross-PM triggers in the [shared skills index](../02_智能体/共享技能/INDEX.md).

| Current task | Matching quick reference |
|---|---|
| Write a handoff card | `pm-role-boundary-check` + `changelog-header-check` |
| Verify before writing a handoff/ship card | `handoff卡-verify清单.md` |
| Corrupt Git, abnormal `.git/index`, or unexplained dirty state | `git撤销恢复.md` |
| Suspected stale mount after switching Codex / Cowork / Claude | `mount-stale防御.md` |
| PM misrouting or a question from zlbdh triggers self-correction | `PM自纠-trigger.md` |
| Physical-device smoke or APK release completion | `真机smoke清单.md` |
| Draft a PROP | `pm-role-boundary-check` + `prop-status-semantics` |
| Write chat summary section ⑥ | `chat-summary-dedup` |
| Introduce a new `@capacitor/*` dependency | `capacitor-version-verify` + `capacitor-plugin-defense` |
| Select a `navigator` / `Intl` API | `web-api-source-selection` |
| Change a PROP status field | `prop-status-semantics` |

## Q5: Scale-adaptive classification

| Scale | Typical scenario | Required process |
|---|---|---|
| L1 | Copy, typo, isolated style, or documentation spelling fix | Act directly and record in status |
| L2 | Single-file feature or bug fix, completed by one PM | Lightweight PRD or abbreviated handoff; necessary tests |
| L3 | Feature across files/modules; one handoff spans 1–2 days | Full PRD, handoff/ship card, status, and RETRO review |
| L4 | Architecture refactor, schema, cross-PM coordination, meta-rule upgrade, or 2+ days | PROP, ADR assessment, full process, and dedicated RETRO |

Quick indicators:
- README typo or one emoji: L1.
- One business bug or UI label: L2.
- A complete feature such as HabitCard or NightProtection: L3.
- Split a database, change the framework, or make a meta-rule permanent: L4.

Escalation rules:
- L1 reveals cross-file effects → L2.
- L2 reveals effects across modules → L3.
- L3 touches meta-rules, multiple PMs, or schema → L4.

When scale increases, rerun Q1–Q7, rewrite the handoff card, and record it in `状态.md`.

## Q6: Cross-PM coordination

The unit being coordinated is a PM role, not its runtime.

| Item | Check |
|---|---|
| Q6.1 Current PM runtime | The main session hosts the Project PM. Other writing PMs default to workers; read-only diagnostic PMs default to explorers. Release actions remain with one owner and must not be delegated. |
| Q6.2 Cross-PM synchronization | Handoff card plus chat summary ①–⑦; prose cannot replace them. |
| Q6.3 Stale-mount defense | After switching Codex / Claude Code / Cowork, verify with `git status --short` in a real shell. |
| Q6.4 Handoff-area confirmation | Before switching PMs, write to `交接区/待接手/`. Do not move the card when work starts; move it to `已接手/` upon completion. |

Common triggers:
- Project PM → Development PM: handoff card plus issue BK defense.
- Project PM → Test and Release PM: ship card plus all six ADR-016 conditions.
- Operating System PM → Development PM: do not switch directly; let the Project PM coordinate.
- Any PM → Knowledge PM: submit a knowledge-retention report or RETRO candidate.

## Q7: Agent instantiation

| Question | Default |
|---|---|
| Write or read-only? | Writing a non-single-source file defaults to a worker; read-only diagnosis defaults to an explorer. |
| Is the file on the single-source/no-parallel-write list? | For `状态.md`, `交接区`, `CHANGELOG`, `元规则池.md`, `角色边界.md`, and `子agent调度机制.md`, agents may only draft; the main session makes the final write. |
| Is this a release action? | Commit, push, version, APK, and smoke remain with one owner and must not be delegated. |
| Are parallel framework workers needed? | B-lite requires at least six disjoint files, main-session acceptance, and the health-check gate. |

Permanent boundaries:
- The Project PM “Mimi” owns spawn authority and acceptance authority.
- Except for the Project PM's main session, each PM's actual work defaults to a real agent: write = worker; read-only = explorer.
- A dispatched agent must not spawn further agents on its own.
- An agent is an execution instance; it does not change PM responsibilities or authority.

## Related references

- [Decision checkpoint](decision-checkpoint.md) — Q1–Q7 entry point.
- [Decision appendix](decision-checkpoint-附录.md) — examples and history.
- [Role boundaries](../01_架构/角色边界.md) — path allowlist.
- [Agent scheduling](../01_架构/子agent调度机制.md) — scheduling entry rules.
- [Agent scheduling appendix](../01_架构/子agent调度机制-附录.md) — full mapping and historical explanations.
