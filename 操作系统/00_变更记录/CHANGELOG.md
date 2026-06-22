---
name: changelog
scope: project
type: episodic
loaded: on-demand
description: 开发操作系统（framework + 元规则）改动的轻量时间线日志 — PROP/ADR/RETRO 的补充，按时间倒序追加
---

# 操作系统演进日志（CHANGELOG）

按时间倒序记录**开发操作系统**改动。

⚠️ **业务代码**改动走 `{{APP_REPO_DIR}}/` git history，**不进本文件**。
⚠️ **本文件是 PROP/ADR/RETRO 的轻量补充**，不替代主档案；事件追加一行便于浏览。
⚠️ **历史已归档**：2026-06-16 及更早条目见 `CHANGELOG-2026-06-16-较早条目.md`、`CHANGELOG-2026-06-15-较早条目.md`、`CHANGELOG-2026-05-21至06-14-较早条目.md`、`CHANGELOG-2026H1.md`。

> 引入由 PROP-017 / ADR-021 — 学姐妹项目「账号管理 / srm 服务器管理」的「改进日志」机制。

---

## 跟 PROP / ADR / RETRO 的分工

| 改动类型 | 主档案 | CHANGELOG 追加？ |
|---|---|---|
| 重大架构决策 / 元规则演进（L4）| PROP + ADR | ✅ 追加一行索引 |
| Sprint 复盘 | RETRO | ✅ 追加一行索引 |
| 中等改动（L3）| PROP | ✅ 追加一行索引 |
| **小动作 / L1-L2 / 顺手活** | **本文件主记** | ✅ 滚动近况可单行压缩；复杂项用 4 行格式 |
| 死代码删除 / 文件改名 / 引用修复 / 注释优化 | 本文件主记 | ✅ |
| 跨项目反向学习吸收 | 本文件主记 + 新增 PROP（如影响大）| ✅ |

**格式**：滚动近况优先单行压缩；复杂项用 4 行格式：
```
- **改了啥**：……
- **触发原因**：……
- **验收结果**：……
- **后续影响**：……
```

**写作铁律**：日期 + 一句话标题 + 必要验收证据，单条 ≤ 10 行。

---

## 2026-06-22

