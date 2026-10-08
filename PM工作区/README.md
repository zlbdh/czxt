---
name: pm-workspace-index
scope: project
type: semantic
loaded: on-demand
description: "Entry point for nine private PM workspaces: v4.0, one lead, one meta-layer, five decision, and two implementation roles."
---

# PM Workspaces: Nine Private Work Areas, Final v4.0 Model

> 📦 **Nine private PM workspaces**: PROP-023 v4 / issue CM / PM self-corrections #60/#72 / v4.0 task #104.5 expansion to nine PMs.
> Each PM governs their own directory. A PM must not reorganize, move, or rename another PM's private directory: **self-correction #59**.
> Architecture: nine PMs across four layers—one lead, one meta-layer, five decision, and two implementation roles. See the [role directory](../操作系统/02_智能体/README.md).

## Naming history

- **v1**, 2026-05-15 / PROP-023: one `项目PM/` directory; issue BE defense, with meta-memory only for the Project PM.
- **v2**, early 2026-05-21 / issue CM: six PM directories under `中枢/`, after zlbdh approved a meta-memory center.
- **v2.1**, midday 2026-05-21 / zlbdh's naming suggestion: `中枢/` → `PM记忆中枢/`, making the name self-explanatory and consistent with `操作系统/05_记忆/`.
- **v3**, evening 2026-05-21 / self-correction #60: `PM记忆中枢/` → `PM工作区/`, incorporating `运营PM/`. The old name no longer covered both memory and work materials.

## Nine PM roles: final v4.0 model

| PM role | Directory | Trigger | Status |
|---|---|---|---|
| Project PM "Mimi", orchestrator | [Project PM](项目PM-咪咪/) | Default conversation entry point | ✅ Seven quick references accumulated through practice |
| Operating System PM "Framework Steward" | [Operating System PM](操作系统PM-框架管家/) | Framework governance | ✅ Practical hooks, health-check, and agent-scheduling governance |
| Product PM "Requirements Analyst" | [Product PM](产品PM-需求拆解者/) | Business requirements and PRD review | 🌱 Private lessons awaiting synthesis |
| Technical PM "Fix Strategist" | [Technical PM](技术PM-修复决策者/) | Bug diagnosis and technology selection | 🌱 Private lessons awaiting synthesis |
| Test PM "Quality Gate" | [Test PM](测试PM-质量门户/) | Test strategy and acceptance design | 🌱 Private lessons awaiting synthesis |
| Operations PM "Operations Mimi" | [Operations PM](运营PM-运营咪咪/) | GTM, promotion, and content; issue BI | 🌱 Template placeholder; no project-specific operations content by default |
| 🪞 Knowledge PM "Curator" | [Knowledge PM](沉淀PM-沉淀者/) | Meta-layer PM: issue AJ, PM self-corrections, RETROs, and the meta-rule pool | ✅ Quick references and PM tracking oversight used in practice |
| 🔨 Development PM "Implementer" | [Development PM](开发PM-实施者/) | Application implementation and some decisions; Claude Code environment | 🌱 Private implementation lessons awaiting synthesis |
| ✅ Test and Release PM "Closer" | [Test and Release PM](测试发布PM-闭环者/) | Final verification, release decisions, and lead verification; Codex environment | ✅ Practical v3.48–v3.52 release verification |

## Workspace contents

Each private PM workspace may contain more than memory:

| Subdirectory or content | Purpose | Example |
|---|---|---|
| `速查表/` | Meta-rule pitfalls and defensive checklists; an existing directory must contain an `INDEX.md` navigation entry point | Seven files in `项目PM-咪咪/速查表/` |
| `实战回顾/` | Full timelines of important events led by this PM | To develop |
| `PM自纠/` | PM self-corrections accumulated by date | To develop |
| Work materials | PRD drafts, strategy, content calendars, asset pools, topic ideas, interaction templates, drafts, and published material | Create as needed in project instances; the template root keeps scaffolding only |
| Pending decisions | Cross-PM proposals awaiting a Project PM decision | To develop |

## Mandatory cross-workspace boundary: self-correction #59, May 21, 2026

1. No PM may reorganize, move, rename, or merge another PM's private workspace.
2. Framework consistency does not override PM role boundaries.
3. Cross-PM coordination of private directory changes requires PROP governance and the owning PM's decision.
4. The Project PM may ask another PM to organize their own directory, but must not move it directly.

See the private-workspace boundary section in [role boundaries](../操作系统/01_架构/角色边界.md).

## Relationship to `操作系统/05_记忆/`

| Dimension | `PM工作区/` | `操作系统/05_记忆/` |
|---|---|---|
| Purpose | Private quick references, work materials, and pending decisions for each PM | Project-wide startup memory: user preferences, behavioral reflections, and project-history pointers |
| Governance | Each PM independently | Operating System PM |
| Required startup reading | No; consult before switching roles | Yes; every new conversation or PM handoff |
| Cross-PM reorganization | Prohibited without a PROP and the owning PM's decision | Maintained centrally by the Operating System PM |

## Related

- [Operating system entry point](../操作系统/00_总入口.md).
- [Role boundaries](../操作系统/01_架构/角色边界.md): nine-PM path allowlists and workspace boundaries.
- [Agent scheduling](../操作系统/01_架构/子agent调度机制.md): separate PM responsibilities from agent execution.
- [Role playbooks](../操作系统/02_智能体/README.md).
- [Project startup memory](../操作系统/05_记忆/INDEX.md): project-wide rules, not a private PM workspace.
