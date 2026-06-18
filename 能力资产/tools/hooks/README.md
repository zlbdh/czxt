---
name: hooks-index
scope: project
type: procedural
loaded: on-demand
description: 操作系统 hooks 入口 — manifest / runner / git wrapper / Codex / Claude / watch / scheduled
---

# 能力资产/tools/hooks · 操作系统 Hooks

> 执行层入口。设计真说明见 `操作系统/06_工具治理/hooks-设计.md`；事件矩阵见 `操作系统/06_工具治理/hooks-事件矩阵.md` + `操作系统/06_工具治理/hooks-事件矩阵-附录.md`；命令级 SOP 见 `操作系统/07_完整工作流/hooks-运行SOP.md` + `操作系统/07_完整工作流/hooks-运行SOP-附录.md`。

## 目录

| 路径 | 职责 |
|---|---|
| `manifest.json` | hooks 清单，定义 id / trigger / script / 允许退出码 |
| `run-hooks.ps1` | 统一 runner，按 trigger 执行 hooks |
| `install-hooks.ps1` | 安装/检查本地 `{{APP_REPO_DIR}}/.git/hooks/pre-commit` + `pre-push` wrapper；Check 发现缺失或漂移会失败 |
| `.codex/hooks.json` | Codex 原生 lifecycle hooks 入口（项目根配置） |
| `.claude/settings.json` | Claude Code 原生 lifecycle hooks 入口（项目根配置） |
| `codex/` / `claude/` | 两个运行时的 lifecycle 适配层 |
| `chat-output/` | chat 简版收尾检查脚本 |
| `scheduled/` / `watch/` | Windows 计划任务与 ADR README watcher |
| `tests/` | hooks smoke；`tests/support/` 为内部契约模块；smoke 会临时创建并删除一张 `_hooks-smoke-*` 交接 fixture |

## 快速命令

```powershell
# framework 改动后的轻量检查
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook readme-index-check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook handoff-zone-check

# hook 框架 smoke
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/tests/hooks-smoke.ps1

# 本地 git hooks / Windows scheduled / ADR watcher 检查
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Check
```

完整 manual 会触发 `pre-release-check`（`npm test` + `npm run build`），较重；需要时再跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
```

## 当前 hooks（9 个 / 真源头 manifest.json）

本节只保留计数锚点，防 README 漂移。逐项事件、trigger、写入权限见 `操作系统/06_工具治理/hooks-事件矩阵.md`，适配细节见 `操作系统/06_工具治理/hooks-事件矩阵-附录.md`。

| 类别 | Hook |
|---|---|
| 索引/状态 | `readme-index-check` / `adr-readme-dry-run` / `pm-tracking-check` / `handoff-zone-check` / `chat-summary-check` |
| 安装/健康 | `hook-install-check` / `framework-health-check` |
| 发布/沉淀 | `pre-release-check` / `retro-cadence-check` |

`hook-install-check` 的 Check 模式会把本地 Git wrapper 缺失或内容漂移判为失败；需要修复时再运行 `install-hooks.ps1 -Mode Apply`。

## Codex 原生 hooks（5 个事件）

项目级入口：`.codex/hooks.json`。Codex UI「钩子」页读取该配置；首次加载后需要 review/trust。

| 事件 | 用途 |
|---|---|
| `SessionStart` / `UserPromptSubmit` | 注入项目治理上下文与敏感操作提醒 |
| `Stop` | 疑似实施收尾时检查 chat 交接卡 |
| `PostToolUse` / `PreToolUse` | framework 改动快检 + 业务大文件触碰软提醒 / 疑似密钥写入软提醒 |

## Claude Code 原生 hooks（6 个事件）

项目级入口：`.claude/settings.json`。新增或改动后需 `/hooks` 重载或重启 session。

| 事件 | 用途 |
|---|---|
| `SessionStart` / `UserPromptSubmit` | 与 Codex 共用治理上下文注入 |
| `Stop` | Claude transcript 适配后复用 chat 交接卡检查 |
| `PostToolUse` / `PreToolUse` / `PreCompact` | framework 改动快检 + 业务大文件触碰软提醒 / 密钥写入 ask / 压缩前留痕提醒 |

## 边界

- `.git/hooks` 不是真源头，只放本目录 wrapper 的安装副本。
- `.codex/hooks.json` 和 `.claude/settings.json` 只做运行时 lifecycle 适配，不承载业务逻辑。
- Stop / chat-output hook 只检查并阻断不合格收尾，不会替 agent 改写最终回复、移动交接卡或补 PM 轨迹。
- 自动写入仅限确定性索引，例如 ADR README 表格；语义型摘要先输出报告或 patch。
- `PreToolUse` 只覆盖疑似密钥结构提醒，不替代 `baseUrl`、用户数据删除、真实密钥外传等 C/B 类边界判断。
