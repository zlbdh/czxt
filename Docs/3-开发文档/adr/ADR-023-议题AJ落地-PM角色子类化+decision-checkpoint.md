# ADR-023 · 议题 AJ 落地 — PM 角色子类化 + decision-checkpoint（PROP-020 路径 D 收档）

- **状态**：现行
- **日期**：2026-05-15
- **关联**：[PROP-020 主稿](../../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md) · [PROP-020 路径 D 方案 v0](../../../确认改动/已审批/进行中/PROP-020-路径D-方案v0.md) · [PROP-021 useAppData 拆分](../../../确认改动/已审批/已完成/PROP-021-2026-05-14-useAppData-hook拆分.md) · [PROP-022 navigator 矩阵](../../../确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md) · [PROP-023 项目PM 记忆中枢](../../../确认改动/已审批/进行中/PROP-023-2026-05-15-项目PM记忆中枢化.md) · [ADR-022 决定 5](ADR-022-跨工具同步与角色边界规范.md)
- **议题 AJ 关闭条件**：3/3 跨 Sprint 实战 + 0 触发 #38/#41/#42 同模式 ✅

> ⚠️ **当前覆盖说明（2026-06-15）**：本文是 Q1-Q7 / 9 PM 架构的前身，保留“五类 PM / 3 问”历史证据。当前执行以 [`操作系统/07_完整工作流/decision-checkpoint.md`](../../../操作系统/07_完整工作流/decision-checkpoint.md)、[`ADR-027`](ADR-027-议题CU+DD永久化-沉淀PM元层架构.md) 与 [`ADR-038`](ADR-038-PM实体化agent调度模型.md) 为准。

## 背景

PROP-018a 操作系统部分收档后，议题 AJ raise（zlbdh 5/13）— 项目 PM 同时管业务 + 操作系统的角色重叠是**结构性根因**（PM 自纠链 #38/#41/#42 三次同模式错向），不是个别失误。

**初始方案** PROP-020 路径 C Hybrid（5 sub-agent runtime + .claude/agents/）经 P0 实验验证：
- `.claude/` 是 Anthropic 私有约定，Codex / Cowork 不识别
- 跨工具一致性失败 → zlbdh 5/14 决策**路径转向 D**（纯 markdown 加强版）

**路径 D 加强版**（PROP-020 §「路径 D 方案 v0」）：
- 5 markdown PM 子角色（项目 / 操作系统 / 产品 / 技术 / 测试）
- AI边界.md 升级四类 → 五类
- `decision-checkpoint` workflow（3 问硬检查：哪个角色？路径白名单允许？越界怎么办？）
- 状态.md「PM 角色切换轨迹」段（议题 AJ 留痕机制）

## 决定

议题 AJ **正式关闭**，PROP-020 路径 D 加强版纳入 framework 元规则常态运行。

### 决定 1 — 五类 PM 内部子角色（路径 D）

```
项目 PM「咪咪」（编排者，唯一对外面）
    ├─→ 操作系统 PM「框架管家」(agent/ + tools/ + Docs/3+7/ + 确认改动/ + 交接区/ + 项目PM/)
    ├─→ 产品 PM「需求拆解者」(Docs/1-需求文档/ + 确认改动/待审批/)
    ├─→ 技术 PM「修复决策者」(只读不动手)
    └─→ 测试 PM「质量门户」(只读不动手)
```

每个子角色独立 playbook md + 路径白名单硬规则。

### 决定 2 — decision-checkpoint 3 问硬检查

切角色前 / 写 handoff 卡前 / 起 PROP 前必跑：
- Q1 这件事属于哪个角色？
- Q2 我要改的路径，本角色白名单允许吗？grep AI边界.md
- Q3 如越界 → 写交接卡 / 切其他角色

### 决定 3 — Q4 规则校验扩展（议题 AR 升级版）

PROP-021/022/023 三次连续 PM 自纠（#43-#48 共 6 次）暴露 Q1-Q3 仅覆盖**路径维度**，未覆盖**规则记忆 / 设计自检 / 状态字段 / 版本假设 / chat 输出 / 工具集成**维度。

Q4 防御扩展 7 子维度（议题 AJ 落地 v2）：
- Q4.a — CHANGELOG header 规则（PM 自纠 #43）
- Q4.b — PM 设计自检（取舍 2 反向案例）
- Q4.c — PROP 状态字段语义边界（PM 自纠 #44）
- Q4.d — web API 选型必查矩阵（PM 自纠 #45 / 议题 AT 元规则）
- Q4.e — Capacitor 主版本假设（PM 自纠 #46）
- Q4.f — Capacitor plugin import 方式 + NotificationChannel（PM 自纠 #47 / 议题 BC 元规则）
- Q4.g — chat 输出去重 + 写 handoff/PROP/chat 前必先 grep `项目PM/速查表/`（PM 自纠 #48 / 议题 BE 元规则）

