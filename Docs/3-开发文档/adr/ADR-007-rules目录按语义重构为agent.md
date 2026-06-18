# ADR-007 · `rules/` → `agent/` 按语义重构（agents/skills/workflows/rules/mcp 5 类）

- **状态**：历史结构决策；当前由 `操作系统/` + `能力资产/` 覆盖
- **日期**：2026-05-09
- **决策人**：zlbdh
- **关联**：[PROP-004](../../../确认改动/已审批/已完成/PROP-004-2026-05-09-rules目录按语义重构.md) · **替代 [ADR-003](ADR-003-Agent整合到rules.md) 部分决策**

> ⚠️ **当前覆盖说明（2026-06-15）**：ADR-007 是 `rules/` 语义拆分的历史决策。当前活结构已进一步演进为 `操作系统/` + `能力资产/`，入口见 [`操作系统/00_总入口.md`](../../../操作系统/00_总入口.md)。本文中的 `agent/` 目录树保留为当时演化证据，`rm -rf rules/` 等命令不可直接复制执行；任何删除/移动仍按三类行为铁律重判。

## 背景

2026-05-08 ADR-003 把多处分散的 AI 协作内容（`Agent/agents/`、`Agent/skills/`、`Agent/workflows/`、`Docs/2-产品文档/视觉设计规范.md`、`Docs/3-开发文档/已知技术约束.md` 等）整合进顶层 `rules/` 目录，下面分 9 个分组（ai/process/code/docs/visual/operation/mcp/git/security）。

ADR-003 的核心动机是「**单一维护点**」——改规则只改 `rules/` 即可，不用跨 5 处。这个目标当时实现了。

但 2026-05-09 zlbdh 在审视项目结构时发问：「**为什么没有 agents/skills/workflows 这些目录？rules 不是只放约束、规则之类的东西嘛？skills 又不是约束、规则之类的东西。**」

——指出了真问题：**目录名 `rules/` 跟内容性质不匹配**。盘点后发现：

| 在 `rules/` 下 | 实际内容性质 | 真的是规则？ |
|---|---|---|
| `ai/AI边界.md` | 行为约束 | ✅ |
| `ai/PM-产品经理.md` / `Dev-开发.md` / `QA-测试.md` | 角色 playbook | ❌ 是 **agent** |
| `process/改动分级.md` | 判等级标准 | ✅ |
| `process/实施循环.md` / `审批与归档.md` / `需求接收.md` | 多步骤流程 | ❌ 是 **workflow** |
| `code/写代码.md` / `已知技术约束.md` | 编码约束 | ✅ |
| `docs/写PRD.md` / `visual/视觉设计规范.md` | 规范 | ✅ |
| `operation/出APK.md` / `跑测试.md` | 操作脚本 | ❌ 是 **skill** |
| `operation/发布流程.md` | 多步骤流程 | ❌ 是 **workflow** |
| `mcp/` | 配置 | ❌ 是 **config** |

约一半内容**不是规则**。半年后任何人（包括 zlbdh 自己）打开 `rules/operation/出APK.md` 都会困惑：「为什么 APK 打包脚本叫 rule？」

## 决策

按 5 大语义类重构 `rules/` 为 `agent/`：

```
agent/                       ← AI 协作中心（顶层）
├── INDEX.md                  任务 → 该读哪些
├── agents/                  AI 角色 playbook + 边界
├── skills/                  单一能力操作脚本（"会做这件事"）
├── workflows/               多步骤流程（"按什么顺序做"）
├── rules/                   真规则（"应该怎样" — 约束 / 标准 / 判断框架）
└── mcp/                     MCP 服务器配置
```

