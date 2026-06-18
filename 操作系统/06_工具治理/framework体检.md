---
name: framework-health-check-legacy-pointer
scope: project
type: semantic
loaded: on-demand
description: Framework 体检历史指针 — 当前正式入口已迁到 能力资产/skills/项目体检.md 与 check-operating-system.ps1
---

# Framework 体检 · 历史指针

> 本文件是 2026-05-21 早期 O-4 / PROP-029 v2 的历史入口，保留作溯源。
> **当前正式体检入口**：[`能力资产/skills/项目体检.md`](../../能力资产/skills/项目体检.md)。
> **当前自动体检脚本**：[`能力资产/tools/scripts/check-operating-system.ps1`](../../能力资产/tools/scripts/check-operating-system.ps1)。

## 当前跑法

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-operating-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-readme-indexes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-handoff-zone.ps1
```

随后按起手链路单独跑 [`decision-checkpoint`](../07_完整工作流/decision-checkpoint.md) Q1-Q7；Q1-Q7 不内嵌在脚本里。

完整阈值、报告模板、10 类体检主题、Q1-Q7 自检关系与 P4a-P4s 自动守卫，以 [`能力资产/skills/项目体检.md`](../../能力资产/skills/项目体检.md) 为准。

## 为什么不再维护旧清单

- 旧版是“手动轻量体检”阶段产物，覆盖范围已经落后。
- 当前体检已经纳入 P4a-P4s：基础完整性、文件大小、framework 引用频率、状态新鲜度、mount 缓存提醒、PM 轨迹、README/索引一致性、版本/Sprint、治理计数、旧口径守卫、分支策略、skills 命令新鲜度、PM 工作区入口对齐、活跃 Markdown 链接/锚点、能力资产剩余区、治理语义锚点、hooks 配置/运行态锚点和模板纯净度。P4o 同时桥接进 `check-readme-indexes.ps1`，让 PostToolUse 快检能在编辑后发现断链。
- 为避免双源漂移，本文件只保留指针，不再复制阈值和检查项正文。

## 版本

- v1（2026-05-21 / PROP-029 v2）— 早期手动体检入口。
- v2（2026-06-14）— 降级为历史指针，正式入口迁到 `能力资产/skills/项目体检.md` 与 `check-operating-system.ps1`。
