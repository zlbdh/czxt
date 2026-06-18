---
name: adr-033
scope: project
type: semantic
loaded: on-demand
description: ADR-033 议题 CY 永久化 — 大文件 mount 操作不可信（读 stale/wc 不准 + 写 truncate / Read 工具唯一真值 + >6500B 写后验尾 + 改 framework 工具必真机整跑）/ 扩 ADR-025 到写向 / 第 16 元规则
---

# ADR-033 · 议题 CY 永久化 — 大文件 mount 操作不可信

> 升级：候选议题 CY（#67）+ #92/#94/状态.md mount-break（Sprint-11 今天 3+ 实证）→ 第 16 元规则
> 起稿：沉淀 PM「沉淀者」 / 拍板：项目 PM「咪咪」 / RETRO-015

## 背景

ADR-025（议题 BK）已永久化「Cowork mount stale → git reset 防御」，但只覆盖 **git status 读 stale**。Sprint-11 暴露 mount 对**大文件**的不可信远超此：

- **#92**：verify 工具靠 Read 单点、没真机整跑 → P4a-d 路径残留躲过多日。
- **#94**：Edit 工具改 21KB outputs → **尾部被截断**（`Wr`），cp 到真机后脚本崩。
- **状态.md（84KB）**：python `open().read()` UTF-8 decode 报错（读到半截字符）/ bash `tail` 停 L589 / `grep` 假阴性 —— 同一文件，挂载层喂出残缺/错版/前后矛盾字节。
- **#67（议题 CY 原始）**：Read 长文件前 wc -l 不准。

共性：**>6500B 文件的 mount 读（wc/grep/cat/python）和工具写（Edit/Write）都不可信**，但 **Read 工具是真值通道**（始终读到真机正确内容）。

## 决定

**大文件（>6500B）mount 操作不可信，四条铁律：**

1. **Read 工具 = 唯一真值通道** —— 断言任何文件状态前必用 Read 工具复核，不信 bash/python mount 读、不信记忆（连 PM 自己都踩，见 12:25 BK 自违）。
2. **>6500B 写后必验尾** —— 任何 Edit/Write/cp/heredoc 写大文件后，立即 Read 工具复核**尾部**（防截断 / #94）。
3. **改 framework 工具/脚本后必真机整跑** —— 不接受「只测新增段」（#92）。
4. **大文件 mid-file 写**：Edit 工具有截断风险（>6500B），mount python 读可能 stale/截断 → 用 **bash append（EOF-only，可靠）** 或 **python 读改写 + 多重 guard（decode/尺寸/尾部 sentinel/count==1，读不干净就停）**；guard 全失败 → 真机改。状态.md（84KB）实测 mount 读完全坏 → 只能真机。

## 后果

- ✅ 扩 ADR-025 从「git 读 stale」到「大文件读写全不可信」；议题 CY 永久关闭。
- ✅ check-operating-system.ps1 P4e「mount 缓存陷阱提醒」获 ADR 加持。
- 🟡 状态.md 已 84KB → 后续考虑拆分（议题 backlog）。
- 第 16 元规则 / 元规则池 v3.6.1 → v3.7。
