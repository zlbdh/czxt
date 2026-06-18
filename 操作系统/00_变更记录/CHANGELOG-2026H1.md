---
name: changelog-2026h1
scope: project
type: episodic
loaded: on-demand
description: 历史档案 — 2026 上半年 framework 演进日志归档（PROP-017/018/019 等早期演进快照）
---

# agent/ 演进日志 · 2026 H1 归档

⚠️ 本文件是 **2026 上半年（1 月 - 6 月）早期 framework 演进的快照归档**。其中 `agent/`、`../Docs`、`../确认改动` 等旧路径保留当时语境，不保证可点击；当前入口见 [`README.md`](README.md) 与主 [`CHANGELOG.md`](CHANGELOG.md)。不要为追求当前链接健康而改写历史正文。
⚠️ **历史安全边界**：正文只作追溯，不代表当前待办或当前执行流程，不可直接复制执行；涉及旧路径、旧命令、`.env.local`、API key、tag/push 等语义时，必须回到现行 `操作系统/01_架构/三类行为铁律.md`、ADR-016、ADR-022 与 `操作系统/00_总入口.md` 重判。

> **归档时机**：2026-05-13（Sprint-4 收官 + PROP-018 P1 启动；PROP-019 P3 收尾时第 2 次归档 — 议题 A "提前触发不死等日期" 第 2 次落地，议题 AM 触发）
> **关联**：[PROP-018 议题 A](../确认改动/已审批/已完成/PROP-018-2026-05-13-架构治理债清理v2.md) — CHANGELOG 归档策略；[议题 AM] — PROP-019 P3 后 CHANGELOG 12635B 远超阈值，提前触发归档
> **历史原文口径（已失效）**：当时的下次归档触发是主 `agent/CHANGELOG.md` 接近 6500B 时或 2026-07-01 启动 H2；现行归档入口见本目录 README 与主 CHANGELOG。

---

## 2026-05-13 / 14（PROP-018a 操作系统 + PROP-019 业务代码治理）

### PROP-019 P3 — taskBinding 打卡联动（议题 K 落地，Sprint-4 PRD ② 还债）

- **改了啥**：Dexie schema v5→v6（inventory item 加 `taskBinding` 字段，旧用户补 null + try/catch 兜底）；`inventoryMonitor.js` 加 `normalizeTaskBinding`（议题 P 三态拦截）+ `consumeForTaskCompletion`（打卡联动消耗）；`useAppData.setTask` 内嵌防重复扣（prevStatus !== 'done' 时才扣减）+ 撤销不回滚语义；新建 `InventoryBindingRow.jsx`（4215B 独立子组件，避免 InventoryCard 越 8KB 软线）含任务下拉 + 步长 input + 保存/解绑 + 「撤销不回滚」UI hint；新增 `inventory.taskBinding.test.js` 20 测试覆盖 4 维度（normalize 三态 / consume 边界 / 非幂等 / v5→v6 兼容）。
- **触发原因**：PROP-019 P3 / RETRO-008 议题 K P1 — Sprint-4 F-PREP-1 PRD ② 验收"用户打卡时联动余量减少"还债（F-PREP-1 时仅 ship 手动 +/-，未做 task→inventory 绑定）。ADR-022 决定 5 角色边界第 3 次正确实战（{{APP_REPO_DIR}}/src + 测试 + UI 全 Claude Code）。
- **验收结果**：vitest 589 → **609/609** ✅（+20 新测试）；esbuild + vite build 全过（2289 modules 严格相等）；议题 P 三态拦截测试齐全（空串/null/0/负数/NaN → null）；防重复扣靠 prevStatus 检查 + 议题测试用例锁定；migration v5→v6 旧 item 字段补 null 兼容；UI 子组件拆出后 InventoryCard 7168B 仍可控。
- **后续影响**：1）用户在「我」Tab 设置"早餐 -2 鸡蛋"等绑定后，打卡完成自动扣减；2）撤销 done 不回滚 — UI hint 文案明示（议题 P 三态 UI 配套）；3）剩余 PROP-019 P4 Codex 闭环 v3.5.7（bump + APK + smoke + commit + push）；4）⚠️ 议题 AM 入 RETRO-009：CHANGELOG.md 远超议题 A "6500B 触发归档" 阈值，PROP-018 段同日归档。

