# ADR-003 · Consolidate Agent/ into rules/ as the Single Maintenance Location for Project Rules

> ⚠️ **Status update, 2026-05-09 — Partially superseded by [ADR-007](ADR-007-rules目录按语义重构为agent.md)**
> The core decision to consolidate Agent into one maintenance location remains valid, but the `rules/` name also carried skills/workflows/agents responsibilities.
> ADR-007 reorganized `rules/` as `agent/`, with 5 semantic categories: agents/skills/workflows/rules/mcp.
> This historical decision remains as a dated record; ADR-007 governs the subsequently active directory structure.
> **Current safety override notice (2026-06-15)**: `rules/` / `Agent/` paths and commands such as `rm -rf Agent/` are historical evidence only and must not be copied and executed directly. The current structure is `操作系统/` + `能力资产/`; every deletion or move must be reassessed under the three-class behavior rules.

- **Status**: Partially superseded by ADR-007 (2026-05-09)
- **Date**: 2026-05-08
- **Decision maker**: zlbdh
- **Related**: Same-day L4 restructuring immediately after ADR-002 (the {{APP_REPO_DIR}}/ migration); partially superseded by ADR-007 on 2026-05-09

## Context

On 2026-05-08, ADR-002 (moving code into `{{APP_REPO_DIR}}/`) and 6 incremental rule additions had just been completed, with rules/ acting as a navigation layer. zlbdh asked whether all future rules and constraints would reside and be maintained in that folder.

**Navigation-only rules/ did not meet the expectation of maintaining rules there**:
- Rule content still lived in `Agent/workflows/`, `Agent/skills/`, `Agent/agents/`, `Docs/2-产品文档/视觉设计规范.md`, `Docs/3-开发文档/已知技术约束.md`, and other locations.
- rules/ only provided navigation.
- Editing rules still required finding the original file; the rules/ README stayed unchanged.
- Maintenance locations remained scattered.

Options:

| Option | Description | Assessment |
|---|---|---|
| A | Keep navigation only | Does not match zlbdh's expectation |
| B | **Consolidate all rule content in rules/ and retire Agent/** | ✅ Selected |
| C | Move only hard constraints and retain Agent/ | Still two centers |

zlbdh selected B.

## Decision

**Move all content** from `Agent/` into `rules/`, along with rule content under `Docs/`:

| Original location | New location |
|---|---|
| `Agent/workflows/AI边界.md` | `rules/ai/AI边界.md` |
| `Agent/workflows/改动分级.md` | `rules/process/改动分级.md` |
| `Agent/workflows/实施循环.md` | `rules/process/实施循环.md` |
| `Agent/workflows/需求接收.md` | `rules/process/需求接收.md` |
| `Agent/workflows/发布流程.md` | `rules/operation/发布流程.md` |
| `Agent/skills/写PRD.md` | `rules/docs/写PRD.md` |
| `Agent/skills/写代码.md` | `rules/code/写代码.md` |
| `Agent/skills/出APK.md` | `rules/operation/出APK.md` |
| `Agent/skills/跑测试.md` | `rules/operation/跑测试.md` |
| `Agent/agents/PM-产品经理.md` | `rules/ai/PM-产品经理.md` |
| `Agent/agents/Dev-开发.md` | `rules/ai/Dev-开发.md` |
| `Agent/agents/QA-测试.md` | `rules/ai/QA-测试.md` |
| `Agent/mcp/README.md` | `rules/mcp/README.md` |
| `Docs/2-产品文档/视觉设计规范.md` | `rules/visual/视觉设计规范.md` |
| `Docs/3-开发文档/已知技术约束.md` | `rules/code/已知技术约束.md` |
| `Agent/README.md` | Delete (replaced by `rules/INDEX.md`) |

Delete the entire `Agent/` directory. Top-level items decrease from 7 to 6.

## Consequences

### Benefits
- **One maintenance location**: edit rules only under `rules/`.
- Top-level items decrease from 7 to 6.
- Rules and business/technical documentation have separate meanings:
  - rules/ = all project constraints, processes, AI behavior, and role playbooks.
  - Docs/ = product, technical, testing, operations, historical, and retrospective documentation.
- **Reusable template**: start another project with `cp -r rules/ 新项目/`.

### Costs
- Update path references in about 11 documents once: README / 项目结构.md / RETRO / ADR-002 / PROPOSAL / etc.
- References to Agent/... must use the mapped rules/... paths after the move.
- The original Agent/ name suggested AI automation resources; rules/ sounds narrower. In practice it takes over all Agent responsibilities plus visual rules, known constraints, and indexes.

### Reconsideration
- **Trigger**: rules/ makes rules harder to find (considered unlikely).
- **Reversal**: `mv rules/* Agent/` using the reverse mapping; restore visual and technical constraint documents to Docs/; reverse the 11 references.
- **Estimated reversal cost**: 1.5–2 hours.

---

## Execution Details (2026-05-08)

- Created 8 rules/ subdirectories (ai / process / code / docs / visual / operation / mcp / git / security).
- Moved 15 files to the mapped rules/ locations with `mv`.
- Deleted 6 `_old-pointer-README.md` files left by the navigation-only layout.
- `rm -rf Agent/`
- Used Python to replace path references in 11 files (`Agent/...` → `rules/...`).
- Fixed 2 excessive replacements: the README structure diagram and INDEX.md line 6.
- Wrote ADR-003 (this document).
- Updated the structure diagram in `Docs/3-开发文档/项目结构.md`.
- Updated Cowork memory to reflect the structure.

## Notes

- Keep `git/` and `security/` as placeholders for future rules.
- `mcp/README.md` was moved from Agent/mcp/ without updating its content; the project currently uses no external MCP.
- `Docs/3-开发文档/adr/` stays in place because ADRs are historical decisions, not rules.
- `Docs/7-复盘/` stays in place because RETROs are reflections, not rules.
