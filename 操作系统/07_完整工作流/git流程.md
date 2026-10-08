---
name: git-flow
scope: project
type: procedural
loaded: on-demand
description: Git repository boundaries, Class A/B/C permissions, six commit/push conditions, commit messages, branches, and tags.
---

# Workflow: Git Flow

This document distinguishes two repository boundaries:

| Layer | Repository root | Purpose |
|---|---|---|
| Operating system template repository | Template root; current target remote: `https://github.com/zlbdh/czxt.git` | Maintain the template itself, including `操作系统/`, `能力资产/`, `PM工作区/`, `项目配置/`, and `项目区/` |
| Project instance application repository | `{{PROJECT_ROOT}}\{{APP_REPO_DIR}}\`; remote is typically `https://github.com/zlbdh/{{APP_REPO_DIR}}.git` | Maintain application code, build-output indexes, and application release history |

After initialization into an application project, whether `{{PROJECT_ROOT}}\` is a Git repository is determined by the project card and actual `.git` directory. Historically, the default application repository was `{{APP_REPO_DIR}}/`, with the operating system maintained separately at the project root. Template productization allows the template root to be an independent `czxt` repository.

---

## Who may operate Git? After ADR-016

| Operation | Class A: automatic | Class B: conditional | Class C: never |
|---|---|---|---|
| Read-only `git status`, `log`, or `diff` | ✅ AI may act automatically | — | — |
| Ordinary `git commit` / `push` on main | — | ✅ Six Class B conditions | — |
| Change `package.json` version | — | ✅ As part of an APK task | — |
| Force push or rebase pushed commits | — | — | ❌ |
| Delete a branch or tag | — | — | ❌ |
| Ordinary version tag / push tag as part of an APK release | — | ✅ Class B release-completion conditions | — |
| Delete/change a tag or publish a distribution-channel release | — | — | ❌ Reserved for zlbdh |

See [role boundaries](../01_架构/角色边界.md) and [ADR-016](../../Docs/3-开发文档/adr/ADR-016-AI-git权限下放.md).

---

## Six Class B Git commit/push conditions: ADR-016

AI must satisfy all of the following:

1. ✅ Only the current target repository's main branch. Application releases default to `{{APP_REPO_DIR}}/`; template maintenance defaults to the template root.
2. ✅ Truthful commit messages based on actual working-tree changes; do not falsely label PROP, ADR, or feature work.
3. ✅ No force, rebase, or history rewriting.
4. ✅ If a push fails, stop immediately, record the error in a handoff card, and do not retry.
5. ✅ The handoff card explicitly records the commit hash and push result for later verification.
6. ✅ Contextual authorization: an explicit instruction from zlbdh, or an earlier handoff explicitly allowing the next owner to push.

If any condition is violated, stop immediately, write a handoff card, and wait for zlbdh's decision.

---

## Commit message format

```text
<type>(<scope>): <one-sentence summary>

- Change 1
- Change 2
- Test / APK results, if applicable
```

### Type dictionary

| Type | Purpose | Example |
|---|---|---|
| `feat` | New feature | `feat(sprint-1): complete F-002 nutrition and workout calendar` |
| `fix` | Bug fix | `fix: prevent empty-data crash in calendar day drawer` |
| `refactor` | Refactor without changing behavior | `refactor: extract HealthMeals component` |
| `docs` | Documentation only | `docs: align Git flow with ADR-016` |
| `chore` | Maintenance such as version bumps or dependency updates | `chore: bump version 2.7.0 → 2.8.0` |
| `test` | Tests only | `test: cover LedgerCalendar color-gradient boundaries` |

### Scope: optional

- `sprint-N`: Sprint identifier for an application feature.
- Module name: `accounting`, `health`, `timeline`, etc.
- Meta-rules: `framework` or `agent` in the template repository; use business module names in the application repository.

The title must identify the actual feature, fix, or refactor. The body lists changes, test results, APK path, and smoke conclusion. False PROP/ADR/feature labels are prohibited.

---

## Branch strategy

**Single main branch**: personal-use app with no collaborators.

- ✅ All changes go directly to main.
- ❌ No feature branches: fast application work and no review process make multiple branches unnecessarily complex.
- ❌ No dev branch: main is the development branch.
- Exception: uncertain experiments may temporarily use `experiment/*`. After verification, put valid changes onto main. zlbdh decides experiment-branch cleanup manually; AI must not delete branches.

---

## When to push

The Test and Release PM “Closer” pushes after a feature's full lifecycle is complete: code, tests, APK, and smoke. See the [playbook](../02_智能体/测试发布PM-闭环者.md).

Push according to **business milestones**, rather than at every day's end or every PROP closure.

| Milestone | Push? |
|---|---|
| Development PM “Implementer” completes code and all three test layers; current runtime: Claude Code | ❌ Do not push; leave release completion to the Test and Release PM “Closer” |
| Test and Release PM “Closer” produces the APK and smoke passes; current runtime: Codex | ✅ Push |
| A bug discovered in smoke testing is fixed | ✅ Push the fix commit |
| Framework documentation only: `操作系统/`, `能力资产/`, `Docs/`, `确认改动/` | ❌ Do not add to Git; these are outside the `{{APP_REPO_DIR}}/` repository |

---

## Tag rules

Ordinary version tags are allowed only as part of the Test and Release PM “Closer” release lifecycle.

Required conditions:
- Code, tests, build, APK, and smoke are complete.
- `package.json`, APK naming, and the handoff card agree on the version.
- The tag uses `vX.Y.Z`.
- The handoff explicitly records the commit hash, tag, and push result.
- No existing tag is deleted, rewritten, or moved.

Prohibited:
- Delete, change, or retarget an existing tag.
- Publish a GitHub Release or release through any distribution channel; zlbdh still decides these actions.

---

## AI Git command quick reference

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
git branch --show-current      # Must be main
git remote get-url origin      # Must be zlbdh/{{APP_REPO_DIR}}
git status --short
git diff --stat
# Confirm contextual authorization from the handoff or user instructions.
git add <current-file-1> <current-file-2>
git commit -m "<type>(<scope>): <truthful one-sentence change>"
git push                       # On failure, stop immediately; do not retry.
git log -1 --oneline           # Record the commit hash.
git status --short             # Working tree clean.
```

---

## Related references

- [Role boundaries](../01_架构/角色边界.md) — detailed Class A/B/C rules.
- [ADR-016](../../Docs/3-开发文档/adr/ADR-016-AI-git权限下放.md) — the decision behind this rule.
- [Implementation appendix](实施循环-附录.md), DoD runtime capability table — which tools can operate Git.
- [Handoff format](../03_交接/交接卡格式.md) — warning section ⑤ is the verification point for condition ⑤.