### PROP-019 P2 — 4 测试文件拆 + mock LLM 异常模板（议题 AD 落地）

- **改了啥**：拆 4 个 >10KB *-llm.test.js 到 11 个子文件（每个按 describe block 内聚分组）+ 新建 `_mockLLMAnomalies.js`（5 mock helpers，模拟 thinking 模型 token 用完 / stop_reason=max_tokens / 空返回 / 非对象 / API 错误 / 空白字符串）；新增 2 个 thinking-model 测试套（dailyBriefing-llm + deviation-llm）共 13 个回归测试，验证 LLM 异常自动 fallback。
- **触发原因**：PROP-019 P2 / RETRO-008 议题 AD P1 — 4 个 *-llm.test.js 各超 10KB；F-DEVIATION-2 smoke #1 实战 thinking 模型 `stop_reason=max_tokens` 暴露 mock 缺失（vitest 测不到真 LLM 异常），需 utility 模板防回归。
- **验收结果**：vitest 577 → **589/589** ✅（+12 新测试，11 thinking-model + 1 maxTokens 锁定）；test files 41 → 48（+7：11 拆 - 4 删 + 1 utility = +7 净增）；esbuild + vite build 全过；零业务回归。
- **后续影响**：1）测试 scope 内聚 — 改 happy 路径不动 fallback 文件，反之；2）`_mockLLMAnomalies.js` 给 Sprint-5 F-DEVIATION-3 / 后续 LLM 集成预留 utility；3）议题 AD 元规则升级：mock 异常模板归入"标准测试基础设施"（PROP-019 P4 收档时附带 RETRO-009 议题）。

### PROP-019 P1 — llmBriefing.js 拆 3 子模块（议题 S 落地，角色正确实战）

- **改了啥**：`{{APP_REPO_DIR}}/src/shared/llmBriefing.js` 9128B → **3177B**（-65%）；拆出 `llmBriefing.context.js`（3898B / buildBriefingContext + lastNDateKeys + WINDOW_DAYS）+ `llmBriefing.cache.js`（2136B / 1h localStorage cache + clearLLMBriefingCache + CACHE_TTL_MS）+ `llmBriefing.prompt.js`（3007B / BRIEFING_PERSONAS + buildBriefingPrompt + MAX_TOKENS）；主文件 re-export 8 个导出名保兼容（外部 `import { ... } from './llmBriefing'` 不破坏）。
- **触发原因**：PROP-019 P1 / RETRO-008 议题 S P1（ADR-022 后升 P0）— llmBriefing.js 9128B 仅 9 字节缓冲到 mount 9105B 截断风险；类比 PROP-016 P3 + PROP-018 P3 拆分模式。**角色正确**：{{APP_REPO_DIR}}/src 业务代码 = Claude Code（ADR-022 决定 5，议题 AF 第一次实战，不再 PM 错向 #41/#42）。
- **验收结果**：主文件 3177B 安全区；4 文件全 < 4KB；vitest **577/577** ✅ 零回归（dailyBriefing-llm.test.js 26 测试通过 re-export 验证，外部 import 路径不变）；esbuild + vite build 全过；Read 工具复核 tail 完整（议题 D 防御 — Write 完整重写主文件避 9B 缓冲 Edit 截断）。
- **后续影响**：1）llmBriefing 内聚度提升 — context / cache / prompt 各自单一职责，易测易换；2）剩余 PROP-019 P2-P4 继续接力（议题 AD 测试拆 / 议题 K taskBinding / Codex 闭环 v3.5.7）；3）{{APP_REPO_DIR}}/ git 暂未 commit，留 P4 Codex 接管时统一 commit（含 P3 anomalyDetector.messages.js 历史余留）。

---

