---
name: subagent-dispatch-mechanism-appendix
scope: project
type: semantic
loaded: on-demand
description: 子 agent 调度机制附录 — 背景解释 / 完整 PM 映射 / B-lite 历史 / 能力资产关系
---

# 子 agent 调度机制附录

> 主入口：[`子agent调度机制.md`](子agent调度机制.md)。本文件承接低频解释，避免主入口过大。

## 一、为什么要有本机制

v4.0 已把 9 PM 定义为抽象协作角色，但实战中出现过两个偏差：

1. 把“角色切换”误当成“多 agent 协作”。
2. 新增功能明明适合并行实施，却被主会话单线程包办。

本机制补上中间层：PM 角色仍是抽象职责；真实 agent 只是该职责下的临时执行实例。

## 二、禁嵌套与验收恒单点

被派出的 worker / explorer 不得自己再 spawn 子 agent。worker 需要帮手时，必须回流向项目 PM申请，由项目 PM派平级 agent 并验收。

理由：

1. 单点验收是护栏，保护 ADR-031 项目 PM单点收口。
2. 嵌套会让“父 worker 的一线验收”无人监督，稀释验收质量。
3. 当前项目规模不需要嵌套；需要并行时走 B-lite，由项目 PM派多个平级 worker。

B-lite 多 worker 并行是项目 PM派多个平级 worker，写集互斥、同时跑、主会话单点合并；它与 agent 再派 agent 的嵌套不同。

## 三、B-lite 历史与边界

PROP-044 approve 后，framework 写入分两种形态：

| 形态 | 口径 |
|---|---|
| 单 agent 写非单源 framework 文件 | 默认允许，worker 写入或起草，主会话验收 |
| 多 worker 并行改 framework | 仅限写集大、写集互斥、主会话合并 + 体检 gate |

为什么不是 B-full 完全自治：

- 项目根不是 git 仓库，worktree 隔离对 framework 不适用。
- `状态.md`、`交接区/`、`CHANGELOG.md`、`元规则池.md`、`角色边界.md` 都是单 append 点或宪法级文件。
- 多 agent 自治会稀释 ADR-031 单点对外身份。

## 四、PM 到 agent 的完整映射

| PM | 默认实例化 | 典型方式 | 写入边界 |
|---|---:|---|---|
| 项目 PM「咪咪」 | 不实例化（调度者本身 / 主会话） | 全局调度、拆任务、限边界、验收 | 全局调度，不直接乱动手 |
| 沉淀 PM「沉淀者」 | 查证派 explorer / 写工作区派 worker | 查历史/元规则/复盘证据派 explorer；写 `PM工作区/沉淀PM-沉淀者/` 派 worker | 可写 `PM工作区/沉淀PM-沉淀者/`；单源（元规则池）仅起草、主会话落最后一笔 |
| 操作系统 PM「框架管家」 | 默认派真实 worker 做 framework 写入 + 主会话验收/合并 | 查 hooks/framework 风险派 explorer；改非单源 framework 文件派 worker | 可写非单源 framework 文件；单源禁并行文件仅起草、主会话落最后一笔 |
| 产品 PM「需求拆解者」 | 写 PRD 派 worker / 查证派 explorer | 写 PRD（`Docs/1-需求文档/`）派 worker；查需求/历史 AC/竞品上下文派 explorer | 可写 `Docs/1-需求文档/` |
| 技术 PM「修复决策者」 | 默认派 explorer（只读根因诊断） | 根因定位、调用链梳理 | 只读 |
| 测试 PM「质量门户」 | 默认派 explorer（只读验收策略） | 验收策略、回归面设计 | 只读 |
| 运营 PM「运营咪咪」 | 写 GTM 派 worker / 调研派 explorer | 写 GTM（`PM工作区/运营PM-运营咪咪/`）派 worker；素材盘点/内容方向调研派 explorer | 可写 `PM工作区/运营PM-运营咪咪/`；不动 `{{APP_REPO_DIR}}/**` / framework |
| 开发 PM「实施者」 | 默认派 worker | 业务代码 + 测试代码实施 | `{{APP_REPO_DIR}}/src/` |
| 测试发布 PM「闭环者」 | 发布动作单点不外包 | 发布验证主控；可派只读风险复核 explorer | 发布动作（commit/push/version/APK/smoke）单点不外包 |

## 五、派工卡完整模板

```md
你扮演：<PM / agent 类型>
任务目标：<一句话结果>
工作目录：{{PROJECT_ROOT}}
允许读取：<路径>
允许写入：<路径或“无”>
写集互斥声明：<本 worker 独占文件清单 / 与其他 worker 0 重叠；无并行则填“无并行”>
禁止事项：不得 commit / push / bump version / 改 状态.md / 改 交接区 / 改 CHANGELOG / 改 元规则池 / 改 角色边界 / 改 brief 未列明文件 / 触碰敏感数据
输入材料：<PRD / 交接卡 / 文件路径 / 测试命令>
完成标准：<可验证结果>
输出格式：changed files / 验证结果 / 风险 / 需要主会话处理的事项
```

## 六、与能力资产/agents 的关系

- 当前 Codex runtime 支持临时 `spawn_agent`。
- `能力资产/agents/` 是可复用执行型 agent 资产目录。
- 只有当某类 agent 任务高频、单功能、可标准化时，才沉淀为固定资产。
- 临时子 agent 不是 PM 本体，也不自动成为 `能力资产/agents/` 资产。

## 七、历史固化

- 2026-06-13：新增子 agent 调度机制，明确 PM 职责层与 agent 执行层分离。
- 2026-06-14：PROP-044 approve B-lite，framework 写入可在受控条件下派平级 worker。
- 2026-06-14：9 PM 全量 agent 化拍板，除项目 PM 主会话外，每个 PM 的实际工作默认实例化为真实 agent。
- 2026-06-14：固化禁嵌套自治派 agent，验收恒单点在项目 PM。
- 2026-06-14：ADR-038 永久化 PM 实体化 agent 调度模型。
