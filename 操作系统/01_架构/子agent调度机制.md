---
name: subagent-dispatch-mechanism
scope: project
type: semantic
loaded: on-demand
description: PM 职责层与子 agent 执行层分离 / 项目 PM 统一调度真实子 agent 的入口规则
---

# 子 agent 调度机制

> 核心原则：**PM 是职责与权限，agent 是一次性执行实例**。  
> 对外身份永远是项目 PM「咪咪」；真实子 agent 由项目 PM统一调度、限定边界、验收结果。

本文件保留高频入口和硬规则。背景解释、完整映射、B-lite 历史和能力资产关系见 [`子agent调度机制-附录.md`](子agent调度机制-附录.md)。

## 一、三层模型

| 层 | 定义 | 谁负责 |
|---|---|---|
| PM 职责层 | 9 PM 抽象角色、路径白名单、决策边界 | `操作系统/02_智能体/` + `角色边界.md` |
| 调度层 | 判断是否开 agent、拆任务、限定路径、验收 | 项目 PM「咪咪」 |
| 执行实例层 | explorer / worker / 其他 runtime 子 agent | 当前 Codex subagent runtime 或未来执行型 agent |

硬规则：
- **生成权（spawn）+ 验收权仍在项目 PM「咪咪」**，各 PM 不自治乱开、不下放 spawn 权。
- **禁嵌套自治派 agent / 验收恒单点**：worker / explorer 不得自己再 spawn 子 agent；需要帮手时回流项目 PM，由项目 PM 派平级 agent 并验收。
- agent 是执行实例，不改变 PM 权责；对外身份仍是项目 PM「咪咪」（ADR-031）。

## 二、默认触发规则

### 默认要开 agent

| 场景 | 推荐 agent | 口径 |
|---|---|---|
| 新增功能 + 多文件实现 | worker | 开发 PM「实施者」实例，限定 `{{APP_REPO_DIR}}/src/` |
| 实现与只读诊断可并行 | worker + explorer | worker 写实现，explorer 查风险或历史模式 |
| 2 个以上独立代码问题 | 多个 explorer | 每个问题自包含，不重复查同一件事 |
| 工作流明写 subagent / 多 agent | 对应 agent | 必须真实派发，不能口头代替 |
| 大范围重构且写集可分离 | 多个 worker | 每个 worker 必须有互斥写入范围 |
| framework 写入（操作系统 PM「框架管家」） | worker | 非单源 framework 文件默认派 worker；单源禁并行文件只起草、主会话落最后一笔 |

### 默认由主会话单点收口

| 场景 | 原因 |
|---|---|
| `commit` / `tag` / `push` / version bump | 发布状态强串行，归测试发布 PM「闭环者」主控 |
| APK / 真机 smoke / `状态.md` / 交接卡收口 | 需要单一事实源，避免多 agent 写乱 |
| 单源禁并行文件写入 | 强串行单 append 点，无 worktree 兜底；agent 只起草，主会话落最后一笔 |
| API key / baseUrl / 用户数据删除 | 敏感边界，不交给子 agent |
| 小型、不可并行、无独立审计价值且下一步立即阻塞的动作 | 主会话自己做，避免等待损耗 |

单源禁并行文件：`状态.md` / `交接区/` / `CHANGELOG.md` / `元规则池.md` / `角色边界.md` / `子agent调度机制.md`。

## 三、framework 写入受控并行（B-lite / PROP-044 approve 2026-06-14）

本节是**多 worker 平级并行**改 framework，不是 worker 嵌套派 agent。仅当全部满足以下条件才可派：

1. **写集大**：≥6 个独立文件，小批量单线程即可。
2. **写集互斥**：每个 worker 有明确、不重叠的写入文件清单，派工卡必填。
3. **主会话单点合并 + 体检 gate**：worker 返回后，项目 PM核对越界并跑 `能力资产/tools/scripts/check-operating-system.ps1`，以当前 P4a-P4s 输出为准。

⛔ 永远单点、禁并行写：`状态.md` · `交接区/` · `CHANGELOG.md` · `元规则池.md` · `角色边界.md` · `子agent调度机制.md`。

## 四、PM 到 agent 的映射速查

- 项目 PM「咪咪」不实例化为子 agent；主会话保留全局调度与验收。
- 写入型 PM 默认 worker；只读诊断型 PM 默认 explorer；测试发布 PM 的发布动作单点不外包。
- 完整 9 PM 映射、典型方式和写入边界见 [`子agent调度机制-附录.md`](子agent调度机制-附录.md)。

## 五、派工卡必填字段

每个子 agent brief 必须自包含：

- 角色与任务目标
- 工作目录、允许读取、允许写入
- 写集互斥声明
- 禁止事项
- 输入材料、完成标准、输出格式

完整模板见 [`子agent调度机制-附录.md`](子agent调度机制-附录.md)。

## 六、主会话验收责任

子 agent 返回后，项目 PM必须：

1. 读取其变更或结论。
2. 核对是否越权。
3. 跑必要测试 / 体检。
4. 由主会话决定接纳、修正或回退。
5. 发布、状态、交接、PM 轨迹由主会话统一收口。
6. 最终 chat ①-⑦ 说明是否真实开过 agent。

## 七、一句话执行口径

> **除项目 PM 主会话外，每个 PM 的实际工作默认实例化为真实 agent（写=worker / 只读=explorer）**；单源禁并行文件 agent **起草**、主会话**落最后一笔**；发布动作单点不外包；**不嵌套自治派 agent（worker 不自己 spawn 子 agent，要帮手回流由项目 PM 派平级）、验收恒单点在项目 PM**；项目 PM「咪咪」持**唯一调度权 + 验收权（spawn 权不下放 / 各 PM 不自治乱开）**，并对调度与结果负责。

## 八、关联

- [`子agent调度机制-附录.md`](子agent调度机制-附录.md) — 背景、完整映射、B-lite 历史、能力资产关系
- [`角色边界.md`](角色边界.md) — 9 PM 路径白名单
- [`工具载体矩阵.md`](工具载体矩阵.md) — PM 角色与工具载体解耦
- [`../02_智能体/README.md`](../02_智能体/README.md) — 9 PM playbook 入口
- [`../07_完整工作流/decision-checkpoint.md`](../07_完整工作流/decision-checkpoint.md) — 切角色 Q1-Q7（含 agent 实例化判定）
- [`../../能力资产/agents/README.md`](../../能力资产/agents/README.md) — 可复用执行型 agent 资产目录
