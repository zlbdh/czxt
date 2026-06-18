---
name: changelog-header-check
description: 检查 CHANGELOG 改动是否违反 header 规则。写 handoff 卡列 CHANGELOG 改动前必查。防 PM 自纠 #43。
trigger: 写 handoff 卡列 CHANGELOG.md 改动前
loaded: 条件加载（按 trigger 匹配时由 PM 调度）
---

# 速查：CHANGELOG header 规则（PM 自纠 #43）

> 写 handoff 卡列 `操作系统/00_变更记录/CHANGELOG.md` 改动前 — **必核对 header 规则**

## 铁律

`操作系统/00_变更记录/CHANGELOG.md` header 明示：

```
⚠️ **业务代码**改动走 `{{APP_REPO_DIR}}/` git history，**不进本文件**。
```

→ **业务代码改动**（{{APP_REPO_DIR}}/src/* / 测试代码 / Capacitor 集成）**不进** `操作系统/00_变更记录/CHANGELOG.md`，进 {{APP_REPO_DIR}} git commit msg + 需求历史.md。

## 进操作系统 CHANGELOG 的改动类型

| ✅ 进 CHANGELOG | ❌ 不进 CHANGELOG |
|---|---|
| framework 元规则演化（PROP/ADR/RETRO 索引）| 业务 feature（F-XXX）|
| Sprint 收官（轻量索引行）| 业务 bug 修复 |
| 工具升级（能力资产/skills/* + 能力资产/tools/*）| 测试 mock 文件 |
| 元规则文件改（能力资产/rules/* + 操作系统/07_完整工作流/*）| Capacitor plugin 集成 |
| 议题 AM 归档触发 | 业务代码 refactor |

## 历史实证

### PM 自纠 #43（2026-05-14 F-SYSCHECK-1 handoff 卡）

- handoff 卡列「M 操作系统/00_变更记录/CHANGELOG.md 加 entry」
- F-SYSCHECK-1 是 Sprint-5 业务 feature → **违反 header 规则**
- Claude Code 通过 PROP-014 三阶判定（🟡 非阻塞议题）挡下
- PM handoff 卡误指令暴露 → 议题 AR Q4 候选

## 防御措施

### 写 handoff 卡涉及 CHANGELOG 改动前 30 秒自检

1. **改动性质**：业务 / framework？
2. **路径**：{{APP_REPO_DIR}}/src/* → 不进操作系统 CHANGELOG
3. **正确归宿**：{{APP_REPO_DIR}} git commit msg + Docs/1-需求文档/需求历史.md

### 议题 A 归档触发（独立机制）

CHANGELOG.md 超 6500B 阈值 → **PM 战场归档**到对应日期窗口 `CHANGELOG-2026*.md`（不依赖业务 feature ship）— 已实战多次（PROP-018 P1 / 议题 AM / PROP-019 / 2026-06-14 滚动切档）

## 跟其他元规则关系

- [操作系统/00_变更记录/CHANGELOG.md](../../../操作系统/00_变更记录/CHANGELOG.md) — 主文件 header 明示
- decision-checkpoint Q4.a — 规则记忆校验候选
