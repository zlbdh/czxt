---
name: tools-governance-index
scope: project
type: semantic
loaded: on-demand
description: 工具治理入口 — hooks / 体检 / 工具治理方案 / 历史研究档案
---
# 06_工具治理 · 工具治理层

> hooks / 体检 / 终态愿景 / 记忆治理 / 改进研究的入口；防 framework 长 session 衰减，也记录工具能力边界。

| 文件 | 内容 |
|---|---|
| [framework体检.md](framework体检.md) | 历史体检入口指针；当前正式入口见 `能力资产/skills/项目体检.md` + `check-operating-system.ps1` |
| [hooks-设计.md](hooks-设计.md) | hooks 设计主文：设计判断、分层、自动写入边界、验证入口 |
| [hooks-事件矩阵.md](hooks-事件矩阵.md) | hooks 事件矩阵主文：manifest / Codex / Claude 事件集与计数锚点 |
| [hooks-事件矩阵-附录.md](hooks-事件矩阵-附录.md) | hooks 事件矩阵附录：watch/scheduled 细节、运行时适配差异、暂未接事件 |
| [操作系统终态愿景-v4.0-2026-05-21.md](操作系统终态愿景-v4.0-2026-05-21.md) | v4.0 终态愿景历史蓝图入口；原文在 `历史归档/2026-05/` |
| [操作系统全景图-2026-05-21.md](操作系统全景图-2026-05-21.md) | 2026-05-21 全景快照残篇入口；残篇在 `历史归档/2026-05/` |
| [操作系统改进研究-2026-05-21.md](操作系统改进研究-2026-05-21.md) | 操作系统改进研究历史档案入口；原文在 `历史归档/2026-05/` |
| [记忆治理方案-2026-05-22.md](记忆治理方案-2026-05-22.md) | 项目记忆治理历史方案入口；原文在 `历史归档/2026-05/` |
| `历史归档/2026-05/` | 2026-05 历史原文/残篇归档；不参与 P4b/P4c/P4o 活跃体检，P4q 只守首屏历史边界与残篇声明 |

## 跑法
1. 切操作系统 PM 帽子 + decision-checkpoint
2. 先跑 `能力资产/tools/scripts/check-operating-system.ps1`
3. 再按需补跑 `能力资产/tools/scripts/check-readme-indexes.ps1`、`能力资产/tools/scripts/check-handoff-zone.ps1`、`能力资产/tools/hooks/tests/hooks-smoke.ps1`
4. 输出结论 + 状态.md 留痕；仅有软警告则进 RETRO backlog，硬失败先修再继续

## 维护
- 新增检查项必更新 `能力资产/skills/项目体检.md`、`能力资产/tools/scripts/check-os/check-plan.ps1` / `check-plan-assert.ps1`，以及对应 `能力资产/tools/scripts/check-os/` 子模块说明
- 新增 hooks / watch / scheduled 能力必同步 hooks-设计.md、hooks-事件矩阵.md / 附录与 hooks README
- 责任：操作系统 PM「框架管家」
