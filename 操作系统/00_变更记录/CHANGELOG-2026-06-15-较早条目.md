---
name: changelog-2026-06-15-earlier
scope: project
type: episodic
loaded: on-demand
description: 操作系统演进日志 2026-06-15 较早条目归档
---

# 操作系统演进日志 — 2026-06-15 较早条目

> 从 `CHANGELOG.md` 机械切档；主文件保留最新滚动窗口。
> ⚠️ **历史安全边界**：正文只作追溯，不代表当前待办或当前执行流程，不可直接复制执行；涉及旧路径、旧命令、`.env.local`、API key、tag/push 等语义时，必须回到现行 `操作系统/01_架构/三类行为铁律.md`、ADR-016、ADR-022 与 `操作系统/00_总入口.md` 重判。

## 2026-06-15

- **Docs2-3 / 00_变更记录语义守卫补齐**：修产品入口/IA/API Key 备份边界、ADR 正文首屏历史与敏感配置边界、PROP 发布/配置口径、CHANGELOG/agent 历史首屏安全边界；新增 product-docs/change-records/adr-history/prop-active 守卫接入 readme-index/P4q。验证：readme-index/P4q/check-os/hooks-smoke/handoff-zone/pm-tracking ✅。
- **历史正文与 PROP 扫描式自动对齐补齐**：补 `状态-archive` 正文首屏安全边界、早期已完成 PROP 历史封存说明，`docs-edge-history` 递归扫描 Docs6，`os-semantics` 扫状态归档正文，`prop-template` 扫已完成 PROP 旧路径/API/chat/危险 git 口径。验证：readme-index ✅。
- **Docs/1+5+6+PROP 边缘守卫补齐**：修备份/改库/Sprint/前作/Docs6/PROP 旧口径；新增 docs-edge/prop-template 守卫接入 P4q，交接历史加入口。验证：readme-index/P4q/handoff-zone ✅。
- **Docs/4+7 根入口深层语义收口**：修根 README、RETRO 模板/TASKS/危险 RETRO 与多轮 smoke 历史指针；新增 retro/smoke 守卫。验证：readme-index/check-os/hooks-smoke ✅。
- **边缘治理文档对齐 + 自动边界补强**：修 Actions 手动触发、ADR-025 reset 历史化、PROP 索引/037/039 状态；新增 Actions/PROP/治理语义守卫。验证：锚点 ✅。
- **层级/agent/工作流语义守卫补齐**：修旧层级、PM 工具绑定、子 agent brief/交接混用、发布/git/编号查询旧命令；P4q 补层级与候选重复守卫。验证：readme-index/check-os/hooks-smoke/handoff-zone ✅。
- **Docs/PROP/ADR/RETRO 治理语义守卫补齐**：补开发文档入口、`PROP-025` 追溯档案、PROP 状态/编号例外与 ADR/RETRO 旧口径；新增 P4q + PROP 状态机守卫。验证：readme-index/check-os/handoff-zone/pm-tracking ✅。
- **04_台账自动对齐守卫补齐**：补 P4a 台账入口、P4h 台账锚点、议题全景 `TASKS.md` 真源、历史快照/P4k 守卫；验证 p4h/P4a/P4g/P4k/readme-index/hooks-smoke/check-os ✅，能力资产 P4b 115 safe。
- **shared/mcp/agents/workflows 能力资产尾部审计收口**：修 shared/mcp/agents/workflows P1/P2 口径并新增 P4p 守卫；验证 P4p/readme-index/check-os ✅。
- **rules/skills/PM 工作区深水区审计收口**：修 `拒绝 → 删除` 诱导、commit 编码命令、状态推断双真源、PM/agent 语义漂移；新增 P4m/P4n 守卫。验证：P4m/P4n ✅。
- **工作流/角色边界审计收口**：3 explorer 分审 01/02、03/07、00/04/05/06；修删分支/GitHub Release C 类误导、DoD 6 项、交接流转、项目 PM 收口白名单、B 类例外、禁并行清单、记忆阈值/PROP-039/历史快照提示，并扩 P4k 守卫。验证：readme-index/check-os ✅。
- **PostToolUse 触发面与活文档语义收口**：按 3 explorer 回流修 P1/P2：Codex/Claude 快检触发面补 `Docs/7-复盘/` 和 `TASKS.md`，hooks-smoke 加契约；拆清 Codex apply_patch vs Claude Edit/Write；运营 `ToDo` 改待触发核对项；`state-links` 扩历史归档。验证：hooks-smoke/readme-index/handoff-zone/check-os ✅。
- **P4o 链接/锚点守卫 + 快检桥接**：新增 P4o 并接入总检/快检，扫活跃 Markdown 相对链接与锚点。验证：153 文件 / 938 链接、readme-index/check-os ✅。
- **PM 工作区快检 + 交接守卫补强**：补 P4n 快检与 handoff-zone 标题顺序/状态/卡龄校验。验证：readme-index/handoff-zone/hooks-smoke/check-os ✅。
- **PM 工作区入口对齐 + P4n 守卫**：派 3 explorer 审 PM 工作区/项目 PM 自纠/运营入口；修 9 PM 速查表、PM 自纠 41 artifact 索引、运营 README 与商标暂缓 supersede、框架管家路径白名单；新增 P4n 守 9 PM 目录/README/入口旧口径。验证：P4n/readme-index/hooks-smoke/manual hooks/check-os ✅，P4b 能力资产 safe 106 / warn 0。
- **P4b/P4c Low 语义审计继续**：3 explorer 审剩余 Low；修 mount stale 过度判断、PM 自纠归属、测试 PM 只读边界、AppData 退役文案和旧路径人工 grep 漏报；P4b 扫描改显式扩展过滤+分域摘要。验证：check-os/readme-index/hooks-smoke ✅。
- **P4c Low 历史提示与旧载体工具名对齐**：3 explorer 分审 Low 文件；补历史/快照提示、Q1-Q7 说明、旧阈值/旧命令/旧工具名守卫，现行入口去 `AskUserQuestion`/`TaskCreate`。验证：P4m/P4c/readme-index/hooks-smoke/manual hooks/check-os ✅。
- **P4c Low 低频入口审计**：2 explorer 审 28 个 Low；补 `-ShowLowList`、Q4 共享技能入口、真机 smoke/F 编号/体检模板等旧口径，Low 28→23。验证：readme-index/hooks-smoke/check-os ✅。
- **P4c 极低频入口补齐**：补 `agent-*历史` 快照说明、共享技能入口和 PM 自纠真实路径；P4c 在 Min>0 时打印极低频清单。验收：P4c Min 5→0 / Dead 0，readme-index/hooks-smoke/check-os ✅。
- **framework 软区入口化连收 5 项**：拆 `check-readme-indexes` hooks 计数 helper、压缩 `check-operating-system` façade、拆项目体检 1-4 附录、拆 P4k 工具主语 pattern 表、拆 web-api 信源矩阵；P4b safe 386→396 / soft 50→45，总软警告 94→89。验证：readme-index ✅、P4k 局部 ✅、check-os ✅。
- **check-readme-indexes hooks 锚点模块化**：新增 `hooks-doc-count-anchor.ps1` 承接 hooks README 9/5/6 计数和“后续可镜像”语义守卫；主入口 `check-readme-indexes.ps1` 7879B→5042B。验证：helper 单跑 ✅、readme-index ✅，P4b soft -1。
- **CHANGELOG 2026-06-15 较早条目切档**：新增 `CHANGELOG-2026-06-15-较早条目.md`，把 2026-06-15 较早入口化/模块化记录移出主入口；主文件回到滚动近况定位。验证：check-os ✅，P4b 不再因本文件新增红项。
- **hooks 事件矩阵入口化与计数守卫**：`hooks-事件矩阵.md` 7338B→4032B，新增附录 3355B 承接适配差异/暂未接事件/Stop 细节；修旧议题编号为 `PROP-038`，新增 `hooks-event-matrix-anchor.ps1` 守 9/5/6 与 matcher。验证：readme-index/hooks-smoke/check-os ✅，P4b soft 52→51。
- **hooks/记忆守卫**：拆 hooks support 与 P4k pattern；P4a 补记忆/状态推断，P4m 缺状态推断 fail；修依赖/MCP 旧口径。验收：smoke/readme/check-os ✅，P4a 49→57，P4b warn 8→5。
- **入口/规则警戒区压缩与旧口径修正 9 项**：`00_总入口`、`git流程`、`实施循环-DoD`、`分支间协作机制`、`构建脚本`、`三类行为铁律`、`项目PM-咪咪`、`角色边界`、`状态推断` 均降到 <6000B；修 7 元规则/ADR-024 编号冲突、构建脚本旧日期/5 脚本口径、状态推断 Bash 权威旧口径。验证：P4j/P4k/P4l/P4m/readme-index/check-os ✅，P4b warn 17→8，总软警告 85→76。
- **架构与记忆软区入口化连收 4 项**：`工具载体矩阵.md` 6895B→4532B + 附录，`子agent调度机制.md` 6838B→5753B，`元规则池.md` 6728B→5874B，`行为反思.md` 6570B→5984B；P4b soft 45→41，总软警告 89→85。验证：P4j/P4k/readme-index/check-os ✅。
- **hooks 运行 SOP 入口化与 apply_patch 守卫**：`hooks-运行SOP.md` 7579B→5718B，新增附录 4832B 承接低频安装/事件表/健康码；修 Codex Post/PreToolUse `Edit|Write` 漂移为 `Edit|Write|apply_patch`，新增 `hooks-sop-anchor.ps1` 守卫。验证：readme-index/hooks-smoke/check-os/target hooks ✅，P4b soft 53→52。
- **实施循环入口化附录对齐**：`实施循环.md` 7829B→5328B，新增 `实施循环-附录.md` 3659B 承接阶段细则与端能力表；README/DoD/git/审批/改动分级引用同步，P4j/P4k 扫新附录。验证：readme-index/hooks-smoke/check-os ✅，P4b soft 54→53。
- **Codex apply_patch hooks 入口补齐**：`.codex/hooks.json` 的 Post/Pre matcher 扩到 `Edit|Write|apply_patch`；Codex post/pre 适配器支持从 patch header 解析路径，hooks-smoke 与 P4e/项目体检口径覆盖。
- **项目体检说明入口化拆分**：`项目体检-检查项-7-8.md` 7990B→5326B，新增 7-9 附录 3529B；`项目体检.md` 7693B→3804B，新增项目体检附录 2353B。验证：P4b soft 56→54，总软警告 99→97，P4c 0 死引用。
- **状态推断跨 session 监控入口化拆分**：`状态推断-跨session监控.md` 8215B→4824B，新增附录 4020B 承接 Bash/GNU fallback；主文保留推断 5-9 契约。验证：P4b danger 28→27，P4c/readme ✅。
- **rules 两个红区入口化拆分**：`web-api-信源选型.md` 8323B→7150B + 附录 2759B，矩阵留主文；`已知技术约束.md` 8087B→3931B + 附录 3559B。验证：P4b danger 30→28，P4c/readme ✅。
- **交接卡格式入口化拆分**：主文 8177B→5678B，新增附录 2974B；模板校正为实际卡 H2 ①-⑥，03/交接区 README 补附录。验证：P4b danger 31→30，P4c 0 死引用，handoff/readme ✅。
- **产品 PM「需求拆解者」入口化拆分**：主文 8523B→5790B，附录 3694B；保留身份/触发/输出/白名单/Q1-Q7，P4k 扫附录。验证：P4b 32→31，P4c/P4k ✅。
- **三类行为铁律入口化拆分**：主文 8625B→6278B，附录 3667B；保留 B/C 主表与 `### ❌ C 类`，AGENTS 指向真源，P4k role/tool 扫附录。验证：P4b danger 33→32，P4c/P4k ✅。
- **技术 PM「修复决策者」入口化拆分**：主文 9351B→5213B，附录 4798B；保留只读诊断/路径禁写/协作边界，P4k tool 扫附录。验证：P4b danger 34→33，P4c/P4k ✅。
- **运营 PM「运营咪咪」入口化拆分**：主文 9354B→5222B，附录 4891B；修“可写自身 playbook”为“可提建议，操作系统 PM 落笔”。验证：P4b danger 35→34，P4c/P4k ✅。
- **项目 PM「咪咪」入口化拆分**：主文 9688B→6203B，附录 4511B；补“自动化只 Check/阻断，语义文档不静默改写”。验证：P4b danger 36→35，P4c/P4k/readme-index/hooks-smoke/check-os ✅。
- **测试 PM 质量门户入口化拆分**：主文 9812B→5736B，附录 4243B；P4k tool 扫附录。验证：P4b danger 37→36，P4c/P4k/readme-index ✅。
- **子 agent 调度机制入口化拆分**：主文 11832B→6838B，附录 4644B；P4k 扫附录。验证：P4b danger 38→37，P4c/P4k/readme-index/check-os ✅。
- **元规则池入口化拆分**：主文 12561B→6728B，候选页+附录承接低频正文；23 计数锚点留主文。验证：P4b danger 39→38，P4c/readme-index/P4g/P4k/check-os ✅。
- **议题全景入口化归档**：`议题全景.md` 12619B→2192B，2026-05-22 明细移入 `04_台账/历史归档/2026-05/`；P4g/readme-index 双路径统计。验证：P4b danger 40→39，P4c/check-os/hooks-smoke ✅。
- **操作系统 PM playbook 入口化拆分**：主文 12895B→5703B，新增附录 4259B；02 README 与 P4k 守卫纳入附录。验证：P4b danger 41→40，P4c/readme-index/check-os ✅。
- **05_记忆 INDEX 入口化拆分**：`INDEX.md` 16024B→5228B，新增 `行为反思.md`、`项目历史指针.md`、`AppData-memory退役清单.md` 承接低频正文；上游入口与 P4j/P4k/readme-index 守卫同步。验证：P4b danger 42→41，P4c 0 死引用，check-os ✅。
- **decision-checkpoint 入口化拆分**：主文 16952B→约 4.5KB，新增 `decision-checkpoint-判定细则.md` 承接 Q4-Q7；P4j/P4k 纳入新页，`.env.local` B 类/API key 外传 C 类拆清。验证：readme-index/check-os/hooks-smoke ✅，P4b danger 43→42。
- **角色边界入口化拆分**：`角色边界.md` 17604B→6061B，新增协作附录与 PM 工作区边界，修旧章节引用。验证：P4b danger 44→43，P4c 0 死引用，check-os ✅。
- **hooks 自动对齐边界 + ADR watcher**：补自动写入边界，明确语义文档/交接卡/PM 轨迹不自动重写；重启 `CZXT-ADR-README-Watch`，ADR README 38 同步 ✅。
- **06_工具治理历史大文档入口化**：4 个 2026-05 历史原文移入 `操作系统/06_工具治理/历史归档/2026-05/`，原路径保留小入口；P4b/P4c 排除 `历史归档/` 并同步体检说明。验证：P4b danger 49→44，P4c 0 死代码，check-os ✅。
- **check-os 公共 helper 协议收口**：`Invoke-OsSubcheck` 加 PS 5.1 兼容 `Arguments` 透传，P4a/P4b/P4c 统一走 helper；主脚本 8947B→7725B。验证：Parser ✅、check-os ✅。
- **P4a 基础完整性模块化**：新增 `check-os/p4a-basic-integrity.ps1`，P4a 必查文件/目录和通过计数由子模块承担；主脚本 13670B→11503B。验证：P4a 49 项 ✅、空 Root 负向 exit 10 ✅、check-os ✅。
- **hooks-smoke 路径口径补齐**：`操作系统/06_工具治理/README.md` 改写完整路径 `能力资产/tools/hooks/tests/hooks-smoke.ps1`，并给 readme-index 加守卫。验证：readme-index ✅、hooks-smoke ✅、handoff-zone ✅。
- **P4c 引用频率模块化**：新增 `p4c-framework-references.ps1`；主脚本 16KB→13KB。验证：P4c 正/负向、check-os ✅。
