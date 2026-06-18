---
name: git-flow
scope: project
type: procedural
loaded: on-demand
description: git 仓库边界 / A-B-C 权限 / commit-push 6 条件 / message / 分支与 tag 规则
---

# 工作流：git 流程

本文件区分两层 git 边界：

| 层级 | 仓库根 | 用途 |
|---|---|---|
| 操作系统模板仓库 | 模板根（当前目标 remote：`https://github.com/zlbdh/czxt.git`） | 维护 `操作系统/`、`能力资产/`、`PM工作区/`、`项目配置/`、`项目区/` 等模板本体 |
| 项目实例业务仓库 | `{{PROJECT_ROOT}}\{{APP_REPO_DIR}}\`（remote 通常为 `https://github.com/zlbdh/{{APP_REPO_DIR}}.git`） | 维护业务代码、构建产物索引和业务发布历史 |

实例化到业务项目后，项目根 `{{PROJECT_ROOT}}\` 是否是 git 仓库以项目卡片和真实 `.git` 为准；历史默认是业务仓库在 `{{APP_REPO_DIR}}/`，操作系统层在项目根旁路维护。模板产品化阶段则允许模板根作为独立仓库进入 `czxt`。

---

## 谁能动 git？（ADR-016 后）

| 操作 | A 类 自动 | B 类 条件性 | C 类 永不 |
|---|---|---|---|
| git status / log / diff（只读）| ✅ AI 自动 | — | — |
| git commit / push（main 分支常规）| — | ✅ B 类 6 条件 | — |
| 改 `package.json` version | — | ✅ 配套 APK 任务 | — |
| force push / rebase 已 push 的 commit | — | — | ❌ |
| 删除分支 / 删 tag | — | — | ❌ |
| 常规版本 tag / push tag（配套 APK 发版）| — | ✅ B 类发版闭环条件 | — |
| 删 tag / 改 tag / 推分发渠道 release | — | — | ❌ zlbdh 专属 |

→ 详见 [`角色边界.md`](../01_架构/角色边界.md) + [`ADR-016`](../../Docs/3-开发文档/adr/ADR-016-AI-git权限下放.md)。

---

## B 类 git commit/push 6 条件（ADR-016）

AI 跑 git 必满足以下全部：

1. ✅ 仅当前目标仓库 main 分支（业务发布默认 `{{APP_REPO_DIR}}/`；模板维护默认模板根）
2. ✅ commit message 真实（基于 working tree 实际改动，不虚标 PROP/ADR/feature）
3. ✅ 不 force / 不 rebase / 不 rewrite history
4. ✅ push 失败立刻停手 + 写交接卡报错 + 不重试
5. ✅ 交接卡明示 commit hash + push 结果（事后可核查）
6. ✅ contextual 授权（zlbdh 明确要求 / 或上一棒交接卡含「下一棒可 push」字样）

任一违反 → 立刻停手 + 写交接卡 + 等 zlbdh 决策。

---

## Commit message 格式

```
<type>(<scope>): <一句话总结>

- 改动点 1
- 改动点 2
- 测试 / APK 结果（如有）
```

### type 词典

| type | 用途 | 例 |
|---|---|---|
| `feat` | 新功能 | `feat(sprint-1): F-002 健康饮食/训练月历完成` |
| `fix` | bug 修复 | `fix: 修复月历点格抽屉空数据崩溃` |
| `refactor` | 重构无功能变化 | `refactor: 抽离 HealthMeals 子组件` |
| `docs` | 仅文档 | `docs: 补 git流程.md 跟 ADR-016 对齐` |
| `chore` | 杂项（version bump / 依赖更新）| `chore: bump version 2.7.0 → 2.8.0` |
| `test` | 仅测试 | `test: 加 LedgerCalendar 颜色梯度边界测试` |

### scope（可选）

- `sprint-N` — Sprint 标识（业务 feature）
- 模块名 — `accounting` / `health` / `timeline` 等
- 元规则 — `framework` / `agent`（模板仓库可用；业务仓库按业务模块名）

示例要点：标题写真实 feature / fix / refactor；正文列改动点、测试结果、APK 路径和 smoke 结论，禁止虚标 PROP/ADR/feature。

---

## 分支策略

**单 main 分支**（自用 App，无协作者）

- ✅ 所有改动直接进 main
- ❌ 不开 feature branch（业务节奏快 + 无 review 流程，多分支徒增复杂度）
- ❌ 不开 dev 分支（main 就是 dev，没区别）
- 例外：未确定实验可临时开 `experiment/*`，验证后把有效改动落回 main；实验分支清理由 zlbdh 手动决定，AI 不删分支

---

## Push 时机

每个 feature 完整闭环（代码 + 测试 + APK + smoke）后由测试发布 PM「闭环者」push（playbook 见 [`../02_智能体/测试发布PM-闭环者.md`](../02_智能体/测试发布PM-闭环者.md)）。

不是每天结束、不是每个 PROP 收档 — **按业务里程碑**。

| 时机 | 是否 push |
|---|---|
| 开发 PM「实施者」完成代码 + 测试三层过（当前执行载体：Claude Code） | ❌ 不 push（留给测试发布 PM「闭环者」跑闭环） |
| 测试发布 PM「闭环者」出 APK + smoke 通过（当前执行载体：Codex） | ✅ push |
| smoke 发现 bug 修完 | ✅ push（修复 commit）|
| 单纯 framework 文档改（操作系统/ / 能力资产/ / Docs/ / 确认改动/）| ❌ 不进 git（这些不在 {{APP_REPO_DIR}}/ 仓库）|

---

## Tag 规则

常规版本闭环允许打版本 tag，但必须绑定测试发布 PM「闭环者」发布闭环。

允许条件：
- 已完成代码、测试、build、APK、smoke；
- `package.json` 版本、APK 命名、交接卡版本一致；
- tag 格式为 `vX.Y.Z`；
- 交接卡明示 commit hash、tag、push 结果；
- 不删除、不改写、不移动已有 tag。

不允许：
- 删 tag / 改 tag / 重新指向已存在 tag；
- 推 GitHub Release 或任何分发渠道 release（仍由 zlbdh 决定）。

---

## AI 端 git 实操示例（速记）

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
git branch --show-current      # 必须是 main
git remote get-url origin      # 必须是 zlbdh/{{APP_REPO_DIR}}
git status --short
git diff --stat
# 确认交接卡或用户上下文已给 contextual 授权
git add <本轮文件1> <本轮文件2>
git commit -m "<type>(<scope>): <真实改动一句话>"
git push                       # 失败立刻停，不重试
git log -1 --oneline           # 记录 commit hash
git status --short             # working tree clean
```

---

## 关联

- [`操作系统/01_架构/角色边界.md`](../01_架构/角色边界.md) — A/B/C 三类边界详细规则
- [`Docs/3-开发文档/adr/ADR-016-AI-git权限下放.md`](../../Docs/3-开发文档/adr/ADR-016-AI-git权限下放.md) — 本规则的决策记录
- [`操作系统/07_完整工作流/实施循环-附录.md`](实施循环-附录.md) DoD 端能力对照表 — 哪个工具能跑 git
- [`操作系统/03_交接/交接卡格式.md`](../03_交接/交接卡格式.md) — 交接卡 ⑤ 警戒段是 6 条件 ⑤ 复核点
