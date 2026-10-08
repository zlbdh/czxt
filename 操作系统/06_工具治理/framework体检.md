---
name: framework-health-check-legacy-pointer
scope: project
type: semantic
loaded: on-demand
description: Historical framework-health pointer — the current entry is 能力资产/skills/项目体检.md and check-operating-system.ps1.
---

# Framework Health Check · Historical Pointer

> This preserves the early O-4 / PROP-029 v2 entry from 2026-05-21 for traceability.
> **Current health-check entry**: [project health skill](../../能力资产/skills/项目体检.md).
> **Current automated script**: [check-operating-system.ps1](../../能力资产/tools/scripts/check-operating-system.ps1).

## Current procedure

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-operating-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-readme-indexes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-handoff-zone.ps1
```

Then separately run [decision-checkpoint](../07_完整工作流/decision-checkpoint.md) Q1-Q7 through the startup sequence. Q1-Q7 is not embedded in the scripts.

Use the [project health skill](../../能力资产/skills/项目体检.md) for complete thresholds, report templates, the 11 check themes, the relationship to Q1-Q7 self-checks, and the P4a-P4t automated guards.

## Why the old checklist is no longer maintained

- The former lightweight manual checklist no longer covers the current scope.
- Current checks span P4a-P4t: basic integrity, file sizes, framework reference frequency, status freshness, mount-cache notices, PM tracking, README/index consistency, version/Sprint anchors, governance counts, stale guidance, branch policy, skill-command freshness, PM workspace alignment, active Markdown links/anchors, remaining capability assets, governance semantics, hook configuration/runtime anchors, template cleanliness, and borrowing-workflow consistency. P4o also connects to `check-readme-indexes.ps1`, allowing PostToolUse checks to catch broken links after edits.
- This file keeps only pointers instead of duplicating thresholds and check details, preventing competing sources from diverging.

## Versions

- v1, 2026-05-21 / PROP-029 v2: early manual health-check entry.
- v2, 2026-06-14: retired to a historical pointer; the formal entry moved to `能力资产/skills/项目体检.md` and `check-operating-system.ps1`.
