---
name: appdata-memory-retired-list
scope: project
type: semantic
loaded: on-demand
description: Retired AppData memory files — new sessions no longer depend on them; use memory entry points inside the project.
---

# Retired AppData Memory Files

> Main entry: [INDEX.md](INDEX.md). AppData memory is retained only for historical records and external pointers; it is not authoritative for project facts.

## Version and maintenance

- **v1, 2026-05-20**: migrated the enhanced C version out of AppData memory and unified the source of truth at `操作系统/05_记忆/INDEX.md`.
- **Owner**: Project PM “Mimi” coordinates. Switch to Operating System PM “Framework Steward” for memory-framework writes. Update the project memory entry points with each RETRO, permanent-rule promotion, or PM self-correction.
- **Fallback pointer**: retain AppData `MEMORY.md` as a pointer to this INDEX. Tools that read AppData across conversations must return to authoritative sources inside the project.

## Retired paths: preserve as history, do not delete

The following 15 AppData memory files are for traceability only. This is not an execution or deletion list, and new conversations no longer depend on these files.

Base directory:

```text
AppData\Roaming\Claude\local-agent-mode-sessions\...\spaces\...\memory\
```

| Historical filename | Project source |
|---|---|
| `user_zlbdh.md` | INDEX section 1: zlbdh's preferences. |
| `feedback_mount_8kb.md` | `行为反思.md`, reflection 5: 8KB Edit behavior. |
| `feedback_recommend_explicit.md` | INDEX section 1: decision preferences. |
| `feedback_pm_no_default_inference.md` | `行为反思.md`, reflection 1. |
| `feedback_pm_verify_ui_first.md` | `行为反思.md`, reflection 2. |
| `feedback_prompt_concise.md` | `行为反思.md`, reflection 3. |
| `project_{{PROJECT_SLUG}}.md` | INDEX section 1: current project identity, and `项目历史指针.md`. |
| `project_{{APP_REPO_DIR}}_workflow.md` | `项目历史指针.md`: workflows and roles. |
| `project_{{APP_REPO_DIR}}_ai_model.md` | `项目历史指针.md`: brand-dictionary pointer. |
| `project_{{APP_REPO_DIR}}_sprint5_milestone.md` | `项目历史指针.md`: RETRO-009 pointer. |
| `project_{{APP_REPO_DIR}}_pm_self_correction_51_52.md` | `项目历史指针.md`: PM self-correction series. |
| `project_{{APP_REPO_DIR}}_issue_bw_critical.md` | `项目历史指针.md`: issue BW pointer. |
| `project_{{APP_REPO_DIR}}_mimo_thinking_max_tokens.md` | `项目历史指针.md`: self-correction #53, empty responses from MiMo thinking max_tokens. |
| `project_{{APP_REPO_DIR}}_git_branch_main.md` | `项目历史指针.md`: Git branch main, not master; issue BK. |
| `project_{{APP_REPO_DIR}}_pm_self_correction_54.md` | `项目历史指针.md`: self-correction #54. |
