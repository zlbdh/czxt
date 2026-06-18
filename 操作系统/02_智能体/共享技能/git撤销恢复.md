---
name: git-recovery
description: git 损坏 / .git/index 异常 / working tree dirty 紧急恢复 SOP。Codex push 后 Cowork mount stale 实战 10 次累积。
trigger: git 损坏 / .git/index bad signature / working tree 莫名 dirty / mount stale
loaded: 条件加载
---

# git 撤销恢复 SOP

## 触发场景

1. Codex push 后 Cowork 端 `git status --short` 显示文件 dirty（但内容看似正常）
2. `.git/index` 报 `bad signature 0x00000000` 错
3. mount stale — 文件物理存在但 head/cat 报"No such file"
4. 真机 smoke 失败紧急回滚

## 5 步紧急诊断（议题 BK / ADR-025）

### Step 1: 诊断现状
```powershell
Set-Location "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}"
git status --short
git log --oneline -3
git diff --stat
git diff -- <file>
```

### Step 2: 判断是否 mount stale
- HEAD commit hash 与报告一致 + `git diff` 为空或可解释 → 疑似 mount stale，继续只读核验
- HEAD 一致但 `git diff` 有真实内容 → 真实 dirty，来源不明先停手上报
- HEAD 不一致或 index 报错 → 可能真损坏，跳 Step 4

### Step 3: mount stale 处理
```powershell
git diff --stat          # 只读确认 dirty 范围
git diff -- <file>       # 只读查看具体差异
```
如 dirty 来源不明，停手上报，不自动恢复。

### Step 4: .git/index 损坏诊断
```powershell
Set-Location "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}"
git status               # 记录原始报错
git log --oneline -3     # 如可用，记录 HEAD
```
不要自动 `rm .git/index` 或 `git reset --hard`，必须等 zlbdh 本次明确授权。

### Step 5: 验证完整性
```powershell
git status               # 记录当前状态
git log --oneline -3     # HEAD 完好
Get-ChildItem src         # 业务文件物理存在 + 可读
```

## 真知识源

- `能力资产/rules/codex-push后防御.md` — ADR-025 落地
- `Docs/3-开发文档/adr/ADR-025-Cowork-mount-stale防御机制永久化.md`
- 议题 BK 跨 Sprint 累积 10 次实战
- 当前执行以元规则池 BK 的只读核验 / 禁默认 reset 为准；ADR-025 早期 reset 预批仅作历史背景
