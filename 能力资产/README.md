---
name: capability-assets-index
scope: project
type: semantic
loaded: on-demand
description: Capability layer entry point for rules, shared assets, MCP, skills, agents, workflows, and tools.
---

# Capability Assets (PROP-029 v2 / May 21, 2026)

This is the **execution capability layer for {{PROJECT_NAME}}**: the capabilities used to do the work. The operating system at `{{PROJECT_ROOT}}\操作系统\` defines how to collaborate.

## 1. Seven directories

| Directory | Contents |
|---|---|
| `rules/` | Execution constraints: Git encoding, Web API sources, change levels, security/privacy, technical limitations, and visual design. Read actual directory contents for the file count. |
| `shared/` | Business capabilities: brand dictionary, Mimi persona baseline, and cross-branch collaboration. |
| `mcp/` | MCP inventory matrix. |
| `tools/` | Build scripts, dependency matrix, executable `scripts/`, and automation entry points in `hooks/`. |
| `skills/` | Tool capabilities and scripts: APK builds, status inference, project health checks, tests, and others. |
| `agents/` | Execution agents, currently empty and reserved for future expansion. Distinct from PM roles in `操作系统/02_智能体/`. |
| `workflows/` | Execution workflows, currently empty and reserved for future expansion. Distinct from collaboration workflows in `操作系统/07_完整工作流/`. |

## 2. Read as needed before starting

- Writing a PRD: `rules/写PRD.md`.
- Writing code: `rules/写代码.md`.
- Brand dictionary and Mimi persona: `shared/品牌词典.md` and `shared/咪咪人设统一基准.md`.
- Building and packaging: `tools/构建脚本.md`.
- Tests: `skills/跑测试.md`.
- APK builds: `skills/出APK.md`.
- Project health: `skills/项目体检.md`.

## 3. Layer responsibilities

`操作系统/` is the collaboration and runtime control layer: roles, state, handoffs, memory, ledgers, workflows, and tool governance.

`能力资产/` is the execution capability layer: rules, shared assets, MCP, tools, skills, agents, and workflows.

## 4. Maintenance procedure

- Update after adding an MCP integration or skill, or upgrading dependencies.
- Responsibility: Operating System PM “Framework Steward” and the role receiving the PR.
- Path governance for `能力资产/` belongs to Operating System PM “Framework Steward.” Product, Operations, or Project PMs may draft business-content suggestions for `shared/`. After Project PM acceptance, a PM authorized by the path allowlist applies them. This does not expand Product PM write permissions.

## 5. Version history

- v1, May 21, 2026, PROP-029 v2: physically separated from `agent/` to align with the yuanxing capability-assets model.
