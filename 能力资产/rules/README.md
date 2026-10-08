---
name: rules-index
scope: project
type: semantic
loaded: on-demand
description: Authoritative capability rules for coding, change levels, technical constraints, and issue prevention.
---

# Capability Rules

**Before writing code, read [Writing Code](写代码.md) and [Technical Constraints](已知技术约束.md). Before any change, read [Change Levels](改动分级.md).**

## Purpose

Rules, constraints, standards, and decision frameworks describe **what should be true**, rather than a sequence of steps.

Sequences belong in `workflows/`, single-capability scripts in `skills/`, role behavior in `操作系统/02_智能体/`, and reusable execution-agent assets in `能力资产/agents/`.

## Inventory

| File | Scope |
|---|---|
| [Change Levels](改动分级.md) | L1-L4 classification, test issue triage, and decisions. |
| [Extended Change Rules](改动分级-扩展规则.md) | Extended classification for framework, Docs, handoff, and other paths. |
| [Writing Code](写代码.md) | Naming, file size, state, data flow, errors, and AI calls. |
| [Technical Constraints](已知技术约束.md) and [Appendix](已知技术约束-附录.md) | Twelve constraints: mounts, sandbox, JDK 17, storage, npm.ps1, PowerShell 5.1 stderr, and more. |
| [Writing a PRD](写PRD.md) | Business language and numbering. |
| [Feature Numbering](F编号规则.md) | F-XXX namespaces, numeric ranges, and ID lookup. |
| [Visual Design](视觉设计规范.md) | Mimi's literary style: colors, typography, animation, and interaction. |
| [Security and Privacy](安全与隐私.md) | Current default safeguards for privacy, API keys, and local data. |
| [Borrowing Governance](借鉴治理.md) | Source/item schemas, permissions, security invariants, and A/B/C boundaries. |
| [Post-push Verification](codex-push后防御.md) | Git state and stale-mount safeguards after Codex pushes. |
| [Commit Encoding](git-commit-编码规范.md) | Unicode commit messages, `git commit -F`, and BOM prevention. |
| [Web API Source Selection](web-api-信源选型.md), [Matrix](web-api-信源矩阵.md), and [Appendix](web-api-信源选型-附录.md) | Android WebView selection process, reliability matrix, and counterexamples for navigator.*, Intl.*, and window.* APIs. |

## Relationship to other groups

- `rules/`: decision criteria and constraints—what should be true.
- `操作系统/02_智能体/`: role identities—who does the work. `能力资产/agents/` contains only reusable execution agents.
- `skills/`: a single capability—how to perform one task.
- `workflows/`: multistep procedures—the order of operations.

## Four-level reminder

| Level | Example | Process |
|---|---|---|
| L1 | Copy or small localized change | Change and CHANGELOG. |
| L2 | Behavior refinement or localized bug | Relevant development documentation, code, tests, and CHANGELOG. |
| L3 | New feature | PM/PRD → Development → QA → APK → smoke. |
| L4 | Architecture or schema | Full L3 process plus ADR. |

When uncertain, escalate one level; do not downgrade. The main change-level rule supplies all prerequisite gates.

## File size reminders by tool

| Tool | Advisory | Response |
|---|---|---|
| Cowork, with mount truncation risk | 6,500 bytes | Use Python/Bash for larger writes, bypassing Edit. Health checks warn but do not force splitting. |
| Claude Code / Codex | 8 KB | No hard limit; consider splitting by responsibility above 8 KB. |
| All tools | Verify real bytes before decisions | Confirm with `check-operating-system.ps1` and Read; do not rely solely on mounted `wc -c`. |

See [Writing Code](写代码.md) and section 1 of the technical constraints.