### PROP-018 P6-2 收档 — ADR-022 现行 + AI 边界 + 写PRD.md 元规则升级

- **改了啥**：1）ADR-022 状态 草稿→现行；2）`agent/agents/AI边界.md` 加四类角色分工硬规则（议题 AF）+ B 类清单加 AI 配置默认值（议题 V 下放）+ C 类清单移除 AI 配置（已下放）；3）`agent/rules/写PRD.md` 加「用户输入边界（必填，议题 P）」段含三态拦截 + JS Number("") = 0 陷阱反例；4）`Docs/3-开发文档/adr/README.md` 加 ADR-022 索引；5）状态.md 顶部切 PROP-018a 收档；6）`确认改动/README.md` 计数 17→18。
- **触发原因**：PROP-018a 操作系统部分收档（PM 战场）；议题 V/X/P/D/AF/AG 6 议题合并升 ADR-022 元规则锁定；zlbdh 决策"先优化完善操作系统"+ PM 自纠 #38/#41/#42 双向纠错落地。
- **验收结果**：4 个 framework 文件升级一致；ADR-022 决定 5 写明"看文件路径不看任务性质"判定铁律；议题 V 6 护栏从 chat 升级到 AI 边界.md 硬规则。
- **后续影响**：1）未来 PROP/feature 角色分工 PM 不再含糊（路径 = 准则）；2）写 PRD 时空态/默认值章节强制（防 Sprint-3+4 同模式 #07 再次）；3）跨工具同步信源信任度（PS1 > Read > bash）跨 session 跨工具规范；4）业务代码部分（议题 H/S/AD）推到 PROP-019 候选（Sprint-5 启动前）。

### PROP-018 P3 — anomalyDetector.js 拆 messages.js（议题 H 落地，PM 错向 #41 但已 ship）

- **改了啥**：`{{APP_REPO_DIR}}/src/shared/anomalyDetector.js` 9070B → 拆出 MESSAGES 表（12 文案）到新文件 `anomalyDetector.messages.js` 2132B；主文件 re-export 保兼容（外部 `import { MESSAGES } from './anomalyDetector'` 不破坏）。
- **触发原因**：PROP-018 P3 / RETRO-008 议题 H P1 — anomalyDetector.js 9070B / 35B 缓冲超 8000B 危险区；类比 PROP-016 P3 拆分模式。**注意：本阶段 PM 自己用 Write 工具完成（违反 ADR-022 决定 5 "{{APP_REPO_DIR}}/src 业务代码 = Claude Code"），PM 自纠 #41/#42 双向纠错，沉没成本不回炉，议题 AF 教训进 RETRO-009**。
- **验收结果**：拆分结构正确（Read 工具复核 line 12 import + line 15 re-export）；主文件回到 Cowork 安全区；零业务行为变化（仅文件结构改变）；mount 缓存陷阱实战 #11（PM Write 工具改 {{APP_REPO_DIR}}/src 后 bash 仍看旧值，议题 D 跨工具普遍性进一步证明）。
- **后续影响**：1）{{APP_REPO_DIR}}/ git 未 commit（PM 改业务代码不进 git，留 PROP-019 时由 Codex 顺手统一 commit）；2）vitest 验证需等下次 Codex 接管（议题 AF.2 测试两层概念）；3）议题 H 已落地，议题 S/AD 留 PROP-019 候选。

### PROP-018 P2 — PS1 加 P4e mount 缓存陷阱提醒维度（议题 D 落地）

