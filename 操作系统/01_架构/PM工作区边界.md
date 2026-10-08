---
name: pm-workspace-boundaries
scope: project
type: semantic
loaded: on-demand
description: Nine private PM workspace boundaries — paths, cross-boundary prohibitions, and the relationship to project memory.
---

# PM Workspace Boundaries

> The main entry is [role boundaries](角色边界.md). This file governs the nine private PM workspaces so that framework maintenance does not disturb another PM's private knowledge.

## Nine private PM workspaces

| PM role | Private workspace | Contents |
|---|---|---|
| Project PM “Mimi” | [Project PM workspace](../../PM工作区/项目PM-咪咪/) | Quick references, field reviews, PM self-corrections, and role transition records |
| Operating System PM “Framework Steward” | [Operating System PM workspace](../../PM工作区/操作系统PM-框架管家/) | Framework governance knowledge |
| Product PM “Requirements Analyst” | [Product PM workspace](../../PM工作区/产品PM-需求拆解者/) | PRD and requirements analysis knowledge |
| Technical PM “Fix Strategist” | [Technical PM workspace](../../PM工作区/技术PM-修复决策者/) | Technical diagnosis knowledge |
| Test PM “Quality Gate” | [Test PM workspace](../../PM工作区/测试PM-质量门户/) | Acceptance strategy knowledge |
| Operations PM “Operations Mimi” | [Operations PM workspace](../../PM工作区/运营PM-运营咪咪/) | GTM and operations content |
| Knowledge PM “Curator” | [Knowledge PM workspace](../../PM工作区/沉淀PM-沉淀者/) | Cross-PM knowledge and meta-rule governance |
| Development PM “Implementer” | [Development PM workspace](../../PM工作区/开发PM-实施者/) | Development quick references and field knowledge |
| Test and Release PM “Closer” | [Test and Release PM workspace](../../PM工作区/测试发布PM-闭环者/) | Release completion and smoke-test experience |

## Cross-boundary prohibitions

1. No PM may organize, move, rename, or merge another PM's private workspace.
2. “Framework consistency” must not override PM role boundaries.
3. Changes across private PM directories require a PROP or that PM's own decision; the acting PM must not execute them unilaterally.
4. The Project PM may ask the responsible PM to organize its own directory, but must not move it directly on that PM's behalf.

## Relationship to `05_记忆`

`操作系统/05_记忆/INDEX.md` is project-wide startup meta-memory: user preferences, project history pointers, and shared cross-PM facts. It is not an individual PM's private workspace.

Every PM may read `05_记忆`; Operating System PM “Framework Steward” owns its governance.

## Trigger scenarios

| Scenario | Required action |
|---|---|
| During framework maintenance, a PM's private directory appears to need reorganization | Stop; write a PROP or refer it to that PM |
| Operations content needs to be retained | Write it in the Operations PM workspace; do not move it into the operating system |
| A meta-rule needs cross-PM formalization | Knowledge PM drafts; Operating System PM assists with framework implementation; Project PM accepts |
| A private workspace has broken links or README drift | A repair proposal may be submitted; structural reorganization still requires the responsible PM's decision |

## Related references

- [Role boundaries](角色边界.md) — main path allowlist.
- [Collaboration appendix](角色边界-协作附录.md) — external identity and counterexamples.
- [Agents](../02_智能体/) — nine PM playbooks.
- [PM workspace index](../../PM工作区/README.md) — workspace entry point.
