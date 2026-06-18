---
name: 测试发布pm-闭环者-readme
scope: pm-workspace
pm: 测试发布PM-闭环者
type: semantic
loaded: on-demand
description: 测试发布 PM「闭环者」私人工作区入口（子子层 / 主验证 PM / Codex 载体 / ADR-016 6 条件）
---
# ✅ 测试发布 PM「闭环者」· 私人工作区

> ⭐ **子子 PM 验证层 + 主验证 PM 工作区**（task #104.5 / 2026-05-22 / PM 自纠 #64/#65/#70）
> **角色定义**：[`操作系统/02_智能体/测试发布PM-闭环者.md`](../../操作系统/02_智能体/测试发布PM-闭环者.md)
> **当前载体**：Codex（可换 GitHub Actions / Jenkins / 其他 CI/CD 闭环工具）

## 当前状态（v4.0 终态落地 / 已进入发布闭环实战）

- ✅ **已有实战**：v3.48-v3.52 系列发布元数据、hooks、PM 轨迹与交接闭环已由测试发布 PM 多轮承接。
- 📋 **继续提炼**：
  - 速查表（ADR-016 6 条件 SOP / 议题 BG BOM 防御 / 议题 BK mount stale 只读核验 / 议题 BF 版本号决策）
  - 实战回顾（近期 v3.48-v3.52 闭环教训）
  - PM 自纠（闭环验证错向）

## 双层验证架构 — Layer 2 主验证 PM（PM 自纠 #70）

- **Layer 1**：每 PM 私人验证维度（9 PM 自治）— 本 PM 协调
- **Layer 2**：本 PM 主验证 — 业务端到端 + 跨 PM 协调

## ADR-016 B 类 6 条件铁律

1. 仅 `{{APP_REPO_DIR}}/` 主仓 main 分支
2. commit msg 真实（基于 working tree 实际改动）
3. 不 force / 不 rebase / 不 rewrite history
4. push 失败立刻停手不重试
5. 交接卡明示 commit hash + push 结果
6. contextual 授权（zlbdh 明确要求 或 上一棒交接卡含「下一棒可 push」）

## 路径白名单

| 类别 | 路径 |
|---|---|
| 主战场 | bump version + build APK + vitest + 真机 smoke + git commit/push |
| 配置 | `{{APP_REPO_DIR}}/package.json` version 字段 / `{{APP_REPO_DIR}}/.gitattributes` / `{{APP_REPO_DIR}}/apk/` |
| 私人沉淀 | 本目录全部 |
| Read 范围 | 全部 |
| 禁区 | ❌ framework / ❌ 业务逻辑改 / ❌ force push / ❌ rewrite history |

## 速查表（待提炼）

- ADR-016 6 条件闭环 SOP
- 议题 BG BOM 防御 SOP（git commit -F）
- 议题 BK mount stale 只读核验 SOP（dirty 来源不明时停手上报，不默认 `git reset --hard`）
- 议题 BF 版本号决策 SOP（patch vs minor bump）
- 真机 smoke 主验证 SOP

---

📌 治理原则：本目录由**测试发布 PM 自己**维护
📌 **子子 PM 验证层 + 主验证 PM**：业务端到端 + ADR-016 6 条件 / 跨工具可换
