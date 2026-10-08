---
name: agent-index-history
scope: project
type: episodic
loaded: on-demand
description: Historical archive — AI collaboration center INDEX from the old agent/ directory era (superseded by the current operating-system structure)
---

> ⚠️ **Historical safety boundary**: This body is for traceability only and does not represent the current execution workflow. Do not copy and execute directly; for old paths, old commands, API keys, or handoff formats, reassess against the current `操作系统/` + `能力资产/` sources of truth.
> Historical snapshot, rendered in English: This preserves the old `agent/` era INDEX. Expressions such as “currently active navigation paths” refer to 2026-05, not the present entry points. The companion old README is [`agent-README-历史.md`](agent-README-历史.md).
> Frozen historical source: The links below are old-path samples; for the present entry point, see [`../00_总入口.md`](../00_总入口.md).

# Agent INDEX — Historical Snapshot

🚨 **First actions in a new session** (in order, all mandatory — PROP-011 upgrade):
1. **Read this file** (30 seconds)
2. **Read project-root [`状态.md`](../状态.md)** — summary + progress reference + links
3. ⭐ **Read the latest file in [`交接区/待接手/`](../交接区/待接手/)** — complete 6-section handoff card (introduced by PROP-011)
4. **Run the 7 inferences in [skills/状态推断.md](skills/状态推断.md)** — check code / APK / documentation / handoff-zone alignment
5. **If a stale warning appears → proactively rerun the project health check** [skills/项目体检.md](skills/项目体检.md)

📌 **Read this file at the start of every session** (< 30 seconds).
All AI collaboration content (roles / skills / workflows / rules / configuration) is **under `agent/`** — the sole maintenance point.

> To change any AI collaboration content, edit the corresponding file under `agent/`. `Docs/` contains only business/technical documentation; `{{APP_REPO_DIR}}/` contains only code; `确认改动/` contains only PROP records.

---

## 🎯 Task → Required Reading

| Task | Required reading |
|---|---|
| **Before starting any change** | [agents/AI边界.md](agents/AI边界.md) + [rules/改动分级.md](rules/改动分级.md) |
| **Receive a new requirement** | [workflows/需求接收.md](workflows/需求接收.md) + [agents/PM-产品经理.md](agents/PM-产品经理.md) |
| **Write a PRD / PROP** | [rules/写PRD.md](rules/写PRD.md) |
| **zlbdh approves / rejects a PROP** | [workflows/审批与归档.md](workflows/审批与归档.md) |
| **Assign a new PROP / ADR / RETRO number** | [workflows/审批与归档.md](workflows/审批与归档.md) §C |
| **Write code** | [rules/写代码.md](rules/写代码.md) + [rules/已知技术约束.md](rules/已知技术约束.md) + [agents/Dev-开发.md](agents/Dev-开发.md) |
| **Select a web API (navigator.* / Intl.* / window.*) as a source of truth** | ⭐ [rules/web-api-信源选型.md](rules/web-api-信源选型.md) — Issue AT matrix + real-device verification workflow |
| **Change UI visuals** | [rules/视觉设计规范.md](rules/视觉设计规范.md) |
| **Run tests** | [skills/跑测试.md](skills/跑测试.md) + [agents/QA-测试.md](agents/QA-测试.md) |
| **Build an APK** | [skills/出APK.md](skills/出APK.md) |
| **Release a version** | [workflows/发布流程.md](workflows/发布流程.md) |
| **Wrap up any change** | Final DoD section in [workflows/实施循环.md](workflows/实施循环.md) |
| **Run a project health check (mandatory before archiving every PROP)** | [skills/项目体检.md](skills/项目体检.md) |
| ⭐ **Start a session / reconcile progress** | [skills/状态推断.md](skills/状态推断.md) |
| ⭐ **Collaborate across tools / write a handoff card** | [workflows/交接卡格式.md](workflows/交接卡格式.md) + [`../交接区/README.md`](../交接区/README.md) |
| **Handle privacy / API keys** | [rules/安全与隐私.md](rules/安全与隐私.md) |
| **Commit to git** | [workflows/git流程.md](workflows/git流程.md) |
| **Run MCP** | [mcp/README.md](mcp/README.md) |

---

## 📚 5 Semantic Groups

| Group | Contents | Naming basis |
|---|---|---|
| [agents/](agents/README.md) | AI role playbooks + boundaries | “**Who** does it” |
| [skills/](skills/README.md) | Operating scripts for a single capability | “Know **how** to do it” |
| [workflows/](workflows/README.md) | Ordered, multistep workflows | “In **what order**” |
| [rules/](rules/README.md) | Actual rules (constraints / standards / decision frameworks) | “**How it should be done**” |
| [mcp/](mcp/README.md) | MCP server configuration | Configuration |

---

## 🗂 Current Files by Group: Quick Reference

```
agent/
├── INDEX.md (this file)
├── README.md
├── agents/
│   ├── AI边界.md          A automatic / B must ask / C never modify
│   ├── PM-产品经理.md      PRD / requirement assessment
│   ├── Dev-开发.md         Per-file edits / data-flow constraints
│   └── QA-测试.md          3 validation layers / smoke
├── skills/
│   ├── 出APK.md            Build a dev APK
│   └── 跑测试.md           vitest + esbuild + vite build
├── workflows/
│   ├── Workflows other than 改动分级.md — see rules/
│   ├── 实施循环.md         Requirements→code→tests→APK→wrap-up + DoD
│   ├── 审批与归档.md       PROP state machine + number lookup
│   ├── 需求接收.md         7 steps for receiving a new requirement
│   ├── 发布流程.md         Compile / test / upload / CHANGELOG
│   └── git流程.md          Commit conventions (placeholder)
├── rules/
│   ├── 改动分级.md         L1-L4 classification + test-issue triage
│   ├── 写代码.md           Naming / file size / state management
│   ├── 已知技术约束.md     10 items including mount 9KB / JDK 17 / window.storage
│   ├── 写PRD.md            Business-language principles
│   ├── 视觉设计规范.md     Mimi literary style
│   └── 安全与隐私.md       Privacy / API keys (placeholder)
└── mcp/
    └── README.md           MCP configuration (to be completed)
```

---

## Rename Notes (2026-05-09 PROP-004)

⚠️ On 2026-05-08 this project directory was called `rules/` (created by ADR-003), but user review found that “rules” covered multiple meanings: skills/workflows/agents.

On 2026-05-09, PROP-004 / ADR-007 refactored `rules/` into `agent/`, divided into 5 semantic categories.
ADR-003 is marked “partially superseded by ADR-007” and retained, not deleted — historical decision records preserve timestamps.

The `rules/...` links in historical PROP/RETRO/ADR bodies are snapshots from the time of writing and are no longer active; all currently active navigation paths start from `agent/`.

> Archive note: “Current” here refers to the position in 2026-05; the present entry points have evolved into `操作系统/` + `能力资产/`.
