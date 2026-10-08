---
name: "capacitor-plugin-defense"
description: "Three Capacitor plugin safeguards: static imports, NotificationChannel creation, and cap sync. Prevents self-correction #47 / issue BC."
trigger: "Before writing a Capacitor plugin integration handoff"
loaded: "条件加载（按 trigger 匹配时由 PM 调度）"
---

# Quick Reference: Three Capacitor Plugin Safeguards — Self-Correction #47

> Explicitly include all three safeguards before writing a plugin-integration handoff.

## 1. Require static imports

```js
// Correct.
import { LocalNotifications } from '@capacitor/local-notifications';

// Incorrect in the recorded F-ALARM-1 v3.5.9 smoke failure.
const mod = await import('@capacitor/local-notifications');
const plugin = mod?.LocalNotifications;
// Android WebView reported: "LocalNotifications.then() is not implemented on android"
```

Recorded cause: inconsistent dynamic-import handling in Android Capacitor WebView. The reference recommends static imports to register the plugin with the native bridge.

## 2. Create NotificationChannel on Android 8.0+

```js
// Call idempotently at startup: init / setup.
await LocalNotifications.createChannel({
  id: 'mimi-alarms',
  name: 'Mimi Alarms',
  description: 'F-ALARM-1 wake-up / bedtime / training / custom alarms',
  importance: 5,    // IMPORTANCE_HIGH; visible on the lock screen.
  visibility: 1,    // VISIBILITY_PUBLIC
  sound: 'default',
  vibration: true,
});
```

Recorded cause: Android 8.0+ requires an existing channel before scheduling notifications. Without it, logcat reported `No Channel found for pkg=..., channelId=...`.

## 3. Run cap sync android after npm install

```bash
cd {{APP_REPO_DIR}}
npm install @capacitor/xxx@^N.x
npx cap sync android   # Register the plugin with the native Android project.
```

npm install adds only the JavaScript layer; native integration requires sync.

## Historical evidence

### Self-correction #47: May 15, 2026, F-ALARM-1 v3.5.9 blocked smoke test

- alarmManager.js:158 used `mod?.LocalNotifications ?? null` with dynamic import.
- Startup did not call createChannel.
- Physical-device smoke AC3 produced no alarm: three combined causes, A1 + A2 + A3.

## Plugin handoff template

```text
⑤ Required cautions:
- 🔴 Static import: import { XXX } from '@capacitor/yyy'; do not use dynamic import.
- 🔴 Create NotificationChannel or equivalent at startup; Android 8.0+ requires it.
- 🟡 Rerun npx cap sync android after npm install.
- 🟡 Use vi.mock in tests instead of dynamic-import injection.
```

## Related rules

- [Capacitor version verification](Capacitor版本核对.md): check before installation.
- [Web API source selection](../../../能力资产/rules/web-api-信源选型.md): issue AT matrix; plugins are the preferred option.
