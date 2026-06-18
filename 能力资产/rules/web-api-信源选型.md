---
name: web-api-source-selection
scope: project
type: semantic
loaded: on-demand
description: web API 在 Capacitor/Android WebView 场景下的信源选型规则入口 — 先真机验证再选用，矩阵独立维护（议题 AT）
---

# 规则：web API 信源选型（议题 AT 元规则）

> ⭐ PROP-022 Phase 3 落地（2026-05-15，议题 AT 元规则永久化）— PM 自纠 #45 同模式防御
> 触发证据：F-SYSCHECK-1 v3.5.8 smoke #3 阻塞 — `navigator.onLine` Android WebView 不响应运行时切换
> 已知 API 判定矩阵见 [`web-api-信源矩阵.md`](web-api-信源矩阵.md)；历史反例、Q4 扩展候选和元规则关系详见 [`web-api-信源选型-附录.md`](web-api-信源选型-附录.md)。

## 核心原则

**任何 `navigator.*` / `Intl.*` / `window.*` web API 在 Capacitor / Android WebView 场景下，先真机验证可靠性，再决定是否选用**。

不假设浏览器 API 跨平台同语义 — Chrome / Firefox / Safari 上的行为不能直接推断到 Android WebView 上。

## 适用范围

- 写 PRD / handoff 卡 / 起 PROP 时**选 web API 作为业务信源**之前
- 实施 feature 涉及"系统状态感知"/"设备能力探测"类需求
- 任何 Capacitor 项目集成跨平台 API 选型

## 验证流程（写 PRD / handoff 卡时必跑）

```
准备选某 API 作为信源
    ↓
① grep `web-api-信源矩阵.md`
    ↓
② 命中矩阵？
    ├─ 已记录可靠 ✅ → 直接选
    ├─ 已记录不可靠 ❌ → 用矩阵推荐的替代方案（Capacitor plugin / 原生 / fallback）
    └─ 未记录 ❓ → 跳 ③
    ↓
③ handoff 卡 / PRD 必明示「真机验证 + 入矩阵」步骤
    - 验证范围：Capacitor localhost + Android WebView + 你的目标 Android 版本
    - 验证方式：build dev APK + ADB install + WebView console.log
    - 验证结果：填入 `web-api-信源矩阵.md`；若伴随 `{{APP_REPO_DIR}}/` 代码提交，commit msg 明示议题 AT 矩阵 +1 行，否则在 PRD / 交接卡 / 状态留痕中说明
    ↓
④ 不直接 ship 未验证的 API（PM 自纠 #45 反例 — 假设跨平台同语义直接 fallback）
```

## 已知矩阵

矩阵真源见 [`web-api-信源矩阵.md`](web-api-信源矩阵.md)。

当前已覆盖 10 类 API：网络在线 / 网络事件 / 电量 / CPU 核数 / RAM / 时区 / serviceWorker / focus / visibilitychange / keydown。

快速结论：

- `navigator.onLine` 与 `online/offline`：不可单独作为业务信源，改用 Capacitor Network。
- `visibilitychange` / `document.hidden`：Android WebView 可作为跨午夜刷新主信号。
- `window focus/blur`：Android WebView 后台↔前台不触发，只能作兜底。
- `serviceWorker.register()`：Capacitor 下被 `!window.Capacitor` 守卫跳过，App 内安全不执行。

## 矩阵填充流程

新 web API 验证后入矩阵 4 步：

1. 在 [`web-api-信源矩阵.md`](web-api-信源矩阵.md) 添加一行
2. **证据来源** 列必含：feature 名 / 实测时间 / 关键实证（命令 + 期望 vs 实际）
3. 推荐方案优先级：
   - **首选** Capacitor 官方 plugin（@capacitor/* 系列）
   - **次选** 原生 Android API（通过 Capacitor 自定义 plugin）
   - **兜底** 浏览器 API + fallback `(默认)` UI 提示
4. 改 PROP-XXX 文件「关联议题 AT 矩阵」段；若伴随 `{{APP_REPO_DIR}}/` 代码提交，再在 commit msg 加注脚，否则写入交接卡或状态留痕

## 历史背景与扩展

- 历史反例：F-SYSCHECK-1 v3.5.8 smoke #3，`navigator.onLine` 在 Android WebView 下不响应运行时网络切换。
- 根因：把“浏览器 API fallback”误当成跨平台可靠信源。
- 当前防御：写 PRD / handoff 卡时跑本文件验证流程；未验证 web API 选型默认不降为 A 类。
- 详情见 [`web-api-信源选型-附录.md`](web-api-信源选型-附录.md)。

## 关联

- [`../../确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md`](../../确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md) — PROP-022 主稿
- [`../../交接区/历史归档/2026-05/2026-05-14-1455-F-SYSCHECK-1-network-smoke阻塞-Codex到ClaudeCode.md`](../../交接区/历史归档/2026-05/2026-05-14-1455-F-SYSCHECK-1-network-smoke阻塞-Codex到ClaudeCode.md) — F-SYSCHECK-1 smoke #3 阻塞实证
- [`../../Docs/7-复盘/RETRO-009-候选议题.md`](../../Docs/7-复盘/RETRO-009-候选议题.md) — 议题 AT 候选 backlog
- [`操作系统/01_架构/角色边界.md`](../../操作系统/01_架构/角色边界.md) — 9 PM 角色边界 + 路径白名单
- [`web-api-信源矩阵.md`](web-api-信源矩阵.md) — Android WebView API 可靠性矩阵
- [`web-api-信源选型-附录.md`](web-api-信源选型-附录.md) — 反例、元规则关系、decision-checkpoint Q4 候选背景
