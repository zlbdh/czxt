---
name: capability-agents-index
scope: project
type: semantic
loaded: on-demand
description: 能力资产/agents/ 执行型 agent 索引（PROP-029 v2 预留 / 当前空目录）
---

# 能力资产/agents · 执行型 agent（预留）

> ⚠️ **当前空目录** — PROP-029 v2 物理拆分时预留
> 当前可用 runtime 子 agent 能力由项目 PM「咪咪」统一派 worker / explorer；spawn 权与验收权不下放，各 PM 不自治开 agent。本目录只收录沉淀后的可复用执行型 agent 资产，具体载体以工具载体矩阵为准。

## 与操作系统/02_智能体/ 区别

- **操作系统/02_智能体/**：9 PM 角色 playbook（项目 PM、沉淀 PM、5 决策 PM、开发 PM、测试发布 PM）— 协作编排；详见 [`02_智能体/README.md`](../../操作系统/02_智能体/README.md)
- **能力资产/agents/**（本目录）：未来执行型 agent — 单功能可调用（如自动测试 agent / 自动 grep agent 等）
- **runtime 子 agent**：一次性执行实例，由项目 PM「咪咪」按 [`操作系统/01_架构/子agent调度机制.md`](../../操作系统/01_架构/子agent调度机制.md) 统一派工，不自动沉淀进本目录

## 未来扩展条件

当出现「频繁手动重复 + 单功能 + 可标准化」的工作时，考虑入此目录。

沉淀执行型 agent 前必须先过 `decision-checkpoint` Q1-Q7 与三类行为铁律；涉及 commit / push / tag / version / API key / baseUrl / 用户数据删除 / 发布闭环时，本目录只沉淀检查、草稿或辅助诊断，不沉淀自动执行高风险动作的 agent。

议题 backlog 候选监控：议题 CC 已升 ADR-030 / 第 13 元规则；后续可沉淀「单测真机路径 verify agent」。
