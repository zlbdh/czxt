---
name: 项目pm-咪咪-readme
scope: pm-workspace
pm: 项目PM-咪咪
type: semantic
loaded: on-demand
description: 项目 PM「咪咪」私人工作区入口 — 速查表 + 自纠 + 实战回顾（主 PM / 唯一对外身份 / ADR-031）
---
# 项目 PM「咪咪」· 元记忆中枢

> ⭐ PROP-023 v1 落地（2026-05-15，议题 BE）— PM 自己的元记忆中枢，解决 framework 复杂度超 PM 单 chat 维护能力问题
> ⭐ PROP-023 v2 路径调整（2026-05-21，议题 CM）— 从 `项目PM/` 迁到 `PM工作区/项目PM-咪咪/`，配套 PM 私人工作区同步建立（[`PM工作区/README.md`](../README.md)）
> **核心铁律**：PM 切角色帽子前 / 写 handoff 卡前 / 起 PROP 前 — **先 grep 本文件夹**！

## 起手 30 秒（切项目 PM 帽子 / 写 handoff、PROP、chat 前）

1. 新会话总入口仍按 [`操作系统/00_总入口.md`](../../操作系统/00_总入口.md)；本文件不是每次 session 的第一入口。
2. 当任务涉及项目 PM 编排、handoff、PROP、chat 简版时，先扫 `速查表/` 查相关元规则（防 PM 自纠同模式）。
3. 读 `状态.md` 看进度 + 待接手交接卡；PM 切换轨迹以 `状态.md` 末尾为单一留痕源。
4. 写 handoff / PROP / chat 简版前 — 必跑 `速查表/` 防御检查。

## 目录速查

| 子目录 | 装什么 | 何时读 |
|---|---|---|
| ⭐ [速查表/](速查表/) | 元规则陷阱档案 + 防御检查清单 | **写 handoff / PROP / chat 前必读** |
| [实战回顾/](实战回顾/) | 每个 Sprint feature 完整时间线 + PM 自纠累积 | 起类似 feature 前查同模式 |
| [PM自纠/](PM自纠/) | PM 自纠按类型 + 按日期 | 跨 Sprint 同模式识别 |

## ⭐ 速查表清单（PM 切角色前 1 分钟核对）

| 文件 | 防御点 | PM 自纠来源 |
|---|---|---|
| [速查表/ADR-022决定5-4类角色铁律.md](速查表/ADR-022决定5-4类角色铁律.md) | 路径分判：framework / 业务代码 / 测试代码 / 闭环 | PM 自纠 #41/#42 |
| [速查表/Capacitor版本核对.md](速查表/Capacitor版本核对.md) | 装新依赖前 Read package.json 确认主版本 | PM 自纠 #46 |
| [速查表/plugin集成防御.md](速查表/plugin集成防御.md) | 必静态 import + NotificationChannel + cap sync | PM 自纠 #47 |
| [速查表/chat简版去重检查.md](速查表/chat简版去重检查.md) | chat 输出最后扫一遍代码块去重 | PM 自纠 #48 |
| [速查表/议题AT矩阵速查.md](速查表/议题AT矩阵速查.md) | web API 选型必查 `能力资产/rules/web-api-信源选型.md` | PM 自纠 #45 |
| [速查表/PROP状态字段语义.md](速查表/PROP状态字段语义.md) | 代码完成 ≠ PROP 完成（需 Codex push） | PM 自纠 #44 |
| [速查表/CHANGELOG-header规则.md](速查表/CHANGELOG-header规则.md) | 业务代码改动**不进** `操作系统/00_变更记录/CHANGELOG.md` | PM 自纠 #43 |

## ⭐ 实战回顾清单

| 实战 | feature | 关键议题 | 文件 |
|---|---|---|---|
| #1 | F-SYSCHECK-1（v3.5.8）| 议题 AJ 实战 #1 + 议题 G P0 + 议题 AT 永久化 | [实战回顾/实战-1-F-SYSCHECK-1.md](实战回顾/实战-1-F-SYSCHECK-1.md) |
| #2 | F-ALARM-1（v3.5.9 ⏳）| 议题 AJ 实战 #2 + plugin 集成 bug + 跨时区 + 低电量 | [实战回顾/实战-2-F-ALARM-1.md](实战回顾/实战-2-F-ALARM-1.md) |

## 跟其他 framework 文件的关系

| 角色 | 文件 | 区别 |
|---|---|---|
| **职位定义** | `操作系统/02_智能体/项目PM-咪咪.md` 等 9 PM 角色 md | "项目经理这个职位干啥"（PROP-020 路径 D 落地） |
| **元规则约束** | `能力资产/rules/*` + `操作系统/07_完整工作流/*` | "应该怎样 / 按什么顺序" |
| **本文件夹 PM 工作中枢** | `PM工作区/项目PM-咪咪/` | "PM 实际记的事 + 自己踩过的坑" |
| **项目全局起手记忆** | `操作系统/05_记忆/INDEX.md` | 用户偏好、行为反思、项目历史指针的当前入口 |
| **项目快照** | `状态.md` | 当前进度 + 待接手 + 历史段 |

→ 本文件夹是 **「PM 自己的工作笔记本」**（前 4 个是规则 / 身份 / 通用记忆 / 项目状态，本文件夹是 PM 工作产出）

## 维护规则

- ⭐ **速查表/ 文件长度原则**：入口保持短、最多 1 屏优先；超过约 2KB 时先判断是否仍可快速扫读，再决定拆分。
- ⭐ **实战回顾/ 命名约定**：`实战#N-feature名.md`（按议题 AJ 实战编号）
- ⭐ **待决议 / backlog 命名约定**：如后续恢复本 PM 私有 backlog，再用 `议题XX-标题.md`（按字母编号）
- 跨 Sprint 渐进迁移，不一次性大手术

## 议题 AR Q4.g 候选维度新增

PROP-020 路径 D `decision-checkpoint` Q4 规则校验扩展候选：
- Q4.g — **写 handoff / PROP / chat 前必先 grep `PM工作区/项目PM-咪咪/速查表/`**（议题 BE 落地配套）

待 RETRO-009 收官时议题 AR 升级 decision-checkpoint 时同步落地。

## 关联

- [PROP-023 主稿](../../确认改动/已审批/已完成/PROP-023-2026-05-15-项目PM记忆中枢化.md)
- [PROP-020 路径 D](../../确认改动/已审批/已完成/PROP-020-路径D-方案v0.md) — PM 角色身份定义
- [操作系统/02_智能体/](../../操作系统/02_智能体/) — 9 PM 角色 md
- [能力资产/rules/](../../能力资产/rules/) — 元规则
- [decision-checkpoint.md](../../操作系统/07_完整工作流/decision-checkpoint.md) — Q4 扩展候选
- [状态.md](../../状态.md) — 项目快照
