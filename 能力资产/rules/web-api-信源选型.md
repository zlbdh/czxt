---
name: web-api-source-selection
scope: project
type: semantic
loaded: on-demand
description: Rules for choosing web API data sources in Capacitor and Android WebView. Verify on a physical device before adoption; maintain the matrix separately (issue AT).
---

# Rule: Choosing Web API Data Sources (Issue AT Meta-Rule)

> ⭐ Implemented in PROP-022 Phase 3 on May 15, 2026: made the issue AT meta-rule permanent to prevent repeats of PM self-correction #45.
> Triggering evidence: F-SYSCHECK-1 v3.5.8 smoke test #3 was blocked because `navigator.onLine` did not respond to runtime changes in Android WebView.
> See the [known API matrix](web-api-信源矩阵.md). The [appendix](web-api-信源选型-附录.md) covers historical counterexamples, the proposed Q4 extension, and related meta-rules.

## Core Principle

**Before using any `navigator.*`, `Intl.*`, or `window.*` web API in Capacitor or Android WebView, verify its reliability on a physical device.**

Do not assume browser APIs have identical semantics across platforms. Behavior in Chrome, Firefox, or Safari does not establish behavior in Android WebView.

## When This Applies

- Before choosing a web API as an application data source in a PRD, handoff card, or PROP.
- When implementing system-state awareness or device-capability detection.
- When selecting a cross-platform API for any Capacitor project.

## Required Verification During PRD or Handoff Preparation

1. Search `web-api-信源矩阵.md` for the proposed API.
2. Follow the recorded result:
   - Reliable ✅: use it.
   - Unreliable ❌: use the recommended alternative, such as a Capacitor plugin, native API, or fallback.
   - Not recorded ❓: continue to step 3.
3. Explicitly include **physical-device verification and a matrix update** in the handoff card or PRD.
   - Scope: Capacitor localhost, Android WebView, and the target Android version.
   - Method: build a development APK, install it with ADB, and inspect WebView `console.log` output.
   - Record the result in `web-api-信源矩阵.md`. If the change accompanies a code commit in `{{APP_REPO_DIR}}/`, state that one row was added to the issue AT matrix in the commit message. Otherwise, record it in the PRD, handoff card, or status log.
4. Do not ship an unverified API. PM self-correction #45 records the failure caused by assuming equivalent cross-platform behavior and choosing a fallback without verification.

## Known API Matrix

The source of truth is [web-api-信源矩阵.md](web-api-信源矩阵.md).

It currently covers 10 API categories: network connectivity, network events, battery, CPU core count, RAM, time zone, service workers, focus, visibility changes, and keyboard events.

Quick findings:

- `navigator.onLine` and `online/offline`: do not use them as the sole application data source; use Capacitor Network.
- `visibilitychange` and `document.hidden`: can provide the primary signal for refreshes across midnight in Android WebView.
- `window focus/blur`: background/foreground transitions do not trigger them in Android WebView; use them only as a fallback.
- `serviceWorker.register()`: the `!window.Capacitor` guard skips registration under Capacitor, so it does not run inside the app.

## Updating the Matrix

After verifying a new web API:

1. Add a row to [web-api-信源矩阵.md](web-api-信源矩阵.md).
2. The **Evidence** column must include the feature name, test date, and key evidence: commands, expected results, and actual results.
3. Prefer alternatives in this order:
   - Official Capacitor plugins in the `@capacitor/*` family.
   - Native Android APIs exposed through a custom Capacitor plugin.
   - Browser APIs with a fallback and a `(Default)` UI indicator.
4. Update the related issue AT matrix section in the PROP-XXX file. If application code in `{{APP_REPO_DIR}}/` is also committed, add a note to the commit message. Otherwise, record the update in the handoff card or status log.

## History and Extensions

- Historical counterexample: F-SYSCHECK-1 v3.5.8 smoke test #3 found that `navigator.onLine` did not respond to runtime network changes in Android WebView.
- Root cause: treating a browser API fallback as a reliable cross-platform data source.
- Current safeguard: follow this verification process when preparing a PRD or handoff card. Do not automatically classify an unverified web API selection as Class A.
- See the [appendix](web-api-信源选型-附录.md).

## Related Records

- Historical PROP-022 from the source project, not copied into template instances: `确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md`.
- Historical smoke test #3 evidence from the source project, not copied into template instances: `交接区/历史归档/2026-05/2026-05-14-1455-F-SYSCHECK-1-network-smoke阻塞-Codex到ClaudeCode.md`.
- [RETRO-009 candidate issues](../../Docs/7-复盘/RETRO-009-候选议题.md): issue AT candidate backlog.
- [Role boundaries](../../操作系统/01_架构/角色边界.md): nine PM roles and path allowlists.
- [Android WebView API reliability matrix](web-api-信源矩阵.md).
- [Appendix](web-api-信源选型-附录.md): counterexamples, meta-rule relationships, and the decision-checkpoint Q4 proposal.
