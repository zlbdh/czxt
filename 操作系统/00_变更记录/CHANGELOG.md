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
