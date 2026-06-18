---
name: decision-checkpoint
scope: project
type: procedural
loaded: on-demand
description: PM 切角色帽子 / 动手前必跑的 Q1-Q7 硬检查入口
---

# 工作流：decision-checkpoint（PM 动手前 Q1-Q7 硬检查）

> 议题 AJ 错向防御核心机制。目标：把“凭直觉判断”转成“查表实证”。

## 触发时机

任一情境都先跑 Q1-Q7：

1. 项目 PM 准备切任一 PM 帽子。
2. 准备 Edit / Write 任意文件。
3. 出现“这事性质像 framework / 像内务”的直觉判断。
4. 长任务中途需要防机制衰减。
5. 新 session 起手按 [`实施循环.md`](实施循环.md) DoD 跑本检查。

## Q1-Q7 硬检查（标准协议）

| 问题 | 判断 | 过关动作 |
|---|---|---|
| Q1 这件事属于哪个 PM？ | 看任务和路径：framework→操作系统 PM；PRD→产品 PM；诊断→技术 PM；测试策略→测试 PM；`{{APP_REPO_DIR}}/src/`→开发 PM；发布闭环→测试发布 PM | 识别角色；必要时切帽子 |
| Q2 路径白名单允许吗？ | grep [`角色边界.md`](../01_架构/角色边界.md) 的 `9 PM 完整路径白名单表` | 在白名单才动手；不在则进 Q3 |
| Q3 越界怎么办？ | 默认交给对应 PM；紧急 framework 修复需明示例外 | 写交接卡 / 切正确 PM / 状态留痕 |
| Q4 命中哪个速查表？ | 读 `PM工作区/<X-PM>/速查表/INDEX.md` + [`共享技能/INDEX.md`](../02_智能体/共享技能/INDEX.md)，按 trigger 加载 | 命中才加载；未命中不硬塞 context |
| Q5 改动规模是多少？ | L1-L4 scale 判定，详见 [`decision-checkpoint-判定细则.md`](decision-checkpoint-判定细则.md) | scale 升级时重跑 Q1-Q7 + 补交接/状态 |
| Q6 是否跨 PM 调度？ | 调度的是 PM 角色，不是工具；详见判定细则 | 写 handoff / ship 卡，走交接区 |
| Q7 是否实例化 agent？ | 写活默认 worker，只读默认 explorer；单源/发布单点例外 | 项目 PM 统一 spawn + 验收 |

## Q1 角色路由速查

| 场景 | 归属 |
|---|---|
| 改 `操作系统/`、`能力资产/`、`确认改动/`、`交接区/`、项目根 framework | 操作系统 PM「框架管家」 |
| 写 PRD / 改 Sprint 需求清单 | 产品 PM「需求拆解者」 |
| 诊断 bug / 技术选型 / 跨多文件影响评估 | 技术 PM「修复决策者」（只读） |
| 测试策略 / 验收清单 / mock 设计 | 测试 PM「质量门户」（只读） |
| 改 `{{APP_REPO_DIR}}/src/` 任意业务或测试代码 | 开发 PM「实施者」 |
| bump version / build APK / vitest / 真机 smoke / commit / push | 测试发布 PM「闭环者」 |
| 简单确认 / 状态查询 / 对外汇报 | 项目 PM「咪咪」 |

## Q2 路径白名单速查

每次跑 Q2 必查 [`角色边界.md`](../01_架构/角色边界.md)，不要凭记忆。

| 路径 | 准许角色 | 禁区 |
|---|---|---|
| `操作系统/**`、`能力资产/**`、`项目配置/**`、`项目区/**`、`Docs/3-开发文档/**`、`Docs/7-复盘/**` | 操作系统 PM | 其他 PM 不直接写 |
| `确认改动/**` | 操作系统 PM；产品 PM 可写 `待审批/` | 技术 / 测试 PM 不写 |
| `交接区/**`、`状态.md` | 项目 PM / 操作系统 PM 按职责写 | 单源文件禁并行 |
| 根 `README.md`、`AGENTS.md`、`实例化项目.ps1`、`.gitignore` | 操作系统 PM 维护入口；项目 PM 只做收口留痕 | B 类 review 边界，不承载细规则 |
| `Docs/1-需求文档/**` | 产品 PM | 其他 PM 不写 |
| `{{APP_REPO_DIR}}/src/**` | 开发 PM | 当前非开发 PM 写交接卡 / 派 worker |
| `{{APP_REPO_DIR}}/package.json`、APK、tag、push | 测试发布 PM按 ADR-016/发布条件处理 | 非测试发布 PM 不直接 bump/出包 |
| `{{APP_REPO_DIR}}/.env.local` 本机未跟踪配置 | 条件性 B 类；仅用户授权的本机环境修复可处理 | 不提交、不外传、不写入 tracked 文档 |
| API key 外传 / 写 tracked 密钥 / 不可逆用户数据删除 | 无 | C 类，AI 永不动 |

## Q4-Q7 细则入口

- Q4 trigger 示例、Q5 Scale-adaptive、Q6 跨 PM 调度、Q7 agent 实例化细则：[`decision-checkpoint-判定细则.md`](decision-checkpoint-判定细则.md)
- 失败案例、DoD 整合、实战留痕、议题 AJ 历史：[`decision-checkpoint-附录.md`](decision-checkpoint-附录.md)

## 不要做

- 直觉切角色，不跑 Q1 路由判断。
- 跑 Q2 凭记忆判断路径。
- Q3 越界后为赶进度私自动手。
- 跑过 Q1-Q7 但不在 `状态.md` 留痕。
- 把本检查当形式，快速念完不查表。

## 关联

- [`../01_架构/角色边界.md`](../01_架构/角色边界.md) — 9 PM 路径白名单
- [`../01_架构/三类行为铁律.md`](../01_架构/三类行为铁律.md) — A/B/C 与 C 类清单真源
- [`../01_架构/子agent调度机制.md`](../01_架构/子agent调度机制.md) — worker / explorer / B-lite
- [`../02_智能体/项目PM-咪咪.md`](../02_智能体/项目PM-咪咪.md) — 编排者 / 唯一对外身份
- [`实施循环.md`](实施循环.md) — DoD 含本 workflow