**5 大语义边界**：
- **agents/** — 谁在做（角色身份）
- **skills/** — 单一能力，会做某事（含步骤但不串多个能力）
- **workflows/** — 多步骤有序串联（跨 skill / 跨角色）
- **rules/** — 描述「应该怎样」的判断标准 / 约束
- **mcp/** — 配置

## 替代关系

ADR-003「Agent → 单一维护点」的**核心决策仍然成立**——`agent/` 仍是 AI 协作内容的唯一维护点。

被替代的部分是 ADR-003 中**目录命名为 `rules/`** 这一具体选择。ADR-007 把命名换成更准确的 `agent/`，并按语义子分。

ADR-003 状态字段已更新为「被 ADR-007 部分替代」，文档保留不动作为时间戳；当前活结构以 `操作系统/00_总入口.md` 和 `能力资产/` 为准。

## 实施细节（PROP-004 阶段 1-7）

### 阶段 1 — 准备
- 跑 ls 查最大编号（按 `agent/workflows/审批与归档.md` §C）→ PROP-004 / ADR-007 ✓
- 全面 grep 影响面：{{APP_REPO_DIR}}/ 代码 0 引用 ✓ / build-apk.bat 0 ✓ / GitHub Actions 0 ✓
- 建 ADR-007 占位文件（防撞号）
- 通知 Claude Code 暂停 F-001 实施

### 阶段 2 — mkdir + 批量 mv
- `mkdir -p agent/{agents,skills,workflows,rules,mcp}`
- 15 个内容文件按语义 mv：
  - `rules/ai/{AI边界,PM-产品经理,Dev-开发,QA-测试}.md` → `agent/agents/`
  - `rules/operation/{出APK,跑测试}.md` → `agent/skills/`
  - `rules/operation/发布流程.md` → `agent/workflows/`（语义判定为多步骤流程）
  - `rules/process/{实施循环,审批与归档,需求接收}.md` → `agent/workflows/`
  - `rules/process/改动分级.md` → `agent/rules/`（zlbdh 拍板：判等级是规则不是流程）
  - `rules/{code,docs,visual}/*.md` → `agent/rules/`
- `rm -rf rules/`（含全部旧 README + INDEX）

### 阶段 3 — 写新版导航
- `agent/INDEX.md`（任务 → 该读哪些 14 项映射 + 5 大分组速查 + 历史命名说明）
- `agent/README.md`（5 大分组介绍 + 跟其他顶层目录边界）
- 5 个新分组 README（agents/skills/workflows/rules/mcp）
- 2 个占位实质文件（按 zlbdh 拍板方案 ②B）：
  - `agent/workflows/git流程.md`（占位）
  - `agent/rules/安全与隐私.md`（占位）

### 阶段 4 — 全局路径更新
更新活文档（按 zlbdh 拍板方案 ③C，历史档案不动）：
- `README.md`（项目根，4 段引用 + 文件树 5 分组）
- `Docs/3-开发文档/项目结构.md`（含 Windows 反斜杠 + 关键约定段）
- `Docs/3-开发文档/adr/README.md`（ADR 索引表加 ADR-005/006/007 + ADR-003 标「被替代」）
- `Docs/7-复盘/README.md` + `_模板.md`
- `确认改动/README.md` + `_模板.md`
- `agent/rules/写代码.md` + `agent/workflows/需求接收.md`（agent/ 内部 2 处 ai/ 旧引用）

历史档案保留不动（只在 ADR-003 顶部加「被 ADR-007 部分替代」注释）：
- ADR-001 / ADR-002 / ADR-006
- RETRO-001 / RETRO-002
- PROP-001 / PROP-002 / PROP-003

### 阶段 5 — 本 ADR
（即本文件）

### 阶段 6 — DoD 验证
- vitest 全过（不受文档重构影响）
- vite build 不受影响
- {{APP_REPO_DIR}}/ 代码无 rules/ 引用 ✓
- 活文档无独立 rules/ 顶层引用 ✓
- 仅 adr/README.md 一行描述 ADR-003 历史时保留 "rules/" 字面（合理）

### 阶段 7 — PROP-004 收档
- PROP-004 状态字段 → 已审批 · 已完成（2026-05-09，对应 ADR-007）
- mv `已审批/进行中/PROP-004` → `已审批/已完成/`
- 更新 `确认改动/README.md` 计数（进行中 -1 / 已完成 +1）

## 后果

### 收益
- ✅ **目录名跟内容性质对齐**：半年后看 `agent/skills/出APK.md` 一眼明白；不再有 `rules/operation/出APK.md` 这种语义错位
- ✅ **业内通用术语**：跟 Cowork / Claude Code 默认 `.claude/skills/` `.claude/agents/` 概念对齐
- ✅ **维护单点没破**：仍是一个 `agent/` 顶层目录，「改 AI 协作约定只动这一处」原则保留
- ✅ **新建文件不再纠结放哪儿**：5 大语义类清晰，先按性质判定再放对应分组
- ✅ **Mount 安全**：所有新文件 < 5.4KB，远在 mount 8KB 实测下限内

### 代价
- ❌ 一次跨 30+ 文件的全局路径更新（已完成）
- ❌ ADR-003 部分决策被替代（但这是 ADR 机制的正常用法 — 决策记录允许被后续 ADR 演进）
- ❌ 历史 PROP/RETRO/ADR **内文中** `rules/...` 链接变历史快照（按 zlbdh 拍板方案 ③C 不动 — 它们就是「写下时刻」的快照，保留时间戳价值）
- ✅ **例外**：头部加「被 ADR-XXX 部分替代」注释合规（这是指明当前状态，不算改历史决策本身）

### 风险已防
- {{APP_REPO_DIR}}/ 代码无 rules/ 引用，重构不影响代码 ✓
- build-apk.bat / GitHub Actions 无 rules/ 引用 ✓
- mount 8KB 截断风险：全部新文件 < 6KB ✓
- 占位升级（git流程 / 安全与隐私）不留空目录 ✓

## 命名复盘

ADR-003 当时的取舍是「**单一维护点 vs 语义清晰**」二选一——选了维护点，牺牲了语义。
ADR-007 的取舍是「**两个都要**」——通过子目录细分实现。

教训：「单一维护点」不等于「单一目录名」——可以一个顶层 + 多个语义子分。下次类似决策应同时考虑两个维度。

## 后续可能的演进

- **mcp/ 待补**：当前只有 README 占位，等 zlbdh 决定记 MCP 配置时填实
- **git流程.md / 安全与隐私.md 待补**：占位中，等真要写规范时填实
- **可能会再分**：如果哪天 `agents/` 或 `workflows/` 文件超 10 个，可能要再分子组（但目前 4-5 个文件每组，结构合理）

## 这是项目第几个 L3+

| # | 改动 | 等级 | ADR | RETRO 触发 |
|---|---|---|---|---|
| 1 | F-205 ErrorBoundary | L3 | — | — |
| 2 | PROP-001 大文件拆分 | L3 | ADR-004 | RETRO-001 已写 |
| 3 | PROP-003 导航重构 | L3 | ADR-006 | RETRO-002 已写 |
| 4 | **PROP-004 rules→agent**（本 ADR）| **L4** | **ADR-007** | 计入 RETRO-003 |
| 5 | (下一个) | | | |
| 6 | (下一个) | | | RETRO-003 触发条件（每 3 个 L3+） |

按节奏 RETRO-003 在第 6 个 L3+ 完成时写。
