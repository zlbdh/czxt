---
name: pm-self-correction-96
scope: project
type: episodic
loaded: on-demand
description: PM 自纠 #96 — Cowork 沙箱跑 git reset --hard 清假 dirty 失败且残留 index.lock 污染真机 / ADR-025⊗ADR-033 交叉 / 2026-05-30 B-F7 v3.12.0 收档时
---

# PM 自纠 #96 — Cowork 沙箱 git 写操作 = 真机污染源

**触发**：2026-05-30 B-F7 v3.12.0 ship 收档真值复核时，`git status` 显示 3 文件假 dirty（议题 BK「Codex push 后 mount stale」+ ADR-033 mount 截断幻影）。PM 按 ADR-025 决策 2「预批 `git reset --hard HEAD` 清假 dirty」在 **Cowork 沙箱 bash** 执行 → 失败。

**失误链**：
1. `git reset --hard HEAD` → `error: unable to unlink ... Operation not permitted`（沙箱 mount 无真机 working tree 写权限）。
2. reset 中断 + 残留 `.git/index.lock`（空 0 字节锁），沙箱 `rm` 亦 `Operation not permitted` 清不掉。
3. 后果：真机 `.git/index.lock` 残留 → 挡真机下一棒 `git add/commit/reset`（报 index.lock exists）。**commit `4420167` = 远端安全没动**，但留了个真机要手动清的尾巴。

**Why**：误把 ADR-025「预批 git reset --hard」当成 Cowork 沙箱可执行。实则 ADR-033 已立「Cowork 沙箱真机写操作不可信」——`git reset --hard` 是**写 working tree**操作，沙箱 mount 对真机文件**无 unlink 权限**，失败还残留 lock。ADR-025 那条预批的隐含前提是「在有真机写权限的环境执行」（Claude Code / Codex 真机），不是 Cowork 沙箱。

**正确做法**：
1. **Cowork 沙箱对 git 只做只读诊断**：`git rev-parse HEAD` / `git status` / `git diff` / `git ls-tree` 判定 ship 是否安全 —— HEAD=origin/main=ship commit + 假 dirty diff 是截断幻影 + blob 在 commit 完整 → **ship 安全，不需要清 working tree**。
2. **清假 dirty / index.lock 必真机执行**（Claude Code 或 Codex）：`rm {{APP_REPO_DIR}}/.git/index.lock` +（可选）`git reset --hard HEAD`。
3. **沙箱可靠写通道 = file-tool（Read/Write/Edit）**，不是 bash mount；bash 仅可 `>>` append（不 unlink/不重写，故 mount 受限下仍可能成）。本次台账 4 处 Edit + 状态.md append 均经此通道成功落地。

**How to apply**：
- PM 收 Codex ship 卡做真值复核见 `git status` 假 dirty → **只读诊断三件套**（HEAD vs origin/main 对齐 + diff 方向是截断幻影 + blob 在 origin/main 完整）判 ship 安全，**不在沙箱跑任何 git 写命令**（reset/checkout/clean/add）。
- 真有 working tree 需复原 → 写进 ship 卡⑥「下一棒真机起手」交接，或当场交代 zlbdh 真机一行清理。
- 沙箱误跑 git 写残留 lock → **必须当场诚实交代 zlbdh + 给真机清理命令，不藏**。

**议题候选**：ADR-025 补注一条边界「git reset --hard HEAD 仅真机执行；Cowork 沙箱遇假 dirty 只读诊断判定 ship 安全即可，严禁沙箱 git 写命令」→ 起手时升 议题 BK/ADR-025 patch。

## 历史 PM 自纠系列（近）
- #92 verify 盲区 / #93 对外拍板回避 / #94 Edit 截断大文件尾部 / #95 handoff AC 矛盾
- **#96（本条）** — Cowork 沙箱 git reset --hard 清假 dirty 失败 + 残留 index.lock 污染真机

## 关联
- ADR-025 Cowork mount stale 防御（本条 = 其边界补丁：清假 dirty 必真机）
- ADR-033 大文件 mount 不可信（本条 = 其 git 写向延伸）
- 议题 BK Cowork mount stale
- [[project-{{APP_REPO_DIR}}-git-branch-main]] — git 操作前 verify
- [[feedback-pm-no-default-inference]] — 不默认推测（误以为 ADR-025 沙箱可跑）
