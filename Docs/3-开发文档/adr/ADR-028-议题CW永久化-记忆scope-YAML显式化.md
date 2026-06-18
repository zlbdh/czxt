# ADR-028 · 议题 CW 永久化：记忆 scope YAML 显式化（4 tier × 3 type）

- **状态**：现行
- **日期**：2026-05-22
- **关联**：[PROP-037 记忆 scope YAML 显式化](../../../确认改动/已审批/进行中/PROP-037-2026-05-22-记忆scope-YAML显式化.md) · [记忆治理方案](../../../操作系统/06_工具治理/历史归档/2026-05/记忆治理方案-2026-05-22.md) · [scope-schema.md](../../../操作系统/05_记忆/scope-schema.md)
- **议题 CW 关闭条件**：记忆治理方案落地（12 类位置完整盘点）+ schema 文件就位 + 实证至少 5 关键文件加 frontmatter ✅ 达成

> **当前口径补记（2026-06-17）**：本文中的 Sprint-8/9/10 与 Mem0 集成语句保留 ADR 当时排期，不代表当前有人实施；当前执行以 `scope-schema.md` 与 PROP-037 待重审状态为准，`pm-workspace` 为 PM 工作区现行 frontmatter scope。

## 背景

议题 CW 起源记忆治理方案（2026-05-22）业界 SOTA 对标研究：
- **Mem0**（47K stars）：3 tier scope（user / agent / runtime）
- **Letta / LangMem**：2-3 tier
- **{{PROJECT_NAME}}当前**：12 类记忆位置散落 / **0 scope 标记** / PM 跨 scope 误读

历史问题：
- 项目 PM 把"PM 自纠"（agent scope）当全 PM 共享（project scope） → 错入共享路径
- 新 PM 接手不知道哪些是"必读"（loaded=always）vs"按需"（on-demand）
- 沉淀 PM 跨 PM 监督时找不到 agent scope 文件列表

## 决定

议题 CW **正式永久关闭**，作为第 12 元规则进入永久化池。

### 决定 1 — YAML Frontmatter Schema 永久化（核心）

所有 framework 内记忆类 markdown 文件**必须**顶部加 frontmatter：

```yaml
---
name: <kebab-case-slug>          # 必填 / 唯一标识
scope: project                    # 必填 / global | project | agent | session
type: semantic                    # 必填 / episodic | semantic | procedural
agent: <PM 名>                    # 可选 / scope=agent 时必填
loaded: always                    # 可选 / always | on-demand | triggered
trigger: <条件描述>                # 可选 / loaded=triggered 时必填
description: <一句话描述>          # 必填
---
```

Schema 完整定义详见 [scope-schema.md](../../../操作系统/05_记忆/scope-schema.md)。

### 决定 2 — Scope 4 Tier 定义（永久化 / 比 Mem0 多 1 tier）

| Scope | 范围 | 示例 |
|---|---|---|
| **global** | 跨项目 / AppData | AppData INDEX 指针 |
| **project** | 本项目全局 / 跨 PM | 议题全景 / ADR / 共享技能 |
| **agent** | 单 PM 私人 | PM 速查表 / PM 自纠 |
| **session** | 单次会话 | chat 简版 / 状态.md 顶部 |

业界 Mem0 只有 3 tier（user/agent/runtime）/ 本 framework 多 1 tier 因为 project 概念明确（vs Mem0 多租户用 user）。

### 决定 3 — Type 3 类对齐业界（永久化 / Mem0 / LangMem 兼容）

| Type | 含义 |
|---|---|
| **episodic** | 事件流 / 时间戳重要 |
| **semantic** | 事实 / 反思 / 规则 |
| **procedural** | 可执行步骤 / SOP |

历史排期曾设想在 PROP-039 集成 Mem0 时按 type 路由到对应 memory store；当前不再把 SDK GA 当作阻塞理由，是否外接 store 需等 PROP-039 重估 / 拆分方案明确。

### 决定 4 — 实施清单：关键文件先行（永久化）

12 类记忆位置不一次性全加，**先做关键 5 个**（reach 80% 价值）：

