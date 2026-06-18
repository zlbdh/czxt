# 操作系统模板（czxt）

> 固定的是“操作系统”，可替换的是“项目”。

本目录是从当前项目实践中提取出来的项目协作操作系统模板，准备进入长期产品化模板阶段。目标远端是 [zlbdh/czxt](https://github.com/zlbdh/czxt)。

当前形态：源码模板 + 实例化脚本 + 本地项目区；还不是 npm package、安装器或 CLI。

核心协作模型：9 PM × 主-元-决策-实施四层。

## 固定治理层

模板保留这些固定治理层：

- `操作系统/`：角色边界、Q1-Q7、交接、台账、记忆、工具治理、完整工作流
- `能力资产/`：rules / skills / tools / hooks / mcp / agents / workflows
- `PM工作区/`：9 PM 工作区与速查表
- `交接区/`：跨角色交接队列
- `确认改动/`：PROP 状态机与模板
- `Docs/3-开发文档/`、`Docs/7-复盘/`：ADR / RETRO 治理入口
- `.codex/`、`.claude/`：运行时 hooks 配置模板
- `项目配置/`：项目卡模板；模板仓库只保留 `_模板.project.json`
- `项目区/`：本地放项目实例或试装目录，真实项目内容默认不进模板仓库

项目实例字段用占位符表示：

| 占位符 | 含义 |
|---|---|
| `{{PROJECT_ROOT}}` | 项目根目录，例如 `D:\WGKJ\某项目` |
| `{{PROJECT_ROOT_POSIX}}` | hooks/JSON 里使用的 `/` 路径 |
| `{{PROJECT_NAME}}` | 项目名 |
| `{{APP_REPO_DIR}}` | 业务代码仓库目录名 |
| `{{CURRENT_VERSION}}` | 当前版本锚点 |
| `{{CURRENT_SPRINT}}` | 当前 Sprint 锚点 |
| `{{INIT_TIME}}` | 实例化时间 |

## 项目区

`项目区/` 是模板根的本地项目区，用来放被模板管理或试装的项目实例。它解决“模板在哪里、项目放哪里”的边界问题：

- 模板本体进 `czxt` 仓库。
- 项目实体放 `项目区/本地实例/` 或项目自己的目录。
- 项目实体默认被 `.gitignore` 忽略。
- 模板仓库只追踪 `_模板.project.json`、`项目区/清单.md` 和相关规则；具体项目卡默认放在本机项目目录或 `项目区/本地实例/<项目>/`。

## 实例化到新项目

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\WGKJ\操作系统\实例化项目.ps1 `
  -ProjectRoot D:\WGKJ\新项目 `
  -ProjectName 新项目 `
  -AppRepoDir app `
  -CurrentVersion v0.1.0 `
  -CurrentSprint Sprint-1
```

默认不覆盖已有文件。需要覆盖时显式加 `-Force`。

## GitHub 连接

长期模板仓库目标：

```text
https://github.com/zlbdh/czxt.git
```

当前推荐阶段是先让模板根成为独立仓库并绑定 remote，再做首个受控提交。commit / push 仍按 `操作系统/01_架构/三类行为铁律.md` 和 `操作系统/07_完整工作流/git流程.md` 的 B 类条件执行。

产品化路线图见 [`操作系统/04_台账/长期产品化路线图.md`](操作系统/04_台账/长期产品化路线图.md)。

## 当前边界

- 本目录是“模板根”，不是业务项目根；模板根可以是 `czxt` 仓库。
- 业务代码、真实需求文档、发布产物、密钥和用户数据不属于操作系统模板。
- `项目区/本地实例/` 可放真实项目，但默认不提交。
- hooks 真源头仍在 `能力资产/tools/hooks`；运行时配置只做入口适配。
- 当前模板保留历史治理经验；项目实例化后应复制 `项目配置/_模板.project.json` 到项目自己的本机位置，再填写真实配置。
