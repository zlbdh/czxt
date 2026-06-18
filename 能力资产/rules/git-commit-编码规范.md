---
name: git-commit-encoding-spec
scope: project
type: semantic
loaded: on-demand
description: git commit message 编码规范 — 走文件路径 + UTF-8 无 BOM 避免 subject 出 BOM 前缀，含验证机制与权限门禁（议题 BG）
---

# Git commit 编码规范（议题 BG 永久化 / PROP-024 Phase 3a）

> 适用对象：所有 git commit 操作（测试发布 PM「闭环者」/ 项目 PM「咪咪」授权收口 / zlbdh 本地 / 运营咪咪 / 未来扩展角色）
> 触发：议题 BG 实战 — v3.6.0 commit `d9fef8b` subject 出现 UTF-8 BOM 前缀 `M-oM-;M-?feat`（PowerShell `Out-File` 默认行为）
> 已防御实战：v3.6.1 `d7ba132` ✅ + v3.6.2 `f280780` ✅（连续 2 次 `git commit -F` 防御成功）

## 一、硬规则

### 0.0 先过 git 权限门禁

本文件只规定 commit message 编码，不授权任何人直接 commit / push。

每次执行 `git add` / `git commit` / `git push` 前，必须先确认：

- 只在 `{{APP_REPO_DIR}}/` 主仓 main 分支；
- 满足 ADR-016 6 条件（真实 commit message、不 force、不 rewrite、push 失败不重试、交接卡写 commit hash、具备 contextual 授权）；
- 不包含 API key、用户隐私、真机数据、历史 APK、操作系统本地 framework 文件；
- 如 working tree dirty 来源不明，先停手上报，不用 `git reset --hard` 自动恢复。

门禁详见 [`操作系统/07_完整工作流/git流程.md`](../../操作系统/07_完整工作流/git流程.md) 与 [`操作系统/01_架构/三类行为铁律.md`](../../操作系统/01_架构/三类行为铁律.md)。

### 1.1 写 commit msg 必走文件路径

```powershell
# ✅ 推荐：先写 commit-msg.txt，用 PowerShell 5.1/7 均可用的 UTF-8 无 BOM 写法
$msg = @'
feat(scope): subject 行

body 段第 1 行
body 段第 2 行
'@
[System.IO.File]::WriteAllText(
  (Join-Path (Get-Location) 'commit-msg.txt'),
  $msg,
  (New-Object System.Text.UTF8Encoding($false))
)
git add <paths>
git commit -F commit-msg.txt
# push 不在本编码规范授权范围内；如需 push，切测试发布 PM 并满足 ADR-016 6 条件
Remove-Item commit-msg.txt
```

### 1.2 严禁路径（会污染 commit subject 出 BOM）

```powershell
# ❌ 绝对不要：PowerShell 默认 UTF-8 with BOM
$msg | Out-File commit-msg.txt
git commit -F commit-msg.txt   # → subject 前 3 字节是 BOM
```

```powershell
# ❌ 严禁：直接 git commit -m "$msg"（多行 + 中文容易出问题）
git commit -m "feat(xxx): 中文 subject 多行 body"
```

### 1.3 多行 commit msg 处理

```powershell
# ✅ here-string 是 PowerShell 推荐方式
$msg = @'
... 任意多行 / 含特殊字符 / 含中文 ...
'@
```

```bash
# ✅ Linux/macOS / WSL — 直接 -F 文件路径
cat > commit-msg.txt <<'EOF'
... 任意内容 ...
EOF
git commit -F commit-msg.txt
```

## 二、验证机制

### 2.1 commit 前 verify

```powershell
# 看 commit-msg.txt 文件首 3 字节是否为 BOM (0xEF 0xBB 0xBF)
$bytes = [System.IO.File]::ReadAllBytes((Join-Path (Get-Location) 'commit-msg.txt'))
$bytes[0..([Math]::Min(2, $bytes.Length - 1))] | ForEach-Object { '{0:X2}' -f $_ }
# 输出应该不是 "EF BB BF"（无 BOM）
```

### 2.2 commit 后 verify（关键）

```bash
# Linux/bash 看 commit subject 是否含 BOM
git log -1 --pretty=%B | head -1 | cat -v
# 正常：直接显示 "feat(xxx): subject"
# 错误：显示 "M-oM-;M-?feat(xxx): subject" = BOM 前缀
```

## 三、议题 BG 修复路径（如已 push BOM commit）

按 ADR-016 + 「不 rewrite history」硬规则：**不 amend / 不 rebase**。已 push 的 BOM commit **不修复**，只在**下次 commit 时按本规范防御**。

## 四、检查清单（每次 commit 前必跑）

- [ ] commit msg 写进 `commit-msg.txt` 而非 `-m`
- [ ] `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))` 而非 `Out-File`
- [ ] `git commit -F commit-msg.txt` 而非 `git commit -m`
- [ ] 如 ADR-016 6 条件满足并完成 push，push 后跑 `git log -1 --pretty=%B | head -1 | cat -v` verify 首字符无 BOM
- [ ] commit 完 `Remove-Item commit-msg.txt`（不留临时文件）

## 五、与议题 BH/BO 联动（PROP-024 Phase 3 全包）

- 议题 BH（.bat CRLF）— 已永久化 `{{APP_REPO_DIR}}/.gitattributes`
- 议题 BO（build-apk.bat UTF-8 解析）— Codex Phase 3b 修脚本 + 加 PowerShell 兼容 `.ps1`

3 议题统一通过 PROP-024 Phase 3 治理。

## 六、永久化条件

- 议题 BG 已 2 次防御实战成功（v3.6.1 `d7ba132` + v3.6.2 `f280780`）
- 本规范作为 framework 元规则之一进入 `能力资产/rules/`
- RETRO-009 时议题 BG 可正式收档（如未来发现盲区 → 起新规则文件，不修本文件）

## 七、不要做（硬反例）

- ❌ 用 `Out-File` 或 `>` 重定向写 commit msg 文件
- ❌ 用 `git commit -m "多行中文"` 直接传字符串
- ❌ commit 后不 verify 直接 push（再发 BOM 也不知）
- ❌ 试图 `git commit --amend` 修复已 push 的 BOM commit（违反 ADR-016）
