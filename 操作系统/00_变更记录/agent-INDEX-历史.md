---
name: agent-index-history
scope: project
type: episodic
loaded: on-demand
description: 历史档案 — 旧 agent/ 目录时代的 AI 协作中心 INDEX（已被现行操作系统结构替代）
---

> ⚠️ **历史安全边界**：正文只作追溯，不代表当前执行流程，不可直接复制执行；涉及旧路径、旧命令、API key 或交接格式时，回到现行 `操作系统/` + `能力资产/` 真源重判。
> 历史快照：本文保留旧 `agent/` 时代 INDEX 原貌，文内“当前活的导航路径”等表述指 2026-05 当时，不代表现行入口。配套旧 README 见 [`agent-README-历史.md`](agent-README-历史.md)。
> 原文冻结：下方链接为旧路径样本；当前入口见 [`../00_总入口.md`](../00_总入口.md)。

# Agent INDEX — 历史快照

🚨 **新会话第一动作**（顺序，全部必做 — PROP-011 升级）：
1. **读本文件**（30 秒）
2. **读 项目根 [`状态.md`](../状态.md)** — 看摘要 + 进度速查 + 链接
3. ⭐ **读 [`交接区/待接手/`](../交接区/待接手/) 最新文件** — 完整 6 段交接卡（PROP-011 引入）
4. **跑 [skills/状态推断.md](skills/状态推断.md) 7 项推断** — 看代码 / APK / 文档 / 交接区是否对齐
5. **如果 stale 警告 → 主动跑项目体检** [skills/项目体检.md](skills/项目体检.md) 复检

📌 **每次会话开始读这一份**（< 30 秒）。
所有 AI 协作相关内容（角色 / 技能 / 流程 / 规则 / 配置）**全部在 `agent/` 下**——这是唯一维护点。

> 改任何 AI 协作内容只动 `agent/` 下对应文件即可。`Docs/` 只放业务/技术文档；`{{APP_REPO_DIR}}/` 只放代码；`确认改动/` 只放 PROP 档案。

---

## 🎯 任务 → 该读哪些

| 我要做的事 | 必读 |
|---|---|
| **任何改动开工前** | [agents/AI边界.md](agents/AI边界.md) + [rules/改动分级.md](rules/改动分级.md) |
| **接到新需求** | [workflows/需求接收.md](workflows/需求接收.md) + [agents/PM-产品经理.md](agents/PM-产品经理.md) |
| **写 PRD / PROP** | [rules/写PRD.md](rules/写PRD.md) |
| **zlbdh 审批 / 拒绝 PROP** | [workflows/审批与归档.md](workflows/审批与归档.md) |
| **新 PROP / ADR / RETRO 编号** | [workflows/审批与归档.md](workflows/审批与归档.md) §C |
| **写代码** | [rules/写代码.md](rules/写代码.md) + [rules/已知技术约束.md](rules/已知技术约束.md) + [agents/Dev-开发.md](agents/Dev-开发.md) |
| **选 web API（navigator.* / Intl.* / window.*）作信源** | ⭐ [rules/web-api-信源选型.md](rules/web-api-信源选型.md) — 议题 AT 矩阵 + 真机验证流程 |
| **改 UI 视觉** | [rules/视觉设计规范.md](rules/视觉设计规范.md) |
| **跑测试** | [skills/跑测试.md](skills/跑测试.md) + [agents/QA-测试.md](agents/QA-测试.md) |
| **出 APK** | [skills/出APK.md](skills/出APK.md) |
| **发布版本** | [workflows/发布流程.md](workflows/发布流程.md) |
| **任何改动收尾** | [workflows/实施循环.md](workflows/实施循环.md) 末尾 DoD 段 |
| **跑项目体检（每次 PROP 收档前必跑）** | [skills/项目体检.md](skills/项目体检.md) |
| ⭐ **session 起手 / 进度对账** | [skills/状态推断.md](skills/状态推断.md) |
| ⭐ **跨工具协作 / 交接卡** | [workflows/交接卡格式.md](workflows/交接卡格式.md) + [`../交接区/README.md`](../交接区/README.md) |
| **碰隐私 / API key** | [rules/安全与隐私.md](rules/安全与隐私.md) |
| **提交 git** | [workflows/git流程.md](workflows/git流程.md) |
| **跑 MCP** | [mcp/README.md](mcp/README.md) |

---

## 📚 5 大语义分组

| 分组 | 装什么 | 命名根据 |
|---|---|---|
| [agents/](agents/README.md) | AI 角色 playbook + 边界 | "**谁**在做" |
| [skills/](skills/README.md) | 单一能力的操作脚本 | "知道**怎么做**这件事" |
| [workflows/](workflows/README.md) | 多步骤有序流程 | "按**什么顺序**做" |
| [rules/](rules/README.md) | 真规则（约束 / 标准 / 判断框架） | "**应该怎样**" |
| [mcp/](mcp/README.md) | MCP 服务器配置 | 配置 |

---

## 🗂 速查每分组当前文件

```
agent/
├── INDEX.md（本文件）
├── README.md
├── agents/
│   ├── AI边界.md          A自动 / B必ask / C永不能动
│   ├── PM-产品经理.md      PRD / 需求评估
│   ├── Dev-开发.md         按文件改 / 数据流约束
│   └── QA-测试.md          3 层验证 / smoke
├── skills/
│   ├── 出APK.md            打包 dev APK
│   └── 跑测试.md           vitest + esbuild + vite build
├── workflows/
│   ├── 改动分级.md 之外的流程 — 见 rules/
│   ├── 实施循环.md         需求→代码→测试→APK→收尾 + DoD
│   ├── 审批与归档.md       PROP 状态机 + 编号查询
│   ├── 需求接收.md         接到新需求 7 步
│   ├── 发布流程.md         编译 / 测试 / 上传 / CHANGELOG
│   └── git流程.md          提交规范（占位）
├── rules/
│   ├── 改动分级.md         L1-L4 判等级 + 测试问题分诊
│   ├── 写代码.md           命名 / 文件大小 / 状态管理
│   ├── 已知技术约束.md     mount 9KB / JDK 17 / window.storage 等 10 项
│   ├── 写PRD.md            业务语言原则
│   ├── 视觉设计规范.md     咪咪文人风
│   └── 安全与隐私.md       隐私 / API key（占位）
└── mcp/
    └── README.md           MCP 配置（待补）
```

---

## 重命名说明（2026-05-09 PROP-004）

⚠️ 项目 2026-05-08 曾叫 `rules/`（按 ADR-003 决策建立），但用户审视后发现「rules」承担了 skills/workflows/agents 多重语义。

2026-05-09 PROP-004 / ADR-007 把 `rules/` 重构为 `agent/`，按语义分 5 类。
ADR-003 标「被 ADR-007 部分替代」，不删——历史决策档案保留时间戳。

历史 PROP/RETRO/ADR 内文中的 `rules/...` 链接是写下时刻的快照，不再活；当前活的导航路径全部从 `agent/` 出发。

> 归档注：此处“当前”指 2026-05 当时口径；现行入口已演进为 `操作系统/` + `能力资产/`。
