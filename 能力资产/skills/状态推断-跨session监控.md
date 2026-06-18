---
name: state-inference-cross-session-monitor
scope: project
type: procedural
loaded: triggered
trigger: session 起手 / 跨 session 交接 / PROP 卡进行中 / 实施触碰需升级规范关键词 / 出现"破例"字样时
description: 状态推断推断项 5-9 主入口 — 跨 session 交接卡、PROP 卡告警、规范升级触发、破例计数器、RETRO 索引一致性。
---

# 状态推断 — 推断 5-9（跨 session + 监控）

> 主文件见 [`状态推断.md`](状态推断.md)。推断 1-4 见 [`状态推断-推断项.md`](状态推断-推断项.md)。
> 本文件保留推断 5-9 的高频判断契约；完整 Bash/GNU fallback 跑法见 [`状态推断-跨session监控-附录.md`](状态推断-跨session监控-附录.md)。

## 起手顺序

1. 先完成 AGENTS 5 步：`状态.md`、`操作系统/00_总入口.md`、`角色边界.md`、最新待接手卡、项目体检 + Q1-Q7。
2. 本 skill 再补跑推断 5-9 的必要检查；若发现 stale、积压、进行中 PROP 卡住、同方向破例、RETRO 索引不一致，先处理或交接清楚。
3. 只把结果当“建议 / 风险信号”，不直接替用户拍板，也不替代正式 ①-⑦ / PM 轨迹留痕。

## 推断 5：跨 session 交接卡

**逻辑**：优先读 `交接区/待接手/` 最新文件作上次交接卡；fallback 读 `状态.md` 顶部摘要。

检查点：

- 最新卡是否存在。
- 待接手卡是否为完整 ①-⑥，涉及 PM 轨迹时是否含 ⑦。
- `状态.md` 顶部是否链接最新待接手卡。
- 待接手卡是否比近期代码 / framework 改动明显 stale。
- `交接区/待接手/` 是否积压（当前体检阈值见 `check-handoff-zone.ps1`）。

输出格式：

```text
📍 上次交接卡（YYYY-MM-DD HH:MM，从 <A> → <B>）：
   ① 任务：……
   ② 文件变更：N 新建 / M 修改（含 ≥6500B 警告：……）
   ③ 测试：vitest ✅/❌ | build ✅/❌ | APK ✅/❌ | smoke ✅/❌
   ④ 你的待办：……
   ⑤ 警戒：……
   ⑥ Q&A：……
   ⑦ PM 切换轨迹 / 下一步：……（如卡内提供）
```

如 stale，AI 主动跑推断 1-4 重新对账，不直接用 `状态.md` 数据。旧 3 段卡可兼容读取，但提示下次升级到基础 ①-⑥。

## 推断 6：PROP 卡进行中告警

**逻辑**：`确认改动/已审批/进行中/PROP-*.md` 的 mtime 超过 7 天，提示是否弃用、拆分或继续推进。

输出：

- ✅ 无长期进行中 PROP。
- 🟡 `PROP-XXX` 卡了 N 天，建议确认是继续、拆分还是移动到 `已弃用/`。

## 推断 7：规范升级触发监控

**逻辑**：实施触碰高风险关键词时，主动检查对应规范是否需要升级；已填实文件不再提示“填实”，而是按风险补专项规则或 PROP/ADR。

| 规范文件 | 触发关键词 | 动作 |
|---|---|---|
| `操作系统/07_完整工作流/git流程.md` | git commit / git push / commit message / branch / tag | 复核 ADR-016 6 条件；如有新分支/tag/release 场景，升级 git 流程 |
| `能力资产/rules/安全与隐私.md` | API key / token / 用户隐私 / 备份 / 上云 | 按风险补专项安全规则或起 PROP/ADR |
| `能力资产/mcp/README.md` + `INSTALLED.md` | MCP / mcp 接入 / claude-in-chrome / cowork-mcp | 更新 MCP 清单与敏感动作边界 |

## 推断 8：破例计数器

**逻辑**：扫交接卡 / `状态.md` 历史里的“破例 / exception / 一次性放行”等字样。同方向 ≥2 次，立刻提 PROP 治理，不等第 3 次。

方向粗分：

- git / push / commit 类。
- version / bump / package.json 类。
- 其他同类流程破例。

输出：

- 🔴 同方向 ≥2 次：立即提 PROP 治理。
- 🟡 1 次：记录并警惕复发。
- ✅ 0 次：无动作。

## 推断 9：RETRO README 索引一致性

**逻辑**：实际 `Docs/7-复盘/RETRO-*.md` 文件数 vs `Docs/7-复盘/README.md` 索引行数不一致时告警。

输出：

- ✅ RETRO 索引一致。
- 🔴 文件数 / 索引数不一致：立刻补 README 索引。

## 当前实现入口

- 交接区健康：`能力资产/tools/scripts/check-handoff-zone.ps1`
- PM 轨迹新鲜度：`能力资产/tools/scripts/check-pm-tracking.ps1`
- 全量体检：`能力资产/tools/scripts/check-operating-system.ps1`
- Bash/GNU 旧环境 fallback：[`状态推断-跨session监控-附录.md`](状态推断-跨session监控-附录.md)

## 关联

- [`状态推断.md`](状态推断.md) — 10 项推断总入口
- [`状态推断-推断项.md`](状态推断-推断项.md) — 推断 1-4
- [`状态推断-跨session监控-附录.md`](状态推断-跨session监控-附录.md) — Bash/GNU fallback 和完整示例
- [`../../操作系统/03_交接/交接卡格式.md`](../../操作系统/03_交接/交接卡格式.md) — 交接卡 ①-⑦ 契约
- [`../tools/scripts/check-handoff-zone.ps1`](../tools/scripts/check-handoff-zone.ps1) — 推断 5 的当前项目检查器
