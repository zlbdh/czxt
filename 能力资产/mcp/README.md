---
name: mcp-config-index
scope: project
type: semantic
loaded: on-demand
description: 能力资产/mcp/ MCP/连接器能力索引；INSTALLED.md 为项目侧能力声明单一信息源
---

# 能力资产/mcp/ — MCP / 连接器能力声明

## 这一组讲什么

MCP（Model Context Protocol）/ 连接器 / plugin 的项目侧能力声明 + 用途说明。

## 当前状态

✅ **已填实** — [`INSTALLED.md`](INSTALLED.md) 是项目 MCP / 连接器能力声明单一信息源。Cowork / Codex / Claude Code 的真实安装仍由各客户端管理，本目录只记录项目侧需要什么能力、历史用过什么能力、接入新能力时的注意事项。

## 持续维护内容

- 继续维护 [`INSTALLED.md`](INSTALLED.md) 的核心 / 按需 / 未用能力矩阵。
- 如出现 MCP 能执行敏感动作（写文件 / git / 外部发送），补到 `操作系统/01_架构/三类行为铁律.md` 的 A/B/C 分级边界；常规 commit / push 按 ADR-016 B 类，force push / rebase / 删 tag / GitHub Release 等仍按 C 类。

## 何时更新（触发条件）

满足任一条 → 立刻更新 [`INSTALLED.md`](INSTALLED.md) 并视影响更新本索引：

- ✅ 第一次接入新 MCP（Slack / GitHub / Linear 等业务 MCP）
- ✅ 第一次出现 MCP 相关 bug 影响开发流程
- ✅ MCP 跟 AI 边界有冲突（如常规 git push 属 B 类，force push / rebase / 删 tag / Release 属 C 类）
- ✅ 多个 session 用了不同 MCP 配置导致结果不一致

任何上面 4 条触发 → 立刻补 MCP 服务器清单 + 用途 + 边界。

## 跟其他分组的区别

- **mcp/**：能力声明（项目需要哪些 MCP / 连接器 / plugin、何时用、是否需现场核验）
- 其他分组：行为约定
