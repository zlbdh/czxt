---
name: 沉淀pm-沉淀者-readme
scope: pm-workspace
pm: 沉淀PM-沉淀者
type: semantic
loaded: on-demand
description: "Knowledge PM \"Curator\" workspace entry point: meta layer, close collaboration with the lead PM, and ADR-027."
---

# 🪞 Knowledge PM "Curator": Private Workspace

> ⭐ **Meta-layer PM workspace**: task #104.5 / 2026-05-22 / PM self-corrections #65/#68/#71/#72.
> **Role definition**: [Knowledge PM playbook](../../操作系统/02_智能体/沉淀PM-沉淀者.md).
> **Meta-layer PM**: works closely with lead PM "Mimi" throughout the project lifecycle.

## Current status: v4.0 final model implemented; lessons now accumulating

- ✅ **Initial records exist**: `速查表/` contains SOPs for issue AJ tracking, identifying PM self-corrections, and evaluating meta-rule promotion.
- 📋 **Continue developing**:
  - Practice reviews: Knowledge PM summaries of important governance batches.
  - PM self-corrections: reflection on the learning process itself and meta-meta-rules.

## Six main responsibilities: follow section 4 of the role definition

See section 2, the responsibility matrix, in the [role definition](../../操作系统/02_智能体/沉淀PM-沉淀者.md):

1. Monitor issue AJ tracking; scan `状态.md` every 30 minutes.
2. Identify recurring PM self-correction patterns across sprints.
3. Draft cross-sprint RETROs.
4. Govern the meta-rule pool at `操作系统/01_架构/元规则池.md`.
5. Run decision-checkpoint Q1–Q7, including the agent-instantiation decision.
6. Trigger framework health checks.

## Three learning layers: leads Layers 2 and 3

- **Layer 1**: each of the nine PMs' private records; this PM may read but not write them.
- **Layer 2**: this PM's cross-PM coordination and learning, primarily in this directory.
- **Layer 3**: project-wide learning across the entire lifecycle, `操作系统/04_台账/项目沉淀/`.

## Path allowlist

| Category | Path |
|---|---|
| Primary responsibility | This entire directory |
| Meta-rule pool | `操作系统/01_架构/元规则池.md` |
| Project learning records | `操作系统/04_台账/项目沉淀/` |
| Issue backlog | `操作系统/04_台账/议题全景.md` |
| Tool triggers | `能力资产/tools/scripts/check-*.ps1` |
| Read access | All files |
| Prohibited | ❌ `{{APP_REPO_DIR}}/**` / ❌ Other PMs' private learning records, under self-correction #59 |

## Quick references

Create a quick-reference file when the same PM self-correction pattern occurs a third time. Initial entries already exist in `速查表/`; continue expanding them through practice:

- Issue AJ tracking SOP, from PM self-corrections #57/#58/#62.
- Recurring PM self-correction identification SOP, from PROP-030 practice.
- Meta-rule promotion assessment SOP, informed by 9 permanent and 19 candidate rules.
- RETRO drafting SOP, from RETRO-009/010/011/012 templates.

📌 This directory is maintained by the **Knowledge PM**. Other PMs must not reorganize it: self-correction #59.
📌 **Meta-layer position**: close to the lead PM, spanning the project lifecycle, outside the subordinate implementation layer; self-correction #72.
