---
name: web-api-source-selection-appendix
scope: project
type: reference
loaded: on-demand
description: web API 信源选型规则附录 — 历史反例、元规则关系、Q4 扩展候选
---

# web API 信源选型附录

本附录承接低频解释；高频选型流程和矩阵见 [`web-api-信源选型.md`](web-api-信源选型.md)。

## 反例（PM 自纠 #45）

**F-SYSCHECK-1 v3.5.8 smoke #3 阻塞**：

- 起手时 PM handoff 卡写：“网络：Capacitor `@capacitor/network`（如已 in package.json 用，否则用 `navigator.onLine` + `online` / `offline` 事件）”。
- Claude Code fallback 到 `navigator.onLine`（项目未装 `@capacitor/network`）。
- 真机 smoke 揭示 `navigator.onLine` 在 Android WebView 不响应运行时切换。
- PROP-022 Phase 1 修复：加 `@capacitor/network` 依赖；Phase 3 将议题 AT 元规则永久化。

根因：PM 假设“不可用就 fallback 到浏览器 API”是合理 fallback；实际上浏览器 API 在 Android WebView 不一定可靠。

防御：写 PRD / handoff 卡时跑主文“验证流程”，未入矩阵的 API 先真机验证再作为业务信源。

## 跟其他元规则的关系

- [`操作系统/01_架构/角色边界.md`](../../操作系统/01_架构/角色边界.md)：产品 PM / 技术 PM 在 web API 选型时必查本规则。
- [`改动分级.md`](改动分级.md)：未验证 web API 选型属 B 类（依赖判断 + 真机验证，不在 A 类自动做范围）。
- [`已知技术约束.md`](已知技术约束.md)：mount 9KB / JDK 17 等历史约束与本规则同属跨平台陷阱档案。
- [`写PRD.md`](写PRD.md)：议题 P 三态与本规则协同；fallback 不等于“肯定能用”，仍需验证。

## 议题 AR Q4 规则校验扩展候选

PROP-020 路径 D `decision-checkpoint` 的 Q4“我的指令是否符合现有 framework 元规则”候选维度 +1：

- Q4.d：web API 选型必查本文件（PM 自纠 #45 同模式防御）。

该候选来自 RETRO-009 前；当前已由主文验证流程和 decision-checkpoint 人工规则承接，后续如自动化再单独提 PROP。

## 关联

- [`../../确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md`](../../确认改动/已审批/已完成/PROP-022-2026-05-15-navigator矩阵+capacitor-network依赖.md)
- [`../../交接区/历史归档/2026-05/2026-05-14-1455-F-SYSCHECK-1-network-smoke阻塞-Codex到ClaudeCode.md`](../../交接区/历史归档/2026-05/2026-05-14-1455-F-SYSCHECK-1-network-smoke阻塞-Codex到ClaudeCode.md)
- [`../../Docs/7-复盘/RETRO-009-候选议题.md`](../../Docs/7-复盘/RETRO-009-候选议题.md)
- [`../../操作系统/07_完整工作流/decision-checkpoint.md`](../../操作系统/07_完整工作流/decision-checkpoint.md)