- **hooks-smoke 契约拆分（L1 / 清文件大小软债 / 派 worker）**：`hooks-smoke-claude-contracts.ps1` 9949B→6064B，PROP-001 路径门禁 fixture 抽到新 `hooks-smoke-claude-pathgate-contracts.ps1`（5 协调点：dot-source 清单 / Assert 预期集 / lifecycle 调用）；主会话亲跑 smoke PASS、断言一条不减。⚠️ **反讽现场**：拆完体检 >8KB 🔴 转移到 `CHANGELOG.md` 自身（9727B，本会话 9 刀累积撑过线）——活生生的"只增不减"，正是 **PROP-002** 要治的；CHANGELOG 归档收敛列待办（有锚点校验需谨慎，不并入本刀）。
- **add-pm-track.ps1 加固（-TaskFile / L1 / dogfood 闭环）**：上轮 dogfood 抓到 -Task 含 ASCII 引号被命令行解析截断（fail-safe 已兜住未写坏）；本轮加 `-TaskFile` 参数走文件读 task，根治任意含引号/`|`/特殊字符的任务文本。验证：本轮 16:25 轨迹即用 -TaskFile（task 内含 `"引号"` 与 `|`）盖戳，引号未截断、`|`→`/` 转义生效。
- **PROP-002 起草（rank-12 演化收敛闸 / 待审批 / L3）**：ultracode Workflow 5-agent 并行实测框架演化体征（元规则 6→23 零回撤 / ADR 38 无退役档 / 候选 P0 滞留约 1 月 / 复杂度零仪表）后据实起草——提议 04_台账加「演化体征」轻表（5 列、每 RETRO 抄真源）+ 收敛硬规则（永久元规则净增连涨 2 RETRO 无退役→强制本轮 RETRO 必答「有无该退役/合并/下沉」）。提醒不阻断、不删任何现有规则。L3 待 zlbdh review。（dogfood 旁注：add-pm-track.ps1 对 -Task 含 ASCII 引号脆弱，已 fail-safe 兜住，待加固。）
- **PM 轨迹时间戳自动化 helper（RETRO-023 候选 DW 落地 / L2）**：新增 `能力资产/tools/scripts/add-pm-track.ps1`——调用即自动 `Get-Date` 盖真时间戳追加规范 PM 轨迹（`|`→`/` 转义 / UTF-8 无 BOM / LF 自适应 / fail-safe / 必填 From-To-Task），杜绝手填（已 3 次复发 P4f 崩塌红）；`tools/README` 加推荐用法指针。本轮 15:54 轨迹即用该 helper 自盖戳 dogfood 验证。派 操作系统 PM worker 实现，主会话验收 + 真文件 dogfood。
- **体检 scope 收口 P4s（RETRO-023 候选①落地 / L1）**：审计全部 `-Recurse` 子检查后确认仅 `p4s-template-cleanliness.ps1` 仍全 `$Root` 递归未排除自托管实例；`$skipDirs` 加 `\本地实例\`。实测铁证：修复前 p4s 扫 848 文件其中 **424 个是沙盒副本**（翻倍），修复后归 0。至此 dogfood 自托管常驻引入的体检 scope 泄漏（P4g+P4s 两处全 root 扫描）全部收口。
- **RETRO-023 收口**：沉淀 PM「沉淀者」（派 worker 独立视角）复盘本轮 czxt 产品化 dogfood 三刀；核心发现 = ADR-038 调度模型首会话即被作者违反 2 次（软规则失守再证）+ DW 时间戳第 3 次复发（建议提 PROP）+ 体检 scope 排除自托管实例待全面排查。索引已回写 `Docs/7-复盘/README.md`。
- **PROP-001 路径 C 类铁律加 PreToolUse 软门禁（L3 / 首个 czxt 原生 PROP 全流程闭环）**
  - **改了啥**：claude+codex 两份 `pre-write-guard.ps1` 在密钥检测后追加路径裁决——写 `Docs/6-历史归档/`（任意层级）或已存在 `apk/` 文件时，claude 出 `permissionDecision=ask`、codex 走 additionalContext 软警告（按各自契约，均 ask/warn 不 deny + fail-safe）；hooks-smoke 加正/负向 fixture。
  - **触发原因**：dogfood 审计 rank-4 头号主线——路径白名单 / C 类铁律写入时零机械门禁，仅靠 AI 自觉（PM 自纠 #88/#91 已论证此路不通）。
  - **流程**：主会话起 PROP-001 → zlbdh L3 批准 → **派 操作系统 PM worker 实现（按子agent调度机制 ADR-038，首次正确派 worker 而非 inline）** → 主会话验收+越界核对 → readme-index/hooks-smoke/体检 gate 全绿 → 主会话单点 commit。
  - **后续影响**：护栏从"纸面"变"机械兜底"（范围限历史归档+历史APK，剔除噪声大的单源/git命令级，后者留 Phase 2）；跑通了 PROP 状态机 + worker 调度 + 验收 gate 全链路。
- **根 README 门面 dogfooding 修复 + 体检 scope 排除自托管实例（L1+L2）**
  - **改了啥**：根 `README.md` 补 frontmatter + 顶部/实例化段补 `AGENTS.md` 起手导航 + 占位符表补 `{{APP_ID}}`/`{{PROJECT_SLUG}}` 行与“脚本自动替换、勿手改”说明；`p4g-readme-list-consistency.ps1` frontmatter 扫描排除 `\本地实例\`。
  - **触发原因**：审计 rank-2/3 门面缺口；dogfood 自托管沙盒副本被 P4g 重复计数（35→71）暴露体检 scope 对 `项目区/本地实例/` 排除不统一。
  - **验收结果**：README frontmatter 覆盖 34/35→35/35=100%（长期标黄闭环）；软警告 10→9；P4a 绿。
  - **后续影响**：对外补上 README→AGENTS→00_总入口 三级漏斗；自托管实例可常驻 项目区 而不污染模板自带体检度量。
- **实例化脚本递归套娃 BUG 修复（L2 / dogfood 实跑发现）**
  - **改了啥**：`实例化项目.ps1` 把 `项目区` 从 `$copyItems` 总递归清单移出，改为只拷骨架（README/清单/.gitignore + 空 `本地实例/.gitkeep`）；加 in-tree 目标守卫；补 `{{APP_ID}}`/`{{PROJECT_SLUG}}` 替换 + `-AppId`/`-ProjectSlug` 参数。同步 `p4a-basic-integrity.ps1` 守卫为「项目区不得进总递归清单(防套娃) + 须骨架复制(防漏拷)」。
  - **触发原因**：dogfood 自装操作系统到 `项目区/本地实例/` 时，旧脚本递归复制 `项目区`（含正在生成的实例自身）→ 无限套娃撑盘。
  - **验收结果**：robocopy 清套娃；重跑自装 exit 0、0 套娃、0 残留占位符；模板根 + 沙盒 P4a 绿（new skeleton 守卫通过）。
  - **后续影响**：解锁「操作系统进项目区」+ P2 多项目试装首个机械证据；顺带堵住「新项目继承模板旧本地实例」泄漏。

## 2026-06-18

- **PROP-039 重估拆分收口**：把原 Mem0+Skills SDK 整包路径拆为 Mem0 本机只读记忆检索试点与 Agent/Skills 载体层只读上下文加载试点；同步 PROP、README、scope-schema、元规则候选与 readme-index 锚点。未装 SDK、未写 key、未引入业务依赖。
- **PROP-034 进行中口径收口**：模型分层不再标“未开工/待排期”；更新为本地实现完成、待发布与外部三模型实测，明确不得伪造成本数据且未授权不做 commit/push/tag/version/release。验证：PROP 索引 + 状态快照 + 交接卡同步。

## 2026-06-17

- **接收归档 chat 收尾守卫补齐**：chat-output ⑥ 默认仍要求 `交接区/待接手/`；若待接手为空且目标为 `交接区/已接手/` 下 `status: accepted` 卡，则允许作为接收归档收尾详情。同步交接规范、manifest、hooks smoke 与锚点守卫。验证：hooks-smoke / readme-index ✅。
- **操作系统全量逐文件审计收口**：4 explorer 读完审计开始时 95 个 `操作系统/**/*.md`；修交接假绿、测试归属、历史边界、旧 5 PM 附录口径、计数/索引/坏字符，新增逐文件明细，当前基线 96 Markdown。验证：full gate ✅。
- **07_完整工作流 P1/P2 收口**：3 explorer 审决策/发布/hooks SOP；修需求接收 PROP 路由、Q7 真实 agent、审批 PM 路由、release keystore/APK 覆盖/version/tag、git preflight、DoD 交接和 scheduled/Stop/Claude ask 边界，补 `workflow-spec-anchor`。验证：target ✅。
- **06_工具治理 P1/P2 收口**：3 explorer 审 hooks/体检/历史；修 FileChanged 兜底、scheduled 检查、Stop 阻断、历史残篇/frontmatter、check-plan/Q1-Q7，补历史锚点与 hooks 设计计数锚点。验证：target ✅。
- **05_记忆 P1/P2 收口**：3 explorer 审入口/历史/scope；修起手、pm-workspace、ADR-028、状态推断，补 `memory-spec-anchor`。验证：target ✅。
- **04_台账 P2 守卫补强**：3 explorer 审版本/Sprint/议题/历史；修阶段口径，补 `ledger-spec-anchor`。验证：target ✅。
- **03_交接 P1/P2 收口**：3 explorer 审规范/hooks/现实；补 frontmatter、chat ⑥、Stop、② 路径与 `handoff-spec-anchor`。验证：target ✅。
- **02_智能体 P1/P2 收口**：3 explorer 审 playbook/附录/共享技能；修单源、tag、分支、写权、历史边界，补 `agents-playbook-anchor`。验证：target ✅。

## 2026-06-16

- 详见 `CHANGELOG-2026-06-16-较早条目.md`。
