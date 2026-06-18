---
name: rules-index
scope: project
type: semantic
loaded: on-demand
description: 能力资产/rules/ 真规则索引 — 写代码 + 改动分级 + 已知技术约束 + 议题防御规则
---

# 能力资产/rules/ — 真规则

⭐ **写代码前必读 [写代码.md](写代码.md) + [已知技术约束.md](已知技术约束.md)；任何改动开工前必读 [改动分级.md](改动分级.md)**

## 这一组讲什么

真正的「规则 / 约束 / 标准 / 判断框架」—— 描述「应该怎样」，不描述「按什么顺序做」。

按顺序做的属于 `workflows/`；具体能力的脚本属于 `skills/`；角色行为属于 `操作系统/02_智能体/`；可复用执行型 agent 资产才属于 `能力资产/agents/`。

## 文件清单

| 文件 | 一句话 |
|---|---|
| ⭐ [改动分级.md](改动分级.md) | L1-L4 判等级 + 测试问题分诊 + 决策树 |
| [改动分级-扩展规则.md](改动分级-扩展规则.md) | L1-L4 在 framework / Docs / 交接区等路径上的扩展判定 |
| ⭐ [写代码.md](写代码.md) | 命名 / 文件大小 / 状态管理 / 数据流 / 错误处理 / AI 调用 |
| ⭐ [已知技术约束.md](已知技术约束.md) + [附录](已知技术约束-附录.md) | 12 项约束速查（mount / 沙箱 / JDK 17 / storage / npm.ps1 / PS5.1 stderr 等） |
| [写PRD.md](写PRD.md) | 业务语言原则 / 编号规则 |
| [F编号规则.md](F编号规则.md) | F-XXX 命名空间 / 数字段约定 / 编号查询 |
| [视觉设计规范.md](视觉设计规范.md) | 咪咪文人风（配色 / 字号 / 动画 / 交互） |
| [安全与隐私.md](安全与隐私.md) | 当前有效隐私 / API key / 本地数据默认动作 |
| [codex-push后防御.md](codex-push后防御.md) | Codex push 后 git 状态 / mount stale 防御 |
| [git-commit-编码规范.md](git-commit-编码规范.md) | 中文 commit message / `git commit -F` / 编码防 BOM 规范 |
| ⭐ [web-api-信源选型.md](web-api-信源选型.md) + [矩阵](web-api-信源矩阵.md) + [附录](web-api-信源选型-附录.md) | navigator.* / Intl.* / window.* API 在 Android WebView 的选型流程、可靠性矩阵与反例说明 |

## 跟其他分组的区别

- **rules/**：判断标准 / 约束（"应该怎样"）
- **操作系统/02_智能体/**：角色身份（"谁在做"）；**能力资产/agents/** 只放可复用执行型 agent 资产
- **skills/**：单一能力（"会做这件事"）
- **workflows/**：多步骤流程（"按什么顺序做"）

## 速记 — 4 级判等级

| 等级 | 例子 | 流程 |
|---|---|---|
| L1 | 文案 / 单点小修 | 直接改 + CHANGELOG |
| L2 | 行为微调 / 单点 bug | 改对应 DEV 文档 + 代码 + 测试 + CHANGELOG |
| L3 | 新功能 | PM (PRD) → Dev → QA → APK → smoke |
| L4 | 架构 / schema 变化 | L3 全套 + 写 ADR |

判等级有疑问 → 默认升一级，不要降级。

## 速记 — 文件大小规则（按工具分层）

| 工具 | 软建议 | 行为 |
|---|---|---|
| Cowork（mount 截断风险）| 6500B | >6500B 改大文件用 Python/Bash 写入，绕 Edit；项目体检告警但不强制拆 |
| Claude Code / Codex | 8KB | 无硬限制；>8KB 按单一职责工程审美建议拆 |
| 所有工具共同 | 决策前核真实字节 | 关键判断信 `check-operating-system.ps1` / Read 复核，不信单独 mount `wc -c` |

详见 [写代码.md](写代码.md) 文件大小规则与 `已知技术约束.md` §1。
