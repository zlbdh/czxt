---
name: retro-index
scope: project
type: semantic
loaded: on-demand
description: RETRO Sprint 复盘文档索引
---
# 复盘 / Retrospective

🔍 这里存「跑了一段时间后回头看」的反思笔记。
不是给最终用户看的产品文档，是 zlbdh + 咪咪自己看的"我们这套规范本身有没有问题"。

> ⚠️ **历史安全覆盖说明**：RETRO 正文记录当时事实，不等于当前 SOP。早期文档里的 `git reset --hard HEAD` 预批、`git push origin master`、decision-checkpoint 3 问、chat 简版 ①-⑥ 等均已被现行规则取代：破坏性恢复命令按 [`操作系统/01_架构/三类行为铁律.md`](../../操作系统/01_架构/三类行为铁律.md) 和 [`能力资产/rules/codex-push后防御.md`](../../能力资产/rules/codex-push后防御.md)；分支按单 `main`；决策按 Q1-Q7；chat 收尾按 ①-⑦。

## 为什么要复盘

任何流程都会跑偏。半年前定的规则今天可能：
- 卡住效率（教条但没必要）
- 已经没人遵守（事实上失效）
- 应该被替换（有更好的方法）

定期复盘是**规范保持活的**唯一办法。不复盘的规范都会变成形式主义。

## 复盘节奏（双轨）

**业务批次轨**：每完成 N 个 L3+ 改动复盘一次。N 暂定 = 3。

也就是说，做完 3 个新功能（不算修 bug 的小改动）就停一次，写一份 RETRO 文档。

**framework 触发轨**：Framework PROP 落地、议题永久关闭、9 PM / agent 调度模型升级、元规则池变化、hooks / 体检守卫显著变化，也要写 RETRO 或在最近 RETRO 中专项复盘。

为什么不只按时间（如每月）：怕碰上闲月还硬挤出来写、忙月又跳过；按业务批次 + framework 触发更贴合实际节奏。

## 复盘文档命名

```
RETRO-001-2026-05.md     ← 第 1 次复盘，含日期辅助识别
RETRO-002-2026-07.md
...
```

编号递增。

## 怎么写

用 `_模板.md`。核心结构就 4 段：

1. **这批改动做了什么**（跟 PRD 对照）
2. **哪里顺**（保留这些做法）
3. **哪里卡**（坑、低效、没必要的步骤）
4. **要不要改规范**（具体 action item）

15-30 分钟写完，不要花一下午。

## 复盘后怎么落地

如果复盘里说"某个流程要改"：
1. 在 `确认改动/待审批/` 写一份 PROPOSAL
2. zlbdh 同意后，按 L4 改动等级走（因为这是规范级变更）
3. 真改 `操作系统/` 或 `能力资产/` 下对应规则文件（例如 `操作系统/07_完整工作流/`、`操作系统/03_交接/`、`能力资产/rules/`）
4. 在新 RETRO 里追溯"上次提的 X 已经改完"

不要在 RETRO 文档里直接改规则——RETRO 是观察笔记，规则改动走流程。

## 现有 RETRO 索引