**Q4 防御机制实现**：通过 PROP-023 「项目PM/速查表/」7 速查表文件落地（每文件 ≤ 2KB，PM 切角色前 1 分钟核对）。

### 决定 4 — 跨 Sprint 留痕机制

`状态.md` 加「## 🎩 PM 角色切换轨迹」段，每次切角色 + 跑 decision-checkpoint 加一行（议题 AJ 留痕机制正式运行）。

## 后果

### 实战验证（议题 AJ 关闭条件达成）

| 实战 # | 时间 | feature | 路径越界？ | PM 自纠（被挡）|
|---|---|---|---|---|
| #1 | 2026-05-14 | F-SYSCHECK-1 完整闭环 + PROP-021 + PROP-022 | ❌ 0 | 3（#43/#44/#45）|
| #2 | 2026-05-15 | F-ALARM-1 完整闭环 + 议题 BC 元规则首次实证 | ❌ 0 | 3（#46/#47/#48）|
| #3 | 2026-05-15 | F-REMIND-1 完整闭环 + Q4 防御首次实战 + 议题 G P0 预防 #3 | ❌ 0 | 0（速查表机制起效）|

→ **跨 Sprint 3 次实战 / 0 路径越界 / 0 触发 #38/#41/#42 同模式 / 6 次 PM 自纠全被挡** ✅

### ADR-022 决定 5 连续正确实战（议题 AJ 防御机制证据）

议题 AJ 启动以来 ADR-022 决定 5「四类角色分工硬规则」连续 **9 次正确实战**（PROP-019 P1/P2/P3 + F-SYSCHECK-1 + PROP-021 + PROP-022 + F-ALARM-1 修复 + F-ALARM-1 + F-REMIND-1）— PM 自纠 #41/#42 同模式**0 次再触发**。

### 收益

1. **议题 AJ 真正落地**：跨工具一致 + 错向前认知提醒（80% 价值）— Markdown 路径 D 比原 Runtime 路径 C 实战表现更强
2. **6 个元规则永久化**：议题 AJ / AT / AM / AO / BC / BE 全部进 framework `agent/rules/` + `项目PM/速查表/`
3. **PM 自纠链断开**：今日 6 次 PM 自纠（#43-#48）全被挡（Claude Code PROP-014 三阶判定 5 次 + PM 自检 1 次 + Q4 防御首次实战 0 越界）
4. **framework 复杂度承载能力提升**：项目PM 记忆中枢化（PROP-023）解决"复杂度超 PM 单 chat 维护能力"根因

### 代价

1. **PM 投入约 6h**（PROP-020 P1'-P4' + PROP-023 P2+P3 + 5 角色 md + 速查表 + 实战 #26 ADR 收档）
2. **跨 Sprint 持续维护成本**：每次切角色需跑 decision-checkpoint + 状态.md 留痕（约 1-2 min / 次）
3. **议题 AR Q4 7 维度仍是"候选"状态**：未来需 PROP-024 之类正式纳入 decision-checkpoint workflow 主体

### 后续

1. **PROP-024 候选**（Sprint-5 收官 / RETRO-009 时）：
   - decision-checkpoint workflow 升级到 Q1-Q4（含 7 子维度 a-g）
   - alarmManager 拆分（议题 AY 累积压力 14.3KB → 23.0KB 越警戒区）
2. **PROP-023 P4-P6 渐进迁移**（跨 Sprint）：实战回顾 / 议题 backlog / PM 自纠 / 角色切换轨迹 集中
3. **ADR-024 候选**（议题 AP 跨工具决策框架）+ **议题 AN 子类型细分** RETRO-009 时一并整合

### 议题 AJ 关闭后跨 Sprint 监控

- PROP-020 状态切「已完成」（本 ADR ship 后）
- 跨 Sprint 继续记录 PM 角色切换轨迹（不停留痕）
- 如再触发 #38/#41/#42 同模式 → 议题 AJ 重开 + PROP-025 升级 v3

## 翻案规则

如未来发现路径 D 仍有结构性盲区：**不修本 ADR**，新建 ADR-N 写明原因，本 ADR 标「被 ADR-N 部分替代」（按 ADR README 翻案铁律）。

## 关联文件

- [PROP-020 主稿](../../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md) — 议题 AJ 落地完整方案档案
- [agent/agents/项目PM-咪咪.md](../../../agent/agents/项目PM-咪咪.md) 等 5 角色 md — PROP-020 P1' 落地
- [agent/agents/AI边界.md](../../../agent/agents/AI边界.md) — 五类升级（PROP-020 P2'）
- [agent/workflows/decision-checkpoint.md](../../../agent/workflows/decision-checkpoint.md) — 3 问硬检查（PROP-020 P3'）
- [agent/rules/web-api-信源选型.md](../../../agent/rules/web-api-信源选型.md) — 议题 AT 元规则（PROP-022 Phase 3）
- [项目PM/](../../../项目PM/) — Q4 防御机制实现（PROP-023 P3 速查表 7 文件）
