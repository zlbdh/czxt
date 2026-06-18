---
name: dev-docs-index
scope: project
type: semantic
loaded: on-demand
description: 开发文档入口 — 当前代码真源 / 历史快照边界 / ADR 入口
---

# 开发文档入口

> 当前工程事实优先级：`{{APP_REPO_DIR}}/src/` 代码与 `{{APP_REPO_DIR}}/package.json` → `操作系统/` + `能力资产/` 规则 → 本目录文档。
> 本目录含早期开发文档，未全部按每次 ship 回填；遇到冲突时，以代码真源和操作系统为准。

## 当前可用入口

| 文档 | 口径 |
|---|---|
| [`adr/README.md`](adr/README.md) | ADR 索引，当前计数由 P4g/P4i 守卫 |
| [`技术栈.md`](技术栈.md) | 技术栈速查，版本以 `{{APP_REPO_DIR}}/package.json` 为准 |
| [`数据库schema.md`](数据库schema.md) | Dexie schema 索引；当前版本以 `{{APP_REPO_DIR}}/src/shared/database/schema.js` 为准 |
| [`项目结构.md`](项目结构.md) | 项目目录导航；细到文件级时以 `rg --files {{APP_REPO_DIR}}/src` 为准 |

## 历史参考

| 文档 | 说明 |
|---|---|
| [`开发流程.md`](开发流程.md) | 2026-05-08 早期流程快照；现行流程看 `操作系统/07_完整工作流/实施循环.md` |
| [`sprint-1-技术拆解.md`](sprint-1-技术拆解.md) | Sprint-1 历史拆解 |
| [`通用提示词-开发操作系统体检.md`](通用提示词-开发操作系统体检.md) / [`通用提示词-开发操作系统修正.md`](通用提示词-开发操作系统修正.md) | 早期跨项目提示词资产；当前内化版本在 `能力资产/skills/项目体检.md` |
| [`通用-记忆系统架构.md`](通用-记忆系统架构.md) | 早期记忆系统方案；当前记忆入口在 `操作系统/05_记忆/INDEX.md` |

## 维护规则

- 改 schema：同步 `数据库schema.md` 顶部当前版本速查，详细字段以代码真源为准。
- 改目录结构：同步 `项目结构.md` 当前根目录导航。
- 历史快照不追新；只在顶部标清“历史口径 / 当前真源”。
