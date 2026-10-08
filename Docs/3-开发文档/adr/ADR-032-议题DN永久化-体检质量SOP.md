---
name: adr-032
scope: project
type: semantic
loaded: on-demand
description: "ADR-032 permanent topic DN health-check quality SOP (meta-rule 15), addressing the three blind spots in PM self-corrections #88/#89/#90"
---

# ADR-032 · Make topic DN permanent: framework health-check quality SOP (meta-rule fifteen)

- **Status**: Current
- **Date**: 2026-05-28
- **Related**: [RETRO-013](../../7-复盘/RETRO-013-2026-05.md) · [PM self-corrections #88+#89](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-88+89-体检盲区-批次.md) · [PM self-correction #90](../../../PM工作区/项目PM-咪咪/PM自纠/PM自纠-90.md) · [README design rules](../../../操作系统/01_架构/README设计规范.md) · [PROP-042](../../../确认改动/已审批/已完成/PROP-042-2026-05-28-大文件红区拆分清单.md)
- **Topic DN closure criteria**: Four same-pattern cases, #88/#89/#90 plus **#91, a persistently outdated ADR README**, and field-tested defensive SOP ✅ Met
- **v2 upgrade, task #124 / 2026-05-28**: Add decision 6, list-style README consistency, and revise decision 4 from three inventories to four.

## Context

The 2026-05-28 Sprint-10 governance sprint exposed **three consecutive framework health-check blind spots**:

| # | Misjudgment | Task exposing it |
|---|---|---|
| #88 | Marked `PM-产品经理.md` as removable residue **without reading its ADR-007 preservation notice**, nearly violating the historical-archive rule | task #117, starting PROP-042 |
| #89 | Classified red-zone files **only by >8KB size**, without weighing separability against core importance; forced splitting would damage frequent use | task #118, withdrawal of PROP-042 stages 2-3 |
| #90 | Used **only `find -name README.md`**, missing `00_总入口.md`, `AGENTS.md`, `INDEX*`, and other entry points, undermining topic BE startup checks | task #121, startup-entry audit |

Three instances of the same pattern reveal a systematic missing SOP, promoted into ADR-032.

## Decision

**Permanently close DN** and add it as **meta-rule fifteen**.

### Decision 1 — Broaden entry-point file coverage (#90)

Framework entry points are **more than README files**. Use the full definition:

```bash
find . \( -name "README.md" \
       -o -name "AGENTS.md" \
       -o -name "00_总入口*" \
       -o -name "总入口*" \
       -o -name "INDEX.md" \) \
   -not -path "*/.git/*" \
   -not -path "*/node_modules/*" \
   -not -path "*/已接手/*" \
   -not -path "*/状态-archive/*"
```

If an entry point contains the following, **check it against the current v4.0 target**:
- "5 PM" / "6 PM" / "8 PM" / "10 PM": should be "9 PM × 4 layers."
- "PM-产品经理" / "Dev-开发" / "QA-测试": historical PM names, except intentional ADR-007 archive exemptions.
- Versions such as "v2.x" / "v3.x": check against {{APP_REPO_DIR}}/package.json and the latest remote tag.

### Decision 2 — Large-file red-zone assessment v2 (#89)

A >8KB red flag **must be followed by a separability-versus-core-importance assessment**:

1. Use `awk` to measure bytes per `## ` section.
2. Classify each section as **long-tail** (cases / history / references / on-demand) or **core** (frequent decisions / mandatory reading).
3. **Recommend splitting only when long-tail sections are ≥30% of the file**.
4. If everything is core, **accept the advisory warning without forcing a split**. AGENTS.md explicitly treats 8KB as an engineering preference, not a hard rule.

Field examples:
- ✅ `decision-checkpoint.md`, 18KB: ~5KB of cases, traceability examples, AJ closeout history, and references moved successfully to an appendix in task #117.
- ❌ `INDEX.md`, 14.8KB: all six sections are core; the only history section is 728B. Do not split; withdrawn in task #118.
- ❌ `角色边界.md`, 13.6KB: the whole nine-PM matrix is core. Do not split; withdrawn in task #118.

### Decision 3 — Read preservation notices before applying archive exemptions (#88)

Before declaring a file removable or obsolete, **read whether it says**:
- **Retained as a historical archive**.
- **ADR-007 rule: historical archives remain untouched**.
- **Absorbed and superseded**, with the old file preserved.
- **Historical archive / superseded by X**.

Any such notice means **intentional preservation: do not delete; exempt from topic AY**.

### Decision 4 — Four mandatory pre-check inventories (v2 adds the fourth)

```
1. All project entry-point files, using decision 1's find command.
2. All files >8KB, using find -size +8192c.
3. All files lacking frontmatter, using grep -L "^---".
🆕 4. Consistency of list-style README/.md files, under decision 6.
```

These form the prerequisite SOP: **every framework health check must run all four**.

### 🆕 Decision 6 — List-style README consistency (v2 / #91)

Every index / list / summary README or Markdown file **must match the actual file inventory**:

| List file | Consistency check |
|---|---|
| `Docs/3-开发文档/adr/README.md` table | Compare with `ls Docs/3-开发文档/adr/ADR-*.md \| wc -l` |
| Current permanently closed ADR table in `操作系统/04_台账/议题全景.md` | Compare with the number of topic-permanence ADR files |
| "v3.X / N permanent" field in `操作系统/01_架构/元规则池.md` | Compare with section two's table rows |

**One-command bash check**, a Sprint-11 integration candidate for `能力资产/tools/scripts/check-operating-system.ps1`:
```bash
adr_files=$(ls Docs/3-开发文档/adr/ADR-*.md | wc -l)
adr_readme=$(grep -c "^| ADR-" Docs/3-开发文档/adr/README.md)
[ "$adr_files" = "$adr_readme" ] || echo "🔴 Mismatch / files $adr_files vs README $adr_readme"

panorama_adr=$(grep -cE "^\| \*\*🆕? ADR-|^\| \*\*ADR-" 操作系统/04_台账/议题全景.md)
echo "Permanent ADR rows in the topic panorama: $panorama_adr"

pool_rows=$(sed -n '/## 二、/,/## 三、/p' 操作系统/01_架构/元规则池.md | grep -cE '^\| \*\*')
echo "Meta-rule pool section-two rows: $pool_rows"
```

**Dual verification ownership**:
- **Operating System PM Framework Steward, when creating an ADR**: Immediately update all three locations — ADR README, topic panorama, and meta-rule pool. Updating only the ADR is insufficient.
- **Knowledge PM Curator, weekly**: Run the three-way bash consistency check and trigger repairs on mismatch.

**Automation path**, the ultimate defense:
- Integrate a one-command check into a P4? phase of `check-operating-system.ps1`, a Sprint-11 candidate.
- After PROP-038 Hooks GA, watch the ADR directory and update README automatically, Sprint-9+.

### Decision 5 — Expand the meta-rule pool from fourteen to fifteen

```
G / AT / AM / AO / BC / BE(ADR-029) / AJ(ADR-023) / P(ADR-024)
BK(ADR-025) / CT(ADR-026) / CU+DD(ADR-027) / CW(ADR-028)
CC(ADR-030) / DH+DK+DF(ADR-031)
🆕 DN Health-check quality SOP → ADR-032, this record
```

## Consequences

### Benefits
- ✅ Defenses cover the three #88/#89/#90 blind spots and prevent recurrence.
- ✅ A systematic health-check SOP replaces the assumption that checking README files is sufficient.
- ✅ Unified governance of archives, large-file warnings, and entry points.

### Risks and mitigations
| Risk | Mitigation |
|---|---|
| SOP execution cost: three find inventories every time | Integrate into a P4? phase of `能力资产/tools/scripts/check-operating-system.ps1` for one-command use |
| Subjectivity in "long-tail ≥30%" | Provide field examples contrasting decision-checkpoint and INDEX; accumulate Knowledge PM experience |

### Verification
| Dimension | Result |
|---|---|
| Decision 1 | task #121 scanned multiple entry types and found two new stale items ✅ |
| Decision 2 | task #117 split decision-checkpoint; task #118 withdrew INDEX / role-boundary splits ✅ |
| Decision 3 | task #117 self-correction #88 withdrew deletion of PM-产品经理.md ✅ |

## Implementation checklist (retrospective + follow-up)

- ✅ Artifact for self-corrections #88+#89, task #118.
- ✅ Standalone #90 artifact, task #121.
- ✅ Create README设计规范.md, task #120 / topic DN precursor.
- ✅ Draft this ADR, task #122.
- ⏳ Integrate three SOP inventories into check-operating-system.ps1, Sprint-11+ candidate.
- ⏳ Update Knowledge PM quick-reference category D with the #90 lesson.

## Referenced decisions
- #88: Misclassification of PM-产品经理.md, an ADR-007 archive.
- #89: Byte-count blind spot; withdrawal of PROP-042 stages 2-3.
- #90: Missed entry points, including 00_总入口 / INDEX.
- 🆕 #91: ADR README remained at ADR-025, missing seven records; failed list consistency triggered v2.
- Topic BE startup checks, ADR-029: stale entry points undermine BE.
- Topic AY large-file governance: advisory warnings are not hard rules.

---

⭐ **ADR-032 is permanently current: meta-rule fifteen, a systematic health-check quality SOP.**
