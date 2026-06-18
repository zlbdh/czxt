---
name: hooks-run-sop
scope: project
type: procedural
loaded: on-demand
description: 操作系统 hooks 运行 SOP 主入口 — manual / git / Codex / Claude / watch / scheduled
---

# Hooks 运行 SOP

> 本文件保留日常跑法、真源和关键边界。低频命令/健康码/排障见 [`hooks-运行SOP-附录.md`](hooks-运行SOP-附录.md)；设计见 [`hooks-设计.md`](../06_工具治理/hooks-设计.md)，事件见 [`hooks-事件矩阵.md`](../06_工具治理/hooks-事件矩阵.md)。

## 手动入口

framework 改动后优先跑轻量 hook；完整 manual 会触发较重发布门禁（`npm test` + `npm run build`）。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook readme-index-check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check -Hook handoff-zone-check

# 需要完整手动门禁时再跑（会触发 pre-release-check）
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
```

ADR README 确定性索引可 Apply：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/update-adr-readme.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/update-adr-readme.ps1 -Mode Apply
```

交接区健康只报警，不自动移动文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/scripts/check-handoff-zone.ps1
```

## 真源与入口

| 入口 | 真源/路径 | 必记 |
|---|---|---|
| 项目 hooks 清单 | `能力资产/tools/hooks/manifest.json` | 9 个项目 hook；由 `run-hooks.ps1` 执行 |
| Git hooks | `能力资产/tools/hooks/install-hooks.ps1` | 生成 `{{APP_REPO_DIR}}/.git/hooks/pre-commit` + `pre-push` wrapper，`.git/hooks` 不进版本控制 |
| Codex 原生 | `.codex/hooks.json` | 5 个事件；需 Codex UI review/trust 后执行 |
| Claude Code 原生 | `.claude/settings.json` | 6 个事件；首次需 `/hooks` 重载或重启 session |
| ADR watcher | `能力资产/tools/hooks/watch/adr-readme-watch.ps1` | 只自动应用 ADR README 确定性索引 |
| Scheduled | `能力资产/tools/hooks/scheduled/daily-framework-check.ps1` | Windows 计划任务跑 scheduled runner：索引、PM 轨迹、交接区、framework health、RETRO 节奏 |

## Git hook 入口

Git hook wrapper 由 `install-hooks.ps1` 生成；pre-push 会跑发布门禁（`pre-release-check`：`npm test` + `npm run build`），任一失败 exit 1 阻止 push：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger pre-push -Mode Check
```

日常只查安装漂移：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
```

pre-commit、Apply / Remove 命令见 [`hooks-运行SOP-附录.md`](hooks-运行SOP-附录.md#git-hook-安装与移除)。

## 原生 lifecycle 入口

Codex 接 5 事件、Claude Code 接 6 事件，详见事件矩阵。关键差异：Codex `PostToolUse` / `PreToolUse`（Edit|Write|apply_patch）需从 patch header 解析路径；Claude `PreToolUse` 可 `ask`，`PostToolUse` 只做非阻塞 systemMessage，另有 `PreCompact` 留痕提醒。

`PreToolUse` 只覆盖疑似密钥结构提醒（Codex 软提醒 / Claude ask），不是完整 C 类判定器。遇到 `baseUrl`、用户数据删除、真实密钥外传、不可逆破坏性操作，仍必须回到 `操作系统/01_架构/三类行为铁律.md` 人工重判。

逐事件脚本与字段兼容见事件矩阵及附录。

## Watch / Scheduled

```powershell
# ADR watcher 检查
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/watch/install-adr-watch-task.ps1 -Mode Check

# Scheduled 检查
powershell -NoProfile -ExecutionPolicy Bypass -File 能力资产/tools/hooks/scheduled/install-scheduled-task.ps1 -Mode Check
```

Apply / Remove、健康码和重建命令见 [`hooks-运行SOP-附录.md`](hooks-运行SOP-附录.md#watch--scheduled-低频命令)。

## 自动写入边界

- 自动写入只覆盖“文件系统可确定”的索引，例如 ADR README 表格。
- `PostToolUse` 只做快检提醒，不生成 patch；当前 readme-index 快检已包含 P4o/P4q/P4r 相关锚点，scheduled/watch 运行态仍以 P4r 总检为准。
- `PreToolUse` 只做疑似密钥结构提醒，不自动替代 `baseUrl`、用户数据删除、真实密钥外传等 C/B 类边界判断。
- `Stop` / `chat-output` 只在疑似实施收尾时查 ①-⑦、交接卡路径和 `状态.md` 行号；只读审计 / 未改文件有豁免；简单对话可写 ⑥“无” + ⑦ `N=0 / 本 session 无切帽子`，不替 agent 改回复。
- `handoff-zone-check` 只报警，不自动把交接卡从 `待接手` 移到 `已接手`。
- 交接卡、PM 轨迹、`状态.md` 顶部摘要、历史总结仍由 PM 判断后写入。

## 失败处理

README 索引先 `Check` 后 `Apply`；PM 轨迹回 `状态.md` 补真行号；framework 体检按 P4 输出逐项处理；watch 误触发先停 watch 再手动 runner 复核。低频排障见附录。

## 完成标准

- `能力资产/tools/hooks/tests/hooks-smoke.ps1` 通过；`tests/support/*.ps1` 只做内部契约分层，不单独进 manifest。
- `run-hooks.ps1 -Trigger manual -Mode Check` 通过，或说明本轮轻量 hook 范围。
- hooks-smoke 锁定 `framework-health-check` 的 scheduled 入口合同：manifest 仍指向 `能力资产/tools/scripts/check-operating-system.ps1` façade，内部 P4 子模块不单独进 manifest。
- hooks 文档或运行态变更后必须跑 `能力资产/tools/scripts/check-operating-system.ps1`，确认 P4r hooks 配置与运行态锚点通过。
- README / INDEX 一致性检查输出明确。
- ADR README updater 在当前状态下 `Check` 无差异。
