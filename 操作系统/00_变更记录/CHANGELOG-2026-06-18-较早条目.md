---
name: changelog-2026-06-18-archive
scope: project
type: episodic
loaded: on-demand
description: Earlier operating-system evolution entries archived for 2026-06-17~18
---

# CHANGELOG 2026-06-17~18 Earlier Entries

> Rolled out of `CHANGELOG.md` for traceability; consult `CHANGELOG.md` for current updates. This is an English rendering of the historical record; the original wording remains in Git history.
> **Historical safety boundary**: this archive contains historical references to hooks / git / push / tag. They are for traceability only. **Do not copy and execute directly**; consult `三类行为铁律.md` and ADR-022 before sensitive operations.

## 2026-06-18

- **PROP-039 reassessment and split completed**: split the original combined Mem0+Skills SDK approach into a local read-only Mem0 memory-retrieval pilot and a read-only context-loading pilot at the Agent/Skills carrier layer; synchronized PROP, README, scope-schema, meta-rule candidates, and readme-index anchors. No SDK was installed, no key was written, and no business dependency was introduced.
- **PROP-034 in-progress status clarified**: model tiers are no longer described as not started/awaiting scheduling; the status now states that local implementation is complete, with release and external three-model measurements pending. It explicitly forbids fabricated cost data and unauthorized commit/push/tag/version/release operations. Verification: PROP index + status snapshot + handoff card synchronized.

## 2026-06-17

- **Accepted-archive chat completion guard completed**: chat-output ⑥ still requires `交接区/待接手/` by default; if pending is empty and the target is a `status: accepted` card under `交接区/已接手/`, it is allowed as the completion-detail reference for accepting and archiving. Synchronized handoff specifications, manifest, hooks smoke, and anchor guards. Verification: hooks-smoke / readme-index ✅.
- **Full per-file operating-system audit completed**: 4 explorers read all 95 `操作系统/**/*.md` files present when the audit began; corrected false-green handoffs, test ownership, historical boundaries, outdated 5-PM appendix wording, counts/indexes/corrupted characters; added per-file details, bringing the current baseline to 96 Markdown files. Verification: full gate ✅.
- **07_Complete_Workflows P1/P2 closeout**: 3 explorers reviewed decision/release/hooks SOPs; corrected incoming-requirement PROP routing, real agents in Q7, approval PM routing, release keystore/APK overwrite/version/tag, git preflight, DoD handoffs, and scheduled/Stop/Claude ask boundaries; added `workflow-spec-anchor`. Verification: target ✅.
- **06_Tool_Governance P1/P2 closeout**: 3 explorers reviewed hooks/health checks/history; corrected FileChanged fallback, scheduled checks, Stop blocking, historical fragments/frontmatter, and check-plan/Q1-Q7; added historical anchors and hooks-design count anchors. Verification: target ✅.
- **05_Memory P1/P2 closeout**: 3 explorers reviewed entries/history/scope; corrected startup, pm-workspace, ADR-028, and status inference; added `memory-spec-anchor`. Verification: target ✅.
- **04_Ledgers P2 guards strengthened**: 3 explorers reviewed versions/Sprints/issues/history; corrected stage descriptions and added `ledger-spec-anchor`. Verification: target ✅.
- **03_Handoffs P1/P2 closeout**: 3 explorers reviewed specifications/hooks/actual behavior; added frontmatter, chat ⑥, Stop, the ② path, and `handoff-spec-anchor`. Verification: target ✅.
- **02_Agents P1/P2 closeout**: 3 explorers reviewed playbooks/appendices/shared skills; corrected single-source, tag, branch, write-authority, and historical boundaries; added `agents-playbook-anchor`. Verification: target ✅.
