---
name: "web-api-source-selection"
description: "Source-selection matrix for navigator.*, Intl.*, and window.* APIs, covering Android WebView compatibility and recommended choices."
trigger: "Before choosing a web API as an application data source"
loaded: "条件加载（按 trigger 匹配时由 PM 调度）"
---

# Quick Reference: Issue AT Web API Source Matrix

> Before choosing `navigator.*`, `Intl.*`, or `window.*` as an application data source, **check this reference**.

## Recorded matrix: May 15, 2026, after PROP-022 Phase 2 device verification

| API | Dimension | Android WebView evidence | Recommendation |
|---|---|---|---|
| `navigator.onLine` | Network connectivity | Did not respond to runtime changes | `@capacitor/network` |
| `window 'online'/'offline'` events | Network events | Based on navigator.onLine | `Network.addListener` |
| `navigator.getBattery()` | Battery | Available | Use with null fallback |
| `navigator.hardwareConcurrency` | CPU cores | Available; returned 8 | Read once at startup |
| `navigator.deviceMemory` | RAM | Available; returned 8 | Supplemental source |
| `Intl.DateTimeFormat().resolvedOptions().timeZone` | Time zone | Available; read new value after restart | Keep Intl |

Full matrix and evidence: [Web API source selection](../../../能力资产/rules/web-api-信源选型.md).

## Rule from self-correction #45

Do not assume browser APIs have identical semantics across platforms. Chrome/Firefox/Safari behavior does not directly establish Android WebView behavior.

## Verification before PRD/handoff

1. Search the matrix.
2. If validated, select the API. If incompatible, use the recommended alternative. If unknown, continue to step 3.
3. Explicitly include device verification and adding results to the matrix in the handoff.
4. Do not ship an unverified API directly.

## Historical evidence

### Self-correction #45: F-SYSCHECK-1 v3.5.8 smoke #3

- Handoff allowed `@capacitor/network` if installed, otherwise a `navigator.onLine` fallback.
- Claude Code fell back to `navigator.onLine`; Android WebView did not respond.
- PROP-022 Phase 1 repaired it; Phase 3 made the meta-rule permanent.

## Related rules

- [Web API source selection](../../../能力资产/rules/web-api-信源选型.md): full matrix and evidence.
- [Plugin integration safeguards](plugin集成防御.md): integration rules after selecting a Capacitor plugin.
- Decision-checkpoint Q4.d: mandatory API-selection matrix check.
