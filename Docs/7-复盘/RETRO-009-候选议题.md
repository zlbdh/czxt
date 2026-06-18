# RETRO-009 候选议题 backlog（Sprint-5 进行中预录）

> ⚠️ **本文件不是正式 RETRO-009**，是 Sprint-5 期间累积的「待复盘议题清单」+ 「连续实战记录」。Sprint-5 收官时按 `_模板.md` 长成正式 RETRO-009。
>
> ⚠️ **历史链接说明**：正文中的 `agent/...` 链接是 2026-05 当时目录结构，当前真源已迁到 `操作系统/` 与 `能力资产/`；不要把本候选文件里的旧链接当作当前执行入口。
>
> **起稿**：2026-05-14（PROP-020 路径 D 上线 + F-SYSCHECK-1 ship 后）
> **预期收官**：Sprint-5 5/5 完成
> **起草角色**：操作系统 PM「框架管家」（议题 AJ 实战 #4，decision-checkpoint Q1/Q2/Q3 全过）

## 议题 backlog（按优先级 + 时间倒序）

### 🔴 P0（必处理 / 阻塞类）

#### 议题 G — useAppData.js 拆分（**升 P0**，PROP-021 已闭环）

- **触发证据**：
  - F-SYSCHECK-1 实战 #1：useAppData.js 9593B → 10449B（+856B），超 handoff 卡 ≤400B 目标 215%
  - Claude Code 已尽力压缩（merge online/offline 进 F-DAY-2 useEffect 省 190B，从 +1046B 降至 +856B）
  - 剩余 856B 是 feature 真实最小成本，不可压
- **根因**：useAppData.js 已承担多重职责（today 计算 / task actions / inventory actions / systemState detect / hydration / completedDates / userProfile patch / ...），单文件无法继续承载 Sprint-5 后续 4 棒（F-ALARM-1 / F-REMIND-1 / F-DEVIATION-3 / F-WEEKLY-1）
- **建议方案**：开 **PROP-021「useAppData hook 拆分」**：
  - `useTodayTick.js` — today / 跨午夜 / F-DAY-2/3 tolerance
  - `useTaskActions.js` — setTask / 撤销 / 议题 K taskBinding 集成
  - `useSystemState.js` — F-SYSCHECK-1 systemSense 检测 + online/offline 监听
  - `useInventoryActions.js` — F-PREP-1 inventory CRUD + 议题 K 联动
  - `useAppData.js` 主入口仅做 compose + 顶层 data state
- **优先级**：P0（Sprint-5 第 2 棒 F-ALARM-1 启动**前**建议 ship，否则 useAppData.js 继续膨胀）
- **预估**：L3 / 2-3h Claude Code + 0.5h Codex 闭环
- **状态**：✅ 已闭环（PROP-021 + v3.5.8 真机 smoke + push）：`useAppData.js` 10449B → 6202B，拆出 `useTodayTick` / `useSystemState` / `useTaskActions` / `useRecordActions`。

### 🟡 P1（强烈建议）

#### 议题 AM — CHANGELOG 归档机制实战 ✅ 第 3 次落地

- **触发证据**：2026-05-14 14:05 议题 A "提前触发不死等日期" 第 3 次实战（PROP-019 3 entries → H1，CHANGELOG.md 8004B → < 4KB）
- **状态**：✅ 已落地，归档机制成熟（议题 A 已实证 3 次）
- **后续**：议题 A 机制写进 ADR-022 决定 6 候选 或 议题 AM 收档进 ADR-023 关联段
- **建议方案**：RETRO-009 时一并写 ADR-022 决定 6「CHANGELOG 归档触发阈值与流程」

#### 议题 AN — "framework 内务"细分边界

- **触发证据**：PROP-020 P0 阻塞 #1 — Cowork sandbox 挡 `.claude/agents/` Write；PM 路径白名单内但物理工具不允许
- **根因**：ADR-022 决定 5「framework 内务 = PM」过于粗粒度；实际 `.claude/` 等工具私有目录属于「PM 起稿型」（写 markdown 草稿）vs「Claude Code 落地型」（操作物理文件）
- **建议方案**：扩展 AI边界.md 五类段，加「子类型 a：纯 markdown（PM 直写）」vs「子类型 b：工具私有目录（PM 起稿 + Claude Code 落地）」二级分类
- **优先级**：P1（影响未来 framework 路径决策清晰度）

#### 议题 AO — `.claude/` 目录归属与 .gitignore ✅ 已落地

