---
name: changelog-2026-06-16-archive
scope: project
type: episodic
loaded: on-demand
description: Earlier operating-system evolution entries archived for 2026-06-16
---

# CHANGELOG 2026-06-16 Earlier Entries

> Rolled out of `CHANGELOG.md` for traceability; consult `CHANGELOG.md` for current updates. This is an English rendering of the historical record; the original wording remains in Git history.
> **Historical safety boundary**: this archive contains historical references to hooks / git / push / tag. They are for traceability only. **Do not copy and execute directly**; consult `三类行为铁律.md` and ADR-022 before sensitive operations.

- **01_Architecture P1/P2 closeout**: 3 explorers deeply reviewed roles/rules/meta-rules/agent; corrected Class C, tag/env/schema, the candidate count of 17, and ADR boundaries; added `architecture-anchor`. Verification: target ✅.
- **Historical boundaries and audit-coverage ledger**: 3 explorers separately reviewed history, active entry points, and coverage evidence; added the ledger, corrected historical snapshots presented as active and the wording that this file was archived, and added readme-index/P4q guards. Verification: P4q/readme-index/P4b ✅.
- **PM private quick references 9/9 + large business-file touch warning**: added 5 minimal PM INDEX files and a P4n hard check for 9/9; connected PostToolUse to `p4b-touch-warning.ps1`; touching red/soft-zone files in `{{APP_REPO_DIR}}/src` only produces a soft warning. Verification: hooks-smoke/P4n/P4b/check-os ✅.
- **PM private-area entries / P4r negative tests / P4b triggers**: added each private-area entry to 5 PM playbooks; P4r strictly asserts Codex `command`+`commandWindows` and adds a command-only negative fixture; the Development PM playbook adds P4b trigger governance. Verification: hooks-smoke/P4r/P4n/P4b/check-os ✅.
- **Entry/role/hooks mapping guards**: corrected Operations/Knowledge boundaries, startup flow, and outdated rule subjects; added P4r mappings, check-plan prefixes, P4m/P4p/P4k negative anchors, and an explanation of ADR watcher runtime behavior. Verification: hooks-smoke/P4r/check-os ✅.
- **Table-driven health-check entry + script warnings cleared**: made `check-operating-system.ps1` table-driven, added `check-plan-assert.ps1`, and split P4m/P4b/handoff helpers; capability-asset P4b warnings fell 4→0. Verification: readme-index/check-os ✅.
- **PROP status guard and handoff false positives**: added `prop-status-helpers.ps1`, anchoring header status + five-state directories + README details; accepted cards only block unfinished to-dos. Verification: readme-index/handoff-zone/check-os ✅.
- **P4b historical exemptions and hooks contracts**: added `framework-scope.ps1` to centralize historical exclusions; handoff-zone blocks acceptance prompts left on accepted cards; hooks smoke strictly locks apply_patch/PreToolUse. Verification: hooks-smoke/P4b/P4o ✅.
- **Active warning-zone document reduction and P4r closeout**: archived the remaining 2026-06-15 CHANGELOG entries; hooks SOP/design adds P4r closeout, and role boundaries/Project PM write authority are narrowed; all 5 target active documents are <6000B. Verification: readme-index/handoff-zone/pm-tracking/check-os ✅.
- **Handoff soft prompts cleared and status chain corrected**: accepted the 19:12 card, removed residual prompts meaning to accept this card now/as the next step from 5 accepted cards, and pointed the status header to the new pending card. Verification: handoff-zone/pm-tracking/readme-index ✅.
- **hooks/P4r/PROP requirements-chain semantic guards completed**: corrected runner TextPath, Stop read-only false positives, chat-output N=0, an env example key, ADR watcher Check, P4r overall hooks health, PROP write authority/status, and the Docs1 historical boundary. Verification: readme-index/P4r/hooks-smoke ✅.
- **PM capability entries and rules/skills semantic guards completed**: corrected PM/rules/skills write authority, tool subjects, L1/L2 gates, outdated status-inference formulas, and cross-branch handoff guards; expanded P4m/P4k/P4p/handoff-zone. Verification: target guards/P4b/handoff-zone ✅.
- **Capability-asset tool scripts reduced to soft-zone entry points + stricter handoff guards**: converted `governance-semantics-anchor` into a façade, reused a common helper in `os-semantics`, and made `check-handoff-zone` strict about pending frontmatter, Status, and path compatibility. Verification: readme-index/check-os ✅.
- **P4b business-debt governance strengthened**: P4b health checks add a business-debt governance summary for `{{APP_REPO_DIR}}/src`; `TASKS.md` adds entry points for four strategy types; `p4b-business-debt-anchor` checks the same table row; corrected the ADR-032 path. Verification: readme-index/check-os/hooks-smoke ✅.
- **Hooks runtime and automatic-alignment boundary guards completed**: missing/drift results from `hook-install-check` now exit 10 and are included in hooks-smoke; clarified that PreToolUse only warns about suspected key structures and does not replace manual Class B/C classification. Verification: install-check/hooks-smoke ✅.
