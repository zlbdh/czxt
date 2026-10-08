---
name: project-memory-index
scope: project
type: semantic
loaded: always
description: Project memory index for new sessions and multiple runtimes; the single entry point for retired AppData memory pointers.
---

# Project Memory Index · Required for New Sessions

> **Single entry point**: start here for required cross-conversation context. AppData memory has been retired to pointers; authoritative project information belongs under `{{PROJECT_ROOT}}\`.
>
> **Startup trigger**: reach this file through `AGENTS.md` and `操作系统/00_总入口.md`. At a new conversation, PM takeover, Codex launch, or Claude Code launch, read this index and follow only the pointers relevant to the task.
>
> **Maintenance**: point project information to authoritative sources in `Docs/`, `操作系统/`, and `能力资产/`. Keep frequent-use entry points here; do not duplicate long historical content.
>
> **Scope schema**: see [memory frontmatter](scope-schema.md).

---

## 1. User identity and preferences

### zlbdh: project owner and developer

- **Language**: converse with zlbdh in Chinese. Maintained project documentation, plans, and commit messages use English, following the current localization instruction.
- **Decisions**: when presenting options, state a clear recommendation with one to three reasons. Avoid tentative phrasing such as “I bet” or “I lean toward”.
- **PM working style**: make appropriate decisions and keep progressing; do not ask zlbdh to choose every minor detail.
- **Visual preferences**: Mimi's literary UI style, cherry-pink palettes, and a gentle, restrained tone.
- **Private boundary**: Mimi's Diary is a private project. Do not bring it into other work unless zlbdh raises it.
- **Role**: zlbdh is the final decision maker, code author, and physical-device smoke-test verifier.

### Current project identity

- **Project**: {{PROJECT_NAME}}, package `{{APP_ID}}`; fill the subtitle from the project instance.
- **Code path**: `{{PROJECT_ROOT}}\{{APP_REPO_DIR}}\`.
- **Current version**: use the top snapshot in `状态.md`, `{{APP_REPO_DIR}}/package.json`, and the latest accepted ship card. Read any in-flight card in `交接区/待接手/` first.
- **Branch**: `main`, not master.
- **AI and branding**: providers, models, endpoints, and compliance conclusions come from the project instance source of truth. See the [brand dictionary](../../能力资产/shared/品牌词典.md) for generic terminology and protocol/model-layer boundaries. The template does not assume a particular brand, model, or compliance conclusion.

---

## 2. Behavioral reflection entry points

The detailed content lives in [behavioral reflections](行为反思.md). Load sections according to the task:

| Trigger | Required reflection |
|---|---|
| Inferring code, API, or model state | 1: verify first; do not assume. |
| Deciding UI, tabs, routes, or module entry points | 2: verify actual code first. |
| Writing execution prompts for Codex or Claude Code | 3: keep prompts minimal; put details in the handoff card. |
| Creating a handoff or ship card | 4: verification checklist. |
| Editing files above 6500B in Cowork or above 8KB in Codex/Claude | 5: large-file write risks. |
| Finding project data, configuration, or state outside the project | 6: misplaced framework storage. |
| Switching PM roles, working a long session, or delivering results | 7: prevent PM-transition recording from fading. |

---

## 3. Important project-history entry points

Early examples live in [project-history pointers](项目历史指针.md). For current decisions, prioritize authoritative sources:

| Information | Authoritative source |
|---|---|
| Current snapshot and pending handoffs | [Status](../../状态.md) and `交接区/待接手/`. |
| Sprint and requirements history | [Requirements](../../Docs/1-需求文档/). |
| Complete ADR index | [ADR index](../../Docs/3-开发文档/adr/README.md). |
| Complete RETRO index | [RETRO index](../../Docs/7-复盘/README.md). |
| Permanent meta-rule pool | [Meta-rule pool](../01_架构/元规则池.md). |
| PMs, agents, and role boundaries | [Agent entry](../02_智能体/README.md) and [role boundaries](../01_架构/角色边界.md). |
| Tool governance, hooks, and health checks | [Tool governance](../06_工具治理/README.md) and [hooks](../../能力资产/tools/hooks/README.md). |
| Project ledgers | [Ledger index](../04_台账/INDEX.md). |

---

## 4. Required checklist after reaching this file

1. Confirm that you reached this file through `AGENTS.md` and `操作系统/00_总入口.md`; reading it completes this step.
2. Read the top of [status](../../状态.md) and its latest PM-transition records.
3. Read the [main entry](../00_总入口.md) and [role boundaries](../01_架构/角色边界.md).
4. Read the latest card in `交接区/待接手/`, if present.
5. Run the relevant [project health checks](../../能力资产/skills/项目体检.md). Run automated gates before and after framework changes.
6. Verify the working tree with `git -C {{APP_REPO_DIR}} status --short --branch` (issue BK / ADR-025).
7. Load `PM工作区/<X-PM>/速查表/INDEX.md` according to the current task; do not load context indiscriminately.

---

## 5. Maintenance and retired pointers

- **Owner**: Project PM “Mimi” coordinates; switch to Operating System PM “Framework Steward” for memory-framework changes.
- **Version source**: do not hardcode current version or Sprint here. Read `状态.md`, `{{APP_REPO_DIR}}/package.json`, and the completion card.
- **AppData memory**: retained only as pointers; no longer authoritative for project facts. See the [retirement list](AppData-memory退役清单.md).
- **New memory files**: add frontmatter according to the [scope schema](scope-schema.md), then link from this entry or the relevant README.
