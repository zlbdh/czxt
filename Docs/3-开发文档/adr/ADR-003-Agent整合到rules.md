# ADR-003 · Agent/ 整合到 rules/，rules/ 成为项目规则唯一维护点

> ⚠️ **2026-05-09 状态更新 — 被 [ADR-007](ADR-007-rules目录按语义重构为agent.md) 部分替代**
> 「Agent → 单一维护点」的核心决策仍然成立，但 `rules/` 这个目录名承担了 skills/workflows/agents 多重语义。
> ADR-007 把 `rules/` 重构为 `agent/`，按语义分 5 类（agents/skills/workflows/rules/mcp）。
> 本 ADR 历史决策保留不动，作为时间戳；当前活的目录结构以 ADR-007 为准。
> **当前安全覆盖说明（2026-06-15）**：本文中的 `rules/` / `Agent/` 路径和 `rm -rf Agent/` 等命令只作历史证据，不可直接复制执行；现行结构以 `操作系统/` + `能力资产/` 为准，任何删除/移动仍按三类行为铁律重判。

- **状态**：被 ADR-007 部分替代（2026-05-09）
- **日期**：2026-05-08
- **决策人**：zlbdh
- **关联**：紧随 ADR-002（{{APP_REPO_DIR}}/ 迁移）之后的同日 L4 重构；2026-05-09 被 ADR-007 部分替代

## 背景

2026-05-08 我们刚完成 ADR-002（代码迁移到 `{{APP_REPO_DIR}}/`）和 6 项规范增量补齐（rules/ 作为指路牌层）。但 zlbdh 提出："后续的有关规则/约束之类的东西是不是都在这个文件夹下并在这个文件夹下维护？"

——**指路牌模式跟"在 rules/ 维护"不一致**。指路牌模式下：
- 规则内容仍在 `Agent/workflows/`、`Agent/skills/`、`Agent/agents/`、`Docs/2-产品文档/视觉设计规范.md`、`Docs/3-开发文档/已知技术约束.md` 等多处
- rules/ 只是导航
- "改规则" 仍然要跑去原文件改，rules/ README 不动
- 维护点散落

候选方案：

| 选项 | 描述 | 评估 |
|---|---|---|
| A | 维持指路牌模式 | 跟 zlbdh 期望不一致 |
| B | **整合：所有规则内容搬进 rules/，废弃 Agent/** | ✅ 选这个 |
| C | 折中：只搬"硬约束"，Agent/ 保留 | 仍是双中心 |

zlbdh 选 B。

## 决定

将 `Agent/` 全部内容**整体迁入** `rules/`，同时把 `Docs/` 下规则性内容也搬过来：

| 原位置 | 新位置 |
|---|---|
| `Agent/workflows/AI边界.md` | `rules/ai/AI边界.md` |
| `Agent/workflows/改动分级.md` | `rules/process/改动分级.md` |
| `Agent/workflows/实施循环.md` | `rules/process/实施循环.md` |
| `Agent/workflows/需求接收.md` | `rules/process/需求接收.md` |
| `Agent/workflows/发布流程.md` | `rules/operation/发布流程.md` |
| `Agent/skills/写PRD.md` | `rules/docs/写PRD.md` |
| `Agent/skills/写代码.md` | `rules/code/写代码.md` |
| `Agent/skills/出APK.md` | `rules/operation/出APK.md` |
| `Agent/skills/跑测试.md` | `rules/operation/跑测试.md` |
| `Agent/agents/PM-产品经理.md` | `rules/ai/PM-产品经理.md` |
| `Agent/agents/Dev-开发.md` | `rules/ai/Dev-开发.md` |
| `Agent/agents/QA-测试.md` | `rules/ai/QA-测试.md` |
| `Agent/mcp/README.md` | `rules/mcp/README.md` |
| `Docs/2-产品文档/视觉设计规范.md` | `rules/visual/视觉设计规范.md` |
| `Docs/3-开发文档/已知技术约束.md` | `rules/code/已知技术约束.md` |
| `Agent/README.md` | 删（由 `rules/INDEX.md` 替代） |

`Agent/` 整个目录删除。顶层目录从 7 项减到 6 项。

## 后果

### 好处
- **唯一维护点**：改规则只改 `rules/` 下，不再分散
- 顶层目录从 7 项减到 6 项（更清爽）
- 规则与"业务/技术文档"语义彻底分离：
  - rules/ = 项目所有约束 + 流程 + AI 行为 + 角色 playbook
  - Docs/ = 产品/技术/测试/运维/历史/复盘 文档
- 可以作为模板**复制到其他项目**：直接 `cp -r rules/ 新项目/` 起步

### 代价
- 一次性更新约 11 处文档的路径引用（README / 项目结构.md / RETRO / ADR-002 / PROPOSAL / 等）
- mv 后所有人提到「Agent/...」的引用都要改成「rules/...」对应路径
- 原"Agent/" 目录名带"AI 自动化资源"含义，rules/ 名称偏"规则"，语义略缩窄；不过实质上 rules 接管所有原 Agent 职责 + 新加的视觉/已知约束/index 等

### 后续如果反悔了
- **触发条件**：rules/ 这层让查规则反而更难（不太可能）
- **撤销路径**：`mv rules/* Agent/`（按反向映射）+ 还原视觉/已知技术约束到 Docs/ 各处 + 反向更新 11 处引用
- **预估翻案成本**：1.5-2 小时

---

## 执行细节（2026-05-08）

- 新建 8 个 rules/ 子目录（ai / process / code / docs / visual / operation / mcp / git / security）
- 用 `mv` 一次性移动 15 个文件到 rules/ 对应位置
- 删除 6 个 `_old-pointer-README.md`（之前指路牌模式留下的）
- `rm -rf Agent/`
- Python 批量替换 11 个文件的路径引用（`Agent/...` → `rules/...`）
- 修复 2 处过度替换（README 项目结构图、INDEX.md 第 6 行）
- 写 ADR-003（本文）
- 同步更新 `Docs/3-开发文档/项目结构.md` 项目结构图
- 更新 Cowork memory 反映新结构

## 备注

- 留 `git/` 和 `security/` 两个分组占位，将来需要时再补具体规则
- `mcp/README.md` 是从 Agent/mcp/ 搬过来的，内容暂未更新（项目目前未启用任何外部 MCP）
- `Docs/3-开发文档/adr/` 仍在原位（ADR 是历史决策记录，不属于规则范畴，留 Docs 合理）
- `Docs/7-复盘/` 也保留（RETRO 是反思笔记，不是规则）
