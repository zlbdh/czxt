---
name: changelog
scope: project
type: episodic
loaded: on-demand
description: Lightweight reverse-chronological log of development operating-system changes, supplementing PROP/ADR/RETRO.
---

# Operating-System Evolution Log — CHANGELOG

Record development operating-system changes in reverse chronological order.

**Business-code changes** belong in `{{APP_REPO_DIR}}/` Git history, outside this file.
**This log supplements PROP/ADR/RETRO**; it does not replace those records. Add one-line event pointers for browsing.
**Archived history:** entries from 2026-06-22 and earlier are in `CHANGELOG-2026-06-22-较早条目.md`, `CHANGELOG-2026-06-18-较早条目.md`, `CHANGELOG-2026-06-16-较早条目.md`, `CHANGELOG-2026-06-15-较早条目.md`, `CHANGELOG-2026-05-21至06-14-较早条目.md`, and `CHANGELOG-2026H1.md`.

> Introduced through PROP-017 / ADR-021, borrowing the improvement-log mechanism from the sibling Account Management and SRM Server Management projects.

## Relationship to PROP / ADR / RETRO

| Change | Primary record | Add to CHANGELOG? |
|---|---|---|
| Major architecture decisions / meta-rule evolution, L4 | PROP + ADR | Yes, one-line pointer |
| Sprint retrospective | RETRO | Yes, one-line pointer |
| Medium changes, L3 | PROP | Yes, one-line pointer |
| Small actions / L1-L2 / incidental work | This file | Yes; compact rolling entries or four lines for complex items |
| Dead-code removal, renaming, reference fixes, comment improvements | This file | Yes |
| Learning brought back from other projects | This file + new PROP if substantial | Yes |

Prefer one-line rolling entries. Use four lines for complex items:
```
- **Change**: ...
- **Trigger**: ...
- **Acceptance result**: ...
- **Follow-up impact**: ...
```

**Writing rule:** date, a one-sentence title, and necessary acceptance evidence; no more than ten lines per entry.

## 2026-09-21

- **Four regression root causes fixed, L2:** instantiation parameters now use JSON data serialization, PowerShell-context encoding and literal regexes, supporting special-character names and nested business directories. Final JSON/PS validation precedes success markers. PM traces read actual status from independent Git roots, supporting CP936, worktrees, failure blocking and non-Git fallback. ADR counts derive from files and indexed status; PROP-003 archival now reflects existing publication evidence. RED/GREEN, focused review and resumed-run details: `交接区/待接手/2026-09-04-1643-四项回归修复-操作系统PM到项目PM.md`. Final precommit review also restricted ADR-test temporary-directory ownership to this run.

## 2026-08-24

- **Capture transaction safety review, PROP-004 / ADR-039 / L4:** completed staging→capture tree ledgers, repair's two-move seal, same-byte ABA, rename-committed reconciliation, post-cleanup checks, real ADS/unknown preservation, exact initial/post-move Git cleanup, and P4t preflight handle lifetimes. Tree seals use streaming SHA-256 and per-member DFS with budgets of `20000` members / `536870912` bytes. Fresh WinPS 362/362, assets 6/6, scaffold 63/63, docs 148/148, capture 8/8, hooks-smoke PASS; independent safety review P0/P1/P2=0. Encoding `4ee4686`, functionality `7bf9ce4`, and handoff `cda4339` were normally pushed under ADR-016; main divergence verified `0/0`.

- **Codex project hooks restored, L2:** restored the template root's user-level trusted-project configuration and changed five `.codex/hooks.json` commands to quote-free PowerShell bootstrap. Bootstrap accepts only the nearest unique CZXT root marker, binds `.codex/invoke-hook.ps1`, stops on dual-marker conflict, and requires neither Git nor an absolute template path, avoiding nested `cmd.exe /C` quoting. TDD covers a missing dispatcher, incorrect .cmd/Git-root binding, independent non-Git roots, nested outer Git roots and dual-marker conflict. Hooks-smoke PASS; Codex hooks/list showed 5/5 enabled+trusted, zero warnings and errors.

## 2026-07-22

- **Borrowing-lifecycle final hardening, PROP-004 / ADR-039 / L4:** handle binding and strict TDD closed installer/seal/closure reparse, hard-link, ABA, status-trace deletion/directory-replacement and irreversible-commit boundaries; fixed hostile hook-output encoding. Final WinPS 349/349, scaffold 63/63, docs 148/148, capture 8/8, P4t 10/10, seal 20/20, close x64/x86 each 31/31. One Force upgrade preserved the existing dogfood status prefix and 211 protected files. Fresh instance `借鉴闭环终验-20260722-164424` passed first installation and P4a-P4t. Template P4a 284, P4t 0/0; baseline 57/57 and preexisting dirty paths 42/42 fully reconciled. No commit, push or publication.

## 2026-07-19

- **Borrowing lifecycle established, PROP-004 / ADR-039 / L4:** unified 借鉴区/, immutable source captures, dual-card state machine, nine permission dimensions, one borrowing Skill, trusted closure transaction, read-only offline P4t and Git/local/web capture façade. Two independent reviews and final dogfood completed credential detection across every tracked destination, borrowing-evidence/v1, post-P4t official-card locks, public-leaf mode checks, cwd-relative isolation, per-target junction guards and Force in-place upgrades. Gate 0, scaffold 21/21, docs 137/137, capture 8/8, P4t 7/7, real instances and template/generic-project P4a-P4t all passed. Baseline artifacts 57/57 and preexisting dirty paths 42/42 reconciled. No commit, push or publication.

## 2026-07-10

- **Template truth and hook cleanup, PROP-003 / RETRO-024 / L3:** corrected P1 complete/P2 incomplete and ADR 35 current + 3 superseded. Development, dependency, brand and build entries now reflect project-instance truth templates; P4s adds targeted guards. Hooks-smoke used a unique TempRoot and concurrent sentinel for RED/GREEN; final PASS, temp count 9→9 and no fixture residue. Status inference gained ADR-033 same-value metadata and triggered RETRO-024. Final review safely archived the complete June 22 section; main CHANGELOG shrank 7125→2999B. Framework, handoff, index and status-inference gates passed. No fetch, commit or push.

## 2026-06-28

- **PM professional-mode capability layer, L2:** retained nine PMs and added PM专业mode能力层.md. Requirements, design, frontend, backend and hardware first attach as modes, plugins, workers/explorers under Product, Technical and Development PMs. product-design is Product PM's experience-design capability; no separate Design PM.

## 2026-06-22 and earlier

- See `CHANGELOG-2026-06-22-较早条目.md` for June 22, `CHANGELOG-2026-06-18-较早条目.md` for June 17-18, `CHANGELOG-2026-06-16-较早条目.md`, and the earlier archives listed above.