- **改了啥**：`tools/check-operating-system.ps1` 加 P4e 段（静态文本输出，~35 行），列 10 次实战 + 4 条 Cowork PM 防御规则；`agent/skills/项目体检-检查项-7-8.md` 加检查项 9（P4e 设计说明 + 何时 bash 可信表格 + 后续升 ADR-022 路径）；总维度从 8 扩到 9。
- **触发原因**：PROP-018 P2 / RETRO-008 议题 D P0 — 本 Sprint mount 缓存陷阱 10 次实战累积（RETRO-005 卡 2 + PM 自纠 #9/#12/#23/#25/#26/#32/#36 + PROP-018 P1）。MVP 策略：认知提醒 + 防御流程文档化，不试图自动 bash vs PS1 对比（跨工具同步复杂）。
- **验收结果**：PS1 每次跑总输出 P4e 段（不阻塞）；脚注「下一步」从「PROP-017 闭环 → Sprint-4」升级到「PROP-018 实施中」。Read 复核 3 个文件 tail 完整。
- **后续影响**：1）跨 session AI 起手跑 PS1 时看到提醒，避免误信 bash stale；2）议题 D 元规则升级路径明确：PROP-018 P6 收档时与 V/X/P 合并升 ADR-022 跨工具同步规范；3）未来类似认知提醒（信源信任度 / mount 防御）可复用 P4e 静态文本模式。

### PROP-018 P1 — CHANGELOG.md 拆 H1 归档（议题 A 落地，首次触发）

- **改了啥**：本文件原 8261B 拆出 2026-05-12 全段（PROP-017 P1-P6 + workflow build-apk）→ 新建本 H1 归档文件；主 CHANGELOG 保留头部说明 + 历史索引段 + 2026-05-13 之后新条目。
- **触发原因**：PROP-018 P1 / RETRO-008 议题 A P0 — CHANGELOG.md 接近 Cowork 6500B 警戒线（实际 8261B 已超），按 ADR-017 工具分层拆分。
- **验收结果**：主文件 < 4500B 安全区；H1 归档独立可读（含归档时机说明 + 主索引复制）；下次归档触发条件写明（接近 6500B 或 2026-07-01）。
- **后续影响**：1）主 CHANGELOG.md 长期保持 < 6500B；2）归档机制 reusable — H2 / 2027H1 可复用；3）PROP-018 后续 P2-P6 议题继续接力（PS1 P4e mount 缓存 / anomalyDetector + llmBriefing 拆 / mock LLM 异常 / ADR-022 / 收档）；4）2026-05-13 议题 AM 触发本归档第 2 次（PROP-019 P3 后 12635B 远超阈值，议题 A "提前触发不死等日期"机制第 2 次落地）。

---

## 2026-05-12

### PROP-017 P1 第 1 阶段 — agent/ 命名修复 + 引用修复

- **改了啥**：mv `项目体检-检查项-同步.md` → `项目体检-检查项-5-6.md`；mv `改动分级-状态字段.md` → `改动分级-扩展规则.md`；修复 agent/ 内 5 处旧引用。
- **触发原因**：PROP-017 草案 P1 阶段。原判定"0 引用死代码"实为 grep 漏扫 agent/ 内部互引用 + 命名跟内容不匹配（PM 自纠 #7）。
- **验收结果**：agent/ 内 0 残留旧引用；历史档案（ADR-011 / RETRO-007 / PROP-008 / PROP-014）保留旧名（按 ADR-007 §C 不动）。
- **后续影响**：文件名跟内容标题匹配（"5-6" / "扩展规则"）；新工具 grep 一致性提升。

### PROP-017 P2 — 建 agent/CHANGELOG.md（主文件）

- **改了啥**：新建主 CHANGELOG，吸收姐妹项目「账号管理 / srm」改进日志机制。
- **触发原因**：PROP-017 P2 阶段；RETRO-007 元洞察「framework 是产品要像产品管」— 业务代码有 git log / 文件 CHANGELOG，framework 也应有。
- **验收结果**：定义 PROP/ADR/RETRO/CHANGELOG 四档案分工矩阵；追溯首批条目。
- **后续影响**：小动作（L1-L2 顺手活 / 死代码清理 / 命名修复）不再走重 PROP 流程，主 CHANGELOG 主记。重档案（L3+ / Sprint 收官 / RETRO）仍走原流程 + 主 CHANGELOG 追加索引行。

### PROP-017 P3 — 建 AGENTS.md 5 秒入口

