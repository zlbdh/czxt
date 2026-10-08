---
name: readme-design-spec
scope: project
type: semantic
loaded: on-demand
description: README design standard (issue DN / task #120) — three required sections, frontmatter, update triggers, and issue BE startup safeguards.
---

# README Design and Maintenance Standard (Issue DN / Sprint-10)

> ⭐ **Background**: The Sprint-10 README health check reviewed 31 files and found three seriously outdated entries: the project root said v2.3 while the actual version was v3.10.0; `02_智能体` still listed the old Product Manager PM; and the PM workspace said six PMs instead of nine. These READMEs threaten issue BE's mandatory startup checks because stale entry points misdirect new sessions.
> ⭐ **Basis**: PROP-040 task #120, PM self-correction #88 (misclassification of the ADR-007 historical archive), and PM self-correction #89 (health-check byte-size blind spot).

---

## 1. Three required sections in every README

```markdown
---
name: <kebab-case-slug>
scope: project | agent | session
type: semantic | procedural
loaded: always | on-demand | triggered
description: <one sentence, at most 120 characters, including the core scope>
---

# <Directory name> — <one-sentence purpose>

## What this group covers (30-second overview)

## File list (table; at most 80 characters per row)

## How this group differs from others
```

Optional section 4, “Related documents”, and section 5, “Quick reference”: add only when below 500B, following issue CO's minimalism.

---

## 2. Design by scope

| Path | scope | type | loaded | Typical use |
|---|---|---|---|---|
| Root `README.md` | project | semantic | always | Includes the first action for a new AI session. |
| `操作系统/*/README.md` | project | semantic | on-demand | Framework subgroup entry point. |
| `能力资产/*/README.md` | project | semantic/procedural | on-demand | Execution-capability subgroup. |
| `PM工作区/<PM>/README.md` | **agent** | semantic | on-demand | Private workspace entry point with `agent: <PM name>`. |
| `Docs/*/README.md` | project | semantic | on-demand | Documentation group, such as ADR/RETRO lists. |

---

## 3. Update triggers and owners

| Trigger | Required README update | Responsible PM |
|---|---|---|
| Ship a new application version | Root README's current vX.Y.Z | Project PM during release archival. |
| Upgrade the nine-PM matrix, such as v3 → v4 or adding a PM | `操作系统/02_智能体/README`, `PM工作区/README`, and the root README's nine-PM summary | Operating System PM. |
| Add an ADR | `Docs/3-开发文档/adr/README` | Operating System PM when creating the ADR. |
| End of Sprint | Refresh each PM workspace README's quick-reference list | Knowledge PM during health-check maintenance. |
| Create, rename, or merge a directory | Parent README's file list | Operating System PM. |

---

## 4. Issue DN health-check procedure: permanent lessons from self-corrections #88 and #89

Perform **all three steps** when checking READMEs:

1. **Version**: does the current vX.Y.Z in the root README match `{{APP_REPO_DIR}}/package.json` version?
2. **Architecture**: do READMEs covering the nine-PM matrix include “v4.0” or “9 PMs across 4 layers”?
3. **Historical records**: before deciding to split a file above 8KB, **check for a historical-record preservation notice or an ADR-007-style explanation** (self-correction #88).

For files above 8KB, distinguish splittable material from essential content (self-correction #89):
- First inspect section byte sizes with `awk`.
- Determine whether each section contains examples/historical detail or essential core material.
- Recommend splitting only when the non-core sections account for at least 30% of the file.

---

## 5. 🆕 Consistency checks for list READMEs (ADR-032 v2 decision 6)

Every README or Markdown index, list, or summary **must agree with the actual file count**:

| List document | Cross-check |
|---|---|
| Table in `Docs/3-开发文档/adr/README.md` | `ls Docs/3-开发文档/adr/ADR-*.md \| wc -l` |
| Permanent/current ADR table in `操作系统/04_台账/议题全景.md` | Number of ADR files that make issue rules permanent. |
| “v3.X / N permanent” field in `操作系统/01_架构/元规则池.md` | Number of rows in section 2's table. |

Historical snapshots support traceability spot checks, not the sole source for current counts. Use active entry points and automated guards for current numbers.

**The Operating System PM must update indexes when creating an ADR. Update the meta-rule pool only for a meta-rule ADR**:
1. Create ADR-XXX.
2. Add one row to the ADR README table.
3. Add one row to the issue-overview ADR table.
4. If the ADR makes a collaboration rule permanent, advance the meta-rule pool from v3.X to v3.(X+1) and add one row to section 2. Do not force ordinary ADRs into the meta-rule pool.

→ PM self-correction #91: failed soft rules leave list READMEs chronically stale. Require two checks and, ultimately, automation through PROP-038 Hooks.

## 6. Issue BE startup-check safeguards

READMEs are frequently used, always-loaded entry points. **An outdated README undermines issue BE's mandatory startup checks.**

Required monthly checklist, led by the Knowledge PM:
- [ ] Root README version matches `{{APP_REPO_DIR}}/package.json`.
- [ ] Nine-PM list in `操作系统/02_智能体/README` matches [role boundaries](角色边界.md).
- [ ] Nine-PM list in `PM工作区/README` matches.
- [ ] README frontmatter coverage matches P4g output; `check-operating-system.ps1` is the current authority.

---

## 7. Related documents

- [PM self-corrections #88 and #89](../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-88+89-体检盲区-批次.md).
- [ADR-033](../../Docs/3-开发文档/adr/ADR-033-大文件mount不可信.md): current large-file governance boundaries.
- [Scope schema](../05_记忆/scope-schema.md): issue CW.
- ADR-029: issue BE mandatory startup checks.
- [Knowledge PM quick reference](../../PM工作区/沉淀PM-沉淀者/速查表/INDEX.md): category D, rule 9.

---

⭐ **ADR-032 / ADR-032 v2 made this standard permanent. Maintain its current guidance; do not treat it as a candidate rule.**