| 编号 | 时间窗 | 触发批次 | 要点 |
|---|---|---|---|
| [RETRO-001](RETRO-001-2026-05.md) | 2026-05-08 | 规范增量 6 + F-205 + {{APP_REPO_DIR}} 迁移 L4 | 首次复盘 — 规范初稳 |
| [RETRO-002](RETRO-002-2026-05.md) | 2026-05-09 | Sprint-1 前期（F-205 / ADR-004 / PROP-003）3 件 L3+ | 业务实施开始 |
| [RETRO-003](RETRO-003-2026-05.md) | 2026-05-09 | 框架升级密集期（PROP-004 / 005 / 006）3 件 L3+ | rules→agent 重构 + 自动化 95% |
| [RETRO-004](RETRO-004-2026-05.md) | 2026-05-11 | 框架细化期（PROP-007 / 008 / 009 / 010）4 件 L3+ | 6500B 必拆（当时口径，现由 ADR-017 分层化）+ 交接卡机制 + 自纠闭环 |
| [RETRO-005](RETRO-005-2026-05.md) | 2026-05-12 | Sprint-1 收尾期（F-002 / F-003 / F-LAYOUT-12 + PROP-012）4 件 L3+ + 1 件 L4 | **Sprint-1 10/10 收官 🎉** + ADR-016 git 权限下放实战首秀 + PROP-013 6500B 工具分层化 backlog |
| [RETRO-006](RETRO-006-2026-05.md) | 2026-05-12 | Sprint-2 全周期（PROP-013/014 + F-PROFILE-12 + F-CHAT-23-DEVIATION）7 件 L3+ | **Sprint-2 5/5 收官 🎉** + ADR-017/018 实战 + PROP-014 chat 简版首次约束 Claude Code + RETRO-005 完成率 6/6 ⭐⭐⭐ |
| [RETRO-007](RETRO-007-2026-05.md) | 2026-05-12 | Sprint-3 全周期（PROP-015 + F-PLAN-1/DAY-1/POSE-1/SLEEP-1/CHAT-4）6 件 L3+ | **Sprint-3 5/5 收官 🎉🎉🎉** + 4 个 APK（v3.2-3.5）+ 测试 +188 + 首次质量门禁回退闭环 + PM 自纠 4→6 |
| [RETRO-008](RETRO-008-2026-05.md) | 2026-05-13 | Sprint-4 5/5 收官（v3.5.1→v3.5.6） | 一日 5 棒 ship + 34 议题暴露 + 议题 V 落地（C 类下放） |
| [RETRO-009](RETRO-009-2026-05.md) | 2026-05-19 | Sprint-5 收官 + PROP-024（v3.5.8→v3.6.3） | Sprint-5 5/5 收官 + 议题 AJ/P 永久化 + 14 议题盘点 |
| [RETRO-010](RETRO-010-2026-05.md) | 2026-05-20 | Sprint-6 收官（v3.6.4→v3.7.0） | Sprint-6 3/3 收官 + 议题 BW 升级临界 + PM 自纠 #51-53 |
| [RETRO-011](RETRO-011-2026-05.md) | 2026-05-20 | Sprint-7 第 1 棒 PROP-025 ship 后（中期专项） | 议题 BW 永久关闭决议 + PM 自纠 #54 案例研究 |
| [RETRO-012](RETRO-012-2026-05.md) | 2026-05-21 | Sprint-7 收官（v3.8.0→v3.8.2） | BW/BU/BV/BX/BZ 五议题永久关闭 + framework 治理升级 |
| [RETRO-013](RETRO-013-2026-05.md) | 2026-05-22~28 | Sprint-8+9 各第 1 棒（v3.9.0 / v3.10.0） | v4.0 架构 2 次完整 ship 实战 + 议题 CC 升 ADR-030 |
| [RETRO-014](RETRO-014-2026-05.md) | 2026-05-28 | Sprint-10 治理 sprint（task #117-#122） | 单日 6 task + 4 新 ADR(029-032) + 元规则 12→15 |
| [RETRO-015](RETRO-015-2026-05.md) | 2026-05-29~30 | Sprint-11 混合 sprint（verify 修复 + v3.10.1） | verify 修复 + CA+CB ship + 9 PM 流程首次完整跑通 |
| [RETRO-016](RETRO-016-2026-06.md) | 2026-06-03~04 | 单 Cowork session 6 件闭环（v3.19-v3.22：recurrence 全频率收口 + A→G 护肤线两刀 + v3.20 parse 阻塞修复 + tag 残留闭合） | 两日 6 刀 / 1211→1286 全绿 / **#95 source-grep 定式提元规则候选** + LLM 链路确定性测试候选 + mount stale 防御打法 4 条（ADR-025 补录候选） |
| [RETRO-017](RETRO-017-2026-06.md) | 2026-06-04~06 | 单 Cowork session 9 件闭环（v3.23-v3.31：A→G/A→E/F 安全三链 + 还债定式三连 + H 清零） | 9 刀 / 1295→1392 全绿 / **A 档案 100% 收口** + ⭐ ultracode 对抗审查首次入流程（抓 C 类红线 + 证伪 PM 前提）+ 还债定式三连 + 免勘察直通边界（PM 自纠）+ 审查驱动 scope 扩展治理样本 / P1 智能内核「小刀直通」型扫完 |
| [RETRO-018](RETRO-018-2026-06.md) | 2026-06-06~07 | v3.32/33/34 三闭环（Home 摘要卡 + 护肤线收口 + **F 钠盐 4 轮 smoke 收敛**·F 清零） | 1402→1454 全绿 / 🥇 LLM 行为约束必须第一刀定义「输出可见 marker」AC（3 轮往返主因）+ prompt 动词即 API（「替代」种子）+ maxTokens path-dependent 取证打法（thinking 吃光 4000）+ 输出契约转向 + 下级实证反驳健康样本 #2 |
| [RETRO-019](RETRO-019-2026-06.md) | 2026-06-07~08 | v3.35/36/37/38 四闭环（G-F5 仪态 + **G-F6 周期预约 5 轮 epic**·G 清零 + HIIT 墙钟 + B 多日视图） | 1454→1533 全绿 / 🥇 多层门控改任一层必全链同词验证（G-F6 二进宫）+ 加固闸模式（canonical 机读输入正则为准·LLM 兜底）+ node-passes-device-fails tail 终极解=确定性化 + LLM saga↔确定性刀交替提速（确定性刀连 3 个一轮过）+ 字节闸前置还债定式 |
| [RETRO-020](RETRO-020-2026-06.md) | 2026-06-08~09 | v3.39/40/41/42 四闭环（便当食品安全 + 出行备货 + **重量曲线🏆首破 schema-less** + M 偏离记录·2 把 schema 数据刀） | 1549→1623 全绿 / 🏆 schema 迁移安全定式确立（2 把刀真机零丢失·新表 4 处改 checklist·无 upgrade·v140→v160）+ 数据刀 ultracode 隐私维度（截断/本地/可删除/不批判）+ 投资刀确定性切法（M 先记录后学习）+ 便当米饭蜡样芽孢杆菌真隐患修 |
| [RETRO-021](RETRO-021-2026-06.md) | 2026-06-14 | PROP-044 AC3+AC4 framework 受控并行首次试点（26 文件 scope frontmatter / 3 并行 worker / 非 Sprint 专项） | B-lite 实战验证 ✅ 0 越界（精确 61−26）+ 体检 gate exit 0 + 派工卡互斥字段有效 / 🔴 barrier 浪费（B 305s 拖死 A 79s·C 55s）→ 候选 **DU** 工作量均衡 + **DV** 越界探针 / 升 ADR 暂缓·标候选·再 1-2 次实战 |
| [RETRO-022](RETRO-022-2026-06.md) | 2026-06-14 | 单日 framework 治理大批次 + **PM 实体化 agent 化**（指针同步 11 文件 + P4h 锚点守卫 + PROP-044 B-lite 2 次试点 + 发布门禁/状态.md 切档 2 P0 + 9 PM 全量 agent 化） | 🥇 hooks 上线即抓自己作者的假绿 + 指针锚点 P4h 守卫封堵漂移 + B-lite spread 5.5×→1.5×（DU 第 2 数据点）+ 🐛 npm.ps1 shim 坑（`cmd /c` 解）+ 状态.md -68% 字节守恒 / **PM 实体化 agent 调度模型升 ADR-038**（9 PM 全量 agent 化 + 项目 PM 单点调度·验收 + 禁嵌套 + 单源落笔）/ DU/DV/DW 留候选 |
| [RETRO-023](RETRO-023-2026-06.md) | 2026-06-22 | czxt 产品化 dogfood 三刀（实例化递归套娃修复 `2d216a8` / README门面+体检scope `6abddc8` / PROP-001 路径软门禁 `96e82cf`·首个 czxt 原生 PROP 全生命周期） | 🥇 dogfood 实跑抓出 5 explorer 漏掉的递归套娃高危 BUG + 🛡️ 框架自带守卫反向 catch 作者本人三处改动 + 🔴 ADR-038 调度模型首会话即被作者违反 2 次（inline→纠正后 PROP-001 首次正确派 worker）+ DW 时间戳第 3 次复发→建议提 PROP + 体检 scope 排除自托管实例待全面排查 |

附属候选文件：[`RETRO-009-候选议题.md`](RETRO-009-候选议题.md) 不是正式 RETRO，不计入正式编号。

**索引同步规则**（RETRO-005 卡 4 修复）：写完新 RETRO **立刻** 回头更新本表。状态推断 + P4i / readme-index 会共同监控「README 索引 vs 实际 RETRO 文件数」一致性。
