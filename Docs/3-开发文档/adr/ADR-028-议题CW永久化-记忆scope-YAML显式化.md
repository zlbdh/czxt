# ADR-028 · Make topic CW permanent: explicit memory scope in YAML (four tiers × three types)

- **Status**: Current
- **Date**: 2026-05-22
- **Related**: [PROP-037 explicit memory scope in YAML](../../../确认改动/已审批/进行中/PROP-037-2026-05-22-记忆scope-YAML显式化.md) · [Memory governance plan](../../../操作系统/06_工具治理/历史归档/2026-05/记忆治理方案-2026-05-22.md) · [scope-schema.md](../../../操作系统/05_记忆/scope-schema.md)
- **Topic CW closure criteria**: Memory governance plan implemented, with all 12 location categories inventoried; schema file present; frontmatter demonstrated in at least five key files ✅ Met

> **Current guidance addendum (2026-06-17)**: Sprint-8/9/10 and Mem0 integration statements below preserve this ADR's original schedule and do not imply that anyone is implementing them now. Current execution follows `scope-schema.md` and the PROP-037 pending rereview status; `pm-workspace` is the current frontmatter scope for PM workspaces.

## Context

Topic CW originated in the 2026-05-22 memory-governance plan's state-of-the-art comparison:
- **Mem0**, 47K stars: three scope tiers, user / agent / runtime.
- **Letta / LangMem**: two to three tiers.
- **{{PROJECT_NAME}} at the time**: 12 dispersed memory-location categories, **zero scope labels**, and PMs reading across the wrong scopes.

Historical problems:
- The Project PM treated PM self-corrections, which have agent scope, as shared project-scope material and put them on a shared path.
- Incoming PMs could not distinguish mandatory reading (`loaded=always`) from on-demand material.
- The Knowledge PM could not find an inventory of agent-scope files for cross-PM oversight.

## Decision

**Permanently close topic CW** and add it as the twelfth permanent meta-rule.

### Decision 1 — Permanent YAML frontmatter schema (core)

Every framework memory Markdown file **must** begin with frontmatter:

```yaml
---
name: <kebab-case-slug>          # Required / unique identifier
scope: project                 # Required / global | project | agent | session
type: semantic                 # Required / episodic | semantic | procedural
agent: <PM name>                # Optional / required when scope=agent
loaded: always                 # Optional / always | on-demand | triggered
trigger: <trigger description> # Optional / required when loaded=triggered
description: <one-sentence description> # Required
---
```

See [scope-schema.md](../../../操作系统/05_记忆/scope-schema.md) for the full definition.

### Decision 2 — Four scope tiers, one more than Mem0

| Scope | Coverage | Example |
|---|---|---|
| **global** | Cross-project / AppData | AppData INDEX pointer |
| **project** | Entire project / cross-PM | Topic panorama / ADRs / shared skills |
| **agent** | One PM's private context | PM quick references / self-corrections |
| **session** | One conversation | Chat shorthand / top of 状态.md |

Mem0 has three tiers, user/agent/runtime. This framework adds an explicit project concept, whereas Mem0 uses user for multitenancy.

### Decision 3 — Three types aligned with Mem0 / LangMem

| Type | Meaning |
|---|---|
| **episodic** | Event stream where timestamps matter |
| **semantic** | Facts / reflections / rules |
| **procedural** | Executable steps / SOPs |

The historical schedule envisaged routing by type to a memory store during PROP-039 Mem0 integration. SDK GA is no longer treated as a blocker; an external store awaits PROP-039 reevaluation / a defined split plan.

### Decision 4 — Implement key files first

Do not add frontmatter to all 12 categories at once. **Start with five key files** for 80% of the value:

