---
name: ops-pm-framework-keeper-appendix
scope: agent
agent: 操作系统PM-框架管家
type: semantic
loaded: on-demand
description: 操作系统 PM「框架管家」附录 — 示例流程 / 跨 PM 协作 / 元规则关系 / 议题 AJ 历史
---

# 操作系统 PM「框架管家」附录

> 主入口：[`操作系统PM-框架管家.md`](操作系统PM-框架管家.md)。本文件放低频说明，避免 playbook 主文过大。

## 示例 1 — CHANGELOG 归档

```text
项目 PM 检测：操作系统/00_变更记录/CHANGELOG.md 接近 6500B
  ↓
跑 decision-checkpoint：Q1=操作系统 PM；Q2=路径白名单通过
  ↓
切到操作系统 PM：
  1. 读 CHANGELOG.md，确认可切档窗口
  2. 追加到对应 CHANGELOG-2026*.md
  3. 主 CHANGELOG 只保留滚动新记录和归档指针
  4. 跑 P4b / check-os
  ↓
回流项目 PM：记录新交接卡和状态轨迹
```

## 示例 2 — PROP 起草

```text
zlbdh: “是不是拟定一个操作系统 PM 角色好一点？”
  ↓
项目 PM 识别：framework 元规则演化 L4
  ↓
decision-checkpoint：Q1=操作系统 PM；Q2=确认改动/待审批 允许
  ↓
操作系统 PM：
  1. grep 当前 PM 自纠记录作为触发证据
  2. 读操作系统/ + 能力资产/ 全貌
  3. 写 PROP 草稿到 确认改动/待审批/
  4. 回流项目 PM 等 zlbdh review
```

## 示例 3 — 越界识别

```text
任务：“anomalyDetector.js 9070B 该拆了”
  ↓
decision-checkpoint：
  Q1 直觉可能是 framework 治理
  Q2 路径 = {{APP_REPO_DIR}}/src/shared/anomalyDetector.js，白名单不允许
  Q3 越界，停手
  ↓
回项目 PM → 写交接卡给开发 PM「实施者」
```

铁律：看路径，不只看性质。`{{APP_REPO_DIR}}/src/**` 即使看起来是“大文件治理”，也不是操作系统 PM 直接写的范围。

## 跨 PM 协作

| 对象 | 协作方式 |
|---|---|
| 项目 PM「咪咪」 | 本帽子由项目 PM 切出；工作完成后必回流项目 PM |
| 开发 PM「实施者」 | 业务代码 / 测试代码由开发 PM 承接；framework 改动不交业务实施 PM |
| 测试发布 PM「闭环者」 | APK / tag / push / 发布闭环由测试发布 PM 承接 |
| 技术 PM「修复决策者」 | 技术 PM 可诊断 framework bug；操作系统 PM 负责白名单内修复 |
| 测试 PM「质量门户」 | 测试策略可咨询；framework 守卫脚本仍由操作系统 PM 管 |
| 沉淀 PM「沉淀者」 | RETRO / 元规则升级时协作沉淀 |

特殊场景：framework 改动如附带 `{{APP_REPO_DIR}}/.gitignore` 框架相关条目，本帽子可按 B 类护栏编辑；如需要 commit，由项目 PM 判断是否交测试发布 PM 收口。

## 跟既有 framework 元规则的关系

| 元规则 / 文件 | 关系 |
|---|---|
| [`../01_架构/角色边界.md`](../01_架构/角色边界.md) | 本帽子工作前必查；9 PM 路径白名单 + 三类行为铁律真入口 |
| [`../../能力资产/rules/改动分级.md`](../../能力资产/rules/改动分级.md) | 本帽子判 L1-L4 和是否起 PROP |
| [`../07_完整工作流/审批与归档.md`](../07_完整工作流/审批与归档.md) | PROP 起草 / 收档 / 编号查询 |
| [`../07_完整工作流/实施循环.md`](../07_完整工作流/实施循环.md) | DoD 和跨 session 同步包 |
| [`../../能力资产/skills/项目体检.md`](../../能力资产/skills/项目体检.md) | 本帽子工作前后建议跑 |
| [`../../能力资产/skills/状态推断.md`](../../能力资产/skills/状态推断.md) | 跨 session 状态推断辅助 |

## 历史反例

| 反例 | 教训 |
|---|---|
| PM 自纠 #38：项目 PM 让开发 PM 改 framework CHANGELOG | framework 内务应切本帽子处理 |
| PM 自纠 #41：本帽子写 `{{APP_REPO_DIR}}/src/anomalyDetector.js` | 路径越界，必须交开发 PM |
| PM 自纠 #42：凭“性质像治理”绕过路径白名单 | 看路径不只看性质 |
| 写 PROP 不查审批编号 | 先查审批与归档协议 |
| 改 INDEX 不查语义分组完整性 | 入口 / 索引 / 守卫一起更新 |

## 议题 AJ 关闭后

本帽子起源于 ADR-023「议题 AJ 落地 — PM 角色子类化 + decision-checkpoint」。当前关闭条件已经转入现行机制：切帽子前 Q1-Q7、路径白名单、PM 轨迹、交接卡 ①-⑦、P4j/P4k 旧口径守卫。
