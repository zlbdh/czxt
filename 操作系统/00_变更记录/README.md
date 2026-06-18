---
name: changelog-index
scope: project
type: semantic
loaded: on-demand
description: 变更记录目录索引 — CHANGELOG + 状态-archive 归档
---
# 00_变更记录 · Framework 演进日志

> 轻量演进记录（区别于重的 PROP / ADR / RETRO）
> 除 `CHANGELOG.md` 外，本目录的 `CHANGELOG-2026*`、`agent-*历史.md`、`状态-archive/` 都是历史追溯材料，不作为当前执行流程或当前真相源。

| 文件 | 内容 |
|---|---|
| [CHANGELOG.md](CHANGELOG.md) | 当前 framework 变更日志（滚动近况，接近 6500B 即切档） |
| [CHANGELOG-2026-06-16-较早条目.md](CHANGELOG-2026-06-16-较早条目.md) | 2026-06-16 较早条目归档，仅追溯 |
| [CHANGELOG-2026-06-15-较早条目.md](CHANGELOG-2026-06-15-较早条目.md) | 2026-06-15 较早条目归档，仅追溯 |
| [CHANGELOG-2026-05-21至06-14-较早条目.md](CHANGELOG-2026-05-21至06-14-较早条目.md) | 2026-05-21 至 2026-06-14 较早条目归档，仅追溯 |
| [CHANGELOG-2026H1.md](CHANGELOG-2026H1.md) | 2026 上半年早期归档，仅追溯 |
| [agent-INDEX-历史.md](agent-INDEX-历史.md) / [agent-README-历史.md](agent-README-历史.md) | PROP-029 v2 拆分前 agent/ 顶层文件历史快照，仅追溯 |
| [状态-archive/](状态-archive/) | `状态.md` 历史归档切片，仅追溯 |

## 写入规则
- 小改动（< 1KB）入本目录
- 重大决策 → ADR
- 提议 → PROP
- 复盘 → RETRO
- 入口顺序见 [项目结构.md](../../Docs/3-开发文档/项目结构.md)

## 维护
- 责任：操作系统 PM「框架管家」
