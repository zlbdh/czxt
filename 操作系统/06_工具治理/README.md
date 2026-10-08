---
name: tools-governance-index
scope: project
type: semantic
loaded: on-demand
description: Tool-governance entry — hooks, health checks, governance plans, and historical research.
---
# 06 Tool Governance

> Entry points for hooks, health checks, the target-state vision, memory governance, and improvement research. These help prevent framework discipline from fading during long sessions and record tool capability boundaries.

| File | Purpose |
|---|---|
| [Framework health check](framework体检.md) | Historical entry pointer; current entry is `能力资产/skills/项目体检.md` and `check-operating-system.ps1`. |
| [Hook design](hooks-设计.md) | Design decisions, layers, automated-write boundaries, and verification entry points. |
| [Hook event matrix](hooks-事件矩阵.md) | Manifest, Codex, and Claude event sets and count anchors. |
| [Event matrix appendix](hooks-事件矩阵-附录.md) | Watch/scheduled details, runtime differences, and events not yet connected. |
| [v4.0 vision entry](操作系统终态愿景-v4.0-2026-05-21.md) | Historical blueprint; original in `历史归档/2026-05/`. |
| [May 21, 2026 overview entry](操作系统全景图-2026-05-21.md) | Entry to the surviving snapshot fragment in `历史归档/2026-05/`. |
| [Improvement research entry](操作系统改进研究-2026-05-21.md) | Historical research; original in `历史归档/2026-05/`. |
| [Memory-governance plan entry](记忆治理方案-2026-05-22.md) | Historical plan; original in `历史归档/2026-05/`. |
| `历史归档/2026-05/` | Original records and fragments from May 2026. Excluded from active P4b/P4c/P4o checks; P4q checks only the first-screen historical boundary and fragment notice. |

## Procedure

1. Switch to the Operating System PM role and run decision-checkpoint.
2. Run `能力资产/tools/scripts/check-operating-system.ps1` first.
3. Add `能力资产/tools/scripts/check-readme-indexes.ps1`, `能力资产/tools/scripts/check-handoff-zone.ps1`, and `能力资产/tools/hooks/tests/hooks-smoke.ps1` as needed.
4. Report findings and record them in `状态.md`. Put soft warnings in the RETRO backlog; fix hard failures before continuing.

## Maintenance

- For each new check, update `能力资产/skills/项目体检.md`, `能力资产/tools/scripts/check-os/check-plan.ps1` / `check-plan-assert.ps1`, and the corresponding `能力资产/tools/scripts/check-os/` module documentation.
- For new hook/watch/scheduled capabilities, synchronize hook design, the event matrix and appendix, and the hooks README.
- Owner: Operating System PM “Framework Steward”.
