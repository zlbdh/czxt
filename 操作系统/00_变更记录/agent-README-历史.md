---
name: agent-readme-history
scope: project
type: episodic
loaded: on-demand
description: Historical archive — AI collaboration center README from the old agent/ directory era (5 groups, superseded by the current operating-system structure)
---

# agent/ — AI Collaboration Center

> ⚠️ **Historical safety boundary**: This body is for traceability only and does not represent the current execution workflow. Do not copy and execute directly; for old paths, old commands, API keys, or handoff formats, reassess against the current `操作系统/` + `能力资产/` sources of truth.
> Historical snapshot, rendered in English: This preserves the old `agent/` era README. Expressions such as “current/sole entry point” refer to 2026-05, not the present entry points. The companion old INDEX is [`agent-INDEX-历史.md`](agent-INDEX-历史.md).
> Frozen historical source snapshot: The links in the body below are old-path samples and are not maintained as present clickable entry points; for the present entry point, see [`../00_总入口.md`](../00_总入口.md).

⭐ **Entry point**: [INDEX.md](INDEX.md) — task → rules to read

## What This Is

The sole maintenance point for all AI collaboration content (roles / skills / workflows / rules / configuration).
Anything outside this directory is not an AI collaboration convention.

## 5 Groups

| Group | Contents |
|---|---|
| [agents/](agents/) | AI role playbooks (PM / Dev / QA / AI boundaries) |
| [skills/](skills/) | Single-capability operating scripts (build APKs / run tests) |
| [workflows/](workflows/) | Multistep workflows (change cycle / approval and archiving / requirement intake / release / git) |
| [rules/](rules/) | Actual rules (coding / PRD writing / visual standards / known constraints / security) |
| [mcp/](mcp/) | MCP server configuration |

## Boundaries with Other Top-Level Directories

| Directory | Contents | Relationship to agent/ |
|---|---|---|
| `agent/` | AI collaboration conventions | The directory itself |
| `Docs/` | Business / technical / test / operations / retrospective documentation | agent/ contains rules; Docs/ contains business documentation |
| `{{APP_REPO_DIR}}/` | React + Capacitor code | agent/ does not modify code |
| `确认改动/` | PROP archive | agent/workflows/审批与归档.md governs PROP transitions |
| `apk/` | APK archive | agent/skills/出APK.md governs packaging |
| `.github/` | GitHub Actions | agent/skills/出APK.md governs the CI portion |

## Historical Naming

On 2026-05-08, ADR-003 placed all AI collaboration content in `rules/`, but the name rules could not cover the meanings of agents/skills/workflows.
On 2026-05-09, PROP-004 / ADR-007 refactored it into `agent/` with 5 semantic categories.

See [`Docs/3-开发文档/adr/ADR-007-...md`](../Docs/3-开发文档/adr/ADR-007-rules目录按语义重构为agent.md).
