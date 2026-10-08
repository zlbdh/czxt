# ADR-027 · Make topics CU + DD permanent: Knowledge PM meta layer + nine PMs across lead–meta–decision–implementation

- **Status**: Current
- **Date**: 2026-05-22
- **Related**: [PROP-036 Knowledge PM meta layer](../../../确认改动/已审批/已完成/PROP-036-2026-05-22-沉淀PM角色元层.md) · [PM self-correction #65](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-65.md) · [PM self-correction #72](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-72.md) · [Knowledge PM role](../../../操作系统/02_智能体/沉淀PM-沉淀者.md) · [Role boundaries](../../../操作系统/01_架构/角色边界.md)
- **Topics CU + DD closure criteria**: v4.0 architecture implemented across all task #104 stages; six accumulated PM self-corrections (#57/#58/#62/#65/#69-72); three knowledge layers; direct alignment with the lead PM ✅ Met

> Current terminology: Earlier "child / grandchild" roles correspond to "decision / implementation." The four layers are now consistently called lead–meta–decision–implementation.

## Context

Topics CU and DD originated in PM self-corrections #65 and #72 and are closely linked.

**Topic CU, PM self-correction #65**: Knowledge consolidation was dispersed across private PM work. Each PM wrote their own corrections, reflections, and RETROs, causing:
- Nine recurrences of topic AJ traceability collapse, including repeated #57/#58/#62 patterns.
- Uneven knowledge capture: frequent for the Project PM, sparse for decision PMs.
- No cross-PM view of framework degradation.
- A need for a **dedicated Knowledge PM**.

**Topic DD, PM self-correction #72**: The new Knowledge PM was initially classified as a "grandchild PM" beside Development and Test and Release. zlbdh asked, "Shouldn't this role consolidate knowledge for the whole project? Why is it a grandchild?"
- Grandchild PMs are the implementation layer, executing decision-PM instructions.
- The Knowledge PM actually belongs in the **meta layer**, observing all PMs and providing the lead PM with reflection and improvement proposals.
- The implementation layer is insufficient; this role must sit beside the lead PM.
- The nine-PM matrix therefore becomes **lead–meta–decision–implementation**.

## Decision

**Permanently close CU + DD**, consolidating them into the eleventh permanent meta-rule.

### Decision 1 — Nine PMs across four layers

The framework matrix is formally **four layers and nine roles**, implemented in task #104.1 in 角色边界.md ✅:

```
                    🎩 Lead PM (1)
                    Project PM "Mimi" (sole outward-facing identity)
                         │
              ┌──────────┴──────────┐
              │                     │
        🪞 Meta-layer PM (1)     (other PMs do not move upward)
        Knowledge PM "Curator"
              │
              │ Beside the lead PM / oversight across the decision layer
              │
   ┌──────────┴──────────────────────┐
   │   🧠 Decision PMs (5)           │
   │   Operating System / Product / Technical / Test / Operations
   └────────────────┬───────────────────┘
                    │
              ┌─────┴──────┐
              │            │
        🔨 Grandchild PMs (2, implementation layer)
        Development PM "Implementer" / Test and Release PM "Closer"
```

Every new PM **must** belong to one of the four layers: lead / meta / decision / implementation. Floating roles are prohibited.

### Decision 2 — Permanent responsibilities of Knowledge PM Curator

The [Knowledge PM role file](../../../操作系统/02_智能体/沉淀PM-沉淀者.md), 4.7KB, establishes **six core responsibilities**:

| # | Responsibility | Frequency |
|---|---|---|
| 1 | Monitor topic AJ traceability to prevent #57/#58/#62 recurrence | On every received chat |
| 2 | Detect accumulated PM self-correction patterns and candidate meta-rules | Weekly |
| 3 | Draft RETROs | Sprint end |
| 4 | Govern the meta-rule pool; propose promotion from candidate to permanent | Monthly |
| 5 | Audit decision-checkpoint Q1-Q6 for authority violations / floating roles | Sampling |
| 6 | Check framework health for structural drift | Mid-Sprint |

The Knowledge PM **does not make decisions**, but proposes improvements to the lead PM, and **does not implement application code** in {{APP_REPO_DIR}}/src/.

### Decision 3 — The meta layer sits beside the lead PM

The Knowledge PM belongs in the **meta layer**, not the decision or grandchild layer:

- ✅ **Scope**: Observe five decision PMs and two grandchild PMs for structural drift.
- ✅ **Reporting**: Report directly to lead PM Mimi, outside the decision-PM chain.
- ❌ **Prohibited**: Taking a decision PM's specific decisions, such as product feature tradeoffs or technical architecture choices; performing grandchild-PM implementation, such as editing {{APP_REPO_DIR}}/src/.

Relationship: Lead PM ←→ Knowledge PM ← oversight → five decision PMs + two grandchild PMs.

A future meta-layer role, such as Governance PM, must provide cross-PM oversight and report to the lead PM.

### Decision 4 — Three-layer knowledge architecture (shared origin with DC + DD)

Knowledge consolidation has **three layers**, implemented in task #102 + #104.5 ✅:

| Layer | Name | Location | Responsible PM |
|---|---|---|---|
| 1 | Private PM knowledge | `PM工作区/{PM名}/` | Each PM |
| 2 | Main Knowledge PM consolidation | `PM工作区/沉淀PM-沉淀者/` | Knowledge PM Curator |
| 3 | Project-wide knowledge across the lifecycle | `操作系统/04_台账/项目沉淀/` | Knowledge PM leads; lead PM reviews |

- Layer 1: Immediate personal reflection through self-corrections, quick references, and tool field notes.
- Layer 2: Cross-PM aggregation, candidate meta-rule discovery, and RETRO drafting.
- Layer 3: Long-term cross-Sprint project knowledge: topic panorama, permanent ADRs, and meta-rule governance outcomes.

### Decision 5 — Two-layer verification architecture (shared origin with DB)

Verification has **two layers**:

| Layer | Verifier | Scope |
|---|---|---|
| 1 | Each PM's own verification | Their own output; for example, Operating System PM checks its edits to 角色边界.md |
| 2 | Main verification by Test and Release PM | Integrated cross-PM output, such as device verification before application code ships |

Avoid missing layer 1 ("I think it is right") and making layer 2 the only defense ("Codex will catch it anyway").

### Decision 6 — Expand the permanent meta-rule pool from ten to eleven

Add the consolidated **CU + DD · Knowledge PM meta-layer architecture**:

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
🆕 CU+DD Knowledge PM meta layer → ADR-027, this record
```

CU and DD are promoted together because they share a root: CU establishes the dedicated PM; DD fixes its layer.

## Consequences

### Benefits

- ✅ Dedicated Knowledge PM monitoring defends against topic AJ traceability collapse.
- ✅ A cross-PM view detects framework degradation instead of each PM attending only to its own area.
- ✅ A named owner identifies recurring self-corrections and avoids missing candidate meta-rules.
- ✅ Clear nine-PM hierarchy: one lead / one meta / five decision / two grandchild roles across four layers.
- ✅ Three knowledge layers and two verification layers provide sufficient defensive depth.

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| The Knowledge PM also misses something, allowing a tenth AJ recurrence | Introduce Layer 4 actual automation after Sprint-9, PROP-038; Layer 5 AI self-reflection later |
| Meta-layer scope expands without limit | Decision 2 fixes six responsibilities; additions require lead-PM approval |
| Boundaries between grandchild and decision PMs are unclear | ADR-022 clarifies them; the Class C list in 角色边界.md is permanent |

### Verification

| Dimension | Method | Result |
|---|---|---|
| Nine-PM, four-layer matrix exists | Nine files in `操作系统/02_智能体/` with four-layer labels | ✅ |
| Knowledge PM definition | All six responsibilities in `沉淀PM-沉淀者.md` | ✅ |
| Knowledge PM workspace | `PM工作区/沉淀PM-沉淀者/` exists | ✅ |
| Layer 3 project knowledge | `操作系统/04_台账/项目沉淀/README.md` exists | ✅ |
| Topic AJ defense in this session | Chat shorthand section ⑦ and transition history in 状态.md | ✅ Ongoing monitoring |

## Implementation checklist (retrospective)

- ✅ task #104.1 — Upgrade 角色边界.md to nine PMs across lead–meta–child–grandchild.
- ✅ task #104.2 — Create the 沉淀 PM-沉淀者.md role definition.
- ✅ task #104.5 — Create the physical PM 工作区/沉淀PM-沉淀者/ directory.
- ✅ task #102 — Create the Layer 3 project-knowledge README.
- ✅ task #106.1 — Synchronize CU + DD in 议题全景.md.
- ✅ task #107.3 — Make this ADR permanent on 2026-05-22.

## Referenced decisions

- PM self-correction #65: A dedicated Knowledge PM is needed.
- PM self-correction #69: Two knowledge layers, later expanded to three.
- PM self-correction #70: Two verification layers.
- PM self-correction #71: Layer 3 project knowledge.
- PM self-correction #72 ⭐⭐⭐: Promote the Knowledge PM to the meta layer; nine PMs across lead–meta–child–grandchild.
- v4.0 target vision §I: nine PMs × four categories; §V: knowledge architecture; §IX: meta-layer PM.

---

⭐ **ADR-027 is permanently current, alongside ADR-022/023/024/025/026 as a framework meta-rule ADR.**
