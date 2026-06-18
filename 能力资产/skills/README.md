---
name: skills-execution-index
scope: project
type: procedural
loaded: on-demand
description: 能力资产/skills/ 操作脚本索引 — 跨 PM 共享可执行 SOP
---

# 能力资产/skills/ — 操作脚本

## 这一组讲什么

单一能力的具体做法。每份 skill 解决"会做这一件事"——含步骤但不串多个能力。

跨 skill 串联的属于 `workflows/`。

## 主入口清单

| 文件 | 一句话 |
|---|---|
| [出APK.md](出APK.md) | 打包 dev APK（Windows 一键脚本 / GitHub Actions / 手动 gradle 三条路） |
| [跑测试.md](跑测试.md) | 核心 QA（vitest 单测 + vite build）；esbuild 语法层仅保留 Cowork 旧兜底 |
| ⭐ [项目体检.md](项目体检.md) | P4a-P4s framework 体检（字节阈值 / 计数对齐 / 交接区 / PM 轨迹 / 旧口径 / PM 工作区 / 活跃 Markdown 链接 / 能力资产剩余区 / 治理语义锚点 / hooks 配置 / 模板纯净度等） |
| ⭐ [状态推断.md](状态推断.md) | 10 项推断（APK 完成 / 代码改动 / RETRO 触发 / ADR 一致性 / 跨 session / 状态新鲜度等）— 实施循环起手 / PROP 收档对账；不替代 AGENTS 5 步 |

> 拆分细则文件（如 `项目体检-检查项*.md`、`状态推断-*`）由主入口文件引用，不在此表重复展开；以 `rg --files 能力资产/skills` 查看真实文件全集。

## 跟其他分组的区别

- **skills/**：单一能力（"会出 APK"、"会跑测试"）
- **操作系统/07_完整工作流/**：多 skill 串联（"先跑测试，再出 APK，再 smoke" = 发布流程）
- **操作系统/02_智能体/**：谁在用这个 skill
- **rules/**：用这个 skill 时要守哪些规则

## 速记

| 想做的事 | skill | 工具 |
|---|---|---|
| 打 APK | 出APK.md | `{{APP_REPO_DIR}}/build-apk.ps1`（自动归档）或按 ADR-016 授权后走 GitHub Actions |
| 跑测试 | 跑测试.md | `npm test` + `npm run build` |
