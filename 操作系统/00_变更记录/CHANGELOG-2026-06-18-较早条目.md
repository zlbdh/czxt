---
name: changelog-2026-06-18-archive
scope: project
type: episodic
loaded: on-demand
description: 操作系统演进日志 2026-06-17~18 较早条目归档
---

# CHANGELOG 2026-06-17~18 较早条目

> 从 `CHANGELOG.md` 滚动归档，保留浏览证据；当前近况仍看 `CHANGELOG.md`。
> **历史安全边界**：本归档含历史 hooks / git / push / tag 等词，仅作追溯，**不可直接复制执行**；敏感操作仍先查 `三类行为铁律.md` 与 ADR-022。

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
