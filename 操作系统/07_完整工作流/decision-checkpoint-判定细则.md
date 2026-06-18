---
name: decision-checkpoint-decision-details
scope: project
type: procedural
loaded: on-demand
description: decision-checkpoint Q4-Q7 判定细则 — trigger / scale / 跨 PM / agent 实例化
---

# decision-checkpoint 判定细则

> 主入口：[`decision-checkpoint.md`](decision-checkpoint.md)。本文件放低频细则，避免主文过大。

## Q4 速查表 trigger 示例

Q4 分两步：先查 PM 私人速查表，再查 [`共享技能/INDEX.md`](../02_智能体/共享技能/INDEX.md) 的跨 PM trigger。

| 当前任务场景 | 匹配速查表 |
|---|---|
| 写 handoff 卡 | `pm-role-boundary-check` + `changelog-header-check` |
| 写 handoff / ship 卡前 verify | `handoff卡-verify清单.md` |
| git 损坏 / `.git/index` 异常 / dirty 不明 | `git撤销恢复.md` |
| Codex / Cowork / Claude 切换后疑似 mount stale | `mount-stale防御.md` |
| 发现 PM 错向或 zlbdh 反问触发自纠 | `PM自纠-trigger.md` |
| 真机 smoke / APK 发布闭环 | `真机smoke清单.md` |
| 起 PROP | `pm-role-boundary-check` + `prop-status-semantics` |
| 写 chat 简版 ⑥ 输出 | `chat-summary-dedup` |
| 引入 `@capacitor/*` 新依赖 | `capacitor-version-verify` + `capacitor-plugin-defense` |
| 选 `navigator` / `Intl` API | `web-api-source-selection` |
| 改 PROP 状态字段 | `prop-status-semantics` |

## Q5 Scale-adaptive 判定

| Scale | 典型场景 | 需要的 ceremony |
|---|---|---|
| L1 | 文案、typo、单点样式、文档错别字 | 直接动手 + 状态留痕 |
| L2 | 单文件 feature / bug fix / 单 PM 完成 | 轻 PRD 或简版 handoff，必要测试 |
| L3 | 多文件 feature / 跨模块 / 单棒 1-2 天 | 完整 PRD + handoff / ship + 状态 + RETRO 回顾 |
| L4 | 架构重构 / schema / 跨 PM 协调 / 元规则升级 / 2+ 天 | PROP + ADR 评估 + 全 ceremony + RETRO 专项 |

快速症状：
- README 错别字、一个 emoji：L1。
- 单业务 bug、单 UI 文案：L2。
- HabitCard / NightProtection 一类完整 feature：L3。
- 拆 database、改 framework、元规则永久化：L4。

升级规则：
- L1 发现跨文件影响 → L2。
- L2 发现多模块影响 → L3。
- L3 触及元规则、跨 PM、schema → L4。

Scale 升级时必须重跑 Q1-Q7、重写交接卡，并在 `状态.md` 留痕。

## Q6 跨 PM 调度判定

核心：调度的是 PM 角色，不是工具载体。

| 子项 | 检查 |
|---|---|
| Q6.1 当前 PM 载体 | 项目 PM由主会话承载；除项目 PM 外，写入型 PM 默认 worker，只读诊断型 PM 默认 explorer；发布动作单点不外包 |
| Q6.2 跨 PM 同步 | handoff 卡 + chat 简版 ①-⑦，不能用散文代替 |
| Q6.3 mount stale 防御 | Codex / Claude Code / Cowork 切换后用真 shell `git status --short` verify |
| Q6.4 交接区确认 | 跨 PM 切换前写 `交接区/待接手/`；开始做事不移动，完成时再流转到 `已接手/` |

常见触发：
- 项目 PM → 开发 PM：写 handoff 卡 + 议题 BK 防御。
- 项目 PM → 测试发布 PM：写 ship 卡 + ADR-016 6 条件。
- 操作系统 PM → 开发 PM：不直接切，让项目 PM 编排。
- 任一 PM → 沉淀 PM：提交沉淀报告或 RETRO 候选。

## Q7 agent 实例化判定

| 问题 | 默认 |
|---|---|
| 写还是只读？ | 写非单源文件默认 worker；只读诊断默认 explorer |
| 是否单源禁并行？ | `状态.md` / `交接区` / `CHANGELOG` / `元规则池.md` / `角色边界.md` / `子agent调度机制.md` 只允许 agent 起草，主会话落最后一笔 |
| 是否发布动作？ | commit / push / version / APK / smoke 单点不外包 |
| 是否需要并行 framework worker？ | 仅在 ≥6 互斥文件 + 主会话验收 + 体检 gate 时走 B-lite |

恒守边界：
- spawn 权 + 验收权在项目 PM「咪咪」。
- 除项目 PM 主会话外，每个 PM 的实际工作默认实例化真实 agent（写=worker / 只读=explorer）。
- 被派 agent 不再自行 spawn 子 agent。
- agent 是执行实例，不改变 PM 权责。

## 关联

- [`decision-checkpoint.md`](decision-checkpoint.md) — Q1-Q7 主入口
- [`decision-checkpoint-附录.md`](decision-checkpoint-附录.md) — 案例和历史
- [`../01_架构/角色边界.md`](../01_架构/角色边界.md) — 路径白名单
- [`../01_架构/子agent调度机制.md`](../01_架构/子agent调度机制.md) — agent 调度入口规则
- [`../01_架构/子agent调度机制-附录.md`](../01_架构/子agent调度机制-附录.md) — 完整映射与历史解释
