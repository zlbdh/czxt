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
⚠️ **历史已归档**：2026-06-18 及更早条目见 `CHANGELOG-2026-06-18-较早条目.md`、`CHANGELOG-2026-06-16-较早条目.md`、`CHANGELOG-2026-06-15-较早条目.md`、`CHANGELOG-2026-05-21至06-14-较早条目.md`、`CHANGELOG-2026H1.md`。

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

## 2026-06-28

- **PM 专业 mode / 能力层落地（L2）**：保持 9 PM 不扩编，新增 `PM专业mode能力层.md`，明确需求/设计/前端/后端/硬件先挂产品/技术/开发 PM 的 mode、plugin、worker/explorer；`product-design` 作为产品 PM 体验设计能力，不单设设计 PM。

## 2026-06-22

- **hooks-smoke 契约拆分（L1 / 清文件大小软债 / 派 worker）**：`hooks-smoke-claude-contracts.ps1` 9949B→6064B，PROP-001 路径门禁 fixture 抽到新 `hooks-smoke-claude-pathgate-contracts.ps1`（5 协调点：dot-source 清单 / Assert 预期集 / lifecycle 调用）；主会话亲跑 smoke PASS、断言一条不减。⚠️ **反讽现场**：拆完体检 >8KB 🔴 转移到 `CHANGELOG.md` 自身（9727B，本会话 9 刀累积撑过线）——活生生的"只增不减"，正是 **PROP-002** 要治的；CHANGELOG 归档收敛列待办（有锚点校验需谨慎，不并入本刀）。
- **add-pm-track.ps1 加固（-TaskFile / L1 / dogfood 闭环）**：上轮 dogfood 抓到 -Task 含 ASCII 引号被命令行解析截断（fail-safe 已兜住未写坏）；本轮加 `-TaskFile` 参数走文件读 task，根治任意含引号/`|`/特殊字符的任务文本。验证：本轮 16:25 轨迹即用 -TaskFile（task 内含 `"引号"` 与 `|`）盖戳，引号未截断、`|`→`/` 转义生效。
- **PROP-002 起草（rank-12 演化收敛闸 / 待审批 / L3）**：ultracode Workflow 5-agent 并行实测框架演化体征（元规则 6→23 零回撤 / ADR 38 无退役档 / 候选 P0 滞留约 1 月 / 复杂度零仪表）后据实起草——提议 04_台账加「演化体征」轻表（5 列、每 RETRO 抄真源）+ 收敛硬规则（永久元规则净增连涨 2 RETRO 无退役→强制本轮 RETRO 必答「有无该退役/合并/下沉」）。提醒不阻断、不删任何现有规则。L3 待 zlbdh review。（dogfood 旁注：add-pm-track.ps1 对 -Task 含 ASCII 引号脆弱，已 fail-safe 兜住，待加固。）
- **PM 轨迹时间戳自动化 helper（RETRO-023 候选 DW 落地 / L2）**：新增 `能力资产/tools/scripts/add-pm-track.ps1`——调用即自动 `Get-Date` 盖真时间戳追加规范 PM 轨迹（`|`→`/` 转义 / UTF-8 无 BOM / LF 自适应 / fail-safe / 必填 From-To-Task），杜绝手填（已 3 次复发 P4f 崩塌红）；`tools/README` 加推荐用法指针。本轮 15:54 轨迹即用该 helper 自盖戳 dogfood 验证。派 操作系统 PM worker 实现，主会话验收 + 真文件 dogfood。
- **体检 scope 收口 P4s（RETRO-023 候选①落地 / L1）**：审计全部 `-Recurse` 子检查后确认仅 `p4s-template-cleanliness.ps1` 仍全 `$Root` 递归未排除自托管实例；`$skipDirs` 加 `\本地实例\`。实测铁证：修复前 p4s 扫 848 文件其中 **424 个是沙盒副本**（翻倍），修复后归 0。至此 dogfood 自托管常驻引入的体检 scope 泄漏（P4g+P4s 两处全 root 扫描）全部收口。
- **RETRO-023 收口**：沉淀 PM「沉淀者」（派 worker 独立视角）复盘本轮 czxt 产品化 dogfood 三刀；核心发现 = ADR-038 调度模型首会话即被作者违反 2 次（软规则失守再证）+ DW 时间戳第 3 次复发（建议提 PROP）+ 体检 scope 排除自托管实例待全面排查。索引已回写 `Docs/7-复盘/README.md`。
- **PROP-001 路径 C 类铁律加 PreToolUse 软门禁（L3 / 首个 czxt 原生 PROP 全流程 / 派 worker）**：claude+codex `pre-write-guard.ps1` 对写历史归档 / 已存在 apk 出 ask / 软警告（ask 不 deny + fail-safe）；护栏从纸面变机械兜底（审计 rank-4，PM 自纠 #88/#91 佐证）。全流程：主会话起 PROP→zlbdh 批→派 worker(ADR-038)→验收 gate→单点 commit `96e82cf`。详见 PROP-001 / RETRO-023。
- **根 README 门面修复 + 体检 scope 排除自托管实例（L1+L2）**：README 补 frontmatter + AGENTS 起手导航 + 占位符表补 `{{APP_ID}}`/`{{PROJECT_SLUG}}` 与“勿手改”说明；`p4g` frontmatter 扫描排除 `\本地实例\`（dogfood 沙盒副本污染 35→71 暴露）。验收 frontmatter 34/35→35/35、软警告 10→9、P4a 绿。详见 commit `6abddc8`。
- **实例化脚本递归套娃 BUG 修复（L2 / dogfood 实跑发现）**：`实例化项目.ps1` 项目区改只拷骨架（防自实例化无限套娃）+ in-tree 守卫 + 补 `{{APP_ID}}`/`{{PROJECT_SLUG}}` 替换；`p4a` 守卫同步「项目区不进总递归清单 + 须骨架复制」。robocopy 清套娃、重跑 0 套娃/0 残留；解锁操作系统进项目区 + P2 首证；堵住新项目继承旧实例泄漏。详见 commit `2d216a8`。

## 2026-06-18 及更早

- 详见 `CHANGELOG-2026-06-18-较早条目.md`（2026-06-17~18）、`CHANGELOG-2026-06-16-较早条目.md` 及上方头部所列更早归档。