- **触发证据**：PROP-020 P0 实验后 `.claude/agents/_pingtest.md` 1411B 残留物理文件
- **状态**：✅ PM 已加 `.claude/` `.cursor/` 到 `{{APP_REPO_DIR}}/.gitignore`，Codex commit 顺手带
- **后续**：议题 AO 整合进 ADR-022 决定 7 候选 — 「AI 工具私有目录入 git 策略」
- **优先级**：P1（防未来其他 AI 工具加入 — Cursor / Copilot 等）

#### 议题 AP — 单端工具增强 vs 跨工具一致 判断框架

- **触发证据**：PROP-020 路径 C → D 转向核心原因
- **根因**：议题 AJ 类决策时需要明确判断 — runtime 单端硬挡 vs markdown 跨工具一致，二者不可兼得时如何选
- **建议方案**：RETRO-009 写「判断决策表」入 `agent/rules/` 或 ADR-024 候选 — 「跨工具协作架构决策框架」
- **优先级**：P1（未来类似 L4-L5 决策直接复用）

#### 议题 AR — decision-checkpoint Q4 规则校验扩展（PM 自纠 #43 触发）

- **触发证据**：F-SYSCHECK-1 handoff 卡（PM 写）列「M agent/CHANGELOG.md 加 entry」违反 CHANGELOG header 规则「业务代码改动走 {{APP_REPO_DIR}}/ git history，不进本文件」；Claude Code 通过 PROP-014 三阶判定挡下；decision-checkpoint Q1/Q2/Q3 仅路径维度，未覆盖**规则记忆错向**
- **根因**：decision-checkpoint 3 问设计时只考虑「路径越界」一类，未考虑「指令本身违反现有规则」类
- **建议方案**：扩展 decision-checkpoint 到 **Q4 — 我的指令是否符合现有 framework 元规则**？
  - 类比 C 类敏感操作前 grep AI边界.md，扩展到「写 handoff 卡 / 起 PROP 前 grep 相关规则文件」
  - 或加 `prerelease-rule-check` 子 workflow
- **优先级**：P1（议题 AJ 防御机制扩展，PROP-020 路径 D v1 候选）
- **PM 自纠 #43**：handoff 卡 CHANGELOG 误指令，靠 Claude Code 挡而非 PM 自检 → decision-checkpoint 盲区

### 🟢 P2（值得想）

#### 议题 AQ — vite build modules 数估算方法

- **触发证据**：F-SYSCHECK-1 handoff PM 估 modules +1-3，Claude Code 实际 +7（偏差 +4 / +57%）
- **根因**：PM 估算 modules 数靠"+1 新文件 = +1 module"直觉，未考虑 import 链放大
- **建议方案**：建立 baseline — 新增 1 .jsx + 1 .js + 1 .test.js → 实测 modules 增量公式
- **优先级**：P2（不影响业务，但 PM 估算精度提升）

### ✅ 已完成（留档）

- **议题 AM**：CHANGELOG.md 归档（2026-05-14 实战 #3 完成）
- **议题 AO**：`.claude/` 进 .gitignore（2026-05-14 完成）
- **议题 G**：useAppData hook 拆分 + F-SYSCHECK-1 竞态结构性修复（2026-05-15 v3.5.8 完成）

---

## ⭐ ADR-022 决定 5 连续正确实战记录

| 棒次 | 时间 | 描述 | 角色边界过关？ |
|---|---|---|---|
| 1 | 2026-05-13 PROP-019 P1 | llmBriefing.js 拆 3 子模块（议题 S）— Claude Code 单兵 {{APP_REPO_DIR}}/src | ✅ |
| 2 | 2026-05-13 PROP-019 P2 | 4 测试拆 11 + mock LLM 异常 utility（议题 AD）— Claude Code 单兵 测试 | ✅ |
| 3 | 2026-05-13 PROP-019 P3 | taskBinding 打卡联动（议题 K，Sprint-4 PRD ② 还债）— Claude Code 单兵 {{APP_REPO_DIR}}/src + 测试 + UI | ✅ |
| 4 | 2026-05-14 F-SYSCHECK-1 | 系统状态感知（Sprint-5 第 1 棒）— Claude Code 单兵 {{APP_REPO_DIR}}/src + 测试 + UI | ✅ |
| 5 | 2026-05-14 PROP-021 | useAppData hook 拆分 + systemState 竞态结构性修复 — Claude Code 单兵 {{APP_REPO_DIR}}/src | ✅ |
| 6 | 2026-05-15 PROP-022 | Capacitor Network 修网络信源 + 议题 AT 文档化 tests — Claude Code 单兵 {{APP_REPO_DIR}}/src + npm 依赖 | ✅ |

