---
name: agent-readme-history
scope: project
type: episodic
loaded: on-demand
description: 历史档案 — 旧 agent/ 目录时代的 AI 协作中心 README（5 大分组说明，已被现行操作系统结构替代）
---

# agent/ — AI 协作中心

> ⚠️ **历史安全边界**：正文只作追溯，不代表当前执行流程，不可直接复制执行；涉及旧路径、旧命令、API key 或交接格式时，回到现行 `操作系统/` + `能力资产/` 真源重判。
> 历史快照：本文保留旧 `agent/` 时代 README 原貌，文内“当前/唯一入口”等表述指 2026-05 当时，不代表现行入口。配套旧 INDEX 见 [`agent-INDEX-历史.md`](agent-INDEX-历史.md)。
> 原文冻结快照：下方原文内链接是旧路径样本，不维护为当前可点击入口；当前入口见 [`../00_总入口.md`](../00_总入口.md)。

⭐ **入口**：[INDEX.md](INDEX.md) — 任务 → 该读哪些规则

## 这是什么

所有 AI 协作相关内容（角色 / 技能 / 流程 / 规则 / 配置）的唯一维护点。
不在这里的都不是 AI 协作约定。

## 5 大分组

| 分组 | 装什么 |
|---|---|
| [agents/](agents/) | AI 角色 playbook（PM / Dev / QA / AI 边界） |
| [skills/](skills/) | 单一能力操作脚本（出 APK / 跑测试） |
| [workflows/](workflows/) | 多步骤流程（改动循环 / 审批归档 / 需求接收 / 发布 / git） |
| [rules/](rules/) | 真规则（写代码 / 写 PRD / 视觉规范 / 已知约束 / 安全） |
| [mcp/](mcp/) | MCP 服务器配置 |

## 跟其他顶层目录的边界

| 目录 | 装什么 | 跟 agent/ 的关系 |
|---|---|---|
| `agent/` | AI 协作约定 | 本身 |
| `Docs/` | 业务 / 技术 / 测试 / 运维 / 复盘文档 | agent/ 是规则，Docs/ 是业务 |
| `{{APP_REPO_DIR}}/` | React + Capacitor 代码 | agent/ 不动代码 |
| `确认改动/` | PROP 档案库 | agent/workflows/审批与归档.md 管 PROP 流转 |
| `apk/` | APK 归档 | agent/skills/出APK.md 管打包 |
| `.github/` | GitHub Actions | agent/skills/出APK.md 管 CI 部分 |

## 历史命名

2026-05-08 ADR-003 曾把所有 AI 协作内容塞进 `rules/`，但 rules 这个名字承担不了 agents/skills/workflows 的语义。
2026-05-09 PROP-004 / ADR-007 重构为 `agent/` 按语义 5 分类。

详见 [`Docs/3-开发文档/adr/ADR-007-...md`](../Docs/3-开发文档/adr/ADR-007-rules目录按语义重构为agent.md)。
