---
name: hooks-design
scope: project
type: semantic
loaded: on-demand
description: 操作系统 hooks 设计主文 — Layer 4 自动化 v0 / PROP-038 落地入口
---

# Hooks 设计 · Layer 4 自动化 v0

> 目标：把“软规则靠 PM 记得”升级为“项目内可版本化、可手动跑、可接 git/watch/scheduled 的 hooks”。

本文件只保留 hooks 的设计判断、分层、写入边界和验证入口。事件矩阵主文见 [`hooks-事件矩阵.md`](hooks-事件矩阵.md)，运行时细节见 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md)。

## 设计判断

当前操作系统需要 hooks：PROP-038 把 Hooks / Watch / Cron / MCP events 定为议题 CK 的 Layer 4 根治方向；PM 自纠 #76 证明 chat 简版不能保证真实写入；ADR-032 已把列表类 README 一致性列为永久 SOP。

## 分层

| 层 | 放置 | 职责 |
|---|---|---|
| 规则层 | `操作系统/` | 为什么要跑、何时必须跑、失败怎么判 |
| 执行层 | `能力资产/tools/hooks/` | trigger wrapper、manifest、watch/scheduled/git 入口 |
| 脚本层 | `能力资产/tools/scripts/` | 可复用的确定性脚本 |
| Codex 原生入口 | `.codex/hooks.json` | Codex lifecycle 事件适配，不放业务逻辑 |
| Claude Code 原生入口 | `.claude/settings.json` | Claude Code lifecycle 事件适配；脚本归 `能力资产/tools/hooks/` |
| 本地安装层 | `{{APP_REPO_DIR}}/.git/hooks/` / Windows Task Scheduler | 生成物，不作为真源头 |

## 当前 v0 hooks

当前项目 hooks 真源头是 `能力资产/tools/hooks/manifest.json`，现有 9 个项目 hook；Codex 原生入口接 5 个事件，Claude Code 原生入口接 6 个事件。

事件表、脚本路径、scheduled/watch/git wrapper 补充说明都放在 [`hooks-事件矩阵.md`](hooks-事件矩阵.md) 和 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md)。矩阵是可读镜像，不是第四个真源头。

## Codex 原生 lifecycle 适配

Codex 桌面「钩子」页读取 Codex 原生配置，不会自动读取项目 `manifest.json` 或 `.git/hooks`。

当前用项目级 `.codex/hooks.json` 接 5 个 lifecycle 事件。适配层只做事件桥接，实际治理脚本仍归 `能力资产/tools/hooks/`；项目级 Codex hooks 需要 Codex UI review/trust 后才会执行。

完整 Codex 事件矩阵见 [`hooks-事件矩阵.md`](hooks-事件矩阵.md#codex-原生-lifecycle-适配)，PostToolUse / PreToolUse 镜像说明与字段兼容策略见 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md#codex-适配差异)。

注意：`PreToolUse` 只做疑似密钥结构提醒（Codex 软提醒 / Claude ask），不是完整 C 类判定器；`baseUrl`、用户数据删除、真实密钥外传、不可逆破坏性操作仍按三类行为铁律人工重判。

## Claude Code 原生 lifecycle 适配（PROP-038 议题 CK / 2026-06-14）

Claude Code 侧用项目级 `.claude/settings.json` 接 6 个 lifecycle 事件。

新建 `.claude/settings.json` 当次会话不自动加载；首次需在 Claude Code 里打开 `/hooks` 一次（重载配置）或重启 session 才生效。

Claude 事件与 Stop 适配差异见事件矩阵及附录。

## 自动写入边界

✅ 可以自动写：
- 从文件系统确定性生成的索引表。
- 只补缺失、删多余、重排顺序的 README 表格。

🟡 仅人工报告，不进入自动写入链：
- 项目根 README 当前版本摘要、`状态.md` 顶部 3 秒速查、`议题全景.md` 语义表等需要 PM 判断的语义内容。

❌ 不自动写：
- API key / baseUrl / 用户数据。
- 业务代码 `{{APP_REPO_DIR}}/src/**`。
- 需要 PM 判断语义的历史总结。
- chat 收尾 ①-⑦、PM 切换轨迹、交接卡内容、`状态.md` 顶部摘要等语义型文档。

## 为什么不会自动语义对齐

当前 hooks 的自动写入只覆盖“文件系统可确定”的索引，例如 ADR README 表格；其余文档只做检查或提醒：

- Codex `PostToolUse` 在 Edit/Write/apply_patch 改 framework/PM 工作区/治理入口后跑 `check-readme-indexes.ps1` 快检；触碰 `{{APP_REPO_DIR}}/src` 红/软区业务大文件时只软提醒开发 PM按功能判断；apply_patch 会从 patch header 解析目标路径。
- Claude Code `PostToolUse` 当前按 Edit/Write 改 framework/PM 工作区/治理入口触发同一快检；触碰业务大文件同样只软提醒；发现漂移会提醒，但不会生成 patch。
- `PreToolUse` 只做疑似密钥结构提醒，不会自动判断 `baseUrl`、用户数据删除、真实密钥外传等完整 C/B 类边界。
- `Stop` / `chat-output` 会检查并阻断疑似实施收尾的不合格输出（①-⑦、可读交接卡路径、`状态.md` 行号），不会替 agent 改写回复或补卡。
- `handoff-zone-check` 只报警，不会自动把交接卡从 `待接手` 移到 `已接手`。
- Windows ADR watcher 只处理 ADR README 这种确定性索引，不处理历史总结、交接区、PM 轨迹或状态摘要。

## 验证

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/tests/hooks-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-readme-indexes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-operating-system.ps1
```

`hooks-smoke.ps1` 是公开验证入口；`tests/support/*.ps1` 只拆分内部契约（config / chat-output / Codex / Claude / lifecycle coordinator），不作为独立 hook 注册到 `manifest.json`。
