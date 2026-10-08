---
name: mount-stale-defense
description: Cowork stale-mount detection and read-only safeguards under ADR-025; issue BK recorded ten incidents with zero business-data incidents.
trigger: Inconsistent Cowork file reads, cross-tool collaboration, or startup after a release-completion report.
loaded: on-demand
---

# Cowork Stale-Mount Defense SOP

## Triggers

During collaboration with Codex or Claude Code, Cowork's file view may lag behind the filesystem:

- A file exists but head/cat reports “No such file.”
- Git reports modified files whose content appears normal.
- A directory listing omits files that appear after refreshing.

## Five-step defense — ADR-025

### 1. Check before work

```powershell
Set-Location "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}"
git status --short      # Working-tree state.
git log --oneline -3    # HEAD integrity.
```

In Cowork Bash, use its mounted path or `<project-root>/{{APP_REPO_DIR}}`. Do not copy a Windows `D:\...` path blindly.

### 2. Assess dirty state calmly

A successful prior push report and matching HEAD suggest a stale mount, but do not prove the absence of damage. Continue with read-only `git diff`.

### 3. Preserve evidence; do not restore automatically

```powershell
git diff --stat
git diff -- <file>
```

Stop and report unknown changes. Destructive recovery requires zlbdh's explicit authorization for this occurrence.

### 4. Verify mount synchronization

```powershell
Get-ChildItem src                         # Files physically exist.
Get-Content important-file.js -TotalCount 5 # File contents are readable.
```

### 5. Record only when needed

Routine read-only checks do not update `状态.md`. Add a role-transition trace only for a new issue dimension, cross-PM handoff, or an explicit main-session decision to record it.

## Cross-RETRO history

- Issue BK v1–v4: ten incidents, zero business-data incidents.
- ADR-025 permanently closed the issue and promoted it to meta-rule 9.
- BK v4 remains monitored without a new ADR.

## Authoritative sources

- `能力资产/rules/codex-push后防御.md`.
- `Docs/3-开发文档/adr/ADR-025-Cowork-mount-stale防御机制永久化.md`.
- Current meta-rule BK requires read-only verification and prohibits default reset. ADR-025's early reset preapproval is historical background only.
