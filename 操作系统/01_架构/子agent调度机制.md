---
name: subagent-dispatch-mechanism
scope: project
type: semantic
loaded: on-demand
description: Separate PM responsibilities from subagent execution; the Project PM centrally dispatches real subagents.
---

# Subagent Dispatch

> Core principle: **a PM defines responsibilities and permissions; an agent is a temporary execution instance**.  
> The external identity is always Project PM “Mimi”. The Project PM centrally dispatches real subagents, limits their scope, and accepts their results.

This file contains frequent-use entry points and mandatory rules. See the [appendix](子agent调度机制-附录.md) for background, the complete mapping, B-lite history, and the relationship to capability assets.

## 1. Three-layer model

| Layer | Definition | Owner |
|---|---|---|
| PM responsibilities | Nine abstract PM roles, path allowlists, and decision boundaries | `操作系统/02_智能体/` and `角色边界.md` |
| Dispatch | Decide whether to instantiate agents, split tasks, bound paths, and accept results | Project PM “Mimi” |
| Execution instances | Explorers, workers, or other runtime subagents | Current Codex subagent runtime or future execution agents |

Mandatory rules:
- **Spawn and acceptance authority remain with Project PM “Mimi”**. Individual PMs do not spawn autonomously; spawn authority is not delegated.
- **No nested autonomous dispatch; acceptance always has one owner**. Workers and explorers must not spawn further subagents. Return requests for help to the Project PM, who dispatches peer agents and accepts their work.
- Agents are execution instances and do not change PM permissions or responsibilities. The external identity remains Project PM “Mimi” (ADR-031).

## 2. Default triggers

### Instantiate an agent by default

| Scenario | Recommended agent | Rule |
|---|---|---|
| New feature across multiple files | Worker | Development PM “Implementer” instance, limited to `{{APP_REPO_DIR}}/src/`. |
| Implementation and read-only diagnosis can proceed in parallel | Worker + explorer | Worker implements; explorer examines risks or historical patterns. |
| Two or more independent code issues | Multiple explorers | Each issue is self-contained; do not duplicate the same investigation. |
| Workflow explicitly requires subagents or multiple agents | Corresponding agents | Actually dispatch them; a verbal role change is not a substitute. |
| Broad refactoring with separable write sets | Multiple workers | Each worker must have a disjoint write scope. |
| Framework writes by Operating System PM “Framework Steward” | Worker | Delegate nonsingle-source framework files by default. For single-source files that prohibit parallel writes, agents draft and the main session performs the final write. |

### Close through the main session by default

| Scenario | Reason |
|---|---|
| `commit`, `tag`, `push`, or version bump | Release state is strictly sequential, controlled by Test and Release PM “Closer”. |
| APK, physical-device smoke, `状态.md`, or final handoff card | A single source of truth prevents conflicting agent writes. |
| Writes to single-source files that prohibit parallel writes | Strictly sequential, one append point, and no worktree protection. Agents draft; the main session performs the final write. |
| API key, baseUrl, or user-data deletion | Sensitive boundaries are not delegated to subagents. |
| Small, nonparallel work with no independent audit value that immediately blocks the next step | The main session handles it to avoid waiting overhead. |

Single-source files that prohibit parallel writes: `状态.md` / `交接区/` / `CHANGELOG.md` / `元规则池.md` / `角色边界.md` / `子agent调度机制.md`.

## 3. Controlled parallel framework writes: B-lite / PROP-044 approved 2026-06-14

This means **multiple peer workers writing framework files**, not workers dispatching nested agents. Dispatch is allowed only when all conditions hold:

1. **Large write set**: at least six independent files; small batches can stay sequential.
2. **Disjoint writes**: every worker has an explicit, nonoverlapping file list in its assignment.
3. **Main-session integration and health gate**: after workers return, the Project PM checks boundaries and runs `能力资产/tools/scripts/check-operating-system.ps1`, using the current P4a–P4t output.

⛔ Always one writer; no parallel writes: `状态.md` · `交接区/` · `CHANGELOG.md` · `元规则池.md` · `角色边界.md` · `子agent调度机制.md`.

## 4. Quick PM-to-agent mapping

- Project PM “Mimi” is not instantiated as a subagent; the main session retains global dispatch and acceptance.
- Writing PMs default to workers; read-only diagnostic PMs default to explorers. The Test and Release PM's release actions remain centralized and are not delegated.
- See the [appendix](子agent调度机制-附录.md) for all nine PM mappings, common uses, and write boundaries.

## 5. Required assignment fields

Every subagent brief must be self-contained:

- Role and task objective.
- Working directory, allowed reads, and allowed writes.
- Disjoint-write declaration.
- Prohibited actions.
- Inputs, completion criteria, and output format.

See the [full template](子agent调度机制-附录.md).

## 6. Main-session acceptance duties

When a subagent returns, the Project PM must:

1. Read its changes or findings.
2. Check for permission violations.
3. Run necessary tests and health checks.
4. Decide in the main session whether to accept, correct, or revert the work.
5. Centrally finalize publication, status, handoff, and PM transition records.
6. State in the final seven-part chat handoff whether agents were actually instantiated.

## 7. Execution rule

> **Except for the Project PM's main session, each PM's actual work defaults to a real agent instance: worker for writes, explorer for read-only work**. For single-source files that prohibit parallel writes, agents **draft** and the main session **performs the final write**. Release actions remain centralized and are not delegated. **No nested autonomous dispatch: workers do not spawn subagents; they return requests for help so the Project PM can dispatch peers. Acceptance always remains with the Project PM**. Project PM “Mimi” retains **exclusive dispatch and acceptance authority: spawn authority is not delegated and individual PMs do not spawn autonomously**, and is accountable for both dispatch and results.

## 8. Related documents

- [Dispatch appendix](子agent调度机制-附录.md): background, complete mapping, B-lite history, and capability assets.
- [Role boundaries](角色边界.md): nine-PM path allowlists.
- [Tool matrix](工具载体矩阵.md): decouple PM roles from tools.
- [Agent entry point](../02_智能体/README.md): nine PM playbooks.
- [Decision checkpoint](../07_完整工作流/decision-checkpoint.md): Q1–Q7 at role transitions, including agent-instantiation decisions.
- [Capability agents](../../能力资产/agents/README.md): reusable execution-agent assets.
