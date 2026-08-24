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
⚠️ **历史已归档**：2026-06-22 及更早条目见 `CHANGELOG-2026-06-22-较早条目.md`、`CHANGELOG-2026-06-18-较早条目.md`、`CHANGELOG-2026-06-16-较早条目.md`、`CHANGELOG-2026-06-15-较早条目.md`、`CHANGELOG-2026-05-21至06-14-较早条目.md`、`CHANGELOG-2026H1.md`。

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

## 2026-08-24

- **capture 事务安全终审（PROP-004 / ADR-039 / L4）**：补齐 staging→capture 树账本、repair 双移动封印、同字节 ABA、rename committed 对账、cleanup 后终检、真实 ADS/unknown 保留、初次与 post-move Git 精确清理及 P4t preflight 句柄生命周期；树 seal 改为流式 SHA-256 与逐成员 DFS，固定 `20000` 成员 / `536870912` 字节预算。fresh WinPS 362/362、assets 6/6、scaffold 63/63、docs 148/148、capture 8/8、hooks-smoke PASS；独立安全复审 P0/P1/P2=0。编码 `4ee4686`、功能 `7bf9ce4`、交接 `cda4339` 已按 ADR-016 正常 push，核验 main 分叉 `0/0`。

- **Codex 项目 hooks 恢复（L2）**：补回模板根用户级可信项目配置，并将 5 个 `.codex/hooks.json` 命令改为 quote-free PowerShell bootstrap；bootstrap 只接受最近且唯一的 CZXT 根标记并绑定 `.codex/invoke-hook.ps1`，双标记冲突即停，不依赖 Git 或绝对模板路径，规避 Windows `cmd.exe /C` 嵌套引号问题。TDD 覆盖 dispatcher 缺失、`.cmd`/Git 根误绑、独立非 Git、外层 Git 内嵌与双标记冲突；hooks-smoke PASS，Codex `hooks/list` 5/5 enabled+trusted、0 warning、0 error。

## 2026-07-22

- **完整借鉴闭环终审加固（PROP-004 / ADR-039 / L4）**：以句柄绑定与严格 TDD 收口安装器/封存/关闭事务的 reparse、hardlink、ABA、状态轨迹删除/目录替换及不可逆提交边界，并修复 hooks 敌对输出编码；最终 WinPS 349/349、骨架 63/63、文档 148/148、capture 8/8、P4t 10/10、seal 20/20、close x64/x86 各 31/31。既有 dogfood 单次 Force 保留状态前缀与 211 个保护文件，全新实例 `借鉴闭环终验-20260722-164424` 首装及 P4a-P4t 通过；模板 P4a 284、P4t 0/0，基线 57/57 与旧脏 42/42 对账完整。未 commit / push / 发布。

## 2026-07-19

- **完整借鉴闭环现行（PROP-004 / ADR-039 / L4）**：建立统一 `借鉴区/`、不可变来源 capture、双卡状态机、九维权限、唯一借鉴 Skill、可信关闭事务、只读离线 P4t 与 Git/local/web 捕获 façade；两轮独立审查与最终 dogfood 补齐 tracked 全 sink 凭据检测、`borrowing-evidence/v1`、P4t 后正式卡锁、公开 leaf 模式防伪、cwd 相对路径隔离、逐目标 junction 守卫及 `-Force` 原位升级。Gate 0、骨架 21/21、文档 137/137、capture 8/8、P4t 7/7、真实实例和模板/generic project 双端 P4a-P4t 均通过；基线 57/57 工件与 42/42 旧脏路径对账完整。未 commit / push / 发布。

## 2026-07-10

- **模板真值与 hooks 自清理收敛（PROP-003 / RETRO-024 / L3）**：纠正 P1 已完成、P2 未完成与 ADR 35 现行 + 3 被替代口径；开发文档、依赖/品牌/构建入口改为项目实例真值模板，P4s 加定向守卫；hooks-smoke 用唯一 TempRoot + 并发 sentinel 完成 RED/GREEN，最终 PASS 且 temp 9→9、fixture 无残留；状态推断补 ADR-033 同值状态元数据并触发 RETRO-024；终审推动 06-22 全节无损切档，主 CHANGELOG 7125→2999B。framework / 交接 / 索引 / 状态推断门禁均通过；未 fetch / commit / push。

## 2026-06-28

- **PM 专业 mode / 能力层落地（L2）**：保持 9 PM 不扩编，新增 `PM专业mode能力层.md`，明确需求/设计/前端/后端/硬件先挂产品/技术/开发 PM 的 mode、plugin、worker/explorer；`product-design` 作为产品 PM 体验设计能力，不单设设计 PM。

## 2026-06-22 及更早

- 详见 `CHANGELOG-2026-06-22-较早条目.md`（2026-06-22）、`CHANGELOG-2026-06-18-较早条目.md`（2026-06-17~18）、`CHANGELOG-2026-06-16-较早条目.md` 及上方头部所列更早归档。
