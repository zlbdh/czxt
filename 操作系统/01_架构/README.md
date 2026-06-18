---
name: architecture-index
scope: project
type: semantic
loaded: on-demand
description: 架构层入口 — 角色边界 + 子 agent 调度机制 + 元规则池 + 工具载体矩阵 + 三类行为铁律 + README 设计规范
---
# 01_架构 · 协作架构层

> Framework 的「宪法层」— 演化原则 / 角色边界 / 决策归属 / 状态机

| 文件 | 内容 |
|---|---|
| [演化哲学.md](演化哲学.md) | Framework 演化扩编三问（新增 PM 角色专用 / 不模仿现实公司 / 单工作流不复杂化 等）|
| [角色边界.md](角色边界.md) | **9 PM × 主-元-决策-实施四层**路径白名单 + 决策归属（v4.0 / task #104.1）|
| [角色边界-协作附录.md](角色边界-协作附录.md) | 对外身份铁律 + 反例 + 沉淀/验证/元规则治理说明 |
| [PM工作区边界.md](PM工作区边界.md) | 9 PM 私人工作区路径表 + 跨界禁令 |
| [子agent调度机制.md](子agent调度机制.md) + [附录](子agent调度机制-附录.md) | PM 实体化 agent 调度入口 / worker-explorer / 单源禁并行 / B-lite |
| [元规则池.md](元规则池.md) + [候选](元规则池-候选.md) + [附录](元规则池-附录.md) | **23 永久元规则 v3.9** / 17 候选 / 沉淀 PM 治理（ADR-023~038）|
| [工具载体矩阵.md](工具载体矩阵.md) + [附录](工具载体矩阵-附录.md) | PM 抽象 vs 工具载体彻底解耦（ADR-026 / 议题 CT）；附录承接候选载体与迁移愿景 |
| [三类行为铁律.md](三类行为铁律.md) + [附录](三类行为铁律-附录.md) | A 自动 / B 必问 / C 永不动；灰区/撤销/L1-L4 对照见附录 |
| [README设计规范.md](README设计规范.md) | README 必含 3 段 + 更新触发 + 议题 DN 体检 SOP（task #120）|
| [状态机.md](状态机.md) | 任务 5 态（PLANNED→DELIVERED→ACCEPTED/CONDITIONAL/REJECT→CLOSED）|

## 维护
- 角色调整 / 决策归属变化时必同步
- 责任：操作系统 PM「框架管家」
