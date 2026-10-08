---
name: 测试发布pm-闭环者-readme
scope: pm-workspace
pm: 测试发布PM-闭环者
type: semantic
loaded: on-demand
description: "Test and Release PM \"Closer\" workspace entry point: verification layer, lead verification PM, Codex execution environment, and six ADR-016 conditions."
---

# ✅ Test and Release PM "Closer": Private Workspace

> ⭐ **Verification-layer and lead verification PM workspace**: task #104.5 / 2026-05-22 / PM self-corrections #64/#65/#70.
> **Role definition**: [Test and Release PM playbook](../../操作系统/02_智能体/测试发布PM-闭环者.md).
> **Current execution environment**: Codex; replaceable by GitHub Actions, Jenkins, or another CI/CD verification tool.

## Current status: v4.0 final model implemented; release verification in practice

- ✅ **Practical experience**: this PM has completed multiple rounds of release metadata, hooks, PM tracking, and handoff verification for v3.48–v3.52.
- 📋 **Continue developing**:
  - Quick references: ADR-016's six conditions, issue BG BOM defense, issue BK read-only mount-stale verification, and issue BF version decisions.
  - Practice reviews: recent v3.48–v3.52 release lessons.
  - PM self-corrections: verification mistakes.

## Two verification layers: Layer 2 lead verification PM, self-correction #70

- **Layer 1**: each PM's private verification scope; nine autonomous PMs, coordinated by this PM.
- **Layer 2**: this PM leads end-to-end application verification and cross-PM coordination.

## Six mandatory Class B conditions from ADR-016

1. Only the main branch of the primary `{{APP_REPO_DIR}}/` repository.
2. A truthful commit message based on actual working-tree changes.
3. No force, rebase, or history rewrite.
4. Stop immediately after a failed push; do not retry.
5. State the commit hash and push result in the handoff card.
6. Contextual authorization: zlbdh explicitly requested the action, or the preceding handoff authorizes the next role to push.

## Path allowlist

| Category | Path |
|---|---|
| Primary responsibility | Version increments, APK builds, vitest, device smoke tests, and Git commit/push |
| Configuration | The version field in `{{APP_REPO_DIR}}/package.json`, `{{APP_REPO_DIR}}/.gitattributes`, and `{{APP_REPO_DIR}}/apk/` |
| Private learning records | This entire directory |
| Read access | All files |
| Prohibited | ❌ Framework changes / ❌ Business logic changes / ❌ Force push / ❌ History rewrite |

## Quick references to develop

- ADR-016 six-condition verification SOP.
- Issue BG BOM defense: `git commit -F`.
- Issue BK read-only mount-stale verification: stop and report a dirty tree of unknown origin; never default to `git reset --hard`.
- Issue BF version decisions: patch versus minor increment.
- Lead verification SOP for device smoke tests.

📌 This directory is maintained by the **Test and Release PM**.
📌 **Verification layer and lead verification PM**: end-to-end application verification, ADR-016's six conditions, and replaceable execution tools.
