---
name: subagent-dispatch-mechanism-appendix
scope: project
type: semantic
loaded: on-demand
description: Subagent dispatch appendix — background, complete PM mapping, B-lite history, and capability assets.
---

# Subagent Dispatch Appendix

> Main entry: [subagent dispatch](子agent调度机制.md). This file holds less frequently needed explanations to keep the entry point compact.

## 1. Why this mechanism exists

Version 4.0 defined nine PMs as abstract collaboration roles, but practical work exposed two deviations:

1. Mistaking a role change for collaboration between multiple agents.
2. Handling a new feature entirely in the main session when parallel implementation was appropriate.

This mechanism supplies the missing layer: PM roles remain abstract responsibilities; actual agents are temporary execution instances operating under those responsibilities.

## 2. No nesting; one acceptance owner

A dispatched worker or explorer must not spawn further subagents. When a worker needs help, it must return the request to the Project PM, who dispatches peer agents and accepts their results.

Reasons:

1. Centralized acceptance protects ADR-031's Project PM ownership of final delivery.
2. Nesting leaves the parent worker's first-line review unsupervised and weakens acceptance quality.
3. The current project scale does not need nesting. Use B-lite and let the Project PM dispatch multiple peer workers when parallelism is needed.

B-lite means that the Project PM dispatches multiple peers with disjoint write sets, they run concurrently, and the main session integrates their work. It is distinct from an agent spawning another agent.

## 3. B-lite history and boundaries

After PROP-044 approval, framework writes have two forms:

| Form | Rule |
|---|---|
| One agent writes nonsingle-source framework files | Allowed by default; the worker writes or drafts and the main session accepts. |
| Multiple workers edit framework files in parallel | Only with a large, disjoint write set, main-session integration, and the health gate. |

Why this is not fully autonomous B-full:

- The project root is not a Git repository, so worktree isolation does not apply to the framework.
- `状态.md`, `交接区/`, `CHANGELOG.md`, `元规则池.md`, and `角色边界.md` are single append points or foundational governance files.
- Autonomous agents would dilute the single external identity required by ADR-031.

## 4. Complete PM-to-agent mapping

| PM | Default instantiation | Typical use | Write boundary |
|---|---|---|---|
| Project PM “Mimi” | Not instantiated; dispatcher and main session | Global dispatch, task decomposition, boundaries, acceptance | Global dispatch; no arbitrary direct edits. |
| Knowledge PM “Curator” | Explorer for verification; worker for workspace writes | Explorer examines history, meta-rules, and retrospective evidence; worker writes `PM工作区/沉淀PM-沉淀者/` | May write that workspace; for the single-source meta-rule pool, draft only and let the main session perform the final write. |
| Operating System PM “Framework Steward” | Real worker for framework writes, followed by main-session acceptance/integration | Explorer examines hooks/framework risks; worker changes nonsingle-source framework files | May write nonsingle-source framework files; single-source files that prohibit parallel writes are drafts only, finalized by the main session. |
| Product PM “Requirements Analyst” | Worker for PRDs; explorer for verification | Worker writes PRDs in `Docs/1-需求文档/`; explorer checks requirements, historical acceptance criteria, or competitor context | May write `Docs/1-需求文档/`. |
| Technical PM “Fix Strategist” | Explorer for read-only root-cause diagnosis | Locate root causes and trace call chains | Read-only. |
| Test PM “Quality Gate” | Explorer for read-only acceptance strategy | Acceptance strategy and regression-scope design | Read-only. |
| Operations PM “Operations Mimi” | Worker for GTM; explorer for research | Worker writes GTM in `PM工作区/运营PM-运营咪咪/`; explorer inventories materials and researches content direction | May write that workspace; never edit `{{APP_REPO_DIR}}/**` or framework files. |
| Development PM “Implementer” | Worker | Implement application and test code | `{{APP_REPO_DIR}}/src/`. |
| Test and Release PM “Closer” | Release actions remain centralized and are not delegated | Control release verification; may delegate read-only risk review to an explorer | Commit, push, version, APK, and smoke actions remain centralized and are not delegated. |

## 5. Complete assignment template

```md
Role: <PM / agent type>
Objective: <one-sentence outcome>
Working directory: {{PROJECT_ROOT}}
Allowed reads: <paths>
Allowed writes: <paths or "none">
Disjoint-write declaration: <exclusive file list with zero overlap; use "no parallel work" when applicable>
Prohibited actions: no commit / push / version bump / edits to 状态.md, 交接区, CHANGELOG, 元规则池, or 角色边界 / edits to files absent from this brief / access to sensitive data
Inputs: <PRD / handoff card / paths / test commands>
Completion criteria: <verifiable outcomes>
Output: changed files / verification results / risks / items requiring the main session
```

## 6. Relationship to capability agents

- The current Codex runtime supports temporary `spawn_agent` instances.
- `能力资产/agents/` contains reusable execution-agent assets.
- Turn a task type into a fixed agent asset only when it is frequent, focused on one function, and standardizable.
- A temporary subagent is not the PM itself and does not automatically become an asset in `能力资产/agents/`.

## 7. Historical milestones

- 2026-06-13: added subagent dispatch, separating PM responsibilities from agent execution.
- 2026-06-14: PROP-044 approved B-lite, permitting peer workers for framework writes under controlled conditions.
- 2026-06-14: approved instantiation across all nine PMs. Except for the Project PM's main session, each PM's actual work defaults to a real agent instance.
- 2026-06-14: fixed the prohibition on nested autonomous dispatch and centralized acceptance with the Project PM.
- 2026-06-14: ADR-038 made the PM agent-dispatch model permanent.
