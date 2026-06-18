---
name: appdata-memory-retired-list
scope: project
type: semantic
loaded: on-demand
description: AppData memory 退役清单 / 新会话不再依赖 / 项目目录记忆入口指针
---

# AppData memory 退役清单

> 主入口：[`INDEX.md`](INDEX.md)。AppData memory 仅保留历史归档和外部指针，不作为项目真相源。

## 版本与维护

- **v1**（2026-05-20）— C 强化版从 AppData memory 迁出，统一单一信息源到 `操作系统/05_记忆/INDEX.md`
- **维护责任**：项目 PM「咪咪」统筹；涉及记忆 framework 时切操作系统 PM「框架管家」落笔。每次 RETRO / 议题永久化 / PM 自纠时同步项目内记忆入口。
- **冗余保护**：AppData `MEMORY.md` 保留为指针文件（指向本 INDEX），跨对话工具若读取 AppData，也应回到项目目录真源

## 退役路径（历史归档，不删除）

以下 15 个 AppData memory 文件仅作溯源，不作为执行/删除清单；新对话不再依赖：

```text
AppData\Roaming\Claude\local-agent-mode-sessions\...\spaces\...\memory\
  user_zlbdh.md               → INDEX §一 zlbdh 偏好
  feedback_mount_8kb.md       → 行为反思.md 反思 5 Edit 8KB
  feedback_recommend_explicit.md → INDEX §一 zlbdh 决策模式
  feedback_pm_no_default_inference.md → 行为反思.md 反思 1
  feedback_pm_verify_ui_first.md → 行为反思.md 反思 2
  feedback_prompt_concise.md  → 行为反思.md 反思 3
  project_{{PROJECT_SLUG}}.md → INDEX §一 当前项目身份 + 项目历史指针.md
  project_{{APP_REPO_DIR}}_workflow.md    → 项目历史指针.md 工作流与角色
  project_{{APP_REPO_DIR}}_ai_model.md    → 项目历史指针.md 品牌词典指针
  project_{{APP_REPO_DIR}}_sprint5_milestone.md → 项目历史指针.md RETRO-009 指针
  project_{{APP_REPO_DIR}}_pm_self_correction_51_52.md → 项目历史指针.md PM 自纠系列
  project_{{APP_REPO_DIR}}_issue_bw_critical.md → 项目历史指针.md 议题 BW 指针
  project_{{APP_REPO_DIR}}_mimo_thinking_max_tokens.md → 项目历史指针.md PM 自纠 #53 / MiMo thinking max_tokens 空回复
  project_{{APP_REPO_DIR}}_git_branch_main.md → 项目历史指针.md git main 分支（不是 master / 议题 BK）
  project_{{APP_REPO_DIR}}_pm_self_correction_54.md → 项目历史指针.md PM 自纠 #54
```
