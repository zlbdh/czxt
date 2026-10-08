# ADR-007 · Restructure `rules/` as `agent/` by Meaning (5 Categories: agents/skills/workflows/rules/mcp)

- **Status**: Historical structural decision; Superseded by the current structure, `操作系统/` + `能力资产/`
- **Date**: 2026-05-09
- **Decision maker**: zlbdh
- **Related**: [PROP-004](../../../确认改动/已审批/已完成/PROP-004-2026-05-09-rules目录按语义重构.md) · **Partially supersedes [ADR-003](ADR-003-Agent整合到rules.md)**

> ⚠️ **Current override notice (2026-06-15)**: ADR-007 is a Historical structural decision about separating `rules/` by meaning. The active structure has evolved into `操作系统/` + `能力资产/`; see [`操作系统/00_总入口.md`](../../../操作系统/00_总入口.md). The `agent/` tree is historical evidence. Commands such as `rm -rf rules/` must not be copied and executed directly; reassess any deletion or move under the three-class behavior rules.

## Context

On 2026-05-08, ADR-003 consolidated scattered AI collaboration content (`Agent/agents/`, `Agent/skills/`, `Agent/workflows/`, `Docs/2-产品文档/视觉设计规范.md`, `Docs/3-开发文档/已知技术约束.md`, etc.) into top-level `rules/`, with 9 groups: ai/process/code/docs/visual/operation/mcp/git/security.

Its core aim, **one maintenance location**, was achieved: rules could be changed in `rules/` rather than across 5 places.

On 2026-05-09, zlbdh asked why agents/skills/workflows directories were absent: rules should hold constraints and rules, whereas skills are neither.

The actual problem was **a mismatch between the `rules/` name and its contents**:

| Under `rules/` | Actual meaning | A rule? |
|---|---|---|
| `ai/AI边界.md` | Behavioral constraints | ✅ |
| `ai/PM-产品经理.md` / `Dev-开发.md` / `QA-测试.md` | Role playbooks | ❌ **agent** |
| `process/改动分级.md` | Classification criteria | ✅ |
| `process/实施循环.md` / `审批与归档.md` / `需求接收.md` | Multistep processes | ❌ **workflow** |
| `code/写代码.md` / `已知技术约束.md` | Coding constraints | ✅ |
| `docs/写PRD.md` / `visual/视觉设计规范.md` | Standards | ✅ |
| `operation/出APK.md` / `跑测试.md` | Operational scripts | ❌ **skill** |
| `operation/发布流程.md` | Multistep process | ❌ **workflow** |
| `mcp/` | Configuration | ❌ **config** |

About half the content was **not rules**. In six months, anyone opening `rules/operation/出APK.md`, including zlbdh, could reasonably wonder why an APK packaging script was called a rule.

## Decision

Restructure `rules/` as `agent/` with 5 semantic categories:

```
agent/                       ← AI collaboration center (top level)
├── INDEX.md                  Task → reading list
├── agents/                  AI role playbooks and boundaries
├── skills/                  Single-capability procedures (“can do this”)
├── workflows/               Multistep processes (“in what order”)
├── rules/                   Actual rules (“how it should be”: constraints, standards, decisions)
└── mcp/                     MCP server configuration
```