| Priority | File | Timing |
|---|---|---|
| P0 | `操作系统/05_记忆/INDEX.md` | ✅ task #107.4 |
| P0 | `状态.md` | ✅ task #107.4 |
| P0 | `操作系统/04_台账/议题全景.md` | ✅ task #107.4 |
| P0 | `操作系统/02_智能体/共享技能/INDEX.md` | ✅ Already present; add scope |
| P0 | `AGENTS.md` | ✅ task #107.4 |
| P1 | Nine PM role files in `操作系统/02_智能体/*.md` | Scheduled for Sprint-8 |
| P2 | All 12 categories | Scheduled for Sprint-9 |

Every new memory file **must** include frontmatter under permanent topic CW.

### Decision 5 — Show scope in INDEX

Annotate each memory entry in `操作系统/05_记忆/INDEX.md` with scope, such as `[project] Topic panorama`, so incoming PMs can filter it.

Implement in task #107.4, this task.

### Decision 6 — Integrate with decision-checkpoint Q4

Filter Q4 quick-reference matching in `操作系统/07_完整工作流/decision-checkpoint.md` by scope:
- Project PM role: prioritize `scope=agent agent=项目PM-咪咪` or `scope=project`.
- Knowledge PM role: prioritize `scope=project` plus `scope=agent` material needed for cross-PM oversight.

Implementation is scheduled for Sprint-8. This ADR establishes the permanent protocol without requiring implementation now.

### Decision 7 — Expand the meta-rule pool from eleven to twelve

Add **CW · Explicit memory scope in YAML**:

```
G  PRD source adherence          (accumulated field evidence)
AT Path adherence                (accumulated field evidence)
AM Multi-role collaboration      (accumulated field evidence)
AO Error isolation               (accumulated field evidence)
BC Cowork engineering consistency (accumulated field evidence)
BE Mandatory startup checks      (accumulated field evidence)
AJ PM subroles                   → ADR-023
P  Three-state input boundaries  → ADR-024
BK Cowork mount stale            → ADR-025
CT PM/tool decoupling            → ADR-026
CU+DD Knowledge PM meta layer    → ADR-027
🆕 CW Memory scope YAML          → ADR-028, this record
```

## Consequences

### Benefits

- ✅ Explicit agent/project distinctions defend against reading the wrong scope.
- ✅ New PMs begin with project scope and their own agent scope, filtering irrelevant noise.
- ✅ Industry-aligned type/scope fields prepare for Mem0 integration.
- ✅ The Knowledge PM can filter all PM private memories by `scope=agent` for oversight.

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| Adding frontmatter to all 12 categories is substantial work | Decision 4 phases it: P0 now / P1 Sprint-8 / P2 Sprint-9 |
| Schema evolution invalidates frontmatter | Version scope-schema.md; v1 is current, major changes require a PROP |
| Mapping four scope tiers to Mem0's three | Design during PROP-039: global+project → user / agent → agent / session → runtime |

### Verification

| Dimension | Method | Result |
|---|---|---|
| Schema file | `操作系统/05_记忆/scope-schema.md` exists with all six sections | ✅ task #107.4 |
| Frontmatter in key files | Five files: INDEX / 状态 / 议题全景 / shared skills / AGENTS | ✅ task #107.4 |
| Meta-rule pool upgrade | `操作系统/01_架构/元规则池.md` includes CW | ✅ task #107.5 |

## Implementation checklist

- ✅ task #107.4 — Schema + frontmatter in five key files + INDEX upgrade.
- 🗄️ Sprint-8 — All nine PM roles; historical schedule, now covered by later frontmatter work and the P4n guard.
- 🗄️ Sprint-9 — All 12 categories; historical schedule, now governed by the PROP-037 pending rereview status.
- 🗄️ Sprint-10 — Mem0 integration; historical schedule, now awaiting PROP-039 reevaluation / splitting.

## Referenced decisions

- Memory governance plan, 2026-05-22: state-of-the-art comparison and 12 memory-location categories.
- Mem0 documentation: three scope tiers.
- PROP-037 + topic CW.

---

⭐ **ADR-028 is permanently current, alongside ADR-022/023/024/025/026/027 as a framework meta-rule ADR.**
