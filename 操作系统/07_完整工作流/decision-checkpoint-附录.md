---
name: decision-checkpoint-附录
scope: project
type: procedural
loaded: on-demand
description: decision-checkpoint 参考附录（失败处理案例 / DoD 整合 / 实战留痕示例 / 议题 AJ 关闭条件 / 关联）— 主文件按需跳转 / PROP-042 第 1 棒拆出
---

# decision-checkpoint 附录（参考 / 案例 / 历史）

> 主文件：[`decision-checkpoint.md`](decision-checkpoint.md)（Q1-Q7 判定协议 + 路径白名单核心 + agent 实例化判定）
> 本附录：参考性案例 + 历史条件 + 关联（按需读 / PROP-042 第 1 棒拆出 / 议题 AY）
> 历史案例里的工具名只代表当时执行载体，不作现行权责主体。

---

## 失败处理（议题 AJ 真实战）

### 场景 1 — Q2 越界识别（议题 AJ 防御机制生效）

```
项目 PM 想做："anomalyDetector.js 9070B 拆 messages 文件"

Q1: 性质是 framework 治理（refactor 不改业务）→ 切「操作系统 PM」帽子
Q2: grep `操作系统/01_架构/角色边界.md` 路径白名单
   → 操作系统 PM 路径白名单：操作系统/ + 能力资产/ + tools/ + 确认改动/ + Docs/3/ + 7/ + 项目根
   → 即将改：{{APP_REPO_DIR}}/src/shared/anomalyDetector.js
   → ❌ {{APP_REPO_DIR}}/** 不在白名单 → 跳 Q3
Q3: 越界 → 切回项目 PM → 写交接卡给开发 PM「实施者」（执行载体：Claude Code）
   → ✅ 防御机制生效，避免 PM 自纠 #41 重演
```

### 场景 2 — Q1 模糊（切错帽子风险）

```
项目 PM 想做："PROP-020 P0 实验文件 _pingtest.md 改名 archived"

Q1: 文件在 .claude/agents/ → 不是 framework 内务（当时旧 5 PM 路径案例；现行按 9 PM 路径白名单 + 真实 agent 机制判断）
   → 切回项目 PM 写交接卡给开发 PM「实施者」（执行载体：Claude Code）
Q2: N/A（Q1 已识别本帽子不能做）
Q3: 默认动作 = 写交接卡给开发 PM「实施者」（执行载体：Claude Code）

→ ✅ 防御识别"看起来像内务实际属对应 PM 职责战场（工具仅作执行载体）"灰区
```

### 场景 3 — Q3 极少例外（紧急情况）

```
紧急情况：framework bug 导致项目 PM 切角色帽子时崩 → 阻塞所有工作

Q1: 操作系统 PM
Q2: 跳过（极少例外）
Q3: 切操作系统 PM 帽子修 framework bug
   → 同时 状态.md PM 角色切换轨迹明示「越界例外 — 紧急 framework 修复」
   → 修完立刻补开 PROP 治理（议题 AJ 重审机制）
```

---

## 跟实施循环 DoD 的整合

[`实施循环.md`](实施循环.md) DoD 5 项扩展为 6 项：

- [ ] **decision-checkpoint** Q1-Q7 跑过 ✅（PROP-020 P3' + ADR-038 Q7）
- [ ] **代码** 按 PRD 实现，无 TODO 残留
- [ ] **测试** vitest + esbuild + vite build 三层全过
- [ ] **PRD** 状态「实施中」→「已完成」+ 需求历史加条目
- [ ] **PROP 收档** 状态字段切「已完成」+ mv + README 计数更新
- [ ] **跑两个对账 skill** 项目体检 + 状态推断 全过

---

## 实战留痕（状态.md PM 角色切换轨迹）

每次跑 decision-checkpoint + 切角色 → 状态.md 加一行（PROP-020 §5 设计）：

```markdown
## 🎩 PM 角色切换轨迹

| 时间 | 从角色 | 到角色 | 任务 | decision-checkpoint 跑过？ | 完成回流 |
|---|---|---|---|---|---|
| 2026-05-14 12:15 | 项目 PM | 操作系统 PM | PROP-020 路径 D 加强版 v0 起稿 | ✅ | ✅ |
```

跨 session / 跨运行时 PM 自纠模式可见性 + RETRO-009 复盘素材。

⭐ **PM 自纠 #76 教训**：Edit 状态.md 后必 grep `task #XXX` 真验证行号（不能只 grep 关键字 / bash mount cache 假象用 Read verify）。

---

## 议题 AJ 关闭条件（PROP-020 §6 引用 / 已 ADR-023 收档）

议题 AJ 关闭 = 4 子条件全过：

1. ✅ 5 角色 md 落地（PROP-020 P1' 完成 2026-05-14 12:25）
2. ✅ 角色边界规则升级（早期 AI边界.md 已并入 `操作系统/01_架构/角色边界.md`）
3. ✅ 本 workflow 新建 + 实施循环.md 引用（PROP-020 P3' 完成）
4. ✅ PM 至少 3 次实战未触发 #38/#41/#42 同模式（跨 Sprint 验证）

→ 已 [ADR-023「议题 AJ PM 角色子类化 + decision-checkpoint」](../../Docs/3-开发文档/adr/ADR-023-议题AJ落地-PM角色子类化+decision-checkpoint.md) 收档。

---

## 关联

- [`../01_架构/角色边界.md`](../01_架构/角色边界.md) — 9 PM × 主-元-决策-实施四层路径白名单
- [`../02_智能体/项目PM-咪咪.md`](../02_智能体/项目PM-咪咪.md) — 编排者（路由判断者 / 唯一对外身份 ADR-031）
- [`../02_智能体/操作系统PM-框架管家.md`](../02_智能体/操作系统PM-框架管家.md) — 议题 AJ 核心角色
- [`实施循环.md`](实施循环.md) — DoD 6 项含本 workflow
- [`../01_架构/元规则池.md`](../01_架构/元规则池.md) — AJ(ADR-023) 永久化
- [`../../确认改动/已审批/已完成/PROP-020-2026-05-14-Agent团队架构.md`](../../确认改动/已审批/已完成/PROP-020-2026-05-14-Agent团队架构.md) — 议题 AJ 落地主稿
