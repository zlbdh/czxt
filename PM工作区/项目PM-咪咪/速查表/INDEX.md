---
name: 项目pm-咪咪-skills-index
scope: pm-workspace
pm: 项目PM-咪咪
type: procedural
loaded: always
description: 项目 PM 速查表索引（条件加载入口）。PM 切角色帽子前先读本文件，按 description 决定加载哪个速查表。
---

# 项目 PM 速查表索引 · Progressive Context Loading

> 📚 **PROP-031 落地**（2026-05-21 / task #83）— 7 速查表升级为 SKILL.md 模式
> **设计哲学**：永远先读本索引（~2KB），根据 trigger 匹配再决定加载具体速查表（每个 ~2KB）

## 当前 7 速查表（按 trigger 字典序）

| 名字 | description | trigger | 来源 PM 自纠 |
|---|---|---|---|
| [chat-summary-dedup](chat简版去重检查.md) | 写完 chat 简版 ①-⑦ 后扫一遍防同段重复 | 写完 chat 简版输出前 | #48 |
| [capacitor-version-verify](Capacitor版本核对.md) | 引入 @capacitor/* 前必先 Read package.json 确认主版本 | 准备引入 @capacitor/XXX 新依赖时 | #46 |
| [capacitor-plugin-defense](plugin集成防御.md) | Capacitor plugin 集成 3 项防御（静态 import / NotificationChannel / cap sync）| 写 Capacitor plugin 集成 handoff 卡前 | #47 |
| [changelog-header-check](CHANGELOG-header规则.md) | 写 handoff 列 CHANGELOG 改动前必查 header 规则 | 写 handoff 卡列 CHANGELOG.md 改动前 | #43 |
| [pm-role-boundary-check](ADR-022决定5-4类角色铁律.md) | 检查 PM 应切哪顶帽子（路径归属判定）| 写 handoff/PROP/chat 时 / 判定路径归属时 | #41/#42 |
| [prop-status-semantics](PROP状态字段语义.md) | PROP 状态字段语义边界（pending/approved/in_progress/completed/rejected）| 改 PROP 状态字段时 | #44 |
| [web-api-source-selection](议题AT矩阵速查.md) | web API（navigator/Intl/window）选型矩阵 + WebView 兼容性 | 选 web API 作业务信源前 | — |

## 加载策略

### Always-load（始终加载）

- 本 INDEX（你正在读 / ~2KB）
- `操作系统/05_记忆/INDEX.md` 起手必读

### 条件加载（按 trigger 匹配）

PM 在 decision-checkpoint Q1-Q3 之后加 **Q4「描述匹配的速查表」**：

```
Q4 当前任务匹配哪个速查表 trigger？
  - 描述 → 匹配 1+ 个 trigger 关键词
  - 加载对应 .md（~2KB）
  - 无匹配 → 跳过
```

### Cost 对比

| 模式 | 30 速查表 × 2KB | 总 context |
|---|---|---|
| Always-load（旧）| 全 load | ~60KB / 60K tokens |
| Progressive（新）| INDEX 2KB + 平均匹配 1-2 个 = 4-6KB | ~6KB / **10x 节省** |

## 新增速查表 SOP

1. 该 PM 自纠累积同模式到第 3 次时 → 立速查表
2. 文件命名：场景关键词.md（中文可读 / 不强制英文）
3. 加 YAML front matter（4 字段 / 见下方模板）
4. 加 1 行到本 INDEX 表格
5. 该 PM 工作区 README 加引用

## YAML front matter 模板

```yaml
---
name: kebab-case-唯一标识
description: 一句话描述用途 + 防什么 PM 自纠 # 触发条件
trigger: 当 X 时 / 准备 Y 时 / 判定 Z 时
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---
```

## 跨 PM 速查表

| PM 子角色 | 速查表目录 | 状态 |
|---|---|---|
| 项目 PM「咪咪」| `PM工作区/项目PM-咪咪/速查表/` | ✅ 7 文件 + 本 INDEX |
| 沉淀 PM「沉淀者」| `PM工作区/沉淀PM-沉淀者/速查表/` | ✅ 有 INDEX + 11 条 |
| 操作系统 PM「框架管家」| `PM工作区/操作系统PM-框架管家/速查表/` | ✅ 有 INDEX / 待提炼 |
| 产品 PM「需求拆解者」| `PM工作区/产品PM-需求拆解者/速查表/` | ✅ 有 INDEX / 待提炼 |
| 技术 PM「修复决策者」| `PM工作区/技术PM-修复决策者/速查表/` | ✅ 有 INDEX / 待提炼 |
| 测试 PM「质量门户」| `PM工作区/测试PM-质量门户/速查表/` | ✅ 有 INDEX / 待提炼 |
| 运营 PM「运营咪咪」| `PM工作区/运营PM-运营咪咪/速查表/` | ✅ 有 INDEX / 待提炼 |
| 开发 PM「实施者」| `PM工作区/开发PM-实施者/速查表/` | ✅ 有 INDEX |
| 测试发布 PM「闭环者」| `PM工作区/测试发布PM-闭环者/速查表/` | ✅ 有 INDEX |

---

📌 **PROP-031 v1 落地**（2026-05-21）— 7 速查表加 YAML front matter + 本 INDEX 总入口 + 加载策略说明
📌 **议题 CO 候选**：Progressive Context Loading 机制化 — 待后续 RETRO 评估 ADR 升级
