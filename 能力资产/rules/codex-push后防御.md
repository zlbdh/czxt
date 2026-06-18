---
name: codex-push-post-defense
scope: project
type: semantic
loaded: on-demand
description: Codex push 后 working tree dirty / 真代码删除 / index 损坏的双 verify 防御规则与非破坏诊断路径（议题 BK）
---

# Codex push 后防御机制（议题 BK 永久化 / PROP-024 Phase 2）

> 适用对象：项目 PM「咪咪」（任一运行时继续工作的 PM）
> 触发场景：Codex 报告 push 完成（commit `xxx` to `origin/main`）后，PM 在任一运行时继续操作前
> 议题 BK 实战累积：2 次（v3.6.1 + v3.6.2 同模式）— 历史曾高频复现；当前作为长期防御规则保留

## 一、症状识别

Codex push 完成报告「working tree clean / up to date with origin/main」，但另一运行时或本机 shell 查看实际状态可能出现：

| 症状 | 实战表现 |
|---|---|
| working tree dirty | `git status --short` 显示 modified 文件 |
| 真代码删除 | `git diff` 显示业务代码行被删（如 v3.6.1 Chat.jsx 删 143 行）|
| 文件截断 | 末尾 `\ No newline at end of file` + 空格（如 v3.6.2 Profile.jsx）|
| `.git/index` 损坏 | git 命令报 `bad signature 0x00000000` |

## 二、双 verify 硬规则（PM 起手必跑）

### 2.1 Codex push 报告收到后立即跑

```powershell
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" status --short    # 看是否 dirty
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1  # 看 HEAD 是否对应 Codex 报告的 commit hash
```

如 `git status` 不 clean → 立即跳 §三 非破坏诊断路径；不要自动恢复。

### 2.2 PM 任何操作前再 verify 一次

任何运行时内 Edit / Write / apply_patch / mv 操作前，跑一次 §2.1 确保起手干净。

## 三、非破坏诊断路径（按严重度递增）

### 3.1 基础诊断（最常见 — v3.6.2 同模式）

```powershell
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" status --short                 # 确认 dirty 文件
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" diff -- <file> | Select-Object -First 30
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1               # 看 HEAD 是否对应 Codex 报告
```

⭐ **当前硬规则**：这里不再默认执行 `git reset --hard HEAD`。即使历史 ship 卡曾写过预批，也必须按当前 Codex / 项目安全边界处理：先停手、保留现场、向 zlbdh 报告 dirty 文件和 diff 摘要；只有用户在本次上下文里明确要求恢复，才可执行破坏性恢复命令。

### 3.2 index 损坏诊断（罕见 — v3.6.1 同模式）

```powershell
# 如 git 命令报 "bad signature 0x00000000 / fatal: index file corrupt"
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" status              # 记录原始报错
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1    # 若可用，记录 HEAD
```

不要自动 `rm .git/index`，也不要接着 `git reset --hard`。这两步会改写 git 工作区状态，必须等 zlbdh 明确授权。

### 3.3 HEAD 完整性 verify（每次必跑）

```powershell
git -C "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}" log --oneline -1
# 输出应该对应 Codex push 报告的 commit hash
# 如不一致 → 严重问题，立即 ask zlbdh
```

## 四、根因推测（仍待 PROP-024 Phase 2 调查）

按可能性排序：

1. **跨运行时 mount/cache + Codex 并行写入 `.git` 冲突**（历史最常见）
2. WSL/Linux 与 Windows 路径混用同步问题
3. Codex 在 push 后某个工具自动操作触发回滚
4. 文件系统 cache 不一致

调查方向 — Codex push 时让其他运行时完全停止 file 操作 + 复跑 → 看是否再现。

## 五、防御实战表

| 实战 | 时间 | 症状 | 恢复方式 |
|---|---|---|---|
| #1 | 2026-05-19 12:00（v3.6.1 push 后）| 5 文件 modified + index 损坏 | 历史曾用 `rm .git/index + git reset + git reset --hard HEAD` 恢复；现规则改为先停手授权 |
| #2 | 2026-05-19 14:45（v3.6.2 push 后）| Profile.jsx 截断（删 7 行）| 历史曾用 `git reset --hard HEAD` 恢复；现规则改为先停手授权 |

## 六、与议题 BG/BH/BO 联动

- 议题 BG（commit BOM）— 已 `能力资产/rules/git-commit-编码规范.md` 永久化
- 议题 BH（.bat CRLF）— 已 `{{APP_REPO_DIR}}/.gitattributes` 永久化
- 议题 BO（build-apk.bat 解析）— PROP-024 Phase 3b Codex 修脚本

议题 BK 与上述 3 议题独立但通过 PROP-024 综合治理同步推进。

## 七、收档条件

- ≥3 次 Codex push 后跑双 verify + 0 再现 → 议题 BK 收档（根因找到 / 修复机制有效）
- 或 — ≥3 次再现但都被本规则捕获 + 业务零事故 → 议题 BK 部分收档（防御有效但根因未知，标 v1 长期监控）

## 八、不要做（硬反例）

- ❌ Codex push 报告后直接做 Edit / Write / apply_patch 操作（不先 verify）
- ❌ working tree dirty 时继续业务操作（污染会扩散）
- ❌ 默认执行 `git reset --hard` / `rm .git/index` / 删除文件等破坏性恢复命令（必须等 zlbdh 本次明确授权）
- ❌ 试图理解 Codex 为什么报 clean 但实际 dirty（先保留现场并报告，再调查）
- ❌ 跳过 §2 双 verify 步骤（议题 BK 防御 100% 依赖前置 verify）
