---
name: "changelog-header-check"
description: "Check CHANGELOG header restrictions before listing a CHANGELOG edit in a handoff. Prevents PM self-correction #43."
trigger: "Before listing CHANGELOG.md changes in a handoff card"
loaded: "条件加载（按 trigger 匹配时由 PM 调度）"
---

# Quick Reference: CHANGELOG Header Rules — Self-Correction #43

> Before a handoff lists changes to `操作系统/00_变更记录/CHANGELOG.md`, **check the header rules**.

## Mandatory rule

The header of `操作系统/00_变更记录/CHANGELOG.md` explicitly states:

> ⚠️ **Application-code changes** belong in `{{APP_REPO_DIR}}/` Git history and **do not belong in this file**.

Application changes—`{{APP_REPO_DIR}}/src/*`, tests, and Capacitor integration—belong in application commit messages and `需求历史.md`, not the operating-system CHANGELOG.

## What belongs in the operating-system CHANGELOG

| ✅ Include | ❌ Exclude |
|---|---|
| Framework meta-rule evolution: PROP/ADR/RETRO indexes | Application features F-XXX |
| Sprint completion: lightweight index row | Application bug fixes |
| Tool upgrades: `能力资产/skills/*`, `能力资产/tools/*` | Test mock files |
| Rule-file changes: `能力资产/rules/*`, `操作系统/07_完整工作流/*` | Capacitor plugin integration |
| Issue AM archive trigger | Application refactors |

## Historical evidence

### Self-correction #43: May 14, 2026, F-SYSCHECK-1 handoff

- The handoff instructed adding an entry to `操作系统/00_变更记录/CHANGELOG.md`.
- F-SYSCHECK-1 was a Sprint-5 application feature, violating the header rule.
- Claude Code blocked the instruction through PROP-014's three-stage assessment as a nonblocking issue.
- The incorrect handoff instruction became an issue AR Q4 candidate.

## Defenses

Before a handoff includes a CHANGELOG change, check for 30 seconds:

1. Is the change application or framework work?
2. A `{{APP_REPO_DIR}}/src/*` change does not enter the operating-system CHANGELOG.
3. Its proper location is the application commit message plus `Docs/1-需求文档/需求历史.md`.

### Issue A archive trigger: independent mechanism

Above 6500 B, the PM archives CHANGELOG.md into the corresponding dated `CHANGELOG-2026*.md` window. This does not depend on shipping an application feature. It has been exercised repeatedly: PROP-018 P1, issue AM, PROP-019, and rolling archival on June 14, 2026.

## Related rules

- [CHANGELOG](../../../操作系统/00_变更记录/CHANGELOG.md): explicit header rule.
- Decision-checkpoint Q4.a: candidate rule-memory check.
