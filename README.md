---
name: czxt-readme
scope: project
type: semantic
loaded: always
description: Product overview and project initialization entry point for the czxt operating system template. Read AGENTS.md when starting a session.
---

# Project Collaboration Operating System Template (czxt)

> Keep the operating system consistent; replace the project.

> **Getting started or starting a new session:** Read [AGENTS.md](AGENTS.md), the five-second guide, and follow its startup sequence to the [operating system entry point](操作系统/00_总入口.md).

This repository contains a project collaboration operating system distilled from project work and maintained in [zlbdh/czxt](https://github.com/zlbdh/czxt).

It currently consists of a source template, a project initialization script, and a local project area. An npm package, installer, and CLI are not yet available.

The collaboration model uses nine PM roles across four layers: lead, meta, decision, and implementation.

Current productization status: **P1 complete; P2 incomplete**. One self-hosted trial has been documented. P2 requires successful trials and health checks for at least two independent project cards. The [project registry](项目区/清单.md) currently has no registered projects; the first self-hosted trial does not establish that multiple project trials are complete.

## Shared governance layers

The template retains these governance layers:

| Directory | Responsibility |
|---|---|
| `操作系统/` | Role boundaries, Q1–Q7, handoffs, ledgers, memory, tool governance, and end-to-end workflows |
| `能力资产/` | Rules, skills, tools, hooks, MCP, agents, and workflows |
| `PM工作区/` | Workspaces and reference sheets for the nine PM roles |
| `交接区/` | Cross-role handoff queue |
| `确认改动/` | PROP state machine and templates |
| `Docs/3-开发文档/` and `Docs/7-复盘/` | ADR and RETRO governance entry points |
| `.codex/` and `.claude/` | Runtime hook configuration templates |
| `项目配置/` | Project card template; only `_模板.project.json` belongs in the template repository |
| `项目区/` | Local project instances and trial installations; actual project content is excluded by default |
| `借鉴区/` | External evidence: sources and lessons learned; execute through the [borrowing skill](能力资产/skills/借鉴.md) |

Project-specific values are placeholders. The initialization script, `实例化项目.ps1`, automatically replaces every occurrence of the following placeholders. Unresolved placeholders are expected in the template root; do not replace them manually.

| Placeholder | Meaning |
|---|---|
| `{{PROJECT_ROOT}}` | Project root, such as `D:\Projects\ExampleProject` |
| `{{PROJECT_ROOT_POSIX}}` | Forward-slash path used in hooks and JSON |
| `{{PROJECT_NAME}}` | Project name |
| `{{APP_REPO_DIR}}` | Directory containing the application repository |
| `{{APP_ID}}` | Application package name or ID; set with `-AppId`, otherwise derived from the project name |
| `{{PROJECT_SLUG}}` | Project slug; set with `-ProjectSlug`, otherwise derived from the project name |
| `{{CURRENT_VERSION}}` | Current version anchor |
| `{{CURRENT_SPRINT}}` | Current sprint anchor |
| `{{INIT_TIME}}` | Initialization time |

## Local project area

`项目区/` holds project instances managed by this template or used for trial installations. It establishes where the template ends and each project begins:

- The template itself belongs in the `czxt` repository.
- Project instances belong in `项目区/本地实例/` or their own project directories.
- `.gitignore` excludes project instances by default.
- The template repository tracks `_模板.project.json`, the project registry at `项目区/清单.md`, and related rules. Keep concrete project cards in a local project directory or `项目区/本地实例/<project>/`.

## Initialize a project

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Projects\czxt\实例化项目.ps1 `
  -ProjectRoot D:\Projects\NewProject `
  -ProjectName NewProject `
  -AppRepoDir app `
  -CurrentVersion v0.1.0 `
  -CurrentSprint Sprint-1
```

Existing files are preserved by default. Add `-Force` explicitly when you intend to overwrite them.

The script copies the shared governance layers, project card template, and project-area structure, then creates these minimal project entry points:

- `TASKS.md`
- `Docs/1-需求文档/README.md`
- The application repository directory, `{{APP_REPO_DIR}}/`

Run `能力资产/tools/scripts/check-operating-system.ps1` for the initial project health check, then add the actual requirements, code, and project card.

After initialization, start in the new project root using [AGENTS.md](AGENTS.md): read the state file, operating system entry point, role boundaries, and decision checkpoint, then run the project health check.

## GitHub connection

Template repository:

```text
https://github.com/zlbdh/czxt.git
```

The initial P1 commit has been published. Subsequent commits and pushes remain subject to the Class B conditions in the [three-class behavior rules](操作系统/01_架构/三类行为铁律.md) and [Git workflow](操作系统/07_完整工作流/git流程.md). Establish synchronization with the remote from a fresh `git fetch`; a local tracking branch alone is insufficient evidence.

See the [productization roadmap](操作系统/04_台账/长期产品化路线图.md).

## Current boundaries

- This directory is the template root and may itself be the `czxt` repository. It is not an application project root.
- Application code, actual requirements, release artifacts, secrets, and user data do not belong in the operating system template.
- Actual projects may be stored in `项目区/本地实例/`, which is excluded from commits by default.
- `能力资产/tools/hooks` remains the source of truth for hooks; runtime configuration adapts those entry points.
- The template retains lessons from earlier governance work. After initialization, copy `项目配置/_模板.project.json` to a local location within the project and fill in its actual configuration.
