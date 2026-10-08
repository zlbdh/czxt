---
name: git-recovery
description: Emergency diagnosis for Git damage, index errors, and unexplained dirty state, based on ten stale-mount incidents after Codex pushes.
trigger: Git damage, index bad signature, unexplained dirty state, or a stale mount.
loaded: on-demand
---

# Git Recovery SOP

## Triggers

1. Cowork shows dirty files after a Codex push although contents appear normal.
2. `.git/index` reports `bad signature 0x00000000`.
3. Files physically exist but head/cat reports “No such file.”
4. A failed physical-device smoke test calls for urgent rollback assessment.

## Five-step diagnosis — issue BK / ADR-025

### 1. Inspect current state

```powershell
Set-Location "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}"
git status --short
git log --oneline -3
git diff --stat
git diff -- <file>
```

### 2. Assess a stale mount

- Matching HEAD plus an empty or explainable diff suggests a stale mount; continue read-only verification.
- Matching HEAD with real content differences is genuinely dirty; stop and report unknown provenance.
- A different HEAD or index error may indicate damage; proceed to step 4.

### 3. Preserve the state

```powershell
git diff --stat          # Inspect the changed scope without writing.
git diff -- <file>       # Read the concrete differences.
```

Stop and report unexplained changes. Do not restore automatically.

### 4. Diagnose index damage

```powershell
Set-Location "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}"
git status               # Capture the original error.
git log --oneline -3     # Record HEAD if available.
```

Do not automatically run `rm .git/index` or `git reset --hard`. Wait for zlbdh's explicit authorization for this occurrence.

### 5. Verify integrity

```powershell
git status               # Record current state.
git log --oneline -3     # Verify HEAD.
Get-ChildItem src        # Confirm source files exist and are readable.
```

## Authoritative sources

- `能力资产/rules/codex-push后防御.md`: ADR-025 implementation.
- `Docs/3-开发文档/adr/ADR-025-Cowork-mount-stale防御机制永久化.md`.
- Ten cross-Sprint issue BK incidents.
- Current execution follows meta-rule BK: read-only verification and no default reset. ADR-025's early reset preapproval is historical background only.
