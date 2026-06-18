---
name: capability-assets-index
scope: project
type: semantic
loaded: on-demand
description: 能力资产层总入口（执行能力 / 用什么做）— rules + shared + mcp + skills + agents + workflows + tools 总索引
---

# 能力资产 · 总入口（PROP-029 v2 落地 / 2026-05-21）

> **🎯 这是{{PROJECT_NAME}}项目的能力资产层**。执行能力 — 用什么做。
> **操作系统**在 `{{PROJECT_ROOT}}\操作系统\` — 怎么协作。

---

## 一、7 子目录导航

| 目录 | 内容 |
|---|---|
| `rules/` | 执行硬规则（git 编码 / web-api 信源 / 改动分级 / 安全隐私 / 已知技术约束 / 视觉设计规范 等；文件数以目录真值为准）|
| `shared/` | 业务能力（品牌词典 / 咪咪人设统一基准 / 跨分支协作机制）|
| `mcp/` | MCP 矩阵清单 |
| `tools/` | 构建脚本 + 依赖矩阵 + scripts/ 真可执行 + hooks/ 自动化入口 |
| `skills/` | 工具能力 / 脚本（出 APK / 状态推断 / 项目体检 / 跑测试 等）|
| `agents/` | 执行型 agent（当前空 / 未来扩 — 区别于操作系统/02_智能体/ PM 子角色）|
| `workflows/` | 执行型 workflow（当前空 / 未来扩 — 区别于操作系统/07_完整工作流/ 协作流）|

## 二、起手必读（按需）

- **写 PRD** → `rules/写PRD.md`
- **写代码** → `rules/写代码.md`
- **品牌词典 / 咪咪人设** → `shared/品牌词典.md` + `shared/咪咪人设统一基准.md`
- **构建打包** → `tools/构建脚本.md`
- **跑测试** → `skills/跑测试.md`
- **出 APK** → `skills/出APK.md`
- **项目体检** → `skills/项目体检.md`

## 三、操作系统 vs 能力资产（拆分逻辑）

```
操作系统/         (怎么协作 / 运行控制层)
└── 角色 / 状态 / 交接 / 记忆 / 台账 / 工作流 / 工具治理

能力资产/         (用什么做 / 执行能力层 / 本目录)
└── rules / shared / mcp / tools / skills / agents / workflows
```

## 四、维护 SOP

- **何时同步**：新 MCP / 新 skill / 依赖升级时
- **维护责任**：操作系统 PM「框架管家」+ 接 PR 的角色
- **路径白名单**：`能力资产/` 由操作系统 PM「框架管家」负责路径治理；`shared/` 的业务内容可由产品 / 运营 / 项目 PM 起草建议，经项目 PM 验收后由白名单允许的 PM 合规落笔，不直接扩大产品 PM 写权限

## 五、版本

- **v1**（2026-05-21 / PROP-029 v2 落地）— 从 `agent/` 物理拆分对齐 yuanxing 能力资产/ 模式
