---
name: 操作系统pm-框架管家-readme
scope: pm-workspace
pm: 操作系统PM-框架管家
type: semantic
loaded: on-demand
description: "Operating System PM \"Framework Steward\" workspace entry point: decision layer and framework governance."
---

# Operating System PM "Framework Steward": Meta-Memory Center

> 🌱 **New placeholder** (2026-05-21 / issue CM): quick references will be developed through practice.

## Role definition

See the [Operating System PM playbook](../../操作系统/02_智能体/操作系统PM-框架管家.md).

## Path allowlist

| Category | Path |
|---|---|
| Primary responsibility | `操作系统/` + `能力资产/`, including `能力资产/tools/` |
| Collaboration | `确认改动/` + `交接区/` + `Docs/3-开发文档/` + `Docs/7-复盘/` |
| Project root framework | `AGENTS.md` / `README.md` / `状态.md` / `TASKS.md` |
| Prohibited | ❌ Absolute boundary around `{{APP_REPO_DIR}}/**` / ❌ Other PMs' private workspaces, such as `PM工作区/项目PM-咪咪/` |

## Quick references to develop

Create a quick-reference file when the same PM self-correction pattern occurs a third time. Current candidates:

- Issue CL: cleanup of remaining cross-references, informed by 12+343 residual references after PROP-029 v2.
- Issue CK: prevent decay of the `状态.md` tracking mechanism, including the 130→60KB split.
- Candidate meta-rules 10/11: short chat handoff deduplication and evidence-based acceptance criteria.

## Practice reviews to develop

- PROP-029 v2 physical split, `agent/` → `操作系统/` + `能力资产/`: 2026-05-21.
- PROP-028 framework completeness, six ledger/tool-governance documents: 2026-05-21.
- `状态.md` split, 130→60KB: 2026-05-21.

## PM self-corrections to collect

- **#59** (2026-05-21): the Operating System PM overstepped into the Project PM's workspace by proposing to move `项目PM/` into `操作系统/05_记忆/`; zlbdh rejected it, and `角色边界.md` was strengthened.
- **#56** (2026-05-20): the Operating System PM failed to identify inappropriate storage of framework assets outside the project early enough.

📌 This directory is maintained by the **Operating System PM**. Other PMs must not reorganize it: PM self-correction #59.
