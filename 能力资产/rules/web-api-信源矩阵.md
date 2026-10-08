---
name: web-api-source-matrix
scope: project
type: reference
loaded: on-demand
description: Reliability matrix for web APIs in Android WebView and Capacitor.
---

# Web API Data Source Matrix

> See the [selection process](web-api-信源选型.md).

| API | Category | Android WebView reliability | Recommended approach | Evidence |
|---|---|---|---|---|
| `navigator.onLine` | Network connectivity | ❌ **Does not respond to runtime changes; cannot be the sole application data source** | `@capacitor/network` Network.getStatus + addListener | Physical-device smoke test #3 on the old F-SYSCHECK-1 v3.5.8 APK: still reported online after ADB airplane-mode commands and svc wifi/data disable; fixed with Capacitor Network following PROP-022 |
| `window.addEventListener('online'/'offline')` | Network events | ❌ Same limitation; based on navigator.onLine | `Network.addListener('networkStatusChange', ...)` | Inferred from the preceding finding |
| `navigator.getBattery()` | Battery | ✅ Available in the tested Android WebView; returned `BatteryManager.level=1`, `charging=true` | Usable; retain a null fallback and `(Default)` indicator | May 15, 2026, Codex v3.5.8 physical-device Phase 2; device `2684ba6e` |
| `navigator.hardwareConcurrency` | CPU core count | ✅ Available in the tested Android WebView; returned `8` | Usable as a startup performance-tier data source; retain a null fallback | May 15, 2026, Codex v3.5.8 physical-device Phase 2 |
| `navigator.deviceMemory` | RAM | ✅ Available in the tested Android WebView; returned `8` | Usable as a supplemental source; verify on the target device before application use | May 15, 2026, Codex v3.5.8 physical-device Phase 2 |
| `Intl.DateTimeFormat().resolvedOptions().timeZone` | Time zone | ✅ Available in the tested Android WebView; restarting the app after switching the system time zone between Tokyo and Shanghai returned the new value | Keep Intl; refresh or restart to read the changed time zone, and retain a fallback | May 15, 2026, Codex ADB evidence: `cmd time_zone_detector set_time_zone_state_for_tests --zone_id Asia/Tokyo` |
| `navigator.serviceWorker.register()` | PWA / offline cache | ✅ **Safe / N/A**: the `!window.Capacitor` guard prevents execution under Capacitor | Keep the existing behavior: register only in the browser path | June 14, 2026, physical device (Xiaomi 13 Pro / Android 16 / WebView 147 / CDP): `window.Capacitor=true` confirmed the service-worker registration branch was skipped and did not run inside the app |
| `window.addEventListener('focus')` | Window / app focus | ❌ **Not triggered**: Android WebView background/foreground transitions do not emit focus/blur | Retain as a fallback for other devices; on the tested device, use `visibilitychange` and `setInterval(60s)` alongside it. **Refreshes across midnight are unaffected** | June 14, 2026, physical device: two HOME-to-foreground cycles produced focus=0/blur=0, while visibilitychange worked |
| `document.hidden` / `visibilitychange` | Page visibility | ✅ **Reliable**: boolean state and accurate background/foreground events | Use as the **primary signal** for refreshes across midnight, through the main useTodayTick path | June 14, 2026, physical device: two background/foreground cycles correctly reported hidden/visible transitions; `typeof document.hidden=boolean` |
| `window.addEventListener('keydown')` | Keyboard events | ✅ **Reliable** for hardware and navigation keys | Usable; mobile software-keyboard behavior still depends on the focused input | June 14, 2026, physical device: TAB, DOWN, and UP all triggered events; lastKey=ArrowUp was correct |

✅ **PROP-022 Phase 2 results recorded** on May 15, 2026 by Codex: the first set of Android WebView physical-device source checks was added to the matrix.

📌 **Physical-device verification completed June 14, 2026** on a Xiaomi 13 Pro with Android 16 and Chromium WebView 147, using CDP injection and two rounds of ADB background/foreground and key tests: visibilitychange and keydown were reliable; serviceWorker was safe because it did not execute under Capacitor; window focus did not trigger, but visibilitychange plus the 60-second tick preserved functionality. The recorded conclusion was that none of these four items posed a functional risk.
