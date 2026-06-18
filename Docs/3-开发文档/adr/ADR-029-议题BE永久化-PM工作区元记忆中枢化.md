# ADR-029 · 议题 BE 永久化：PM 工作区元记忆中枢化（PROP-023 收档 P6）

- **状态**：现行
- **日期**：2026-05-22
- **关联**：[PROP-023 项目 PM 记忆中枢化](../../../确认改动/已审批/已完成/PROP-023-2026-05-15-项目PM记忆中枢化.md) · [PM 自纠 #43-#48 累积 6 次](../../../状态.md) · [PM工作区/](../../../PM工作区/) · [元规则池.md](../../../操作系统/01_架构/元规则池.md)
- **议题 BE 关闭条件**：PM 工作区物理目录 + 6 PM × 速查表/实战回顾/PM自纠 全部就位 + 起手必查机制 累计 100+ 次实战 ✅ 达成

> ⚠️ **术语更新（2026-06-15）**：早期“子子 PM”统一称为“实施 PM”。本文 PM 工作区机制仍现行，层级术语以 `主-元-决策-实施` 为准。

## 背景

议题 BE 起源 2026-05-15 PROP-023 + PM 自纠 #43-#48 累积 6 次同模式（一日内 framework 元规则记忆错向 6 次）：

| # | 类型 | 描述 |
|---|---|---|
| #43 | 规则记忆错向 | F-SYSCHECK-1 handoff 卡列 CHANGELOG entry 违反 header |
| #44 | PROP 状态字段语义边界 | PROP-021 切「已完成」过早 |
| #45 | 跨平台 API 假设 | navigator.* fallback 假设跨平台同语义 |
| #46 | Capacitor 主版本假设 | handoff 卡 `^7.x` 实际项目 `^6.x` |
| #47 | plugin 集成防御缺失 | F-ALARM-1 handoff 卡未明示 plugin 必静态 import + NotificationChannel 必创建 |
| #48 | chat 输出冗余 | 同一轮 chat 列 2 个相同复制贴代码块 |

**根因**：framework 散落 19 PROP / 22 ADR / 8 RETRO / 21 议题 / 5 PM 角色 md / 多 workflow → PM 切角色帽子前理论上 grep 5-8 文件，实际多次凭记忆 → 元规则记忆错向。

**议题 BE 一句话**：PM 切角色 / 新对话 / 新会话起手时**必查** INDEX + 状态.md + PM 工作区私人速查表 + 待接手交接卡，**不靠记忆**。

## 决定

议题 BE **正式永久关闭**，对应元规则池第 6 元规则（BE 起手必查），ADR-029 永久化其物理实现机制。

### 决定 1 — PM 工作区物理目录永久化（PROP-023 P2-P5 已完成）

`PM工作区/` 顶级目录 + 9 PM 子目录永久确立（task #95-#107 累积完成）：

```
PM工作区/
├── README.md                  ← v1→v3.1 5 次迭代历史
├── 项目PM-咪咪/                ← 主 PM
├── 沉淀PM-沉淀者/              ← 元-层 PM（紧贴主 PM）
├── 操作系统PM-框架管家/         ← 决策 PM
├── 产品PM-需求拆解者/           ← 决策 PM
├── 技术PM-修复决策者/           ← 决策 PM
├── 测试PM-质量门户/             ← 决策 PM
├── 运营PM-运营咪咪/             ← 决策 PM
├── 开发PM-实施者/               ← 实施 PM
└── 测试发布PM-闭环者/           ← 实施 PM
```

每个 PM 工作区目录**必含**：
- `README.md` — PM 入口 + 索引
- `速查表/` — 触发 trigger 时按需读（PROP-031 + ADR-028 scope=agent）
- `INDEX.md` — 该 PM 私人记忆条目索引

### 决定 2 — 起手必查 6 项硬约束（永久化 / 状态.md 顶部）

任何 PM 起手**必读 6 项**（议题 BE 起手必查铁律，已落地状态.md 顶部）：

1. **状态.md 顶部 3 秒起手速查** — 当前里程碑
2. **`能力资产/rules/codex-push后防御.md`** — 议题 BK 防御 / ADR-025
3. **`能力资产/rules/git-commit-编码规范.md`** — 议题 BG 防御
4. **`能力资产/shared/品牌词典.md`** — AI 模型 = 小米 MiMo（非 Claude）
5. **`操作系统/01_架构/演化哲学.md`** — 不模仿现实公司架构（3 问判断）
6. **`PM工作区/项目PM-咪咪/速查表/` 7 文件** — 议题 BE 起手必查核心

新 PM 加入 framework 时**必须**在 6 项之外建立自己的速查表（参考 PROP-031 + ADR-028 frontmatter schema）。

### 决定 3 — speedsheet 触发机制永久化（PROP-031 落地）

PM 切角色帽子时通过 [decision-checkpoint Q4](../../../操作系统/07_完整工作流/decision-checkpoint.md) 自动 grep 触发 speedsheet：

```
Q4：当前 PM 帽子的速查表是否有 trigger 匹配当前任务？
↓
有 → 读对应 speedsheet
↓
无 → 走 default workflow
```

`PROP-031 + decision-checkpoint Q4` 已落地 / 本 ADR 永久化机制。

### 决定 4 — 9 PM 私人记忆中枢机制（PROP-023 自然延伸）

每个 PM 私有 3 类记忆（scope=agent / ADR-028 frontmatter）：

| 类型 | 位置 | scope/type/loaded |
|---|---|---|
| 速查表 | `PM工作区/<PM>/速查表/*.md` | agent / procedural / on-demand |
| 实战回顾 | `PM工作区/<PM>/实战回顾/*.md` | agent / episodic / on-demand |
| PM 自纠 | `PM工作区/<PM>/PM自纠/*.md` | agent / episodic+反思 / triggered |

跨 PM 监督由 [沉淀 PM「沉淀者」](../../../操作系统/02_智能体/沉淀PM-沉淀者.md) 主导（ADR-027 元-层 PM）。

### 决定 5 — 议题 BE 元规则 ADR 加持（不变更编号）

议题 BE 早已是元规则池第 6 永久化元规则（v1.0 / 6 个起点之一），本 ADR-029 **不改变其元规则编号**，仅永久化其**物理实现机制**（PM 工作区目录 + 起手必查 6 项 + speedsheet trigger）。

元规则池 v3.2 → v3.3：BE 行加 ADR-029 标注。

```
G  PRD 来源遵循         (累积实战)
AT 路径遵循             (累积实战)
AM 多角色协作           (累积实战)
AO 错误隔离             (累积实战)
BC Cowork 工程一致性    (累积实战)
🆕 BE 起手必查          → ADR-029 (本 ADR 加持 / 元规则编号不变)
AJ PM 子类化            → ADR-023
P  用户输入三态边界     → ADR-024
BK Cowork mount stale   → ADR-025
CT PM 角色去工具绑定    → ADR-026
CU+DD 沉淀 PM 元-层     → ADR-027
CW 记忆 scope YAML      → ADR-028
```

## 后果

### 收益

- ✅ PM 自纠 #43-#48 类型错向**0 复发**（task #95 后实战 100+ 次未触发同模式）
- ✅ 跨 session PM 切换持久化加强（PM 工作区比临时记忆持久）
- ✅ 9 PM 私人记忆中枢统一物理位置（沉淀 PM 跨 PM 监督有具体目录）
- ✅ 议题 BE 元规则 + 物理实现 + speedsheet trigger 三位一体

### 风险与缓解

| 风险 | 缓解 |
|---|---|
| 9 PM 工作区目录密度过高 | 议题 CM v3.1 已通过物理拆分 + 命名一致化解决 |
| PM 不读速查表凭记忆 | speedsheet trigger 自动化（PROP-031 / decision-checkpoint Q4 ✅ 落地）|
| 速查表本身散落 | 议题 CL 长尾监控 + 沉淀 PM 跨 PM 检查 |

### 验证

| 维度 | 验证方式 | 结果 |
|---|---|---|
| PM 工作区物理目录 | `ls PM工作区/` 9 子目录 | ✅ |
| 起手必查 6 项 | 状态.md 顶部段存在 | ✅ |
| speedsheet trigger | decision-checkpoint Q4 + PROP-031 落地 | ✅ |
| 议题 BE 元规则 | 元规则池.md 第 6 元规则就位 | ✅ |
| 同模式 0 复发 | PM 自纠 #43-#48 类型 task #95 后 0 触发 | ✅（100+ 次实战）|

## 实施清单（追溯）

- ✅ PROP-023 P0+P1 approve（2026-05-15 zlbdh）
- ✅ PROP-023 P2-P4 物理落地（task #95-#100 累积）
- ✅ PROP-023 P5 跨 Sprint 渐进迁移（task #95-#107 PM 自纠 73 独立 .md + 议题全景 + 角色切换轨迹）
- ✅ **PROP-023 P6 本 ADR 收档**（task #108.1 / 2026-05-22）
- ✅ PROP-031 speedsheet trigger 落地（已 ADR）
- ✅ ADR-028 scope frontmatter 配套（议题 CW）
- ✅ ADR-027 沉淀 PM 跨 PM 监督机制（议题 CU+DD）

## 引用决议

- PM 自纠 #43-#48（2026-05-15 一日累积 6 次同模式）
- PROP-023 项目 PM 记忆中枢化（2026-05-15 zlbdh approve A+自己执行）
- 元规则池 v1.0 议题 BE 起点 6 元规则之一
- decision-checkpoint Q4 speedsheet trigger（PROP-031）
- ADR-023 议题 AJ PM 子类化（嵌套架构延伸）

---

⭐ **ADR-029 永久现行 / 与 ADR-022/023/024/025/026/027/028 并列 framework 元规则 ADR**