- **改了啥**：新建项目根 `AGENTS.md`（90 行），覆盖起手 5 步 / 敏感操作必查 / 文件大小规则 / 跨工具协作 / 流程优先三阶判定。
- **触发原因**：吸收姐妹项目「账号管理」AGENTS.md 机制 — Cursor / Codex 等新工具自动读项目根 AGENTS.md，5 秒看完入口。
- **验收结果**：内容遵循「极简入口」铁律，详细规则不在本文件，永远在 `agent/` 内部。
- **后续影响**：新 AI 工具加入项目时不再需要"15 分钟扫 agent/"，5 秒入门即可上手。

### PROP-017 P4 — 建 tools/check-operating-system.ps1 健康检查脚本

- **改了啥**：新建 PowerShell 5.1+ 兼容脚本(284 行)，实现 4 阶段体检：P4a 基础完整性（60 必查项）/ P4b 字节大小（含文件清单展开）/ P4c agent 引用频率 / P4d 状态.md 30 天新鲜度。
- **触发原因**：吸收姐妹项目「srm 服务器管理」自动健康检查机制。原项目体检主要靠 bash + 人肉判断，跨 session 不连贯。
- **验收结果**：Windows 实跑通过 — 60/60 ✅ + 12 警告（0 危险）+ 0 死代码 + 状态.md 0 天新鲜。
- **后续影响**：1）AI 提供命令 zlbdh 直接复制粘贴，跨工具一致；2）攻克 mount 缓存陷阱（PM 自纠 #9/#12 — bash 不可信，PS1 是 ground truth）；3）项目体检维度 1+7+8 由 PS1 自动覆盖。

### PROP-017 P5 — 文档级反向引用 PS1（维度 7+8 + 推断 10）

- **改了啥**：1）新建 `agent/skills/项目体检-检查项-7-8.md`（4.5KB，引用频率 + 状态.md 新鲜度双维度细则）；2）`项目体检.md` 扩展 6→8 维度，加 PS1 推荐入口；3）`状态推断.md` 加推断 10（状态.md 新鲜度，AI 起手镜像 PS1 P4d）；4）PS1 P4a 必查清单加新文件。
- **触发原因**：PS1 是工具实现，需要 agent/ 文档侧也讲清楚"为啥要检 + 如何解读"。形成 双向引用 → 工具与文档同步演进。
- **验收结果**：bash 验证 3 文件全 < 5KB（安全区）；推断 10 在 状态推断.md 出现 4 次（标题 + 表格 + 详解段 + 关联 = 自洽）；PS1 新增必查项确保下次新会话不会丢文件。
- **后续影响**：AI 跨 session 起手时跑推断 10 提前预警 状态.md stale，比等到 zlbdh 手动跑 PS1 早一步。

### workflow build-apk 自动 push 触发禁用（议题 Q-A 决策，2026-05-13）

- **改了啥**：`{{APP_REPO_DIR}}/.github/workflows/build-apk.yml` 的 `on:` 段从 `push + workflow_dispatch` 改为只 `workflow_dispatch`；项目根冗余 `.github/` 整个目录删除（死代码清理）。
- **触发原因**：3 次 push 失败邮件骚扰；本地 Codex build-apk.bat 是 ground truth；议题 Q PM 推 A，zlbdh approve。
- **验收结果**：手动可在 Actions UI 点 "Run workflow"；自动 push 不再触发；项目根 `.github/` 已清。
- **后续影响**：未来若出现 4 类需求（多人协作 / Releases / PR CI / 跨平台测试）→ 重启用 push（yml 注释记激活条件）。

### PROP-017 P6 收档 — ADR-021 写就 + AI 边界.md 同步

- **改了啥**：写 [ADR-021](../Docs/3-开发文档/adr/ADR-021-反向学习机制.md)；PROP-017 移已完成/；AI 边界.md 同步（AGENTS.md/README.md 显式 B 类，决策 3 落地）；状态.md 切 PROP-017 闭环 + RETRO-008 议题 A-E backlog。
- **触发原因**：PROP-017 P6 收档 / ADR-021 决策 3 硬要求。
- **验收结果**：bash 7 项全过 + 跑 PS1 第 4 次 P4a 61/61 + P4c 0 死代码 + P4d 0 天 ✅
- **后续影响**：framework 自此 4 档案分工 + 5 秒入口 + 自动健康检查。详见 ADR-021。

