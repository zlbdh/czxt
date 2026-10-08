---
name: agents-entry
scope: project
type: semantic
loaded: always
description: Five-second AGENTS guide for every new session. Full rules are in 操作系统/00_总入口.md.
---

# {{PROJECT_NAME}} — AGENTS Entry Point

> Read this at the start of every session. Full rules are in `操作系统/00_总入口.md`; this file is a **five-second guide**.

## Five startup steps

Before beginning work in any session:

1. Read `状态.md` for the cross-session snapshot.
2. Read `操作系统/00_总入口.md` for the eight numbered operating system modules (00–07) and capability assets entry point.
3. Read `操作系统/01_架构/角色边界.md` for the nine PM roles across the lead, meta, decision, and implementation layers, plus their path allowlists.
4. Read the latest file in `交接区/待接手/`, if present.
5. Run the [project health check](能力资产/skills/项目体检.md): the framework checks and Q1–Q7 self-check.

Route borrowing, reference, and benchmarking requests through the [borrowing skill](能力资产/skills/借鉴.md). Its execution rules are not duplicated here.

## Nine-PM matrix reference

Final v4.0 model, May 22, 2026:

| Layer | Roles |
|---|---|
| Lead (1) | Project PM “Mimi”: sole external identity; PM self-correction #63 |
| Meta (1) | Knowledge PM “Curator”: issue AJ and meta-rule pool governance |
| Decision (5) | Operating System, Product, Technical, Test, and Operations PMs |
| Implementation (2) | Development PM “Implementer” and Test and Release PM “Closer”; their tools are replaceable |

PM roles represent stable responsibilities; tools are replaceable execution environments. See the [tool matrix](操作系统/01_架构/工具载体矩阵.md).

The [meta-rule pool](操作系统/01_架构/元规则池.md) is the single source of truth for current permanent and candidate rule counts.

## Required checks before sensitive actions

For any item below, first search the Class C section (`### ❌ C 类`) in `操作系统/01_架构/三类行为铁律.md`. Do not rely on memory.

- `git commit` or `git push`: conditional Class B actions with six requirements; see ADR-016.
- Changing `package.json` version: Class B when paired with an APK release task.
- Disclosing real secrets, committing them to tracked files, or deleting user data: Class C, never perform. Local `baseUrl`, `model`, and `apiKey` configuration in `{{APP_REPO_DIR}}/.env.local` is subject to the Class B safeguards in ADR-022 and the three-class behavior rules.
- Framework files in `操作系统/`, `能力资产/`, `Docs/`, `确认改动/`, or `交接区/`.
- Template productization files in `项目区/`, `项目配置/`, the root `README.md`, or `实例化项目.ps1`.

Historical lesson: changing version 2.3 to 2.7 violated the then-applicable Class C rule (PROP-012, signal 3). Always check the current rule.

## File-size rules

PROP-013 and ADR-017 define guidance by tool:

| Tool | Guideline | Action |
|---|---|---|
| Cowork, where mounts may truncate | 6,500 bytes | Above this size, write with Python or Bash instead of Edit |
| Claude Code / Codex | 8 KB | Files below 8 KB are generally safe; consider splitting larger files by responsibility |
| All tools | Decisions based on Bash `wc -c` | Verify with the Read tool; see PROP-013, RETRO-005 card 2, and the first PROP-014 P3 trial |

Applies to `{{APP_REPO_DIR}}/src/`, `操作系统/`, and `能力资产/`. Documentation in `Docs/` and historical archives is exempt.

## Cross-role collaboration

Every completed implementation task must include the seven-part chat handoff below (PROP-014 / ADR-018, requirement 3):

```text
[Task: from role A to role B]
1. Time: YYYY-MM-DD HH:MM
2. Changes: N new / M modified files, including commit hash
3. Tests: vitest PASS N/N | esbuild PASS | build PASS | APK pending | smoke pending | push pending
4. Your next steps: [1] ... [2] ... [3] ...
5. Status: pass / warning / failure
6. Details: read 交接区/待接手/...md
7. PM role transitions: N rows added this session in 状态.md at line <line>; PROP-027 v2 requirement
```

Report actual results; the example is a format, not evidence of passing checks. A summary paragraph cannot replace this handoff. See the [handoff format](操作系统/03_交接/交接卡格式.md).

## Process-first triage

When implementation exposes a process problem, use the three levels in PROP-014 / ADR-018:

| Severity | Action |
|---|---|
| Blocking | Stop, open a governance PROP, fix the problem, then continue |
| Nonblocking bug | Continue the business task and add the issue to the RETRO backlog |
| Improvement opportunity | Continue the business task and discuss it at the next RETRO |

## Project-specific conventions

- This directory is the operating system template root. Its remote is `https://github.com/zlbdh/czxt.git`.
- The template root may be an independent Git repository. Initialized projects use their explicit project cards to define repository boundaries.
- Application code belongs in each project's `{{APP_REPO_DIR}}/` subdirectory. The template root contains no application code.
- `项目区/` holds local project instances or trial installations. Actual project content is excluded from template commits by default.
- The template repository keeps only `_模板.project.json` in `项目配置/`. Concrete project cards normally belong in the local project directory or `项目区/本地实例/<project>/`. A directory name alone does not establish project status.
- Four records track evolution: PROP for substantial proposals, ADR for decisions, RETRO for retrospectives, and `操作系统/00_变更记录/CHANGELOG.md` for smaller changes.

## Framework reference

- [Eight operating system modules](操作系统/00_总入口.md)
- [Current PROP status](确认改动/README.md)
- [ADR index](Docs/3-开发文档/adr/README.md)
- [Current RETRO](Docs/7-复盘/README.md)
- [Framework changelog](操作系统/00_变更记录/CHANGELOG.md)

Keep this entry point minimal. Detailed rules belong in `操作系统/` and `能力资产/`. Before adding content, consider whether a new tool can still understand this entry point quickly.
