---
name: mcp-installed
scope: project
type: semantic
loaded: on-demand
description: 项目 MCP/连接器能力声明（单一信息源）— 核心/按需/未用能力矩阵、跨运行时一致性约定与维护 SOP，议题 CG 项目外存储治理落地。
---

# INSTALLED.md · 项目 MCP/连接器能力声明（项目外存储治理 / 议题 CG）

> **🎯 单一信息源原则**：项目需要或历史使用过的 MCP / 连接器 / plugin 统一登记在此。
> **边界**：本文件不是各客户端的实时安装回显；真实可用工具以当前运行时暴露的 tools/plugins 为准。
>
> **2026-05-20 立**（C 强化版 framework 自检 / PROP-026 / 议题 CG）

---

## 一、为什么需要这份清单

Cowork / Codex / Claude Code 等运行时各自有 MCP / plugin / connector 安装机制，但项目侧若无记录，会出现：

- 换设备 / 重装工具后丢失
- 跨运行时不知道哪些能力是项目必需
- 新 PM / 新对话看不到完整 MCP / 连接器矩阵
- 无 Git 版本化（与 AppData memory 同模式 framework 错向）

→ 本文件作为项目 MCP / 连接器**声明文档**（不替代实际安装配置；当前运行时是否已安装需现场核验）

---

## 二、项目侧 MCP / 连接器能力矩阵

> ⚠️ 以下按项目需求和历史使用维护，不声明“此刻已安装”。实际配置在各客户端 / connector / plugin 管理处。

### 🔴 项目核心能力需求（运行时等价，不等于同名 MCP 必装）

| 能力 | 典型实现 | 触发场景 |
|---|---|---|
| **本机文件/命令执行** | Codex shell / Claude Code shell / Cowork workspace | 文件检查、脚本体检、构建测试 |
| **浏览器/桌面控制** | Codex Browser / Chrome / Computer Use / Cowork computer-use | 真机 smoke、截图、页面操控 |
| **自动化提醒** | Codex automation / scheduled-tasks 等运行时能力 | PM 提醒、定时 ship 卡 |
| **历史上下文回看** | 当前运行时 thread/session 能力；必要时读项目内状态/交接卡 | 历史对话回看、跨 session 续接 |
| **文件分享/产物展示** | 当前运行时 artifact / present / connector 能力 | 交付截图、文档、报告 |

### 🟡 项目偶尔使用（按需）

| MCP | 用途 | 触发场景 |
|---|---|---|
| **brand-voice** | 品牌词典 + 内容生成 | 议题 BI 运营咪咪 v0.1 候选 |
| **slack-by-salesforce** | Slack 集成 | 远期：议题 BI 团队协作 |
| **figma** | Figma 操作 | 远期：F-SHARE-1 视觉设计 |
| **canvas-design / theme-factory** | 视觉设计 / 主题 | 远期：UI 设计辅助 |

### 🟢 历史 / 外部运行时曾见但项目当前不要求

| MCP / plugin 类别 | 状态 |
|---|---|
| **bio-research** (biorxiv / c-trials / chembl / consensus / pubmed / ot) | 不相关（健康 App 走小米 MiMo，不需要生物医学库）|
| **finance / sales / marketing / data / hr 等业务 plugin** | 不相关 |
| **adobe-for-creativity / cloudinary** | 远期可能（Sprint-9+ F-SHARE-1）|
| **legal / engineering / design / pdf-viewer** | 不相关 |
| **daloopa / lseg / bigdata / sp-global / zoominfo / common-room** | 不相关（金融 / 销售类）|
| **zoom / docusign / box / sanity / miro / intercom** | 不相关 |
| **brightdata / postiz / fastly / cockroachdb / prisma** | 不相关 |
| **searchfit-seo / customer-support / operations / finance** | 不相关 |
| **product-tracking / common-room / apollo** | 不相关 |

→ **大量历史 / 外部运行时能力与项目无关** — 未来 zlbdh 可按实际客户端清理（议题 CH 候选 — MCP 清理）

---

## 三、项目 MCP 使用约定

### 跨运行时一致性

| 工具 | MCP 配置位置 | 建议 |
|---|---|---|
| Cowork | Cowork 用户设置 | 历史主要工作环境 |
| Codex | Codex 配置 / Codex app plugin/connector | 以当前 tools/plugins 为准，保持项目核心能力可替代 |
| Claude Code | Claude Code 配置 | 以当前 tools/plugins 为准，保持项目核心能力可替代 |

连接器能力可以等价替代，但 lifecycle hooks 不等价；Codex / Claude Code 事件差异以 [`操作系统/06_工具治理/hooks-事件矩阵.md`](../../操作系统/06_工具治理/hooks-事件矩阵.md) 为准。

### 项目核心能力清单（用于跨运行时对齐）

新工作环境配置 Codex / Claude Code 时，应至少确认具备这些能力；不要求同名 MCP：

- ✅ 本机 shell / 文件读写 / 脚本执行
- ✅ 浏览器或桌面操控（真机 smoke / 截图时）
- ✅ 自动化提醒能力（如需定时）
- ✅ 历史上下文回看能力；缺失时以 `状态.md` + `交接区/` 续接

历史 Cowork 专属能力（不是 Codex / Claude Code 必装项）：
- computer-use / cowork mount / present 等按当前运行时等价能力替代

选择边界：本地网页 / localhost 优先 Codex Browser；依赖用户 Chrome 登录态用 Chrome；Windows 桌面 App 才用 Computer Use。

---

## 四、维护 SOP

### 新装 / 卸载 MCP 时

1. 更新本文件清单
2. 如属项目核心使用，标注用途 + 触发场景
3. 重大变更（如卸载核心 MCP）走 PROP 流程

### 跨设备同步

- 本文件 Git 化 → 新设备 clone 后可参考本文件配置 MCP
- 业务运行时 API key 仅在 `{{APP_REPO_DIR}}/.env.local` 且满足 ADR-022 护栏；connector / OAuth token 留在客户端密钥存储；任何本地 secret 写入需用户明确确认，绝不进 tracked 文件。

---

## 五、版本

- **v1**（2026-05-20）— 操作系统 PM 自检 framework 项目外存储治理（PROP-026 / 议题 CG）首次落地

→ 详见 [操作系统/05_记忆/INDEX.md](../../操作系统/05_记忆/INDEX.md) §二第 6 行为规则
