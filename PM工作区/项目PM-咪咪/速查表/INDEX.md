---
name: 项目pm-咪咪-skills-index
scope: pm-workspace
pm: 项目PM-咪咪
type: procedural
loaded: always
description: "Project PM quick-reference index for conditional loading. Read before switching roles and use each description to choose the relevant reference."
---

# Project PM Quick-Reference Index: Progressive Context Loading

> 📚 **PROP-031 implemented**: 2026-05-21 / task #83; seven quick references adopt the SKILL.md pattern.
> **Design**: always read this approximately 2KB index first, then load the approximately 2KB references whose triggers match.

## Seven current references: trigger index

| Name | Description | Trigger | Source self-correction |
|---|---|---|---|
| [chat-summary-dedup](chat简版去重检查.md) | Check chat handoff items ①–⑦ for duplicate sections | After drafting and before sending a short chat handoff | #48 |
| [capacitor-version-verify](Capacitor版本核对.md) | Read package.json to confirm the major version before adding @capacitor/* | Before adding an @capacitor/XXX dependency | #46 |
| [capacitor-plugin-defense](plugin集成防御.md) | Three integration safeguards: static import, NotificationChannel, cap sync | Before a Capacitor plugin integration handoff | #47 |
| [changelog-header-check](CHANGELOG-header规则.md) | Check header rules before listing CHANGELOG changes | Before listing CHANGELOG.md changes in a handoff | #43 |
| [pm-role-boundary-check](ADR-022决定5-4类角色铁律.md) | Determine the correct PM role from path ownership | Handoff / PROP / chat writing or path ownership decisions | #41/#42 |
| [prop-status-semantics](PROP状态字段语义.md) | PROP status boundaries: pending/approved/in_progress/completed/rejected | Before changing a PROP status | #44 |
| [web-api-source-selection](议题AT矩阵速查.md) | Web API selection matrix and WebView compatibility for navigator/Intl/window | Before selecting a Web API as an application data source | — |

## Loading strategy

### Always load

- This INDEX, approximately 2KB.
- `操作系统/05_记忆/INDEX.md`, required at startup.

### Conditional loading by trigger

After decision-checkpoint Q1–Q3, add Q4: match the current task to quick-reference descriptions.

1. Match the description to one or more trigger keywords.
2. Load the corresponding .md file, approximately 2KB each.
3. Skip references when no trigger matches.

### Historical cost comparison

| Mode | Thirty references × 2KB | Total context |
|---|---|---|
| Always-load, old | Load all references | ~60KB / 60K tokens |
| Progressive, new | 2KB INDEX plus an average of 1–2 matches: 4–6KB | ~6KB / 10× savings |

## Adding a quick reference

1. Create one when the same PM self-correction pattern occurs a third time.
2. Name it for scenario keywords: the existing convention allows readable Chinese names and does not require English.
3. Add the four-field YAML frontmatter shown below.
4. Add a row to this INDEX.
5. Add a reference to the PM workspace README.

## YAML frontmatter template

```yaml
---
name: unique-kebab-case-id
description: One sentence explaining its purpose, the PM self-correction prevented, and its trigger.
trigger: When X happens, before Y, or when deciding Z.
loaded: Conditional; the PM loads it when a trigger matches.
---
```

## Cross-PM references

| PM role | Quick-reference directory | Status |
|---|---|---|
| Project PM "Mimi" | `PM工作区/项目PM-咪咪/速查表/` | ✅ Seven files plus this INDEX |
| Knowledge PM "Curator" | `PM工作区/沉淀PM-沉淀者/速查表/` | ✅ INDEX and 11 rules |
| Operating System PM "Framework Steward" | `PM工作区/操作系统PM-框架管家/速查表/` | ✅ INDEX; references to develop |
| Product PM "Requirements Analyst" | `PM工作区/产品PM-需求拆解者/速查表/` | ✅ INDEX; references to develop |
| Technical PM "Fix Strategist" | `PM工作区/技术PM-修复决策者/速查表/` | ✅ INDEX; references to develop |
| Test PM "Quality Gate" | `PM工作区/测试PM-质量门户/速查表/` | ✅ INDEX; references to develop |
| Operations PM "Operations Mimi" | `PM工作区/运营PM-运营咪咪/速查表/` | ✅ INDEX; references to develop |
| Development PM "Implementer" | `PM工作区/开发PM-实施者/速查表/` | ✅ INDEX |
| Test and Release PM "Closer" | `PM工作区/测试发布PM-闭环者/速查表/` | ✅ INDEX |

📌 **PROP-031 v1 implemented**, 2026-05-21: YAML frontmatter for seven references, this INDEX entry point, and the loading strategy.
📌 **Issue CO candidate**: formalize Progressive Context Loading; evaluate promotion to an ADR in a later RETRO.