→ **6 次连续正确**，PM 自纠 #41/#42 同模式已**0 次再触发**（6 次实战中）。

---

## ⭐ 议题 AJ 实战累积记录

| # | 时间 | 实战内容 | decision-checkpoint Q1/Q2/Q3 全过？ | 路径越界？ |
|---|---|---|---|---|
| #1 | 2026-05-14 13:35 - 14:10 | F-SYSCHECK-1 PRD 审 + 写交接卡 + Codex ship 卡 + 议题 A 第 3 次归档 | ✅ 4 次切角色全过 | ❌ 0 越界 |
| #2 | ⏳ Sprint-5 第 2 棒（F-ALARM-1 / F-DEVIATION-3 / 等）| 待累积 | — | — |
| #3 | ⏳ Sprint-5 第 3 棒 | 待累积 | — | — |

→ **累积 3/3 + 0 触发 #38/#41/#42 = 议题 AJ 关闭 + 写 ADR-023**

---

## ⭐ PM 自纠记录（今日累积）

- **#43**（2026-05-14 13:45）：F-SYSCHECK-1 handoff 卡列「M agent/CHANGELOG.md 加 entry」违反 CHANGELOG header 规则
  - 错向类型：**规则记忆错向**（非路径越界）— decision-checkpoint 盲区
  - 防御方式：Claude Code PROP-014 三阶判定（🟡 非阻塞议题）挡下
  - 后续：议题 AR 入 RETRO-009 候选 decision-checkpoint Q4 扩展

---

## ⭐ 议题 D mount 缓存陷阱实战累积

历史 #1-#11（RETRO-008 段已记 11 次）+ 今日新增：
- **#12**（PROP-019 P3 期间，Claude Code）：vite build 前 INVENTORY_DEFAULTS import 路径错，Read 复核立即修复
- **#13**（PROP-020 P0 期间，Cowork）：bash 看 anomalyDetector.js 9070B 旧值 vs Read ground truth
- **#14**（PROP-020 P0 期间，Cowork）：bash 看 .claude/agents/_pingtest.md 不存在 vs Claude Code 已写入
- **#15**（PROP-020 P2' 期间，Cowork）：bash 看 AI边界.md 7462B stale vs Read 验证升级到位
- **#16**（PROP-020 议题 A 第 3 次归档期间，Cowork）：bash 看 CHANGELOG.md 8261B stale vs Read 验证已清

→ 累计 16 次实战，PS1 P4e 防御提醒持续有效。

---

## 起草顺序建议（Sprint-5 收官时长成 RETRO-009）

1. 先写「## 这批改动做了什么」（Sprint-5 5 个 F-XXX + PROP-020 路径 D 落地）
2. 然后「## 哪里顺」（议题 AJ 防御 / decision-checkpoint / ADR-022 决定 5 连续 4 次 / 议题 A 归档 3 次）
3. 然后「## 哪里卡」（议题 G 升 P0 / 议题 AR Q4 扩展 / 议题 AQ 估算偏差 / PM 自纠 #43）
4. 最后「## 要不要改规范」（明确 action item — ADR-023 议题 AJ 关闭 / PROP-021 useAppData 拆分 / ADR-024 跨工具决策框架）

---

## 关联

- [`_模板.md`](_模板.md) — RETRO 4 段结构
- [`README.md`](README.md) — 复盘节奏 + 命名 + 怎么写
- [`RETRO-008-2026-05.md`](RETRO-008-2026-05.md) — 上一份 RETRO（Sprint-4 全周期）
- [`../../agent/CHANGELOG.md`](../../agent/CHANGELOG.md) + [`../../agent/CHANGELOG-2026H1.md`](../../agent/CHANGELOG-2026H1.md) — framework 演化日志
- [`../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md`](../../确认改动/已审批/进行中/PROP-020-2026-05-14-Agent团队架构.md) — 议题 AJ 落地主稿
- [`../../确认改动/已审批/进行中/PROP-020-路径D-方案v0.md`](../../确认改动/已审批/进行中/PROP-020-路径D-方案v0.md) — 路径 D 设计依据
- [`../../agent/agents/AI边界.md`](../../agent/agents/AI边界.md) — 五类 PM 内部子角色
- [`../../agent/workflows/decision-checkpoint.md`](../../agent/workflows/decision-checkpoint.md) — 议题 AJ 错向防御核心
- [`../../agent/agents/项目PM-咪咪.md`](../../agent/agents/项目PM-咪咪.md) 等 5 个 PROP-020 P1' 角色 md
