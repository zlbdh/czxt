---
name: changelog-2026-06-16-archive
scope: project
type: episodic
loaded: on-demand
description: 操作系统演进日志 2026-06-16 较早条目归档
---

# CHANGELOG 2026-06-16 较早条目

> 从 `CHANGELOG.md` 滚动归档，保留浏览证据；当前近况仍看 `CHANGELOG.md`。
> **历史安全边界**：本归档含历史 hooks / git / push / tag 等词，仅作追溯，**不可直接复制执行**；敏感操作仍先查 `三类行为铁律.md` 与 ADR-022。

- **01_架构 P1/P2 收口**：3 explorer 深审角色/铁律/元规则/agent；修 C 类、tag/env/schema、候选数 17、ADR 边界，补 `architecture-anchor`。验证：target ✅。
- **历史边界与审计覆盖台账**：3 explorer 分审历史/活入口/覆盖证据；补台账，修历史快照活化与“本文件归档”，加 readme-index/P4q 守卫。验证：P4q/readme-index/P4b ✅。
- **PM 私区速查 9/9 + 业务大文件触碰提醒**：补 5 个 PM 最小 INDEX、P4n 硬守 9/9；PostToolUse 接 `p4b-touch-warning.ps1`，触碰 `{{APP_REPO_DIR}}/src` 红/软区只软提醒。验证：hooks-smoke/P4n/P4b/check-os ✅。
- **PM 私区入口 / P4r 负向 / P4b 触发机制**：5 PM playbook 补自身私区入口；P4r 强断言 Codex `command`+`commandWindows` 并补 command-only 负向 fixture；开发 PM playbook 补 P4b 触发治理。验证：hooks-smoke/P4r/P4n/P4b/check-os ✅。
- **入口/角色/hooks 映射守卫**：修运营/沉淀边界、起手链路与 rules 旧主语；补 P4r 映射、check-plan 前缀、P4m/P4p/P4k 负向锚点和 ADR watcher 运行态解释。验证：hooks-smoke/P4r/check-os ✅。
- **体检入口表驱动化 + 脚本警戒清零**：`check-operating-system.ps1` 表驱动化，补 `check-plan-assert.ps1`，拆 P4m/P4b/handoff helper；能力资产 P4b warn 4→0。验证：readme-index/check-os ✅。
- **PROP 状态守卫与交接误伤**：补 `prop-status-helpers.ps1`，锚定文件头状态 + 五态目录 + README 明细；已接手卡只拦未完成待办。验证：readme-index/handoff-zone/check-os ✅。
- **P4b 历史豁免与 hooks 契约**：新增 `framework-scope.ps1` 统一历史排除；handoff-zone 拦已接手待接收提示；hooks smoke 强锁 apply_patch/PreToolUse。验证：hooks-smoke/P4b/P4o ✅。
- **警戒区活文档压缩与 P4r 收口**：切档 2026-06-15 剩余 CHANGELOG；hooks SOP/设计补 P4r 收口，角色边界/项目 PM 写权收窄；5 个目标活文档均 <6000B。验证：readme-index/handoff-zone/pm-tracking/check-os ✅。
- **交接软提示清零与状态链回正**：接收 19:12 卡，清 5 张已接手卡“接收本卡时/下一步接收本卡”残留，状态顶部改指新待接手卡；验证 handoff-zone/pm-tracking/readme-index ✅。
- **hooks/P4r/PROP 需求链语义守卫补齐**：修 runner TextPath、Stop 只读误判、chat-output N=0、env 示例密钥、ADR watcher Check、P4r hooks 总健康、PROP 写权/状态与 Docs1 历史边界。验证：readme-index/P4r/hooks-smoke ✅。
- **PM 能力入口与 rules/skills 语义守卫补齐**：修 PM/rules/skills 写权、工具主语、L1/L2 门禁、状态推断旧公式和分支间交接守卫；扩 P4m/P4k/P4p/handoff-zone。验证：target guards/P4b/handoff-zone ✅。
- **能力资产工具脚本软区入口化 + 交接守卫严格化**：`governance-semantics-anchor` façade 化，`os-semantics` 复用公共 helper，`check-handoff-zone` 严格 pending frontmatter、Status 与路径兼容。验证：readme-index/check-os ✅。
- **P4b 业务债治理机制补强**：P4b 体检补 `{{APP_REPO_DIR}}/src` 业务债治理摘要，`TASKS.md` 补四类策略入口，`p4b-business-debt-anchor` 改同表格行校验；修 ADR-032 路径。验证：readme-index/check-os/hooks-smoke ✅。
- **hooks 运行态与自动对齐边界守卫补齐**：`hook-install-check` 缺失/漂移改 exit 10 并进 hooks-smoke；写清 PreToolUse 只提醒疑似密钥结构，不替代 B/C 类人工判定。验证：install-check/hooks-smoke ✅。
