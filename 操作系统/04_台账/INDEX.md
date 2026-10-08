---
name: ledger-index
scope: project
type: semantic
loaded: on-demand
description: Ledger entry — version, Sprint, issue and audit-coverage aggregate views and maintenance procedure.
---

# Ledger Index — Issue CG / PROP-028

> **Single source of truth:** these are aggregate views. Keep pointers and timelines; do not duplicate detailed content. Link to the project's actual knowledge sources: RETRO, TASKS.md, Git, and 状态.md.

## Aggregate views

The original “five views” heading accompanies six entries in the source; all six are retained here.

| Document | Perspective | Source of truth |
|---|---|---|
| [Version timeline](版本时间线.md) | Version overview pointer (current {{CURRENT_VERSION}}; detailed snapshot through v3.8.2) | git log + {{APP_REPO_DIR}}/apk/ |
| [Sprint rhythm](Sprint节奏.md) | Sprint overview pointer (current {{CURRENT_SPRINT}}; detailed snapshot through Sprint-7) | Docs/7-复盘/RETRO-*.md |
| [Issue panorama](议题全景.md) + [historical snapshot](历史归档/2026-05/议题全景-2026-05-22-历史快照.md) | Current issue-status entry and the 2026-05-22 detailed snapshot | RETRO + TASKS.md + 确认改动/ |
| [Project learning](项目沉淀/README.md) | Layer 3 learning across the project lifecycle: business, users, market, and product evolution | Project PM + Operations PM + Knowledge PM |
| [File audit coverage](逐文件审计覆盖台账.md) + [details](逐文件审计覆盖台账-明细.md) | File-by-file and partitioned operating-system audit evidence; do not mistake automated guards for proof of a complete human reading | Agent returns + 状态.md + check-os |
| [Long-term productization roadmap](长期产品化路线图.md) | Productization stages for the czxt template repository; project-area and installer boundaries | README + git remote + 项目配置/ |

## Maintenance procedure

- When drafting each Sprint RETRO, update the version timeline, Sprint rhythm, and issue panorama. Operating System PM owns this work.
- Whenever an issue permanently closes or becomes an ADR, update the issue panorama.
- Whenever a file-by-file operating-system audit concludes, update the audit-coverage ledger.
- A single work-item shipment does not require an update; maintenance mode avoids excessive PM documentation.

### Data lag

This ledger is an **aggregate view**. Pointer pages may lag their sources by several hours to one day. Detailed version and Sprint tables are **periodic snapshots, not exhaustive real-time records**. For the latest information:

- Versions and commits: `git log --oneline`.
- Issues: `TASKS.md` and RETRO.
- Sprint progress: the top summary in `状态.md`.

## Related framework modules

| Path | Responsibility |
|---|---|
| `操作系统/05_记忆/INDEX.md` | Project memory: user preferences, behavior-reflection entry across runtimes, and important history pointers |
| `操作系统/04_台账/INDEX.md` | Project ledger: version, Sprint, and issue aggregates; this file |
| `能力资产/mcp/INSTALLED.md` | MCP tool governance |
| `能力资产/tools/` | Build scripts and dependency matrix |
| `操作系统/02_智能体/` | Nine PM roles and subagent dispatch |
| `操作系统/07_完整工作流/` | Workflows |
| `能力资产/rules/` | Engineering rules |
| `能力资产/shared/` | Shared resources across roles |

## Version

- **v1 — 2026-05-21:** PROP-028 implemented, continuing issue CG and consolidating scattered project records in one directory.
