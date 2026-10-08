---
name: "pm-self-correction-96"
scope: "project"
type: "episodic"
loaded: "on-demand"
description: "PM correction #96: a Cowork sandbox git reset --hard failed while clearing false dirty state and left index.lock on the host; ADR-025 and ADR-033 boundary, during B-F7 v3.12.0 closure on 2026-05-30."
---

# PM Correction #96 — Sandbox Git Writes Can Leave Host Artifacts

**Trigger:** During the final source-of-truth check for B-F7 v3.12.0 on 2026-05-30, `git status` showed three falsely dirty files: issue BK's stale mount after a Codex push, combined with ADR-033's apparent mount truncation. Following ADR-025 decision 2's then-recorded preapproval for `git reset --hard HEAD` to clear false dirty state, PM ran it in **Cowork sandbox Bash**. It failed.

## Failure sequence

1. `git reset --hard HEAD` returned `error: unable to unlink ... Operation not permitted`; the sandbox mount lacked permission to write the host working tree.
2. The interrupted reset left an empty, zero-byte `.git/index.lock`. Sandbox `rm` also returned `Operation not permitted` and could not remove it.
3. The host lock blocked the next host `git add/commit/reset` with an index-lock-exists error. **Commit `4420167` remained safe and unchanged on the remote**, but the lock required manual host cleanup.

## Cause

I incorrectly treated ADR-025's reset preapproval as permission to execute the command from the Cowork sandbox. ADR-033 already established that host writes through that sandbox were unreliable. `git reset --hard` **writes the working tree**; the sandbox mount lacked host-file unlink permission, and failure left a lock. The old preapproval implicitly assumed an environment with host write access, such as Claude Code or Codex on the host, rather than the Cowork sandbox.

## Correct procedure recorded at the time

1. **Use Git only for read-only diagnosis in the Cowork sandbox:** `git rev-parse HEAD`, `git status`, `git diff`, and `git ls-tree`. If HEAD, origin/main, and the ship commit agree; the apparent dirty diff is mount truncation; and the committed blob is complete, **the shipment is safe and the working tree does not need clearing**.
2. **Perform false-dirty or index-lock cleanup on the host**, through Claude Code or Codex. The historical cleanup instruction was `rm {{APP_REPO_DIR}}/.git/index.lock`, optionally followed by `git reset --hard HEAD`.
3. **The reliable sandbox write channel was the file tools, Read/Write/Edit, rather than Bash through the mount.** Bash `>>` append could still succeed because it did not unlink or rewrite files. Four ledger edits and the `状态.md` append succeeded through the recorded channels in this incident.

## Application

- When PM receives a Codex ship card and sees a falsely dirty `git status`, use three read-only checks: HEAD matches origin/main; the diff indicates apparent truncation; and the origin/main blob is complete. Use them to determine shipment safety. **Do not run any Git write command in the sandbox**, including reset, checkout, clean, or add.
- If the working tree actually needs restoration, add it to ship-card section ⑥, “Next host startup,” for handoff, or immediately give zlbdh the host cleanup command.
- If an accidental sandbox Git write leaves a lock, **tell zlbdh immediately and honestly, and provide the host cleanup command. Do not conceal it.**

## Candidate issue

Add this boundary to ADR-025: `git reset --hard HEAD` is host-only; a Cowork sandbox encountering false dirty state should use read-only diagnosis to establish shipment safety, and must not execute Git writes. Promote the issue BK/ADR-025 patch at startup.

## Recent correction history

- #92: verification blind spots; #93: avoidance of external decisions; #94: Edit truncated a large file's tail; #95: contradictory handoff acceptance criteria.
- **#96, this record:** sandbox `git reset --hard` failed while clearing false dirty state and left an `index.lock` artifact on the host.

## Related records

- ADR-025, Cowork stale-mount defenses: this record adds the boundary that clearing false dirty state requires the host.
- ADR-033, unreliable large-file mount reads/writes: this record extends it to Git writes.
- Issue BK, stale Cowork mounts.
- [[project-{{APP_REPO_DIR}}-git-branch-main]] — verify before Git operations.
- [[feedback-pm-no-default-inference]] — do not assume that ADR-025 permits sandbox execution.
