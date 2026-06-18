---
name: capability-workflows-index
scope: project
type: semantic
loaded: on-demand
description: 能力资产/workflows/ 执行型 workflow 索引（PROP-029 v2 预留 / 当前空目录）
---

# 能力资产/workflows · 执行型 workflow（预留）

> ⚠️ **当前空目录** — PROP-029 v2 物理拆分时预留

## 与操作系统/07_完整工作流/ 区别

- **操作系统/07_完整工作流/**：协作流（decision-checkpoint / 实施循环-DoD / 审批与归档 等）— PM 决策类
- **能力资产/workflows/**（本目录）：未来执行型 workflow — 自动化执行链（如 ship 前检查链 / 发布门禁编排草稿 / 自动 RETRO 起稿链等）

## 未来扩展条件

当出现「同样的执行序列 ≥ 5 次 / 步骤固定 / 可脚本化」时，考虑入此目录。

沉淀前先过 [`decision-checkpoint`](../../操作系统/07_完整工作流/decision-checkpoint.md) Q1-Q7 与三类行为铁律；涉及 version bump、commit、tag、push、release 分发、密钥、baseUrl、用户数据删除等敏感动作时，只沉淀检查清单或草稿链，不沉淀自动执行链。发布闭环仍由测试发布 PM「闭环者」主会话按 ADR-016 单点收口。