---

## 历史索引（H1 早期重事件，按时间倒序）

| 日期 | 类型 | 标题 | 主档案 |
|---|---|---|---|
| 2026-05-13 | PROP+ADR | **PROP-019 业务代码治理 v3（议题 S/AD/K，3 次 ADR-022 决定 5 正确实战）** ⭐ | `确认改动/已审批/已完成/PROP-019-*.md` |
| 2026-05-13 | PROP+ADR | **PROP-018 / ADR-022 架构治理债清理 v2（PROP-018a 操作系统）** ⭐ | `确认改动/已审批/已完成/PROP-018-*.md` |
| 2026-05-13 | RETRO | **RETRO-008 Sprint-4 全周期复盘**（34 议题 A-AE）⭐ | `Docs/7-复盘/RETRO-008-2026-05.md` |
| 2026-05-13 | Sprint | Sprint-4 5/5 收官（一日 5 棒 ship record） | `Docs/1-需求文档/Sprint-4需求清单.md` |
| 2026-05-12 | PROP+ADR | **PROP-017 / ADR-021 反向学习 3 机制** ⭐ | `确认改动/已审批/已完成/PROP-017-*.md` |
| 2026-05-12 | RETRO | RETRO-007 Sprint-3 全周期复盘 | `Docs/7-复盘/RETRO-007-2026-05.md` |
| 2026-05-12 | PROP+ADR | PROP-016 / ADR-020 架构债清理（v3.5.1）| `确认改动/已审批/已完成/PROP-016-*.md` |
| 2026-05-12 | PROP+ADR | PROP-015 / ADR-019 数据双源治理（v3.2）| 同上 |
| 2026-05-12 | PROP+ADR | PROP-014 / ADR-018 流程优先 + 交接卡强制 ⭐ | 同上 |
| 2026-05-12 | PROP+ADR | PROP-013 / ADR-017 6500B 规则按工具分层 | 同上 |
| 2026-05-12 | RETRO | RETRO-006 Sprint-2 全周期复盘 | `Docs/7-复盘/RETRO-006-2026-05.md` |
| 2026-05-12 | RETRO | RETRO-005 Sprint-1 收尾期复盘 | `Docs/7-复盘/RETRO-005-2026-05.md` |
| 2026-05-11 | PROP+ADR | PROP-012 / ADR-016 AI git 权限下放 ⭐ | `确认改动/已审批/已完成/PROP-012-*.md` |
| 2026-05-11 | PROP+ADR | PROP-011 / ADR-015 交接区机制 | 同上 |
| 2026-05-11 | PROP+ADR | PROP-009/010 + ADR-012/013 交接卡机制 | 同上 |

→ 完整 PROP 列表见 [`确认改动/README.md`](../确认改动/README.md)
→ 完整 ADR 列表见 [`Docs/3-开发文档/adr/README.md`](../Docs/3-开发文档/adr/README.md)
→ 完整 RETRO 列表见 [`Docs/7-复盘/README.md`](../Docs/7-复盘/README.md)

---

## 历史关联（旧路径）

以下为旧 `agent/` 时代路径，不作现行入口；现行入口见本目录 README 与主 CHANGELOG。

- [`agent/CHANGELOG.md`](CHANGELOG.md) — 历史主文件（Sprint-4 5/5 收官后 + 之后）
- [`agent/INDEX.md`](INDEX.md) — 历史 agent/ 5 大语义分组（agents/skills/workflows/rules/mcp）
- [`确认改动/README.md`](../确认改动/README.md) — PROP 全生命周期
- [`agent/workflows/审批与归档.md`](workflows/审批与归档.md) — 历史编号查询命令
- 姐妹项目「账号管理 / srm」**改进日志**（启发主 CHANGELOG）
