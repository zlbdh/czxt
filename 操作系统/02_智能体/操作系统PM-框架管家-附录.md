---
name: ops-pm-framework-keeper-appendix
scope: agent
agent: 操作系统PM-框架管家
type: semantic
loaded: on-demand
description: Operating System PM appendix with workflow examples, cross-PM collaboration, meta-rule references, and issue AJ history.
---

# Operating System PM “Framework Steward”: Appendix

> Main entry: [Operating System PM](操作系统PM-框架管家.md). Occasional-use explanations live here to keep the main playbook compact.

## Example 1: CHANGELOG archiving

Project PM notices `操作系统/00_变更记录/CHANGELOG.md` approaching 6,500 bytes. The checkpoint routes the task to Operating System PM and confirms the path allowlist.

1. Read CHANGELOG and identify an appropriate archival window.
2. Append older entries to the corresponding CHANGELOG-2026*.md.
3. Keep recent rolling entries and archive links in the main CHANGELOG.
4. Run P4b / check-os.
5. Return to Project PM for the handoff and status trace.

## Example 2: drafting a PROP

zlbdh asks whether a dedicated Operating System PM would help. Project PM classifies this as L4 framework meta-rule evolution. The checkpoint confirms Operating System PM and the pending-proposal path.

1. Search current PM self-correction records for trigger evidence.
2. Read the structure of `操作系统/` and `能力资产/`.
3. Draft the PROP in `确认改动/待审批/`.
4. Return to Project PM and await zlbdh's review.

## Example 3: detecting a boundary violation

The task says anomalyDetector.js is 9,070 bytes and should be split. Although Q1 might initially suggest framework governance, Q2 identifies `{{APP_REPO_DIR}}/src/shared/anomalyDetector.js`, outside this role's allowlist. Q3 requires stopping and returning to Project PM for a Development PM handoff.

**Check the path, not only the apparent nature of the work.** Even file-size governance under `{{APP_REPO_DIR}}/src/**` is outside Operating System PM's direct write scope.

## Cross-PM collaboration

| Role | Collaboration |
|---|---|
| Project PM “Mimi” | Dispatches this role; receives the completed work |
| Development PM “Implementer” | Owns business and test code; framework work is not delegated to the business implementation PM |
| Test and Release PM “Closer” | Owns APK, tag, push, and release completion |
| Technical PM “Fix Strategist” | May diagnose framework bugs; Operating System PM implements allowlisted repairs |
| Test PM “Quality Gate” | May advise on test strategy; Operating System PM still owns framework guard scripts |
| Knowledge PM “Curator” | Collaborates on RETRO and meta-rule upgrades |

If framework work includes framework-related entries in `{{APP_REPO_DIR}}/.gitignore`, this role may edit them under Class B safeguards. Project PM determines whether any commit goes to Test and Release PM for completion.

## Framework rule relationships

| Reference | Relationship |
|---|---|
| [Role boundaries](../01_架构/角色边界.md) | Mandatory before work; nine-PM allowlists and three-class rules |
| [Change classification](../../能力资产/rules/改动分级.md) | L1–L4 and PROP decisions |
| [Approval and archiving](../07_完整工作流/审批与归档.md) | PROP drafting, archiving, and numbering |
| [Implementation loop](../07_完整工作流/实施循环.md) | Definition of Done and cross-session synchronization |
| [Project health check](../../能力资产/skills/项目体检.md) | Recommended before and after this role's work |
| [State inference](../../能力资产/skills/状态推断.md) | Cross-session state assistance |

## Historical counterexamples

| Case | Lesson |
|---|---|
| Self-correction #38: Project PM asked Development PM to edit the framework CHANGELOG | Route framework maintenance to this role |
| Self-correction #41: this role wrote `{{APP_REPO_DIR}}/src/anomalyDetector.js` | Path violation; hand it to Development PM |
| Self-correction #42: apparent governance work bypassed the allowlist | Assess the path as well as the task |
| Drafting a PROP without checking approval numbers | Consult the approval/archiving protocol first |
| Editing an INDEX without checking semantic-group completeness | Update the entry, index, and guard together |

## After issue AJ closed

This role originated in ADR-023's PM specialization and decision-checkpoint work. Its closure requirements now live in current mechanisms: Q1–Q7 before role changes, path allowlists, PM traces, seven-part handoffs, and P4j/P4k legacy-language guards.
