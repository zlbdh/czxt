---
name: web-api-source-matrix
scope: project
type: reference
loaded: on-demand
description: web API 在 Android WebView / Capacitor 场景下的可靠性矩阵。
---

# web API 信源矩阵

> 选型流程见 [`web-api-信源选型.md`](web-api-信源选型.md)。

| API | 维度 | Android WebView 可靠性 | 推荐方案 | 证据来源 |
|---|---|---|---|---|
| `navigator.onLine` | 网络在线 | ❌ **不响应运行时切换，不可单独作为业务信源** | `@capacitor/network` Network.getStatus + addListener | F-SYSCHECK-1 v3.5.8 旧 APK smoke #3 真机实证：ADB 飞行模式 + svc wifi/data disable 后仍显示在线；PROP-022 后由 Capacitor Network 修复 |
| `window.addEventListener('online'/'offline')` | 网络事件 | ❌ 同上（基于 navigator.onLine）| `Network.addListener('networkStatusChange', ...)` | 同上推断 |
| `navigator.getBattery()` | 电量 | ✅ 当前 Android WebView 可用（返回 `BatteryManager.level=1`, `charging=true`）| 可用；仍保留 null fallback `(默认)` | 2026-05-15 Codex v3.5.8 真机 Phase 2，设备 `2684ba6e` |
| `navigator.hardwareConcurrency` | CPU 核数 | ✅ 当前 Android WebView 可用（返回 `8`）| 可用作启动时性能等级信源；仍保留 null fallback | 2026-05-15 Codex v3.5.8 真机 Phase 2 |
| `navigator.deviceMemory` | RAM | ✅ 当前 Android WebView 可用（返回 `8`）| 可作为辅助信源；业务使用前仍需目标机复核 | 2026-05-15 Codex v3.5.8 真机 Phase 2 |
| `Intl.DateTimeFormat().resolvedOptions().timeZone` | 时区 | ✅ 当前 Android WebView 可用；系统时区 Tokyo/Shanghai 切换后 APP 重启可读新值 | 保持 Intl；时区变化后刷新/重启读取，保留 fallback | 2026-05-15 Codex ADB `cmd time_zone_detector set_time_zone_state_for_tests --zone_id Asia/Tokyo` 实证 |
| `navigator.serviceWorker.register()` | PWA / 离线缓存 | ✅ **安全·N/A**（代码 `!window.Capacitor` 守卫，Capacitor 下不执行）| 维持现状（仅浏览器路径才注册）| 2026-06-14 真机（小米13Pro/Android16/WebView147 / CDP）：`window.Capacitor=true` 确认 SW 注册分支跳过、不在 App 内运行 |
| `window.addEventListener('focus')` | 窗口 / App 焦点 | ❌ **不触发**（Android WebView 后台↔前台不发 focus/blur）| 保留作跨设备兜底；本机靠 `visibilitychange`+`setInterval(60s)` 三路兜底，**跨午夜刷新功能不受影响** | 2026-06-14 真机：2 轮 HOME→前台 focus=0/blur=0（同期 visibilitychange 正常）|
| `document.hidden` / `visibilitychange` | 页面可见性 | ✅ **可靠**（boolean + 后台↔前台准确触发）| 用作跨午夜刷新**主信号**（useTodayTick 主路）| 2026-06-14 真机：2 轮 bg/fg visibilitychange 准确 hidden↔visible；`typeof document.hidden=boolean` |
| `window.addEventListener('keydown')` | 键盘事件 | ✅ **可靠**（硬件/导航键触发）| 可用；移动软键盘仍以聚焦输入为准 | 2026-06-14 真机：TAB/DOWN/UP 3 键全触发，lastKey=ArrowUp 正确 |

✅ **PROP-022 Phase 2 已回填**（2026-05-15 Codex）：本轮矩阵完成首批 Android WebView 真机信源记录。

📌 **2026-06-14 真机验证完成**（小米13Pro / Android 16 / Chromium WebView 147 / CDP 注入 + adb bg-fg 与按键 2 轮实测）：visibilitychange / keydown ✅ 可靠；serviceWorker ✅ 安全（Capacitor 下不执行）；window focus ❌ 不触发但有 visibilitychange+60s tick 兜底、功能无损。结论：4 项均不构成功能风险。
