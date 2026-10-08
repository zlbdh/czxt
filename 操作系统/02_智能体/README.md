---
name: agents-index
scope: project
type: semantic
loaded: on-demand
description: Nine PM playbooks and path allowlists across the lead, meta, decision, and implementation layers; final v4.0 model under ADR-027.
---

# Nine PM Role Playbooks

**Before changing PM roles, read the [role boundaries](../01_架构/角色边界.md)** for the nine-PM path allowlist and three-class behavior rules.

## Nine PMs across four layers: v4.0

ADR-023, ADR-027, and ADR-031 define:

- Lead (1): Project PM “Mimi,” the sole external identity.
- Meta (1): Knowledge PM “Curator,” working closely with the lead PM on cross-PM oversight and meta-rule governance.
- Decision (5): Operating System, Product, Technical, Test, and Operations PMs. They coordinate strategy and dispatch allowlisted writing through Q7.
- Implementation (2): Development PM “Implementer” and Test and Release PM “Closer.”

## PMs and agents

**PMs define responsibilities; agents are execution instances.** Nine PMs do not imply nine permanent autonomous agents. Except for the Project PM's main session, real agents are centrally dispatched, path-limited, and accepted by Project PM “Mimi.”

| Scenario | Mechanism |
|---|---|
| New features or implementation across files | The Project PM normally dispatches a worker as the Development PM |
| Technical diagnosis or test strategy | The Project PM normally dispatches an explorer for read-only findings |
| Release completion or status/handoff finalization | The Test and Release PM closes the work at a single point in the main session |
| Framework or hooks | The Operating System PM coordinates; non-single-source writes normally use workers, read-only diagnosis uses explorers, and restricted single-source files receive drafts with final writes by the main session |

See [agent scheduling](../01_架构/子agent调度机制.md) and its [mapping and historical appendix](../01_架构/子agent调度机制-附录.md).

Route borrowing requests through the [borrowing skill](../../能力资产/skills/借鉴.md). The Operating System PM manages cards; the target decision PM provides read-only assessments. This index does not duplicate execution rules.

## Specialist modes and plugin capabilities

Do not expand the nine-PM model simply to mirror real-world job titles. Requirements, design, frontend, backend, hardware, and other specialties should first use existing PM modes, plugins, workers, or explorers. Assess a new PM through the three expansion questions only when responsibility conflicts are persistent and frequent. See [specialist modes](../01_架构/PM专业mode能力层.md).

## File inventory

| Playbook | Responsibility | Category | Layer |
|---|---|---|---|
| [Project PM](项目PM-咪咪.md) and [appendix](项目PM-咪咪-附录.md) | Coordination and sole external identity | Lead | Lead |
| [Knowledge PM](沉淀PM-沉淀者.md) | Cross-PM oversight and meta-rule governance | Knowledge | Meta |
| [Operating System PM](操作系统PM-框架管家.md) and [appendix](操作系统PM-框架管家-附录.md) | Framework governance | Decision | Decision |
| [Product PM](产品PM-需求拆解者.md) and [appendix](产品PM-需求拆解者-附录.md) | PRD drafting | Decision | Decision |
| [Technical PM](技术PM-修复决策者.md) and [appendix](技术PM-修复决策者-附录.md) | Bug diagnosis and technology selection | Decision | Decision |
| [Test PM](测试PM-质量门户.md) and [appendix](测试PM-质量门户-附录.md) | Acceptance strategy | Decision | Decision |
| [Operations PM](运营PM-运营咪咪.md) and [appendix](运营PM-运营咪咪-附录.md) | Go-to-market decisions | Decision | Decision |
| [Development PM](开发PM-实施者.md) | Business code implementation | Execution | Implementation |
| [Test and Release PM](测试发布PM-闭环者.md) | Completion verification and release; primary verification PM | Verification | Implementation |
| [Shared skills index](共享技能/INDEX.md) | Cross-PM SOPs: Git recovery, mount-stale defense, physical-device smoke, handoff verification, and PM self-correction | — | — |
| [Legacy Product Manager](PM-产品经理.md) | Historical archive absorbed into Product PM; retained under ADR-007 | Historical | — |
| [Legacy Dev](Dev-开发.md) | Historical execution runtime: Claude Code | Historical | — |
| [Legacy QA](QA-测试.md) | Historical testing execution runtime | Historical | — |

## Common role-switching protocol

Before switching, run [decision-checkpoint](../07_完整工作流/decision-checkpoint.md) Q1–Q7:

1. Which PM owns the task?
2. Does the path allowlist permit it?
3. How should an out-of-scope task be handled?
4. Which quick-reference triggers match? See PROP-031.
5. What is its L1–L4 scale? See PROP-033.
6. Does it require cross-PM coordination? Added in v4.0.
7. Should an agent be instantiated? See ADR-038.

Work within the role's allowlist. The main session finalizes the trace in `状态.md` under its current PM role and allowlist, then provides the seven-part chat handoff.

## Directory responsibilities

- `操作系统/02_智能体/`: PM identities and boundaries — who you are.
- `操作系统/01_架构/`: architecture rules — how work is organized.
- `能力资产/skills/`: executable SOPs — how to act.
- `能力资产/workflows/`: step orchestration — in what order.
- `能力资产/rules/`: mandatory rules — what must be followed.
- `PM工作区/<X PM>/`: each PM's private quick references, self-corrections, and practical reviews.

## Related references

- [Role boundaries](../01_架构/角色边界.md): complete allowlists and the four-layer model.
- [Agent scheduling](../01_架构/子agent调度机制.md): separation of PM responsibilities and agent execution.
- [Meta-rule pool](../01_架构/元规则池.md): authoritative permanent rules and current count.
- [Tool/runtime matrix](../01_架构/工具载体矩阵.md): PM abstraction independent of execution tools, ADR-026.
- [Three-class behavior rules](../01_架构/三类行为铁律.md): Class A automatic, Class B requires asking, Class C prohibited.
- [Decision checkpoint](../07_完整工作流/decision-checkpoint.md): mandatory role-switching checks.
- [PM workspaces](../../PM工作区/): nine private PM workspaces.
