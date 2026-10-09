---
name: state-archive-index
scope: project
type: episodic
loaded: on-demand
description: Historical 状态.md archive index (time-window partitions / issue CK governance / starting with PROP-031)
---

# Status Archive · Historical 状态.md Records

> 📦 Historical sections split from `状态.md`; historical quotations below are English renderings, while literal commands and identifiers retain their original values.
> Issue CK governance / starting with PROP-031 / 2026-05-21

## Archiving Principles

- **状态.md** main file: retain the latest 3 days of core snapshots + top summary + progress reference + maintenance rules
- **Archive files**: partition by time window (month or half-month), using filenames `YYYY-MM-DD至DD.md` or `YYYY-MM-上/下半月.md`
- **Trigger**: 状态.md > 60KB (7.5 times the issue D 8KB red zone), or a new month

## File Inventory

| File | Time range | Size | Key content |
|---|---|---|---|
| [2026-05-09至18.md](2026-05-09至18.md) | 5/9 ~ 5/18 | ~96KB | PROP-019 closure / PROP-020 path D / all 5 Sprint-5 stages / ADR-023+024 / PROP-024 v3.6.3 / PM history table, 5/14-5/18 |
| [2026-05-19至20.md](2026-05-19至20.md) | 5/19 ~ 5/20 | ~23KB | Permanent closure of issue AJ / ADR-025 / Sprint-5 completion / all 3 Sprint-6 stages / Sprint-7 stage 1 PROP-025 / PM self-corrections #51-#58 |
| [2026-05-21至06-11-PM轨迹.md](2026-05-21至06-11-PM轨迹.md) | 5/21 ~ 6/11 | ~336KB | Historical PM transitions (split from 状态.md on 2026-06-14)|

## Usage

- Need the current snapshot → read [`状态.md`](../../../状态.md)
- Trace historical decisions (Sprint-5 decisions / early PM history) → read the corresponding archive
- Issue BE startup required reading → prioritize the top of `状态.md`; the archive is not required

⚠️ Historical safety boundary: archive content includes dangerous historical commands, credential incidents, and obsolete workflows for tracing only. Do not copy and execute directly. Current safety boundaries are defined by the current guidance in `../../01_架构/三类行为铁律.md`, ADR-016, ADR-022, and ADR-025.
⚠️ Old relative links in archived content may not work; return to `状态.md`, `00_总入口.md`, and the corresponding current README for current entry points.

## Follow-up Governance

- Issue CK recordkeeping decay → PROP-027 candidate (issue AJ v2)
- If 状态.md still exceeds 60KB → continue partitioning later (5/19-5/20 → next archive)
