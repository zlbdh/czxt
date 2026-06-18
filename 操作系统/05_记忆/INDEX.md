---
name: project-memory-index
scope: project
type: semantic
loaded: always
description: 项目记忆索引 / 新会话起手必读 / 多运行时 / AppData memory 退役指针的单一入口
---

# 项目记忆索引 · 新会话起手必读

> **单一入口原则**：所有跨对话必读内容先从本文件进入。AppData memory 已退役为指针；项目真相回到 `{{PROJECT_ROOT}}\` 内。
>
> **起手 trigger**：按 `AGENTS.md` + `操作系统/00_总入口.md` 起手链路进入本文件；任何新对话 / 新 PM 接手 / Codex / Claude Code 启动时，读本文件后再按任务 follow 指针。
>
> **维护规则**：项目类信息指向 `Docs/`、`操作系统/`、`能力资产/` 真知识源；本文件只保留高频入口，不复制长历史正文。
>
> **scope schema**：记忆文件 frontmatter 规范见 [`scope-schema.md`](scope-schema.md)。

---

## 一、用户身份与偏好

### zlbdh（项目所有者，开发者本人）

- **沟通语言**：中文优先，文档/方案/提交说明默认中文。
- **决策模式**：给多选时必须明确推荐 + 1-3 条理由；不要用“我赌 / 我倾向”等弱化表述。
- **PM 工作模式**：希望 PM 主动拍板、持续推进，不要每个小事都让他选。
- **视觉偏好**：咪咪文人风 UI / 樱粉系视觉 / 温柔克制不油腻。
- **私人边界**：眯的日记是私人项目，除非 zlbdh 主动提起，不主动交叉。
- **角色定位**：zlbdh 是最终决策者 + 代码作者 + 真机 smoke 验证者。

### 当前项目身份

- **项目**：「{{PROJECT_NAME}}」（包名 `{{APP_ID}}` / 副标题按项目实例填写）
- **代码路径**：`{{PROJECT_ROOT}}\{{APP_REPO_DIR}}\`
- **当前版本**：以 `状态.md` 顶部快照 + `{{APP_REPO_DIR}}/package.json` + 最新已接收 ship 卡为准；若 `交接区/待接手/` 有 in-flight 卡则优先读待接手。
- **仓库分支**：`main`（不是 master）。
- **AI 模型**：小米官方 + 小米自研 MiMo（`mimo-v2.5-pro`），国内合规；详见 [`../../能力资产/shared/品牌词典.md`](../../能力资产/shared/品牌词典.md)。

---

## 二、行为反思入口

详细正文已拆到 [`行为反思.md`](行为反思.md)。起手只需按任务命中加载：

| 触发场景 | 必读 |
|---|---|
| 准备推断代码/接口/模型状态 | 反思 1：先核实，不默认推测 |
| 准备拍 UI / Tab / 路由 / 模块入口方案 | 反思 2：先 verify 真实代码 |
| 准备给 Codex / Claude Code 写执行提示词 | 反思 3：提示词极简，细节放 handoff 卡 |
| 准备起 handoff / ship 卡 | 反思 4：verify checklist |
| 准备改 Cowork >6500B 或 Codex/Claude >8KB 文件 | 反思 5：大文件写入风险 |
| 发现项目数据/配置/状态在项目外 | 反思 6：framework 项目外存储错向 |
| 切 PM 帽子 / 长 session / 收尾输出 | 反思 7：PM 轨迹留痕防衰减 |

---

## 三、项目重要历史入口

详细早期样本已拆到 [`项目历史指针.md`](项目历史指针.md)。当前判断优先读真知识源：

| 内容 | 真知识源 |
|---|---|
| 当前快照 / 待接手 | [`../../状态.md`](../../状态.md) + `交接区/待接手/` |
| Sprint / 需求历史 | [`../../Docs/1-需求文档/`](../../Docs/1-需求文档/) |
| ADR 完整索引 | [`../../Docs/3-开发文档/adr/README.md`](../../Docs/3-开发文档/adr/README.md) |
| RETRO 完整索引 | [`../../Docs/7-复盘/README.md`](../../Docs/7-复盘/README.md) |
| 元规则永久池 | [`../01_架构/元规则池.md`](../01_架构/元规则池.md) |
| PM / agent / 角色边界 | [`../02_智能体/README.md`](../02_智能体/README.md) + [`../01_架构/角色边界.md`](../01_架构/角色边界.md) |
| 工具治理 / hooks / 体检 | [`../06_工具治理/README.md`](../06_工具治理/README.md) + [`../../能力资产/tools/hooks/README.md`](../../能力资产/tools/hooks/README.md) |
| 项目台账总入口 | [`../04_台账/INDEX.md`](../04_台账/INDEX.md) |

---

## 四、起手必走 checklist（进入本文件后）

1. 确认已按 `AGENTS.md` + `操作系统/00_总入口.md` 进入本文件（已完成 = 你正在读）。
2. Read [`../../状态.md`](../../状态.md) 顶部和最新 PM 切换轨迹。
3. Read [`../00_总入口.md`](../00_总入口.md) 和 [`../01_架构/角色边界.md`](../01_架构/角色边界.md)。
4. Read `交接区/待接手/` 最新卡（如有）。
5. 跑 [`../../能力资产/skills/项目体检.md`](../../能力资产/skills/项目体检.md) 对应体检；动 framework 前后跑自动门禁。
6. `git -C {{APP_REPO_DIR}} status --short --branch` verify 工作区（议题 BK / ADR-025）。
7. 按当前任务加载 `PM工作区/<X-PM>/速查表/INDEX.md`，不要无差别灌 context。

---

## 五、维护与退役指针

- **维护责任**：项目 PM「咪咪」统筹；涉及记忆 framework 时切操作系统 PM「框架管家」。
- **版本来源**：当前版本/Sprint 不在本文件硬编码，读 `状态.md` + `{{APP_REPO_DIR}}/package.json` + 完成卡。
- **AppData memory**：仅保留为指针，不再作为项目真相；退役清单见 [`AppData-memory退役清单.md`](AppData-memory退役清单.md)。
- **新建记忆文件**：先按 [`scope-schema.md`](scope-schema.md) 加 frontmatter，再从本入口或对应 README 建指针。
