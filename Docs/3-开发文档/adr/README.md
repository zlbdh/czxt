---
name: adr-index
scope: project
type: semantic
loaded: on-demand
description: "Permanent ADR index (39 ADRs / ADR-039 unified borrowing area and lifecycle governance, 2026-07-18)"
---
# ADR — Architecture Decision Records

📐 Record why the design is this way. Write an ADR whenever the code alone cannot explain a decision's _why_.

## What is an ADR?

Each ADR records **one architecture choice and its costs**, answering questions such as:
- Why HashRouter instead of BrowserRouter?
- Why IndexedDB instead of localStorage?
- Why not Redux?
- Why call AI directly instead of through our own backend?

The goal: **Three months later, you, Mimi, or another reader can understand the original choice without guessing from scratch.**

## When to write one

Only **L4 changes**, such as architecture / schema changes, require an ADR. Routine L1/L2/L3 work does not.

**Retrospective records** are also allowed: document an unconventional existing choice that nobody has explained.

## Filenames

```
ADR-001-为什么用HashRouter.md
ADR-002-项目代码迁移到业务仓库子目录.md
ADR-003-Agent整合到rules.md
...
```

Numbers increase sequentially; never reuse or skip them.

## Template

See `_模板.md`. Use three sections: **Context / Decision / Consequences**. Prefer brevity; 5-15 lines is ideal.

## Reversing a decision

If a decision is reversed later, **do not modify the original ADR**. Create a new ADR:

```
ADR-007-放弃HashRouter改用BrowserRouter.md
```

Explain that ADR-001 previously chose X, the new choice is Y, and why.

Preserve history so evolution remains visible.

## Existing ADR index

