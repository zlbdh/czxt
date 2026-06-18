---
name: hooks-event-matrix-appendix
scope: project
type: semantic
loaded: on-demand
description: hooks 事件矩阵附录 — watcher/scheduled 细节、运行时适配差异、暂未接事件
---

# Hooks 事件矩阵 — 附录

> 主矩阵见 [`hooks-事件矩阵.md`](hooks-事件矩阵.md)。本文件承接低频解释，不是真源头。

## Watch / Scheduled 细节

Windows 计划任务由 `能力资产/tools/hooks/scheduled/install-scheduled-task.ps1` 负责检查、安装和删除；任务名默认 `CZXT-Framework-Hooks-Daily`，本机生成物归 Windows Task Scheduler，不作为规则真源头。

ADR README watcher 由 `能力资产/tools/hooks/watch/install-adr-watch-task.ps1` 负责检查、安装和删除；任务名默认 `CZXT-ADR-README-Watch`，登录后启动 `adr-readme-watch.ps1 -Apply`，仅处理确定性 ADR README 索引更新。

## Codex 适配差异

Codex `PostToolUse` / `PreToolUse` 是 PROP-038 收尾镜像，与 Claude 侧 `claude/{post-edit-framework-check,pre-write-guard}.ps1` 同源逻辑，但有 3 处 Codex 适配差异：

- 提醒经 `hookSpecificOutput.additionalContext`（Codex 已验证可靠读取，同 SessionStart）+ `systemMessage` 双发。
- `PreToolUse` 是软警告非硬 ask/deny；Codex 权限决策格式未核实，故用 additionalContext 注入上下文让模型自行复核。
- Codex 桌面实际常用 `apply_patch`，适配器兼容 patch header 路径解析。

`PreToolUse` 只识别疑似密钥结构，不是完整 C/B 类边界判定器；`baseUrl`、用户数据删除、真实密钥外传、不可逆破坏性操作仍以 `操作系统/01_架构/三类行为铁律.md` 为准。

`file_path` / `content` 字段读取做多名兼容，防两家字段名差异；均加 BOM-strip + fail-safe，不确定一律 continue/allow。已做独立 stdin 真机验证：注入临时 ADR 漂移确认报警 + 真假密钥 / `.env` 豁免。

## Claude Code 适配细节

Claude 侧 3 个治本新增（PROP-038 / 2026-06-14）均 fail-safe：不确定一律 continue/allow，绝不误 block；`PreToolUse` 只 ask 不 deny。已做独立 stdin pipe-test + 正负向真机验证：`PostToolUse` 注入临时 ADR 漂移确认报警，`PreToolUse` 真假密钥 + 省略号无误报。stdin 读取统一加 BOM strip，防个别宿主头塞 BOM 致 JSON 解析失败。

Codex 侧 `PostToolUse` / `PreToolUse` 已完成镜像并注册到 `.codex/hooks.json`；`PreCompact` / `SessionEnd` 在 Codex 当前入口暂无对应。

## Claude 支持但本项目暂未接的事件

Claude Code 官方 hooks reference 当前还列有 `FileChanged`、`Notification`、`SessionEnd` 等事件。本项目此刻只接 6 个高价值事件：

- `FileChanged`：通用外部改盘暂无等价兜底；当前仅 ADR README 由 Windows watcher 确定性同步，daily scheduled 只做每日健康检查。
- `Notification`：暂无项目治理动作。
- `SessionEnd`：非正常收尾兜底，评估为低收益暂缓。

若后续要做“一份配置、两运行时完全等价”，优先在这里补 Claude 侧未接事件，再评估 Codex 是否有等价入口。

## Stop 适配差异

Codex 在 Stop 事件直接传 `last_assistant_message`；Claude Code 传 `transcript_path`（session JSONL）。`claude/stop-chat-summary.ps1` 两者都吃：优先 `last_assistant_message`，否则从 `transcript_path` 倒序读最后一条 assistant 的 `text` 块，再复用同一条 `run-hooks chat-output` 检查。全程 fail-safe，不确定一律 continue，绝不误 block。

Claude 配置用 exec 形式（`command:"powershell.exe"` + `args` 数组）绕开 shell 对中文路径的解析。
