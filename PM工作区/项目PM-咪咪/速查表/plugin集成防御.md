---
name: capacitor-plugin-defense
description: Capacitor plugin 集成 3 项防御：必静态 import + NotificationChannel + cap sync。防 PM 自纠 #47 议题 BC plugin 集成错向。
trigger: 写 Capacitor plugin 集成 handoff 卡前
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---

# 速查：Capacitor plugin 集成防御 3 项（PM 自纠 #47）

> 写 Capacitor plugin 集成 handoff 卡前 — **3 项必明示**

## 3 项防御铁律

### 1. **必静态 import**（不用 dynamic）

```js
// ✅ 正确
import { LocalNotifications } from '@capacitor/local-notifications';

// ❌ 错误（F-ALARM-1 v3.5.9 smoke 阻塞实证）
const mod = await import('@capacitor/local-notifications');
const plugin = mod?.LocalNotifications;
// → Android WebView 报 "LocalNotifications.then() is not implemented on android"
```

**根因**：Android Capacitor WebView 对 dynamic import 解析不一致；静态 import 是 Capacitor 推荐方式（plugin 注册到 native 桥）。

### 2. **NotificationChannel 必创建**（Android 8.0+）

```js
// ✅ 启动时（init / setup）调用，idempotent
await LocalNotifications.createChannel({
  id: 'mimi-alarms',
  name: '咪咪闹钟',
  description: 'F-ALARM-1 起床 / 睡前 / 训练 / 自定义闹钟',
  importance: 5,    // IMPORTANCE_HIGH，锁屏可见
  visibility: 1,    // VISIBILITY_PUBLIC
  sound: 'default',
  vibration: true,
});
```

**根因**：Android 8.0+ 强制要求 channel 已创建才能 schedule 通知；不创建 → logcat 报 `No Channel found for pkg=..., channelId=...`。

### 3. **cap sync android** 必跑（npm install 后）

```bash
cd {{APP_REPO_DIR}}
npm install @capacitor/xxx@^N.x
npx cap sync android   # ← 把 plugin 注册到 native Android 工程
```

**根因**：npm install 仅装 JS 层；native 集成需 sync。

## 历史实证

### PM 自纠 #47（2026-05-15 F-ALARM-1 v3.5.9 smoke 阻塞）

- alarmManager.js:158 用 `mod?.LocalNotifications ?? null` 动态 import
- 启动时**没调** createChannel
- 真机 smoke AC3 闹钟不响 → 3 根因联合（A1 + A2 + A3）

## handoff 卡模板（涉及 Capacitor plugin）

```
⑤ 警戒（必含）：
- 🔴 必静态 import：`import { XXX } from '@capacitor/yyy'`（不用 dynamic）
- 🔴 NotificationChannel / 类似 channel 启动时必创建（Android 8.0+ 强制）
- 🟡 npm install 后 `npx cap sync android` 复跑
- 🟡 测试改用 vi.mock（替代 dynamic import 注入模式）
```

## 跟其他元规则关系

- [Capacitor版本核对.md](Capacitor版本核对.md) — 装之前的版本检查
- [能力资产/rules/web-api-信源选型.md](../../../能力资产/rules/web-api-信源选型.md) — 议题 AT 矩阵（plugin 是首选方案）
