---
name: mount-stale-defense
description: Cowork mount stale 检测 + 只读防御（ADR-025 落地 / 议题 BK 10 次实战 0 业务事故）
trigger: Cowork 端 ls/cat/head 异常 / 跨工具协作 / 闭环报告后起手
loaded: 条件加载
---

# Cowork mount stale 防御 SOP

## 触发场景

Cowork 跨工具协作（与 Codex / Claude Code）时，文件视图与真实文件系统不同步：
- 文件物理存在但 `head`/`cat` 报"No such file"
- `git status` 显示 modified 但文件内容看似正常
- 子目录 ls 缺文件（第二次自动刷新就出现）

## 5 步防御（ADR-025）

### Step 1: 起手必跑
```powershell
Set-Location "{{PROJECT_ROOT}}\{{APP_REPO_DIR}}"
git status --short      # working tree 状态
git log --oneline -3    # HEAD 完好性
```

Cowork bash 侧使用自身挂载路径或 `<项目根>/{{APP_REPO_DIR}}`，不要照抄 Windows `D:\...` 路径。

### Step 2: 见 dirty 不慌
- 上一棒闭环报告 push 成功 + HEAD hash 一致 → 疑似 mount stale；继续只读 `git diff`，不要直接判定“不是损坏”

### Step 3: 保留现场，不自动恢复
```powershell
git diff --stat
git diff -- <file>
```
如 dirty 来源不明，停手上报；只有 zlbdh 本次明确授权时才执行破坏性恢复。

### Step 4: 验证 mount sync
```powershell
Get-ChildItem src               # 文件物理存在
Get-Content 关键文件.js -TotalCount 5  # 内容可读
```

### Step 5: 留痕
普通只读核验不写 `状态.md`。仅出现新维度、跨 PM 状态交接，或项目 PM 主会话确认需要留痕时，再追加 PM 切换轨迹。

## 跨 RETRO 累积

- 议题 BK v1-v4 累积 10 次实战 / 0 业务事故
- ADR-025 永久关闭 + 元规则升级到第 9 条
- 议题 BK v4 监控（不需新 ADR）

## 真知识源

- `能力资产/rules/codex-push后防御.md`
- `Docs/3-开发文档/adr/ADR-025-Cowork-mount-stale防御机制永久化.md`
- 当前执行以元规则池 BK 的只读核验 / 禁默认 reset 为准；ADR-025 早期 reset 预批仅作历史背景
