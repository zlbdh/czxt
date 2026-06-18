---
name: shared-skills-index
scope: project
type: procedural
loaded: on-demand
description: 跨 PM 共享技能库索引（条件加载入口）。多个 PM 子角色通用的 SOP / SKILL.md。与 PM工作区/<X-PM>/速查表/ 私人速查表区分。
---

# 跨 PM 共享技能库

> 📚 **PROP-032 落地**（2026-05-21 / task #85 / 改进 4）— 多 PM 通用 SOP / 与 PM 私人速查表区分
> **设计哲学**：私人速查表 = 该 PM 独有 / 共享技能 = 多 PM 通用复用

## 当前 5 共享技能

| 名字 | description | trigger | 适用 PM |
|---|---|---|---|
| [git-recovery](git撤销恢复.md) | git 损坏 / .git/index 异常 / working tree dirty 紧急恢复 SOP | git 损坏 / mount stale 实战 | 项目 PM / 操作系统 PM / 技术 PM |
| [mount-stale-defense](mount-stale防御.md) | Cowork mount stale 检测 + 5 步防御（ADR-025 落地）| Cowork 端 ls/cat/head 异常 / 跨工具协作 | 项目 PM / 技术 PM |
| [real-device-smoke-checklist](真机smoke清单.md) | 真机 smoke 必跑 N 项清单 / vitest ≠ 真机（议题 CC 已升 ADR-030 / 第 13 元规则） | 测试发布 PM 闭环前；开发 PM 仅交接自查引用 | 测试发布 PM / 项目 PM |
| [verify-checklist-handoff](handoff卡-verify清单.md) | PM 起 handoff/ship 卡 7 项 verify（议题 CD 候选元规则）| 写 handoff/ship 卡前 | 产品 PM / 项目 PM / 操作系统 PM |
| [pm-self-correction-trigger](PM自纠-trigger.md) | PM 自纠触发条件 + 立即落地流程（PROP-030 / artifact 化）| 任何 PM 帽子下 / 发现自己错向时 | 全 PM |

## 私人 vs 共享技能区分

| 维度 | PM 私人速查表（`PM工作区/<X-PM>/速查表/`）| 共享技能（本目录） |
|---|---|---|
| 适用范围 | 该 PM 独有的元规则 | 多 PM 通用的 SOP |
| 治理权 | 该 PM 自治（PM 自纠 #59 跨界禁令）| 所有 PM 可读 / 操作系统 PM 维护 |
| 示例 | 项目 PM 的「chat 简版去重检查」| 「git 撤销恢复」「真机 smoke 清单」|
| 数量上限 | 每 PM 7-10 个 | 全局 5-15 个 |

## 加载策略（Progressive Context Loading）

PM 切角色 decision-checkpoint Q4 中加 Q4b「共享技能 trigger 匹配」：

```
Q4a 私人速查表 trigger 匹配（PM工作区/<X-PM>/速查表/INDEX.md）
Q4b 共享技能 trigger 匹配（本目录 INDEX）
- 命中 → load
- 0 命中 → 跳过
```

## 新增共享技能 SOP

1. 同模式跨 2+ PM 累积时 → 候选升共享技能
2. 写 .md + YAML frontmatter（同 PROP-031 模板）
3. 加 1 行到本 INDEX
4. 不放 PM 私人目录 — 跨界禁令铁律

---

📌 **议题 CP 候选**：跨 PM 共享技能库机制 — RETRO-013 后继续保留；当前真源见 [`../../01_架构/元规则池-候选.md`](../../01_架构/元规则池-候选.md)。
