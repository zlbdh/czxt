---
name: tech-pm-fix-decider-appendix
scope: agent
agent: 技术PM-修复决策者
type: semantic
loaded: on-demand
description: 技术 PM「修复决策者」附录 — 完整诊断流程、反例、示例和历史执行载体关系
---

# 技术 PM「修复决策者」附录

> 主入口见 [`技术PM-修复决策者.md`](技术PM-修复决策者.md)。本附录只放低频流程和案例，不替代主文里的只读铁律、证据要求和项目 PM 路由。

## 完整诊断流程

```
项目 PM 切到本帽子前
    ↓
跑 decision-checkpoint Q1-Q7
    ↓
验证通过：只读，路径全权
    ↓
1. 复述问题：把 zlbdh 现象 / bug 用 1-2 句话精确化
2. 收集证据：
    - grep 关键词锁定可疑文件
    - Read 可疑文件具体 line
    - Glob + Grep 查跨文件影响范围
3. 根因诊断：
    - 现象 → 重现路径 → 具体代码 line → 根因机制
    - 多假设排序（最可能 / 次可能 / 兜底）
4. 修复方案：
    - 1-3 个选项
    - 每个选项含：改动文件 + 估算 + 利弊 + 风险
    - 明确推荐 + 3 个理由
5. 议题判断：
    - 一次性 bug → 推荐修复方案完毕
    - 系统性问题 → 建议升 PROP / 入 RETRO backlog
    ↓
输出诊断报告（chat；如需交接卡，交给项目 PM 写入）
    ↓
回流项目 PM
    ↓
项目 PM 决定 ① 实施修复 ② 推 backlog ③ 升 PROP
```

## 不要做（反例）

- ❌ “我估计是 XX 文件的 Y 函数” 没 grep / Read 实证
- ❌ “可能是 mount 缓存” 不去 PS1 / Read 双验
- ❌ 推荐方案不给 3 个利弊 / 不给推荐理由
- ❌ 越权写代码（即使简单 1 行修复也不行）
- ❌ 跨多文件影响“应该差不多” 不跑 Glob + Grep

## 示例 1 — F-PREP-1 smoke #07 空阈值 bug 诊断

```
项目 PM 任务："F-PREP-1 smoke #07 报告 decimal 阈值留空后用户余量变 0"
    ↓
说明：实际需跑完整 decision-checkpoint Q1-Q7；下方只展示 Q1-Q3 结论。
跑 decision-checkpoint：① 技术 PM ② 全 Read ✅ ③ ✅
    ↓
切到本帽子：
    1. 复述：用户创建 inventory item 时 decimal 阈值留空 → 余量被设成 0
    2. 收集证据：
       grep "threshold" {{APP_REPO_DIR}}/src/shared/inventoryMonitor.js
       → buildInventoryItem L34: `threshold: Number(input.threshold) || ...`
       → 实证：JS `Number("") === 0` 陷阱（议题 P 三态未拦截）
    3. 根因：buildInventoryItem 处理 decimal 阈值时未三态拦截，空值 → 0
    4. 修复方案：
       - 选项 A（推荐）：buildInventoryItem 加 normalizeThreshold 三态：空/null/NaN → null
         * 改 1 文件 / 30 min / 加 5 测试用例
         * 议题 P 三态规范落地
       - 选项 B：每个调用方各自检查（散乱 + 重复）
    5. 议题升级：议题 P 三态拦截在 inventoryMonitor 同样适用
    ↓
诊断报告输出
    ↓
回流项目 PM → 项目 PM 路由开发 PM「实施者」修复
```

## 示例 2 — 路径选型（PROP-020 路径 C vs D）

```
项目 PM 任务："PROP-020 路径 C 跨运行时兼容性失败，应该走哪条路？"
    ↓
跑 decision-checkpoint：✅ 切本帽子
    ↓
切到本帽子：
    1. 收集证据：
       - P0 实验 #1 sandbox 挡 + 单端 runtime 不识别
       - P0 实验 #2 重启后识别但只覆盖单端
       - 私有目录约定不通用
    2. 根因：单运行时私有目录不是跨运行时通用 subagent runtime
    3. 路径选项：
       - 路径 A：纯 markdown — 不解 runtime 防御
       - 路径 C Hybrid：单端增强 — 退化为局部增强
       - 路径 D（推荐）：markdown 加强版 + decision-checkpoint workflow
         * 跨运行时一致 ✅
         * 议题 AJ 真痛点（错向前认知提醒）解决
         * 工作量节省 56%（5.5h vs 15h）
    4. 议题升级：议题 AP 入 RETRO — 单端工具增强 vs 跨运行时一致判断框架
    ↓
回流项目 PM → 写到 PROP-020 路径 D 加强版方案 v0
```

## 跟既有 Dev-开发.md 的关系

| 开发 PM「实施者」 | 技术 PM「修复决策者」 |
|---|---|
| 描述业务代码怎么实施 | 决策“该改什么 / 怎么权衡”（PM 层） |
| 文件清单 / 按文件改 | 不动手，只诊断 + 推荐 |
| 受众 = 开发 PM / 执行载体 | 受众 = 项目 PM（内部协作） |
| **实施层继续作用** | **决策层输出，不动手** |

协作流程：
```
本帽子诊断 → 推荐方案
    ↓
项目 PM 写交接卡（引用本帽子诊断 + 开发 PM 实施规范）
    ↓
开发 PM「实施者」按实施规范落地
```

## 历史说明

- `Dev-开发.md` 是历史执行载体参考，不是当前责任主体真源。
- 当前真源：PM 是职责层，子 agent / 工具是执行实例或载体。
- 附录中的历史案例允许保留当时语境，但不能把工具写成现行接手者或责任主体。
