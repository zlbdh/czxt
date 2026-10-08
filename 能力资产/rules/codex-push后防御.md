---
name: codex-push-post-defense
scope: project
type: semantic
loaded: on-demand
description: Double verification and nondestructive diagnosis for dirty files, deleted code, truncation, or index corruption after a Codex push (issue BK).
---

# Verification After a Codex Push (Issue BK / PROP-024 Phase 2)

Applies to Project PM “Mimi,” or a PM continuing work in any runtime, after Codex reports pushing commit `xxx` to `origin/main` and before further operations.

Historical evidence: the pattern occurred twice, in v3.6.1 and v3.6.2. It was frequent during that period; this rule remains a long-term safeguard.

## 1. Recognize symptoms

Codex may report a clean working tree synchronized with origin/main while another runtime or local shell observes:

| Symptom | Historical observation |
|---|---|
| Dirty working tree | `git status --short` lists modified files. |
| Deleted source code | `git diff` shows business-code deletions, such as 143 lines from Chat.jsx in v3.6.1. |
| Truncated file | Trailing `\ No newline at end of file` and whitespace, such as Profile.jsx in v3.6.2. |
| Corrupt `.git/index` | Git reports `bad signature 0x00000000`. |

## 2. Mandatory double verification

### 2.1 Immediately after the push report

```powershell
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" status --short    # Check for modifications.
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1  # Compare HEAD with the reported hash.
```

If status is not clean, go directly to the nondestructive diagnosis in section 3. Do not recover automatically.

### 2.2 Again before any PM operation

Repeat section 2.1 before Edit, Write, apply_patch, or mv in any runtime to confirm the initial state is clean.

## 3. Nondestructive diagnosis, in increasing severity

### 3.1 Basic diagnosis (the common v3.6.2 pattern)

```powershell
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" status --short
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" diff -- <file> | Select-Object -First 30
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1
```

**Current mandatory rule:** do not run `git reset --hard HEAD` by default. Even if historical shipping cards mention preapproval, follow current Codex and project safety boundaries: stop, preserve the scene, and report modified files and a diff summary to zlbdh. Destructive recovery requires the user's explicit request in the current context.

### 3.2 Index corruption (the rare v3.6.1 pattern)

```powershell
# If Git reports bad signature 0x00000000 or fatal: index file corrupt:
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" status              # Record the original error.
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1    # Record HEAD if available.
```

Do not automatically run `rm .git/index` or follow it with `git reset --hard`. Both change repository state and require explicit authorization from zlbdh.

### 3.3 Verify HEAD every time

```powershell
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1
# It must match the hash in the Codex push report.
# A mismatch is serious: ask zlbdh immediately.
```

## 4. Root-cause hypotheses, still pending PROP-024 Phase 2 investigation

In estimated likelihood order:

1. Cross-runtime mount/cache behavior combined with concurrent Codex writes to `.git`, historically most common.
2. Synchronization problems from mixed WSL/Linux and Windows paths.
3. An automatic tool operation after the push triggering a rollback.
4. Inconsistent filesystem caches.

Investigation: completely stop file operations in other runtimes during a Codex push, rerun, and check whether the problem recurs.

## 5. Historical incidents

| Incident | Time | Symptom | Historical recovery |
|---|---|---|---|
| 1 | May 19, 2026, 12:00, after v3.6.1 push | Five modified files and a corrupt index | `rm .git/index + git reset + git reset --hard HEAD` was used then. The current rule requires stopping for authorization first. |
| 2 | May 19, 2026, 14:45, after v3.6.2 push | Profile.jsx truncated by seven lines | `git reset --hard HEAD` was used then. The current rule requires stopping for authorization first. |

## 6. Related issues

- BG, commit BOM: permanent rule in `能力资产/rules/git-commit-编码规范.md`.
- BH, `.bat` CRLF: permanent rule in `{{APP_REPO_DIR}}/.gitattributes`.
- BO, `build-apk.bat` parsing: Codex script fix in PROP-024 Phase 3b.

BK is independent of those three issues but proceeds with them under PROP-024 governance.

## 7. Closure criteria

- At least three Codex pushes with double verification and zero recurrence: close BK when the root cause is found and the fix is effective.
- Alternatively, at least three recurrences all caught by this rule with zero business incidents: partially close BK, marking v1 long-term monitoring because the defense works but the root cause remains unknown.

## 8. Prohibited responses

- Editing immediately after a push report without verification.
- Continuing business work with an unexplained dirty tree and spreading corruption.
- Default destructive recovery with `git reset --hard`, `rm .git/index`, or file deletion without zlbdh's explicit current authorization.
- Investigating why Codex reported clean before preserving the scene and reporting it.
- Skipping section 2: this defense depends entirely on verification before further operations.
