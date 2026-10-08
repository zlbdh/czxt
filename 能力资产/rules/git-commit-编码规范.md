---
name: git-commit-encoding-spec
scope: project
type: semantic
loaded: on-demand
description: Commit message encoding through UTF-8 files without BOM, verification, and permission gates (issue BG).
---

# Git Commit Encoding (Issue BG / PROP-024 Phase 3a)

Applies to every Git commit: Test and Release PM “Closer,” authorized closure by Project PM “Mimi,” zlbdh locally, Operations PM “Operations Mimi,” and future roles.

Historical trigger: v3.6.0 commit `d9fef8b` had a UTF-8 BOM prefix, displayed as `M-oM-;M-?feat`, after PowerShell `Out-File` output. The file-based defense succeeded twice: v3.6.1 `d7ba132` and v3.6.2 `f280780`.

## 1. Mandatory rules

### 0.0 Pass Git permission gates first

This rule specifies message encoding. It does **not** authorize commits or pushes.

Before `git add`, `git commit`, or `git push`, confirm:

- Work is on the primary `{{APP_REPO_DIR}}/` repository's main branch.
- All six ADR-016 conditions hold: truthful message, no force, no history rewrite, no retry after push failure, commit hash in the handoff card, and contextual authorization.
- No API keys, user privacy, device data, historical APKs, or local operating-system framework files are included.
- If the origin of a dirty working tree is unknown, stop and report it; never automatically recover with `git reset --hard`.

See the [Git workflow](../../操作系统/07_完整工作流/git流程.md) and [three-class behavior rules](../../操作系统/01_架构/三类行为铁律.md).

### 1.1 Always pass the message through a file

```powershell
# UTF-8 without BOM, compatible with PowerShell 5.1 and 7.
$msg = @'
feat(scope): subject line

First body line
Second body line
'@
[System.IO.File]::WriteAllText(
  (Join-Path (Get-Location) 'commit-msg.txt'),
  $msg,
  (New-Object System.Text.UTF8Encoding($false))
)
git add <paths>
git commit -F commit-msg.txt
# Pushing requires the Test and Release PM and all six ADR-016 conditions.
Remove-Item commit-msg.txt
```

### 1.2 Prohibited methods

The historical PowerShell default below can introduce a BOM:

```powershell
# Do not use this method.
$msg | Out-File commit-msg.txt
git commit -F commit-msg.txt   # The subject may begin with three BOM bytes.
```

Do not pass a multiline or non-ASCII message directly with `-m`:

```powershell
# Prohibited: direct string passing is fragile for multiline/non-ASCII content.
git commit -m "feat(xxx): subject and multiline body"
```

### 1.3 Multiline messages

```powershell
# Use a PowerShell here-string.
$msg = @'
... multiline content, special characters, and Unicode ...
'@
```

```bash
# Linux/macOS/WSL: pass the file with -F.
cat > commit-msg.txt <<'EOF'
... message content ...
EOF
git commit -F commit-msg.txt
```

## 2. Verification

### 2.1 Before committing

```powershell
# Inspect the first three bytes for EF BB BF.
$bytes = [System.IO.File]::ReadAllBytes((Join-Path (Get-Location) 'commit-msg.txt'))
$bytes[0..([Math]::Min(2, $bytes.Length - 1))] | ForEach-Object { '{0:X2}' -f $_ }
# The output must not be EF BB BF.
```

### 2.2 After committing

```bash
# Inspect the subject for a BOM.
git log -1 --pretty=%B | head -1 | cat -v
# Correct: feat(xxx): subject
# Incorrect: M-oM-;M-?feat(xxx): subject
```

## 3. Already-pushed BOM commits

Under ADR-016 and the no-history-rewrite rule, **do not amend or rebase**. Leave the pushed commit unchanged and prevent a recurrence in the next commit.

## 4. Checklist for every commit

- [ ] Message written to `commit-msg.txt`, not passed with `-m`.
- [ ] Written with `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))`, not `Out-File`.
- [ ] Commit uses `git commit -F commit-msg.txt`.
- [ ] If all six ADR-016 conditions were met and the push completed, run `git log -1 --pretty=%B | head -1 | cat -v` afterward to confirm no BOM prefix.
- [ ] Remove the temporary message file with `Remove-Item commit-msg.txt` after committing.

## 5. Related issues (PROP-024 Phase 3)

- BH, `.bat` CRLF: permanent rule in `{{APP_REPO_DIR}}/.gitattributes`.
- BO, `build-apk.bat` UTF-8 parsing: Codex Phase 3b script fix and compatible PowerShell `.ps1`.

All three issues are governed together under PROP-024 Phase 3.

## 6. Permanent-rule criteria

- Two successful BG defenses: v3.6.1 `d7ba132` and v3.6.2 `f280780`.
- This specification is a framework meta-rule in `能力资产/rules/`.
- BG may formally close at RETRO-009. A later blind spot requires a new rule file rather than modifying this historical rule.

## 7. Prohibited examples

- Writing message files with `Out-File` or `>` redirection.
- Passing multiline Unicode messages directly through `git commit -m`.
- Pushing without verifying the newly created commit.
- Using `git commit --amend` to repair an already-pushed BOM commit, contrary to ADR-016.
