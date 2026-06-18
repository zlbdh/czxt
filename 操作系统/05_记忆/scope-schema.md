---
name: memory-scope-schema
scope: project
type: semantic
loaded: triggered
trigger: 新建记忆类文件时 / 给现有文件加 frontmatter 时 / PROP-037 实施时
description: 12 类记忆位置 YAML frontmatter scope 字段规范 — current scopes（global / project / agent / pm-workspace / session）× 3 type
---

# 记忆 scope YAML Schema（PROP-037 + ADR-028）

> **背景**：议题 CW + 记忆治理方案 — 12 类记忆位置需要 scope 显式化，避免 PM 跨 scope 误读（如 PM 私人 vs 跨 PM 共享）。
> **术语提醒**：`scope=agent` 仅用于 `操作系统/02_智能体/` 的 PM playbook 归属层，不等于 runtime 子 agent；PM 私人工作区使用 `scope=pm-workspace` + `pm:` 字段。
> **业界对标**：Mem0 用 3 tier（user/agent/runtime）；本 framework 保留 ADR-028 的 global/project/agent/session 语义，并增加 `pm-workspace` 实现层，避免 PM 私区被误写成 runtime agent。

---

## 一、YAML Frontmatter Schema

每个 framework 内的记忆类 markdown 文件**顶部**加：

```yaml
---
name: <kebab-case-slug>          # 必填 / 唯一标识
scope: project                    # 必填 / global | project | agent | pm-workspace | session
type: semantic                    # 必填 / episodic | semantic | procedural
agent: <PM 名>                    # 可选 / scope=agent 时用于 02_智能体 playbook
pm: <PM 名>                       # 可选 / scope=pm-workspace 时必填
loaded: always                    # 可选 / always | on-demand | triggered
trigger: <条件描述>                # 可选 / loaded=triggered 时必填
description: <一句话描述>          # 必填 / 1 行 / ≤120 字
---
```

## 二、Scope 字段定义

| Scope | 适用范围 | 示例 |
|---|---|---|
| **global** | 跨项目 / AppData / 用户级 | AppData memory 退役指针 / 用户偏好 |
| **project** | 本项目全局 / 所有 PM 共享 | INDEX.md / 议题全景.md / ADR / 共享技能 |
| **agent** | PM 角色 playbook / 抽象角色归属 | `操作系统/02_智能体/*.md` |
| **pm-workspace** | 单 PM 私人工作区 / 不跨 PM | `PM工作区/<X-PM>/` 速查表 / PM 自纠 artifact |
| **session** | 单次会话 / 短期 | chat 简版 / handoff 卡 / 状态.md 顶部当前快照 |

## 三、Type 3 类定义（对齐业界 Mem0/LangMem）

| Type | 含义 | 示例 |
|---|---|---|
| **episodic** | 事件流 / 时间戳重要 | 状态.md / Sprint节奏.md / git history / PM 自纠（含时间）|
| **semantic** | 事实 / 反思 / 规则 | INDEX.md / 议题全景 / ADR / 共享技能 SOP |
| **procedural** | 可执行步骤 / SOP | PM 速查表 / 共享技能 SOP / handoff 模板 |

## 四、Loaded 3 模式

| Loaded | 加载时机 | 适用 |
|---|---|---|
| **always** | 新会话起手必读 | INDEX.md / AGENTS.md / 状态.md 顶部 |
| **on-demand** | PM 切帽子时按需 | PM 角色定义 / 决策档案 |
| **triggered** | 特定条件触发 | PM 自纠 trigger / mount stale 防御 / git 撤销恢复 |

## 五、12 类记忆位置 scope 映射

| # | 位置 | scope | type | loaded |
|---|---|---|---|---|
| 1 | `操作系统/05_记忆/INDEX.md` + 同目录记忆附录 | project | semantic | always / on-demand |
| 2 | `状态.md` | project | episodic | always |
| 3 | `操作系统/00_变更记录/状态-archive/`（`状态.md` 历史归档切片，仅追溯） | project | episodic | on-demand |
| 4 | `PM工作区/<X-PM>/速查表/` | pm-workspace | procedural | on-demand |
| 5 | `PM工作区/项目PM-咪咪/PM自纠/` | pm-workspace | episodic | triggered |
| 6 | `操作系统/02_智能体/共享技能/` | project | procedural | on-demand |
| 7 | PROP/ADR/RETRO/CHANGELOG/状态.md/交接区 | project | semantic | on-demand |
| 8 | `操作系统/04_台账/议题全景.md` | project | semantic | always |
| 9 | `操作系统/04_台账/版本时间线.md + Sprint节奏.md` | project | episodic | on-demand |
| 10 | `能力资产/rules/ + shared/ + mcp/` | project | semantic | on-demand |
| 11 | AppData memory → INDEX 指针（已退役为指针） | global | semantic | on-demand |
| 12 | `{{APP_REPO_DIR}}/.git/` | project | episodic | n/a（业务代码 / 不入 framework）|

## 六、新建记忆文件的检查清单

✅ 文件顶部加 frontmatter
✅ name 用 kebab-case slug（如 `decision-checkpoint`）
✅ scope 按当前字段集选择：global / project / agent / pm-workspace / session
✅ type 3 选 1
✅ scope=agent 时 agent 字段填 PM 名，仅用于 `操作系统/02_智能体/`
✅ scope=pm-workspace 时 pm 字段填 PM 名，用于 `PM工作区/`
✅ loaded=triggered 时 trigger 字段填条件

## 七、未来扩展

- PROP-039 已重估拆分 / 若开新试点，先以 Mem0 本机只读检索验证外部 memory store 价值；不再把 Mem0 / Skills SDK GA 当作当前阻塞理由
- decision-checkpoint Q4 速查表过滤按 scope 自动收窄（如当前是项目 PM 帽子 → 优先匹配 scope=pm-workspace pm=项目PM-咪咪 或 scope=project）

---

⭐ **schema 永久化由 ADR-028 批准（2026-05-22）**
