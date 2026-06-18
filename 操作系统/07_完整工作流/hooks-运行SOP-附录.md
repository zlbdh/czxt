---
name: hooks-run-sop-appendix
scope: project
type: procedural
loaded: on-demand
description: hooks 运行 SOP 附录 — 低频安装命令 / 事件表 / watcher 健康码 / 排障细节
---

# Hooks 运行 SOP — 附录

> 主入口见 [`hooks-运行SOP.md`](hooks-运行SOP.md)。本文件只放低频细节。

## Git hook 安装与移除

`install-hooks.ps1` 同时安装 pre-commit + pre-push 两个 wrapper。`git/pre-commit.ps1` 只是早期单点 wrapper 样本，不维护 pre-push 门禁。

```powershell
# 启用本地 git hook
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Apply

# 仅检查安装状态
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
```

执行真源头：

```text
能力资产/tools/hooks/install-hooks.ps1
能力资产/tools/hooks/run-hooks.ps1
能力资产/tools/hooks/manifest.json
```

## Codex 原生事件表

项目级 Codex hooks 入口：`.codex/hooks.json`。

| Codex event | 用途 |
|---|---|
| `SessionStart`（startup\|resume\|clear\|compact） | 新 session / resume / clear / compact 时注入项目治理上下文 |
| `UserPromptSubmit` | 输入涉及 hooks、操作系统、敏感操作时补治理提醒 |
| `Stop` | 疑似实施收尾时检查 ①-⑦ 交接卡和 PM 切换轨迹 |
| `PostToolUse`（Edit\|Write\|apply_patch）| 改 framework/PM 工作区文件后自动 readme-index 快检；apply_patch 从 patch header 解析路径 |
| `PreToolUse`（Edit\|Write\|apply_patch）| 往非 `.env` 写疑似密钥时软提醒；apply_patch 从 patch header 解析目标路径 |

首次加载后，到 Codex「钩子」页刷新并 review/trust 项目 hooks；未 trust 前 Codex 会发现配置但不会实际执行非托管 hooks。

## Claude Code 原生事件表

项目级 Claude Code hooks 入口：`.claude/settings.json`。

| Claude event | 适配脚本 | 用途 |
|---|---|---|
| `SessionStart` | `能力资产/tools/hooks/codex/session-start.ps1`（与 Codex 共用） | 注入项目治理上下文 |
| `UserPromptSubmit` | `能力资产/tools/hooks/codex/user-prompt-submit.ps1`（共用） | 敏感操作补治理提醒 |
| `Stop` | `能力资产/tools/hooks/claude/stop-chat-summary.ps1`（Claude 专属） | 疑似收尾查 ①-⑦ 交接卡 + PM 切换轨迹 |
| `PostToolUse`（Edit\|Write）| `能力资产/tools/hooks/claude/post-edit-framework-check.ps1` | 改 framework/PM 工作区后 readme-index 快检，仅用 systemMessage 非阻塞提醒 |
| `PreCompact`（auto\|manual）| `能力资产/tools/hooks/claude/pre-compact-snapshot.ps1` | 压缩前快照最后 PM 轨迹 + 提醒补未发交接卡 |
| `PreToolUse`（Edit\|Write）| `能力资产/tools/hooks/claude/pre-write-guard.ps1` | 往非 `.env` 写疑似密钥时 `ask` 确认 |

新建 `.claude/settings.json` 当次会话不自动加载；首次需在 Claude Code 里打开 `/hooks` 一次或重启 session 才生效。

## Watch / Scheduled 低频命令

ADR 目录监听：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/adr-readme-watch.ps1
```

本机登录启动任务：

```powershell
# 安装并立即启动
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Apply -StartNow

# 停止并删除
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Remove
```

健康判定：

- `State=Running` 且 `LastTaskResult=267009`（`0x41301`）表示 watcher 正在运行。
- `LastTaskResult=2147943467`（`0x8007042B` / 低位 1067）表示进程意外终止；按 `-Mode Apply -StartNow` 重建并启动。
- watcher 只自动应用 ADR README 索引；交接卡、PM 轨迹、`状态.md` 摘要和历史总结仍由 PM 写入，hooks 只检查或提醒。

Windows 计划任务：

```powershell
# 安装 / 重建，默认每日 09:30
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Apply

# 删除
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Remove
```

## 排障展开

| 失败 | 排障细节 |
|---|---|
| README 索引不一致 | 先跑 `check-readme-indexes.ps1` 定位，再跑对应 updater 的 `-Mode Check`。只有确定性索引差异才 `-Mode Apply` |
| chat-output 失败 | 按输出补 ①-⑦、⑥ `交接区/待接手/...md` 路径、⑦ `状态.md L<line>`；纯简单对话可写 ⑥“无” + ⑦ `N=0 / 本 session 无切帽子`；不要用总结段替代 |
| PM 轨迹超时 | `Select-String 状态.md -Pattern 'YYYY-MM-DD HH:mm'` 找行号；补真轨迹，不伪造 |
| framework 体检失败 | 按 P4a-P4s 逐项修；P4b 软警告可交接，硬失败必须先修 |
| watch 误触发 | 暂停 watcher，手动跑 `update-adr-readme.ps1 -Mode Check` 与 `check-readme-indexes.ps1` 复核 |
