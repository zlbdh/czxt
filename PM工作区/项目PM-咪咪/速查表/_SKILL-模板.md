---
name: skill-template
description: SKILL.md 规范模板（PROP-031）— PM 角色起新速查表时复制此模板。Progressive Context Loading 标准格式。
loaded: 参考文档（不会被加载，仅作为模板）
---

# SKILL.md 模板 · Progressive Context Loading

> 📚 **PROP-031 落地**（2026-05-21 / task #83）

## 标准 YAML front matter（4 字段必填）

```yaml
---
name: kebab-case-唯一标识        # 例: chat-summary-dedup
description: |
  一句话描述用途（30 字以内）+ 防什么 PM 自纠 # 触发条件（关键词）
trigger: 当 X 时 / 准备 Y 时 / 判定 Z 时   # 关键词触发条件
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---
```

## 写作铁律

| 字段 | 必填 | 写作要点 |
|---|---|---|
| `name` | ✅ | kebab-case / 全局唯一 / 描述场景非动作 |
| `description` | ✅ | 30 字内核心用途 + 防什么 PM 自纠 |
| `trigger` | ✅ | 关键词列表 / 用「时 / 前 / 后」描述时间点 |
| `loaded` | ✅ | 始终写「条件加载（按 trigger 匹配时由 PM 调度）」 |

## 内容部分

YAML front matter 后写正文，结构建议：

1. **铁律 / 核心规则**（带 emoji 加强）
2. **判定流程 / 检查步骤**
3. **同模式累积 / 来源 PM 自纠**
4. **真知识源链接**

## 文件大小原则

- 入口优先短、能快速扫读；超过约 2KB 时先判断是否仍适合做速查表。
- 真正的文件大小阈值按 AGENTS / 项目体检 P4b 的工具分层规则执行，不把 2KB 当硬限制。

## Progressive Loading 收益验证

PM 切角色 decision-checkpoint Q1-Q3 时加 Q4：

```
Q4: 当前任务匹配哪个速查表 trigger？
- 命中 1 个 → 仅 load 该速查表
- 命中 2-3 个 → load 全部命中
- 0 命中 → 跳过（仅 INDEX 入口足够）
```

→ 30 速查表场景下 context 5-10x 节省

---

📌 **使用步骤**：复制本文件到 `PM工作区/<X-PM>/速查表/<scenario>.md` → 改 frontmatter + 正文 → 加到对应 PM 工作区 INDEX
