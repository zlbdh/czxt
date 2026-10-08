---
name: build-apk
scope: project
type: procedural
loaded: on-demand
description: APK build procedure — automatic archiving with Windows build-apk.ps1, GitHub Actions fallback, device smoke testing, release signing, and recovery.
---

# Skill: Build an APK

## Recommended entry point

For Codex on a local Windows machine, prefer:

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-apk.ps1
```

The output is automatically archived at:

```text
{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-debug.apk
```

`build-apk.bat` only builds and assembles, then asks you to copy the output manually. Use `build-apk.ps1` for automatic archiving.

## Standard message asking zlbdh to build an APK

After all tests pass, use the following message. Every number must come from this run's actual `npm test -- --run` / `npm run build` output; never reuse historical example results.

```text
QA passed: <N>/<N> tests / Vite build: <N> modules / <duration>
Version X.Y.Z is ready.

Please build the APK on Windows:

powershell -NoProfile -ExecutionPolicy Bypass -File {{PROJECT_ROOT}}\{{APP_REPO_DIR}}\build-apk.ps1

Output: {{APP_REPO_DIR}}\apk\{{PROJECT_NAME}}-vX.Y.Z-debug.apk
```

## GitHub Actions fallback

If zlbdh does not currently have Windows access but has a GitHub repository:

1. Check all six commit/push requirements in the [Git workflow](../../操作系统/07_完整工作流/git流程.md) and ADR-016.
2. Only the Test and Release PM “Closer” may commit and push, after the requirements are met and zlbdh explicitly authorizes the action.
3. Open GitHub → Actions → “Build Android APK” → manually select `Run workflow` → wait 8–12 minutes → download the APK from Artifacts.

The current `build-apk.yml` uses only `workflow_dispatch`; `git push` does not automatically trigger an APK build.

This skill intentionally omits standalone copy-and-paste `git add`, `git commit`, and `git push` commands to preserve the ADR-016 approval boundary.

## Required smoke test after installation

Exercise the core flows listed in `Docs/4-测试文档/手动测试用例.md`.

Ask zlbdh for screenshots of:

- Home
- Health
- Accounting
- Timeline
- Profile

Save them under `Docs/4-测试文档/smoke截图/vX.Y.Z-任务名/`.

## Release APK: vX.Y.Z, subject to zlbdh's decision

For the first release, complete every step below.

### 1. Create a keystore

```cmd
keytool -genkey -v -keystore zlbdh-release.keystore ^
  -alias mimi -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Configure build.gradle

See the release-signing section in `Docs/5-运维文档/APK打包指南.md`.

### 3. Build the release

```cmd
cd android
gradlew.bat assembleRelease
```

### 4. Copy the output to {{APP_REPO_DIR}}/apk/

```text
{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-release.apk
```

### 5. Handle the tag within the release process

Only after the code, tests, build, APK, smoke results, version, and handoff card agree, and all six ADR-016 requirements are met, may the Test and Release PM “Closer” handle a normal version tag under the [Git workflow](../../操作系统/07_完整工作流/git流程.md) and [release workflow](../../操作系统/07_完整工作流/发布流程.md). Never delete, rewrite, or move an existing tag.

This skill omits standalone copy-and-paste tag and push commands to preserve the complete release process.

## Emergency recovery after a failed APK build or installation

If the installed version crashes or loses data:

1. Ask zlbdh to reinstall the previous development APK immediately:
   - `{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-debug.apk`
2. Restore data from an earlier backup if one exists.
3. Mimi fixes the bug and builds the next patch version's development APK.
