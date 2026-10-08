---
name: 沉淀pm-沉淀者-skills-index
scope: pm-workspace
pm: 沉淀PM-沉淀者
type: procedural
loaded: on-demand
description: "Knowledge PM \"Curator\" quick-reference index: 11 rules for meta-layer cross-PM oversight, health-check quality, and learning mechanisms."
---

# Knowledge PM "Curator": Quick-Reference Index

> 🌱 **New placeholder**: task #104.5 / 2026-05-22 / final v4.0 model implemented.
> 🔴 **First rule created**: PM self-correction #76 / task #110 / 2026-05-22.
> ✨ **Sprint-10 expansion**: task #118 / 2026-05-28 / six additional rules, drawn from ADR-031, PROP-042, and self-corrections #88/#89.

## Eleven accumulated rules: finalized at Sprint-10 close

### A. Verification and tracking: prevent false reports and issue AJ recurrence

| # | Rule | Trigger | Source |
|---|---|---|---|
| 1 | After editing `状态.md`, search `task #XXX` in the actual PM transition table and verify line numbers; a keyword match alone is insufficient | Any framework PM edits `状态.md` | Self-correction #76, issue AJ's tenth recurrence |
| 2 | Verify with the Read tool and line numbers, not Bash mount cache; grep and wc may show an old version | Checking a write after Edit/Write | Self-correction #82 and issue BK cases #11–#13 |

### B. External communication: ADR-031's five rules

| # | Rule | Trigger | Source |
|---|---|---|---|
| 3 | Keep meta-layer internal signals separate from the lead PM's external communication; the Curator does not address the user, and only the Project PM signs external replies | Any Knowledge PM conversational output | Self-correction #74; ADR-031 rule 1 |
| 4 | The Project PM makes execution decisions independently instead of deflecting them to zlbdh through AskUserQuestion | Decisions supported by the PRD and meta-rules | Self-corrections #63/#77; ADR-031 rule 2 |
| 5 | Be concise, use plain language, and distinguish four states: PRD, code, tests, and shipping; keep prompts short and avoid excessive identifiers | Every external report | Self-corrections #80/#83/#86; ADR-031 rules 3–5 |

### C. Engineering boundaries and naming

| # | Rule | Trigger | Source |
|---|---|---|---|
| 6 | Before creating a top-level directory, run `ls -d`, search with `grep -r`, and compare industry naming conventions to prevent collisions | Any PM creates a top-level directory | Self-correction #75; issue CM v3.2 |
| 7 | Verify numerical handoff parameters from real evidence rather than memory; choose the established larger value instead of repeatedly failing with small guesses | Writing a handoff with numerical parameters | Self-correction #79; ADR-030 / issue CC |

### D. Decision timing and health-check quality

| # | Rule | Trigger | Source |
|---|---|---|---|
| 8 | Evaluate minimum viable user value before deciding a slice, not just the smallest code change or only after work becomes blocked | Before slicing work or starting a sprint handoff | Self-corrections #84/#87 |
| 9 | For framework files above 8KB, assess whether they can be split and whether their content is essential. Inspect section byte distribution with `awk`; recommend splitting only if secondary sections are at least 30%. Historical-archive exemptions require the file's retention notice | Framework health checks | Self-corrections #88/#89; ADR-032 decisions 2+3, issue DN permanent |
| 10 | Broaden entry-point checks: use `find` to inspect README, AGENTS, `00_总入口`, and INDEX files. Verify obsolete terms such as “5/6/8 PM,” “PM-产品经理,” or “v2.x” against v4.0 | Framework health checks and startup | Self-correction #90; ADR-032 decision 1, issue DN permanent |
| 11 | Keep README inventories synchronized with actual file counts. Compare the ADR table with `ls ADR-*.md \| wc -l` and update the issue overview ADR table and permanent meta-rule count together | Creating an ADR and weekly review | Self-correction #91; ADR-032 v2 decision 6 / issue DN v3 |

## Progressive Context Loading: issue CO

Match the current task to the rules:

- Editing `状态.md`: rules 1+2.
- Knowledge PM conversation output: rule 3.
- Project PM decisions: rules 4+5.
- Creating directories: rule 6.
- Writing a handoff: rule 7.
- Slicing work: rule 8.
- Framework health checks: rule 9.

Follow the [Project PM "Mimi" index pattern](../../项目PM-咪咪/速查表/INDEX.md).
