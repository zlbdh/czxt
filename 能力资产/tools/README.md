---
name: capability-tools-index
scope: project
type: procedural
loaded: on-demand
description: App-template build reference, instance dependency template, executable scripts, and hook entry points (PROP-028 / task 109).
---

# Tool Governance

Build-script declarations were introduced under PROP-028; **executable `scripts/`** were consolidated in task #109 / issue CM v3.2 on May 22, 2026; **hook entry points** followed in PROP-038 Layer 4 v0 on June 13, 2026.

**Boundary:** `构建脚本.md` is an app-template reference. Each instance follows its project card, actual repository scripts, and CI configuration. Referencing its technology or commands does not expand the [role path allowlists](../../操作系统/01_架构/角色边界.md).

## Structure

| Entry | Type | Contents |
|---|---|---|
| `构建脚本.md` | Declaration | App-template npm scripts, APK builds, and PM responsibilities; the project instance source of truth takes priority. |
| `依赖矩阵.md` | Declaration | Dependency inventory filled from actual manifests, lockfiles, and scripts; upgrade and installation procedures. |
| `scripts/` | Executable | Eight public entry points listed below, with internal subchecks and helpers. |
| `hooks/` | Triggers | `manifest.json`, `run-hooks.ps1`, Git/watch/scheduled wrappers; `tests/support/` holds internal smoke-test contracts. |

Public script entry points:

- `check-operating-system.ps1`
- `check-winps-encoding.ps1`
- `check-pm-tracking.ps1`
- `check-readme-indexes.ps1`
- `update-adr-readme.ps1`
- `check-handoff-zone.ps1`
- `check-pre-release.ps1`
- `check-retro-cadence.ps1`

`scripts/check-os/` contains internal P4a-P4t subchecks and support helpers for the health-check entry point. P4t performs read-only, offline borrowing-cycle consistency checks.

`scripts/check-readme-indexes/` contains internal README/INDEX helpers and bridges P4o/P4q/P4r so both PostToolUse and the complete health check detect broken links in active Markdown, governance semantics, and hook configuration drift. `scripts/check-handoff-zone/` contains internal handoff helpers. These helpers do not receive separate hook-manifest entries; `hooks/manifest.json` is authoritative.

## Invocation examples

```powershell
# Run from the project root.
powershell -File 能力资产/tools/scripts/check-operating-system.ps1
powershell -File 能力资产/tools/scripts/check-pm-tracking.ps1
powershell -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
powershell -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
```

Recommended PM tracking command:

```powershell
powershell -NoProfile -File 能力资产/tools/scripts/add-pm-track.ps1 -From "<from-role>" -To "<to-role>" -Task "<work-performed>"
```

It appends a correctly formatted row with a real `Get-Date` timestamp, preventing manual timestamp errors that break P4f tracking.

Consolidation history: the former `{{PROJECT_ROOT}}\tools/`, created in tasks #90–#92, and this directory's PROP-028 declarations were merged in task #109. PM self-correction #75 requires checking naming conflicts before creating a top-level directory.

## References

- [Build Scripts](构建脚本.md): app-template build and role reference.
- [Dependency Matrix](依赖矩阵.md): actual instance dependencies and upgrade procedures.
- [Hooks](hooks/README.md): manifest, runner, and wrappers.

## Relationship to application tools

- This directory provides declarations about tool purpose and upgrade policy, alongside the executable framework scripts described above.
- `{{APP_REPO_DIR}}/build-apk.bat` and `package.json` are actual application tools.
- `{{APP_REPO_DIR}}/.env.local` is ignored local AI configuration, conditional Class B under ADR-022's six safeguards. Externally transmitting real API keys or writing them to tracked files remains Class C.

## Maintenance

- Synchronize this directory when adding or upgrading dependencies.
- New hooks require updates to `hooks/manifest.json`, `hooks/README.md`, `操作系统/06_工具治理/hooks-设计.md`, the hook event matrix and appendix, and `操作系统/07_完整工作流/hooks-运行SOP.md` and appendix.
- Operating System PM and the role receiving the PR share responsibility.

## Windows PowerShell 5.1 encoding gate

From the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-winps-encoding.ps1 -Root $PWD
```

- Scope: root `实例化项目.ps1` if present, `.claude/**/*.ps1`, `.codex/**/*.ps1`, and `能力资产/**/*.ps1`. Excludes `.git/`, `项目区/本地实例/`, and `借鉴区/**/快照/`.
- Every in-scope script must begin with UTF-8 BOM bytes `EF BB BF` and parse without errors in the current Windows PowerShell 5.1 parser.
- `-ListOnly` lists stable, sorted, deduplicated relative paths without checking BOM/syntax or modifying files.
- Exit code `0` means all checks pass. Invalid Root, discovery/read failures, missing BOM, or syntax errors return `10`.