| 优先级 | 文件 | 何时加 |
|---|---|---|
| P0 | `操作系统/05_记忆/INDEX.md` | ✅ task #107.4 |
| P0 | `状态.md` | ✅ task #107.4 |
| P0 | `操作系统/04_台账/议题全景.md` | ✅ task #107.4 |
| P0 | `操作系统/02_智能体/共享技能/INDEX.md` | ✅ 已有（升级补 scope）|
| P0 | `AGENTS.md` | ✅ task #107.4 |
| P1 | `操作系统/02_智能体/*.md` 9 PM 角色文件 | Sprint-8 排期 |
| P2 | 12 类全覆盖 | Sprint-9 排期 |

新建记忆文件**必须**带 frontmatter（议题 CW 永久规则）。

### 决定 5 — INDEX 升级显示 scope（永久化）

`操作系统/05_记忆/INDEX.md` 在每条记忆条目旁注 scope（如 `[project] 议题全景`），新 PM 起手可按 scope 过滤。

实施在 task #107.4（本任务）。

### 决定 6 — decision-checkpoint Q4 速查表集成（永久化）

`操作系统/07_完整工作流/decision-checkpoint.md` Q4 速查表匹配按 scope 过滤：
- 当前 PM 帽子 = 项目 PM → 优先 `scope=agent agent=项目PM-咪咪` 或 `scope=project`
- 当前 PM 帽子 = 沉淀 PM → 跨 PM 视角，优先 `scope=project` + 跨 PM 监督的 `scope=agent`

实施在 Sprint-8（本 ADR 永久化协议 / 不强制本次落地）。

### 决定 7 — 元规则池升级 11 → 12（永久化第 12 元规则）

新增 **议题 CW · 记忆 scope YAML 显式化** 进入永久化池：

```
G  PRD 来源遵循          (累积实战)
AT 路径遵循              (累积实战)
AM 多角色协作            (累积实战)
AO 错误隔离              (累积实战)
BC Cowork 工程一致性     (累积实战)
BE 起手必查              (累积实战)
AJ PM 子类化             → ADR-023
P  用户输入三态边界      → ADR-024
BK Cowork mount stale    → ADR-025
CT PM 角色去工具绑定     → ADR-026
CU+DD 沉淀 PM 元-层      → ADR-027
🆕 CW 记忆 scope YAML    → ADR-028 本 ADR
```

## 后果

### 收益

- ✅ PM 跨 scope 误读防御（agent vs project 显式区分）
- ✅ 新 PM 接手起手必读 scope=project + scope=agent 自己的，过滤无关 noise
- ✅ Mem0 集成准备就绪（type/scope 字段对齐业界）
- ✅ 沉淀 PM 跨 PM 监督时可按 scope=agent 过滤所有 PM 私人记忆

### 风险与缓解

| 风险 | 缓解 |
|---|---|
| 12 类记忆全加 frontmatter 工程量大 | 决定 4 分批：P0 本次 / P1 Sprint-8 / P2 Sprint-9 |
| Schema 演化导致 frontmatter 失效 | scope-schema.md 版本化（v1 现行 / 重大改动开 PROP） |
| Mem0 集成时 scope 4 tier vs Mem0 3 tier 映射 | PROP-039 实施时设计映射（global+project → user / agent → agent / session → runtime） |

### 验证

| 维度 | 验证方式 | 结果 |
|---|---|---|
| Schema 文件 | `操作系统/05_记忆/scope-schema.md` 存在 + 完整 6 章 | ✅ task #107.4 |
| 关键文件加 frontmatter | INDEX/状态/议题全景/共享技能/AGENTS 5 个 | ✅ task #107.4 实施 |
| 元规则池升级 | `操作系统/01_架构/元规则池.md` 含议题 CW | ✅ task #107.5 |

## 实施清单

- ✅ task #107.4 — Schema 文件 + 5 关键文件加 frontmatter + INDEX 升级
- 🗄️ Sprint-8 — 9 PM 角色文件全加（历史排期，当前已由后续 frontmatter 覆盖与 P4n 守卫接管）
- 🗄️ Sprint-9 — 12 类全覆盖（历史排期，当前以 PROP-037 待重审状态为准）
- 🗄️ Sprint-10 — Mem0 集成（历史排期，当前等待 PROP-039 重估 / 拆分）

## 引用决议

- 记忆治理方案 2026-05-22 §业界 SOTA + §12 类记忆位置
- Mem0 documentation（3 tier scope）
- PROP-037 + 议题 CW

---

⭐ **ADR-028 永久现行 / 与 ADR-022/023/024/025/026/027 并列 framework 元规则 ADR**