| ID | Title | Status | Date |
|---|---|---|---|
| ADR-001 | Why HashRouter | Current | 2026-05-08 (retrospective) |
| ADR-002 | Move application code into {{APP_REPO_DIR}}/ | Current | 2026-05-08 |
| ADR-003 | Consolidate Agent/ into rules/ | Partially superseded by ADR-007 | 2026-05-08 |
| ADR-004 | Split large files, PROP-001 B3 | Current | 2026-05-08 |
| ADR-005 | Chat-history archiving, F-203 | Current | 2026-05-09 |
| ADR-006 | Restructure navigation and separate chat, PROP-003 | Current | 2026-05-09 |
| ADR-007 | Restructure rules/ into semantic agent/ groups, PROP-004; Historical structural decision, now covered by `操作系统/` + `能力资产/` | Superseded by the current structure | 2026-05-09 |
| ADR-008 | Framework automation upgrade, PROP-005 | Current | 2026-05-09 |
| ADR-009 | Framework automation v2 incremental optimization, PROP-006 | Current | 2026-05-09 |
| ADR-010 | Framework automation v3: address all nine risks, PROP-007 | Current | 2026-05-09 |
| ADR-011 | Split files over 6500B, PROP-008; historical one-time split, thresholds now follow ADR-017 tool-specific tiers | Partially superseded by ADR-017 | 2026-05-11 |
| ADR-012 | Handoff-card mechanism, PROP-009 | Current | 2026-05-11 |
| ADR-013 | Extract the handoff-card format, PROP-010 | Current | 2026-05-11 |
| ADR-014 | Habit-backfill field without a Dexie version bump, F-006 | Current | 2026-05-11 |
| ADR-015 | Handoff-area mechanism, PROP-011 | Current | 2026-05-11 |
| ADR-016 | Delegate AI git permissions, PROP-012 | Current | 2026-05-11 |
| ADR-017 | Tool-specific tiers for the 6500B rule, PROP-013 | Current | 2026-05-12 |
| ADR-018 | Process first + mandatory handoff cards, PROP-014; chat shorthand later expanded to ①–⑦ by PROP-027 v2 | Current | 2026-05-12 |
| ADR-019 | Dual-source data governance: merge profiles into userProfile, PROP-015 | Current | 2026-05-12 |
| ADR-020 | Architecture debt cleanup: split four files + remove two dead-code areas, PROP-016 | Current | 2026-05-12 |
| ADR-021 | Reverse learning: AGENTS.md + check-operating-system.ps1 + agent/CHANGELOG.md, PROP-017 | Current | 2026-05-12 |
| ADR-022 | Cross-tool synchronization + AI configuration reclassified from Class C + role boundaries; PROP-018a consolidates six topics V/X/P/D/AF/AG | Current | 2026-05-13 |
| ADR-023 | Topic AJ: PM subroles + decision-checkpoint; PROP-020 path D closeout, 3/3 cross-Sprint trials + zero boundary violations ⭐ | Current | 2026-05-15 |
| ADR-024 | Permanent topic P three-state input boundaries: ten cross-Sprint trials, consistent design/tests/UI, zero violations; triggered by Sprint-5 F-WEEKLY-1 closeout ⭐ | Current | 2026-05-19 |
| ADR-025 | Permanent Cowork stale-mount defenses: BK v3, three trials / zero application incidents, meta-rule nine ⭐ | Current | 2026-05-19 |
| ADR-026 | Permanent CT: PM/tool decoupling, PM abstraction ⊥ tool host, cross-tool portability, meta-rule ten ⭐ | Current | 2026-05-22 |
| ADR-027 | Permanent CU+DD: Knowledge PM meta layer + nine PMs across lead–meta–decision–implementation, meta-rule eleven ⭐ | Current | 2026-05-22 |
| ADR-028 | Permanent CW: explicit memory scope in YAML, four tiers × three frontmatter types, meta-rule twelve ⭐ | Current | 2026-05-22 |
| ADR-029 | Permanent BE: PM workspaces as memory hubs, PROP-023 closeout, physical startup checks, ADR support for unchanged meta-rule six ⭐ | Current | 2026-05-22 |
| ADR-030 | Permanent CC: evidence-driven acceptance + device-tested token budgets, unit tests passing ≠ device passing, mandatory thinking-model.test, meta-rule thirteen ⭐ | Current | 2026-05-28 |
| ADR-031 | Complete outward-facing Project PM identity, DH+DK+DF: sole speaker, autonomous decisions, brevity, plain language, four distinct states; meta-rule fourteen ⭐ | Current | 2026-05-28 |
| ADR-032 | Permanent DN health-check quality SOP: broader entry coverage, separability versus core importance, archive exemptions; meta-rule fifteen ⭐ | Current | 2026-05-28 |
| ADR-033 | Permanent CY: untrustworthy large-file mount operations, inaccurate wc/grep, truncated writes, Read as sole truth, tail verification after >6500B writes, full device runs for framework-tool changes; extends ADR-025 to writes, meta-rule sixteen ⭐ | Current | 2026-05-30 |
| ADR-034 | LLM critical-path rules: authoritative canonical-regex guard, marker acceptance, aligned multilayer gates, bounded prompt verbs; RETRO-018/019, DO+DP, PROP-043 ⭐ | Current | 2026-06-09 |
| ADR-035 | Deterministic LLM-chain tests + #95 source-grep pattern: mock→normalize→card, code-identifier-only assertions; DQ+DR, PROP-043 ⭐ | Current | 2026-06-09 |
| ADR-036 | Safe schema migration: four edits for a new table, no upgrade callback, zero-loss device smoke; v15/v16 demonstrated, DS, PROP-043 ⭐ | Current | 2026-06-09 |
| ADR-037 | Sensitive-change adversarial review + privacy lens: mandatory ultracode for data/safety/irreversible changes; truncate sensitive data, local storage, deletion controls, neutral tone; DT, PROP-043 ⭐ | Current | 2026-06-09 |
| ADR-038 | Concrete PM agent scheduling: all nine PMs, writing=worker/read-only=explorer, sole Project PM scheduling/acceptance, main-session final writes to single sources, no nesting, controlled B-lite parallelism; permanent PROP-044, DX, RETRO-021+022 ⭐ | Current | 2026-06-14 |
| ADR-039 | Unified borrowing area and lifecycle governance: one root, immutable source snapshots, dual-card state contracts, explicit root modes, offline P4t guards | Current | 2026-07-18 |

⭐ **Update this table whenever an ADR is added.** PM self-correction #91 showed a soft-rule failure; topic DN's health-check SOP must compare ADR file count with README table rows. Operating System PM Framework Steward updates the index when creating an ADR; Knowledge PM Curator rechecks it at every Sprint RETRO.
