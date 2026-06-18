---
name: hooks-event-matrix
scope: project
type: semantic
loaded: on-demand
description: 操作系统 hooks 事件矩阵主文 — manifest / Codex / Claude 可读镜像
---

# Hooks 事件矩阵 · manifest / Codex / Claude

> 本文件是可读镜像，不是真源头。事件数量真源头分别是 `能力资产/tools/hooks/manifest.json`、`.codex/hooks.json`、`.claude/settings.json`。低频适配差异、验证故事、暂未接事件和 Stop 细节见 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md)。

## 计数锚点

- 项目 hooks：9 个项目 hook（真源 `能力资产/tools/hooks/manifest.json`）
- Codex 原生：5 个 lifecycle 事件（真源 `.codex/hooks.json`）
- Claude Code 原生：6 个 lifecycle 事件（真源 `.claude/settings.json`）

## 当前 v0 hooks

| Hook | trigger | 写入权限 |
|---|---|---|
| `readme-index-check` | manual / pre-commit / scheduled | 只读 |
| `adr-readme-dry-run` | manual / pre-commit / file-watch | Check 只读 / Apply 写 ADR README |
| `pm-tracking-check` | manual / chat-output / scheduled | 只读 |
| `handoff-zone-check` | manual / scheduled | 只读，警告不阻塞 |
| `chat-summary-check` | chat-output | 只读 |
| `hook-install-check` | manual | Check 发现 `.git/hooks` wrapper 缺失/漂移会失败；Apply 写本地 `.git/hooks` |
| `framework-health-check` | scheduled | 只读 |
| `pre-release-check` | pre-push / manual | 只读；测试/构建失败阻止 push |
| `retro-cadence-check` | scheduled / manual | 只读；exit 5 非阻塞提醒 |

Windows 计划任务、ADR watcher 任务名和安装/删除细节见 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md#watch--scheduled-细节)。

## Codex 原生 lifecycle 适配

当前用项目级 `.codex/hooks.json` 接 5 个 lifecycle 事件：

| Codex event | 适配脚本 | 动作 |
|---|---|---|
| `SessionStart` | `能力资产/tools/hooks/codex/session-start.ps1` | 注入项目治理上下文、PM 边界、hooks 真源头 |
| `UserPromptSubmit` | `能力资产/tools/hooks/codex/user-prompt-submit.ps1` | 用户输入涉及 hooks/操作系统/敏感操作时补治理提醒 |
| `Stop` | `能力资产/tools/hooks/codex/stop-chat-summary.ps1` | 疑似实施收尾缺 ①-⑦ 交接卡时阻断 |
| `PostToolUse`（Edit\|Write\|apply_patch） | `能力资产/tools/hooks/codex/post-edit-framework-check.ps1` | 改 framework/PM 工作区后 readme-index 快检；触碰业务大文件只软提醒 |
| `PreToolUse`（Edit\|Write\|apply_patch） | `能力资产/tools/hooks/codex/pre-write-guard.ps1` | 往非 `.env` 写疑似密钥时软提醒；不替代完整 C/B 类边界判断 |

Codex 的 apply_patch 路径解析、字段兼容、additionalContext 双发和软提醒策略见 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md#codex-适配差异)。

## Claude Code 原生 lifecycle 适配

Claude Code 侧用项目级 `.claude/settings.json` 接 6 个 lifecycle 事件（PROP-038 议题 CK / 2026-06-14）：

| Claude event | 适配脚本 | 动作 |
|---|---|---|
| `SessionStart` | `能力资产/tools/hooks/codex/session-start.ps1`（与 Codex 共用）| 注入项目治理上下文、PM 边界、hooks 真源头 |
| `UserPromptSubmit` | `能力资产/tools/hooks/codex/user-prompt-submit.ps1`（共用）| 输入涉及 hooks/操作系统/敏感操作时补治理提醒 |
| `Stop` | `能力资产/tools/hooks/claude/stop-chat-summary.ps1` | 对疑似收尾回复缺 ①-⑦ 交接卡时阻断 |
| `PostToolUse`（Edit\|Write） | `能力资产/tools/hooks/claude/post-edit-framework-check.ps1` | 改 framework/PM 工作区后 readme-index 快检；触碰业务大文件只软提醒 |
| `PreCompact`（auto\|manual） | `能力资产/tools/hooks/claude/pre-compact-snapshot.ps1` | 压缩前快照最后 PM 轨迹 + 提醒补未发交接卡 |
| `PreToolUse`（Edit\|Write） | `能力资产/tools/hooks/claude/pre-write-guard.ps1` | 往非 `.env` 写疑似密钥时 `ask` 确认；不替代完整 C/B 类边界判断 |

Claude 的 fail-safe、BOM-strip、暂未接事件和 Stop transcript 适配差异见 [`hooks-事件矩阵-附录.md`](hooks-事件矩阵-附录.md#claude-code-适配细节)。
