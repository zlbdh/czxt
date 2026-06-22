---
name: capability-tools-index
scope: project
type: procedural
loaded: on-demand
description: 能力资产/tools/ 工具治理索引 — 构建脚本声明 + 依赖矩阵（PROP-028）+ scripts/ 真可执行（task #109 合并）
---

# 能力资产/tools · 工具治理

> 构建脚本声明（PROP-028 落地）+ **真可执行脚本 `scripts/`**（task #109 合并 / 议题 CM v3.2 / 2026-05-22）+ **hooks 入口**（PROP-038 Layer 4 v0 / 2026-06-13）

## 结构

| 子项 | 类型 | 内容 |
|---|---|---|
| `构建脚本.md` | **声明文档** | npm scripts + build-apk.bat / .ps1 + git 编码规范 + 开发/测试发布 PM 分工 |
| `依赖矩阵.md` | **声明文档** | 运行时 + dev 依赖 + Capacitor 6.x 主版本对齐 + 升级 SOP |
| `scripts/` 🆕 | **真可执行** | 7 个公开入口脚本：`check-operating-system.ps1` / `check-pm-tracking.ps1` / `check-readme-indexes.ps1` / `update-adr-readme.ps1` / `check-handoff-zone.ps1` / `check-pre-release.ps1` / `check-retro-cadence.ps1`；`scripts/check-os/` 是 `check-operating-system.ps1` 的内部 P4a-P4s 子检查/support helper，`scripts/check-readme-indexes/` 是 README/INDEX 锚点内部 helper，并桥接 P4o/P4q/P4r 让 PostToolUse 与总健康能发现活跃 Markdown 断链、治理语义和 hooks 配置漂移，`scripts/check-handoff-zone/` 是交接区检查内部 helper，均不单独进 hooks manifest；hooks 真源见 `hooks/manifest.json` |
| `hooks/` 🆕 | **触发器入口** | `manifest.json` + `run-hooks.ps1` + git/watch/scheduled wrapper；`tests/support/` 是 smoke 内部契约模块 |

## scripts/ 调用示例

```powershell
# 项目根跑
powershell -File 能力资产/tools/scripts/check-operating-system.ps1
powershell -File 能力资产/tools/scripts/check-pm-tracking.ps1
powershell -File 能力资产/tools/hooks/run-hooks.ps1 -Trigger manual -Mode Check
powershell -File 能力资产/tools/hooks/install-hooks.ps1 -Mode Check
```

> ✍️ **写 PM 轨迹推荐用法**：`powershell -NoProfile -File 能力资产/tools/scripts/add-pm-track.ps1 -From "<从>" -To "<到>" -Task "<干了啥>"` —— 自动用 `Get-Date` 盖真实时间戳追加一行规范轨迹，避免手填时间戳出错（P4f 轨迹崩塌）。

> ⚠️ **合并来源**：原 `{{PROJECT_ROOT}}\tools/`（task #90-#92 新建）+ 本目录原声明文档（PROP-028 落地）→ task #109 合并到统一治理 / **PM 自纠 #75 教训**：新建顶级目录前必检查命名冲突

| 文件 | 内容 |
|---|---|
| [构建脚本.md](构建脚本.md) | npm scripts + build-apk.bat / .ps1 + git 编码规范 + 开发/测试发布 PM 分工 |
| [依赖矩阵.md](依赖矩阵.md) | 运行时 + dev 依赖 + Capacitor 6.x 主版本对齐 + 升级 SOP |
| [hooks/README.md](hooks/README.md) | 操作系统 hooks manifest / runner / wrapper 入口 |

## 与 {{APP_REPO_DIR}}/ 真实工具的关系

- **本目录**：声明式文档（说明工具用途 / 升级策略）
- **{{APP_REPO_DIR}}/build-apk.bat / package.json**：真实工具
- **{{APP_REPO_DIR}}/.env.local**：本机 AI 配置（gitignore；按 ADR-022 6 护栏属 B 类）；真实 API key 外传 / 写入 tracked 文件仍是 C 类

## 维护
- 新增 / 升级依赖时同步本目录
- 新增 hooks 时同步 `hooks/manifest.json` + `hooks/README.md` + `操作系统/06_工具治理/hooks-设计.md` + `操作系统/06_工具治理/hooks-事件矩阵.md` / 附录 + `操作系统/07_完整工作流/hooks-运行SOP.md` / 附录
- 责任：操作系统 PM + 接 PR 的角色
