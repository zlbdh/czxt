# ADR-016 · AI git 权限下放（PROP-012）

- **状态**：现行
- **日期**：2026-05-11
- **决策人**：zlbdh
- **关联**：[PROP-012](../../../确认改动/已审批/已完成/PROP-012-2026-05-11-AI-git权限下放.md) · 修订 [ADR-008](ADR-008-框架自动化升级.md) / [ADR-010](ADR-010-框架自动化v3-9隐患全封堵.md) 中关于 AI 边界的部分

> ⚠️ **当前覆盖说明（2026-06-15）**：本文的 git commit / push B 类 6 条件仍是现行基础。AI 配置分类已被 ADR-022 与 [`../../../操作系统/01_架构/三类行为铁律.md`](../../../操作系统/01_架构/三类行为铁律.md) 细化：`{{APP_REPO_DIR}}/.env.local` 本机 baseUrl/model/apiKey 配置属 B 类护栏；真实密钥外传、写 tracked 文件、分享真实 key 属 C 类。

## 背景

PROP-011（交接区机制）实施后，跨工具协作流畅度大幅提升，但暴露出**新的工作流摩擦点**：

### 3 次违规/破例信号（2026-05-11 一天内）

| 时间 | 事件 | 性质 |
|---|---|---|
| 15:30 | 「清债 push」zlbdh 明确要求 Codex 跑 git push | 一次性破例 |
| 16:00 | F-002 smoke 完成后 zlbdh 再次要求 Codex 跑 git push | 第二次同方向反馈 |
| 16:05 | Cowork PM 用 Edit 改 `{{APP_REPO_DIR}}/package.json` version 2.3.0 → 2.7.0，事后才发现这是 C 类第 1 条 | PM 自己违规 |

### 痛点

- zlbdh 角色是 PM/Owner，不是 git 执行者；每次 push 让他手动 = 工作流摩擦
- C 类「永不」假设的是「不可逆 + 高风险」，但 {{APP_REPO_DIR}}/ 仓库实际：
  - 私人仓库（不公开）
  - zlbdh 是 owner（可 force-push 回滚）
  - 没有 collaborator（不会影响他人）
  - 实际风险：低
- 让 AI 出 APK 但禁止 bump version = 流程断点
- 破例 ≥ 2 次 = 规则跟现实脱节

## 决策

把以下行为从 C 类（永不能动）**下放到 B 类（条件性 AI 可动）**：

| 原 C 类 | 新分类 | 条件 |
|---|---|---|
| 改 `package.json` version | **B 类** | 配套 APK 发版任务可执行；单独 bump 仍需 ask |
| git commit / push（main 分支常规）| **B 类** | 必满足 6 条件 |

### B 类 git push 6 条件

1. ✅ 仅 `{{APP_REPO_DIR}}/` 主仓 main 分支
2. ✅ commit message 真实（基于 working tree 实际改动，不虚标）
3. ✅ 不 force / 不 rebase / 不 rewrite history
4. ✅ push 失败立刻停手 + 写交接卡报错 + 不重试
5. ✅ 交接卡明示 commit hash + push 结果
6. ✅ contextual 授权（zlbdh 明确要求 / 或上一棒交接卡含「下一棒可 push」）

任何一条违反 → 立刻停手 + 写交接卡 + 等 zlbdh 决策。

### 保留在 C 类的硬护栏

| C 类条款 | 理由 |
|---|---|
| `git push --force` / force push | 重写历史不可逆 |
| `git rebase` 已 push 的 commit | 同上 |
| 删除分支 / 删除 tag / 操作其他 fork-remote | 不可逆 / 越界 |
| 打 git tag / 推 release | 发版决策 |
| 上传 APK 到分发渠道 | 发布决策 |
| AI 配置 baseUrl / apiKey | 历史口径；当前 `.env.local` 本机配置属 B 类护栏，真实 key 外传 / 写 tracked 文件属 C 类 |
| 删除用户笔记 / 备份 / 数据 | 数据归属 |
| 改 `apk/` 历史 / `Docs/6-历史归档/` | 历史不动 |
| 伪造数据 | 诚实第一 |

## 实施细节

| 阶段 | 文件 | 改动 |
|---|---|---|
| P1 | `agent/agents/AI边界.md` | C 类移除 version + 添加 force push 硬护栏；B 类新增 git commit/push + version bump 行；L1-L4 对照表更新 |
| P2 | `agent/workflows/实施循环.md` | DoD 端能力对照表 git commit/push 行 ❌ → ✅ 条件性；新增 force push 行 ❌；4 端 DoD 段更新；加 6 条件速查 |
| P3 | 本 ADR + ADR README 索引 | — |
| P4 | `确认改动/README.md` 计数 + 已完成列表 + PROP-012 收档 | — |

## 后果

### 收益
- ✅ 消除工作流摩擦（zlbdh 不再每次手动 push）
- ✅ Codex / Claude Code / Cowork 都能完成完整闭环（含 commit/push）
- ✅ 规则跟实际工作流对齐，不再需要破例
- ✅ 保留硬护栏：force push / 发版决策 / 私钥 / 用户数据 仍 C 类

### 代价
- ❌ AI 需要自律遵守 6 条件（依赖交接卡 ⑤ 复核）
- ❌ contextual 授权边界模糊（需在交接卡明示）

### 风险（已防）
- ✅ commit msg 虚标 → 6 条件 ②「真实」+ ⑤「交接卡明示 hash」事后核查
- ✅ AI 误判授权 → 6 条件 ⑥ 必须明示授权来源
- ✅ push 失败连续重试 → 6 条件 ④ 立刻停手
- ✅ 误操作其他分支 / force → 6 条件 ①③ 硬限定

## 这是项目第几个 L3+

| # | 改动 | ADR |
|---|---|---|
| 12 | **PROP-012 AI git 权限下放**（本 ADR）| **ADR-016** |

PROP-012 是 RETRO-004 后第 2 个新 L3+。下一个 RETRO-005 在第 14 个 L3+ 完成时触发（还差 2 个）。

## 一句话

ADR-016 把 git push 从「永不」改成「条件性可」，让 AI 真正能完成开发-测试-发布闭环，同时用 6 条件硬护栏防止越界。
