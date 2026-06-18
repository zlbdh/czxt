---
name: capacitor-version-verify
description: 引入 @capacitor/* 新依赖前必先 Read {{APP_REPO_DIR}}/package.json 确认 Capacitor 主版本。防 PM 自纠 #46 版本错向。
trigger: 准备引入 @capacitor/XXX 新依赖时
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---

# 速查：Capacitor 新依赖版本核对（PM 自纠 #46）

> 写 handoff 卡引入 `@capacitor/*` 新依赖前 — **必先 Read {{APP_REPO_DIR}}/package.json 确认 Capacitor 主版本**

## 铁律

```
准备引入 @capacitor/XXX 新依赖
    ↓
① Read {{APP_REPO_DIR}}/package.json
    ↓
② 查 @capacitor/core 主版本（如 ^6.1.2 / ^7.0.0）
    ↓
③ handoff 卡明示 `@capacitor/XXX@^N.x`（N = core 主版本）
    ↓
④ 不写 `^latest` 不写 `^7.x` 当 core 是 `^6.x`
```

## 历史实证

### PM 自纠 #46（2026-05-15 PROP-022）

- handoff 卡写 `@capacitor/network@^7.x`
- 实际项目 `@capacitor/core: ^6.1.2`
- Claude Code 通过 decision-checkpoint 改装 `^6.0.4` 避主版本冲突
- 如装 `^7` → build 挂

### F-ALARM-1（2026-05-15 PROP-023 校对）

- handoff 卡明示 `@capacitor/local-notifications@^6.x`（吸收 #46 教训）
- Claude Code Read package.json 实证 ✅ 装 `^6.1.3`

## 后续涉及 Capacitor plugin 的 PROP 必做

- ✅ 起 PROP / handoff 前 → Read package.json
- ✅ PROP / handoff 必明示 `^N.x` 主版本
- ✅ 交接卡 ⑤ 警戒段加「Capacitor 版本核对」防御项
- ✅ commit msg 注脚记主版本（防未来 grep 失忆）

## 跟其他元规则关系

- [能力资产/rules/web-api-信源选型.md](../../../能力资产/rules/web-api-信源选型.md) — 议题 AT 矩阵（同性质：跨平台陷阱档案）
- [速查表/plugin集成防御.md](plugin集成防御.md) — 装上之后还要静态 import + NotificationChannel
