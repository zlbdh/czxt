# ADR-029 · Make topic BE permanent: PM workspaces as meta-memory hubs (PROP-023 P6 closeout)

- **Status**: Current
- **Date**: 2026-05-22
- **Related**: [PROP-023 Project PM memory hub](../../../确认改动/已审批/已完成/PROP-023-2026-05-15-项目PM记忆中枢化.md) · [Six accumulated PM self-corrections #43-#48](../../../状态.md) · [PM workspaces](../../../PM工作区/) · [Meta-rule pool](../../../操作系统/01_架构/元规则池.md)
- **Topic BE closure criteria**: Physical PM workspaces; quick references / field reviews / self-corrections for six PMs; mandatory startup checks used in 100+ field cases ✅ Met

> ⚠️ **Current terminology (2026-06-15)**: Earlier "grandchild PMs" are now called "implementation PMs." The workspace mechanism remains current; hierarchy terminology follows `lead–meta–decision–implementation`.

## Context

Topic BE originated in PROP-023 on 2026-05-15 and six same-pattern PM self-corrections #43-#48, all involving framework meta-rule recall failures within one day:

| # | Type | Description |
|---|---|---|
| #43 | Incorrect rule recall | F-SYSCHECK-1 handoff included a CHANGELOG entry that violated the header |
| #44 | PROP status semantics | PROP-021 was marked Completed too early |
| #45 | Cross-platform API assumption | navigator.* fallback was assumed to behave identically across platforms |
| #46 | Capacitor major-version assumption | Handoff specified `^7.x`; project actually used `^6.x` |
| #47 | Missing plugin integration defenses | F-ALARM-1 handoff omitted mandatory static plugin import and NotificationChannel creation |
| #48 | Redundant chat output | Two identical copy/paste code blocks in one chat turn |

**Root cause**: Rules were dispersed across 19 PROPs / 22 ADRs / eight RETROs / 21 topics / five PM role files / multiple workflows. A role switch theoretically required searching five to eight files, but the PM repeatedly relied on memory and recalled meta-rules incorrectly.

**Topic BE in one sentence**: On a role switch, new conversation, or new session, a PM **must check** INDEX + 状态.md + personal workspace quick references + pending handoff cards, **not rely on memory**.

## Decision

**Permanently close topic BE**. It remains meta-rule six, mandatory startup checks; ADR-029 makes its physical implementation permanent.

### Decision 1 — Permanent physical PM workspaces (PROP-023 P2-P5 complete)

Establish top-level `PM工作区/` and nine PM subdirectories, completed across tasks #95-#107:

```
PM工作区/
├── README.md                  ← Five iterations, v1→v3.1
├── 项目PM-咪咪/                ← Lead PM
├── 沉淀PM-沉淀者/              ← Meta-layer PM beside the lead PM
├── 操作系统PM-框架管家/         ← Decision PM
├── 产品PM-需求拆解者/           ← Decision PM
├── 技术PM-修复决策者/           ← Decision PM
├── 测试PM-质量门户/             ← Decision PM
├── 运营PM-运营咪咪/             ← Decision PM
├── 开发PM-实施者/               ← Implementation PM
└── 测试发布PM-闭环者/           ← Implementation PM
```

Each workspace **must include**:
- `README.md`: PM entry point and index.
- `速查表/`: Read on demand when a trigger matches, PROP-031 + ADR-028 `scope=agent`.
- `INDEX.md`: Index of that PM's private memories.

### Decision 2 — Six mandatory startup readings, at the top of 状态.md

Every PM **must read all six**, implementing topic BE's startup rule:

1. **Three-second quick reference at the top of 状态.md**: Current milestone.
2. **`能力资产/rules/codex-push后防御.md`**: Topic BK / ADR-025 defenses.
3. **`能力资产/rules/git-commit-编码规范.md`**: Topic BG defenses.
4. **`能力资产/shared/品牌词典.md`**: The AI model is Xiaomi MiMo, not Claude.
5. **`操作系统/01_架构/演化哲学.md`**: Do not imitate real-company structures; apply the three-question test.
6. **Seven files in `PM工作区/项目PM-咪咪/速查表/`**: The core topic BE startup checks.

A new PM **must** create personal quick references in addition to these six readings, following PROP-031 + ADR-028 frontmatter.

### Decision 3 — Permanent speedsheet trigger mechanism (PROP-031)

On a role switch, [decision-checkpoint Q4](../../../操作系统/07_完整工作流/decision-checkpoint.md) searches for a matching speedsheet trigger:

```
Q4: Does a quick reference for the current PM role have a trigger matching this task?
↓
Yes → Read the matching speedsheet
↓
No → Follow the default workflow
```

PROP-031 + decision-checkpoint Q4 are implemented; this ADR makes the mechanism permanent.

### Decision 4 — Private memory hubs for nine PMs (a natural extension of PROP-023)

Each PM owns three memory categories, with agent scope and ADR-028 frontmatter:

| Type | Location | scope/type/loaded |
|---|---|---|
| Quick references | `PM工作区/<PM>/速查表/*.md` | agent / procedural / on-demand |
| Field reviews | `PM工作区/<PM>/实战回顾/*.md` | agent / episodic / on-demand |
| PM self-corrections | `PM工作区/<PM>/PM自纠/*.md` | agent / episodic+reflection / triggered |

Cross-PM oversight is led by [Knowledge PM Curator](../../../操作系统/02_智能体/沉淀PM-沉淀者.md), the ADR-027 meta-layer PM.

### Decision 5 — Add an ADR to topic BE without renumbering it

BE was already the sixth permanent meta-rule, one of the six starting rules in v1.0. ADR-029 **does not change its number**; it makes the **physical mechanism** permanent: PM workspace directories, six startup readings, and speedsheet triggers.

Meta-rule pool v3.2 → v3.3: add ADR-029 to the BE row.

```
G  PRD source adherence          (accumulated field evidence)
AT Path adherence                (accumulated field evidence)
AM Multi-role collaboration      (accumulated field evidence)
AO Error isolation               (accumulated field evidence)
BC Cowork engineering consistency (accumulated field evidence)
🆕 BE Mandatory startup checks   → ADR-029 (adds an ADR; rule number unchanged)
AJ PM subroles                   → ADR-023
P  Three-state input boundaries  → ADR-024
BK Cowork mount stale            → ADR-025
CT PM/tool decoupling            → ADR-026
CU+DD Knowledge PM meta layer    → ADR-027
CW Memory scope YAML            → ADR-028
```

## Consequences

### Benefits

- ✅ **Zero recurrences** of the #43-#48 failure types in 100+ trials after task #95.
- ✅ More durable cross-session PM transitions: workspaces persist beyond temporary memory.
- ✅ One physical location for nine private memory hubs gives the Knowledge PM concrete oversight directories.
- ✅ Topic BE unifies the meta-rule, physical implementation, and speedsheet trigger.

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| Excessive density across nine workspaces | Topic CM v3.1 addressed it through physical splitting and consistent names |
| PM relies on memory instead of quick references | Automated speedsheet triggers through PROP-031 / decision-checkpoint Q4 ✅ |
| Quick references themselves become dispersed | Topic CL long-tail monitoring and cross-PM Knowledge PM checks |

### Verification

| Dimension | Method | Result |
|---|---|---|
| Physical workspaces | `ls PM工作区/` shows nine subdirectories | ✅ |
| Six startup readings | Section exists at the top of 状态.md | ✅ |
| Speedsheet triggers | decision-checkpoint Q4 + PROP-031 implemented | ✅ |
| Topic BE meta-rule | Rule six in 元规则池.md | ✅ |
| Zero same-pattern recurrences | No #43-#48-type triggers after task #95 | ✅ 100+ field cases |

## Implementation checklist (retrospective)

- ✅ PROP-023 P0+P1 approved by zlbdh, 2026-05-15.
- ✅ PROP-023 P2-P4 physical implementation across tasks #95-#100.
- ✅ PROP-023 P5 gradual cross-Sprint migration across #95-#107: 73 standalone PM self-correction files, topic panorama, and role-transition history.
- ✅ **PROP-023 P6 closes with this ADR**, task #108.1 / 2026-05-22.
- ✅ PROP-031 speedsheet triggers implemented and already recorded in an ADR.
- ✅ ADR-028 scope frontmatter companion, topic CW.
- ✅ ADR-027 cross-PM Knowledge PM oversight, CU+DD.

## Referenced decisions

- PM self-corrections #43-#48: six same-pattern cases on 2026-05-15.
- PROP-023 Project PM memory hub: zlbdh approved option A + direct implementation, 2026-05-15.
- Meta-rule pool v1.0: BE was one of the original six rules.
- decision-checkpoint Q4 speedsheet triggers, PROP-031.
- ADR-023 topic AJ PM subroles: extension of the nested architecture.

---

⭐ **ADR-029 is permanently current, alongside ADR-022/023/024/025/026/027/028 as a framework meta-rule ADR.**
