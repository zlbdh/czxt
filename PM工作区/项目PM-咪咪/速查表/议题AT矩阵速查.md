---
name: web-api-source-selection
description: navigator.* / Intl.* / window.* API 作业务信源选型矩阵。Android WebView 兼容性 + 推荐方案。防业务 API 选型错向。
trigger: 选 web API 作业务信源前
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---

# 速查：议题 AT — web API 信源选型矩阵

> 选 `navigator.*` / `Intl.*` / `window.*` API 作业务信源前 — **必先查这里**

## 当前矩阵（截至 2026-05-15 PROP-022 Phase 2 真机验后）

| API | 维度 | Android WebView | 推荐 |
|---|---|---|---|
| `navigator.onLine` | 网络在线 | ❌ 不响应运行时切换 | `@capacitor/network` |
| `window 'online'/'offline'` 事件 | 网络事件 | ❌ 基于 navigator.onLine | `Network.addListener` |
| `navigator.getBattery()` | 电量 | ✅ 可用 | 用 + null fallback |
| `navigator.hardwareConcurrency` | CPU 核数 | ✅ 可用（返回 8）| 启动一次读 |
| `navigator.deviceMemory` | RAM | ✅ 可用（返回 8）| 辅助信源 |
| `Intl.DateTimeFormat().resolvedOptions().timeZone` | 时区 | ✅ 可用（重启读新值）| 保持 Intl |

⭐ **完整矩阵 + 证据来源** → [`能力资产/rules/web-api-信源选型.md`](../../../能力资产/rules/web-api-信源选型.md)

## 铁律（PM 自纠 #45）

**不假设浏览器 API 跨平台同语义** — Chrome / Firefox / Safari 上的行为不能直接推断到 Android WebView。

## 验证流程（写 PRD / handoff 前）

```
① grep 上面矩阵
    ↓
② 命中？
    ├─ ✅ 直接选
    ├─ ❌ 用推荐方案
    └─ ❓ 跳 ③
    ↓
③ handoff 卡明示「真机验证 + 入矩阵」步骤
    ↓
④ 不直接 ship 未验证的 API
```

## 历史实证

### PM 自纠 #45（F-SYSCHECK-1 v3.5.8 smoke #3）

- handoff 卡：「`@capacitor/network` 如已装用，否则 `navigator.onLine` fallback」
- Claude Code fallback 到 `navigator.onLine` → Android WebView 不响应
- PROP-022 Phase 1 修复 + Phase 3 元规则永久化

## 跟其他元规则关系

- [能力资产/rules/web-api-信源选型.md](../../../能力资产/rules/web-api-信源选型.md) — 完整矩阵 + 证据
- [plugin集成防御.md](plugin集成防御.md) — 选 Capacitor plugin 后的集成规范
- decision-checkpoint Q4.d — web API 选型必查矩阵
