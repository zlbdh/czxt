---
name: web-api-source-selection-appendix
scope: project
type: reference
loaded: on-demand
description: "Web API data-source selection appendix: historical counterexamples, related meta-rules, and the proposed Q4 extension."
---

# Web API Data Source Selection Appendix

This appendix contains less frequently needed background. See the [main rule](web-api-信源选型.md) for the selection process and matrix.

## Counterexample: PM Self-Correction #45

**F-SYSCHECK-1 v3.5.8 smoke test #3 was blocked:**

- The initial PM handoff card specified: “Network: Capacitor `@capacitor/network` if already in package.json; otherwise, use `navigator.onLine` with `online` / `offline` events.”
- Claude Code fell back to `navigator.onLine` because the project did not have `@capacitor/network` installed.
- Physical-device smoke testing showed that `navigator.onLine` did not respond to runtime changes in Android WebView.
- PROP-022 Phase 1 added the `@capacitor/network` dependency. Phase 3 made the issue AT meta-rule permanent.

Root cause: the PM assumed that falling back to a browser API was reasonable when the preferred API was unavailable. Browser APIs are not necessarily reliable in Android WebView.

Safeguard: follow the main rule's verification process when preparing a PRD or handoff card. Verify APIs missing from the matrix on a physical device before using them as application data sources.

## Relationships with Other Meta-Rules

- [Role boundaries](../../操作系统/01_架构/角色边界.md): Product and Technical PMs must consult this rule when selecting web APIs.
- [Change classification](改动分级.md): choosing an unverified web API is Class B because it requires dependency assessment and physical-device verification; it is outside automatic Class A work.
- [Known technical constraints](已知技术约束.md): historical constraints such as the 9 KB mount limit and JDK 17 belong to the same collection of cross-platform pitfalls.
- [Writing PRDs](写PRD.md): the three states in issue P complement this rule. A fallback is not a guarantee that something works; verification is still required.

## Proposed Q4 Rule Check Extension for Issue AR

PROP-020 path D proposed another dimension for decision-checkpoint Q4, “Does my instruction comply with the existing framework meta-rules?”:

- Q4.d: consult this file when selecting web APIs, preventing repeats of PM self-correction #45.

This candidate predates RETRO-009. The main verification process and manual decision-checkpoint rules currently cover it. Propose a separate PROP if it is automated later.

## Related Records

- Historical PROP-022 from the source project, not copied into template instances: `确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md`.
- Historical smoke test #3 evidence from the source project, not copied into template instances: `交接区/历史归档/2026-05/2026-05-14-1455-F-SYSCHECK-1-network-smoke阻塞-Codex到ClaudeCode.md`.
- [RETRO-009 candidate issues](../../Docs/7-复盘/RETRO-009-候选议题.md).
- [Decision checkpoint](../../操作系统/07_完整工作流/decision-checkpoint.md).