**5 semantic boundaries**:
- **agents/** — who acts: role identity.
- **skills/** — one capability, possibly with steps, without chaining capabilities.
- **workflows/** — ordered steps across skills or roles.
- **rules/** — criteria and constraints describing how things should be.
- **mcp/** — configuration.

## Supersession

ADR-003's core decision, **Agent → one maintenance location**, remains valid: `agent/` still centralizes AI collaboration content.

Only its specific choice of **the `rules/` directory name** is superseded. ADR-007 adopts the more accurate `agent/` name and semantic subgroups.

ADR-003's status was updated to “Partially superseded by ADR-007”; the document remains a dated record. The current active structure is governed by `操作系统/00_总入口.md` and `能力资产/`.

## Implementation Details (PROP-004 Stages 1–7)

### Stage 1 — Prepare
- Run ls to find the highest IDs under `agent/workflows/审批与归档.md` §C → PROP-004 / ADR-007 ✓.
- Search the full impact area: {{APP_REPO_DIR}}/ code has 0 references ✓; build-apk.bat 0 ✓; GitHub Actions 0 ✓.
- Create an ADR-007 placeholder to reserve the ID.
- Notify Claude Code to pause F-001 implementation.

### Stage 2 — mkdir and Batch mv
- `mkdir -p agent/{agents,skills,workflows,rules,mcp}`
- Move 15 content files by meaning:
  - `rules/ai/{AI边界,PM-产品经理,Dev-开发,QA-测试}.md` → `agent/agents/`
  - `rules/operation/{出APK,跑测试}.md` → `agent/skills/`
  - `rules/operation/发布流程.md` → `agent/workflows/` (multistep process)
  - `rules/process/{实施循环,审批与归档,需求接收}.md` → `agent/workflows/`
  - `rules/process/改动分级.md` → `agent/rules/` (zlbdh decided classification is a rule, not a process)
  - `rules/{code,docs,visual}/*.md` → `agent/rules/`
- `rm -rf rules/`, including all old README and INDEX files.

### Stage 3 — Write Navigation
- `agent/INDEX.md`: 14 task-to-reading mappings, 5-group reference, historical naming explanation.
- `agent/README.md`: 5-group introduction and boundaries with other top-level directories.
- 5 group READMEs: agents/skills/workflows/rules/mcp.
- 2 substantive placeholder files under zlbdh's selected option ②B:
  - `agent/workflows/git流程.md`
  - `agent/rules/安全与隐私.md`

### Stage 4 — Global Path Updates
Update active documents under zlbdh's option ③C; leave historical archives untouched:
- Root `README.md`: 4 references and the 5-group tree.
- `Docs/3-开发文档/项目结构.md`: Windows backslashes and key conventions.
- `Docs/3-开发文档/adr/README.md`: add ADR-005/006/007 and mark ADR-003 superseded.
- `Docs/7-复盘/README.md` + `_模板.md`.
- `确认改动/README.md` + `_模板.md`.
- `agent/rules/写代码.md` + `agent/workflows/需求接收.md`: 2 old ai/ references within agent/.

Keep historical archives unchanged, except for a top notice on ADR-003 that ADR-007 partially supersedes it:
- ADR-001 / ADR-002 / ADR-006.
- RETRO-001 / RETRO-002.
- PROP-001 / PROP-002 / PROP-003.

### Stage 5 — This ADR
This file.

### Stage 6 — DoD Verification
- All vitest tests pass; documentation restructuring does not affect them.
- Vite build is unaffected.
- No rules/ references in {{APP_REPO_DIR}}/ code ✓.
- No standalone top-level rules/ references in active documentation ✓.
- One adr/README.md historical description of ADR-003 retains literal “rules/,” appropriately.

### Stage 7 — Close PROP-004
- Set PROP-004 status to Approved · Completed (2026-05-09, corresponding to ADR-007).
- Move `已审批/进行中/PROP-004` → `已审批/已完成/`.
- Update `确认改动/README.md` counts: in progress -1, completed +1.

## Consequences

### Benefits
- ✅ **Names match content**: `agent/skills/出APK.md` is understandable later, unlike `rules/operation/出APK.md`.
- ✅ **Common terminology**: aligns with Cowork / Claude Code `.claude/skills/` and `.claude/agents/` concepts.
- ✅ **One maintenance point remains**: a single `agent/` directory for AI collaboration conventions.
- ✅ **Clear placement for new files**: classify by meaning, then use one of 5 groups.
- ✅ **Mount safety**: all new files <5.4KB, well below the measured 8KB lower limit.

### Costs
- ❌ One global update spanning 30+ files, now completed.
- ❌ Partial supersession of ADR-003, a normal use of ADRs to evolve decisions.
- ❌ `rules/...` links **within** historical PROP/RETRO/ADR content become historical snapshots. zlbdh's option ③C retains them as evidence of the time of writing.
- ✅ **Exception**: a top notice stating partial supersession by ADR-XXX is allowed; it clarifies current status without changing the historical decision.

### Mitigated Risks
- {{APP_REPO_DIR}}/ code has no rules/ references; code is unaffected ✓.
- build-apk.bat / GitHub Actions have no rules/ references ✓.
- Mount 8KB truncation: all new files <6KB ✓.
- Placeholder upgrades for git流程 / 安全与隐私 avoid empty directories ✓.

## Naming Retrospective

ADR-003 treated **one maintenance location versus clear meaning** as a tradeoff and chose maintenance simplicity.
ADR-007 achieves **both** through subdirectories.

Lesson: one maintenance location does not require one undifferentiated directory name. One top-level directory can contain semantic subgroups. Consider both dimensions in future decisions.

## Possible Future Evolution

- **mcp/** remains a README placeholder until zlbdh decides to record MCP configuration.
- **git流程.md / 安全与隐私.md** remain placeholders until real rules are needed.
- **Further subdivision** may help if `agents/` or `workflows/` exceeds 10 files; currently 4–5 files per group is reasonable.

## L3+ Change Sequence

| # | Change | Level | ADR | RETRO trigger |
|---|---|---|---|---|
| 1 | F-205 ErrorBoundary | L3 | — | — |
| 2 | PROP-001 large-file split | L3 | ADR-004 | RETRO-001 written |
| 3 | PROP-003 navigation restructuring | L3 | ADR-006 | RETRO-002 written |
| 4 | **PROP-004 rules→agent** (this ADR) | **L4** | **ADR-007** | Counts toward RETRO-003 |
| 5 | (next) | | | |
| 6 | (next) | | | RETRO-003 trigger: every 3 L3+ changes |

Under this cadence, write RETRO-003 after the sixth L3+ change.
