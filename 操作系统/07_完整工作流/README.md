---
name: workflows-index
scope: project
type: procedural
loaded: on-demand
description: 完整工作流入口 — decision-checkpoint + 实施循环 + DoD + 附录
---
# 操作系统/07_完整工作流/ — 多步骤流程

⭐ **改动收尾前必读 [实施循环.md](实施循环.md) 末尾 DoD 段；低频阶段细则读 [实施循环-附录.md](实施循环-附录.md)；PROP 状态切换必读 [审批与归档.md](审批与归档.md)**

## 这一组讲什么

多个 step 有序串联的流程 — 以跨角色为主，按需调用 skill / rules。
每个 workflow 是一条从 A 到 Z 的路径，强调顺序和阶段产出。

## 文件清单

| 文件 | 一句话 |
|---|---|
| ⭐ [decision-checkpoint.md](decision-checkpoint.md) | Q1-Q7 硬检查协议（含 agent 实例化判定）|
| [decision-checkpoint-判定细则.md](decision-checkpoint-判定细则.md) | Q4-Q7 trigger / scale / 跨 PM / agent 实例化细则 |
| [decision-checkpoint-附录.md](decision-checkpoint-附录.md) | decision-checkpoint 示例 / 附录，不重复主规则 |
| ⭐ [实施循环.md](实施循环.md) | 实施循环主入口；保留 session 起手、流程优先、交接矩阵、阶段总览、DoD 速查 |
| [实施循环-附录.md](实施循环-附录.md) | 实施循环低频细则；设计/代码/测试/APK/smoke/端能力对照 |
| [实施循环-DoD.md](实施循环-DoD.md) | 收尾 DoD 独立清单（实施循环引用）|
| ⭐ [审批与归档.md](审批与归档.md) | PROP 5 状态机（待审批 / 进行中 / 已完成 / 已弃用 / 拒绝）+ 编号查询 §C |
| [需求接收.md](需求接收.md) | 接到新需求怎么开工（7 步） |
| [发布流程.md](发布流程.md) | 编译 / 测试 / APK / release notes |
| [git流程.md](git流程.md) | git 仓库边界 / A-B-C 三类权限 / commit-push 6 条件 / commit message / 分支与 tag 规则 |
| [hooks-运行SOP.md](hooks-运行SOP.md) | hooks 手动/自动运行、真源头、关键边界和验收入口 |
| [hooks-运行SOP-附录.md](hooks-运行SOP-附录.md) | hooks 低频安装/删除命令、事件表、watcher 健康码和排障细节 |

## 跟其他分组的区别

- **workflows/**：多 step 顺序（"按这个顺序跑"）
- **skills/**：单一能力（"会做这件事"）
- **rules/**：判断标准（"应该怎样" — 不是过程）
- **操作系统/02_智能体/**：谁在跑

## 速记 — 流程触发表

| 触发 | 进入哪个 workflow |
|---|---|
| 接到新想法 | 需求接收.md |
| zlbdh 审批 PROP | 审批与归档.md §A |
| zlbdh 拒绝 PROP | 审批与归档.md §B |
| 开始 L3/L4 改动 | 实施循环.md |
| 改动收尾 | 实施循环.md DoD 段 + 实施循环-DoD.md |
| 准备发版本 | 发布流程.md |
