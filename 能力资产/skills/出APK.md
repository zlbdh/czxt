---
name: build-apk
scope: project
type: procedural
loaded: on-demand
description: 出 APK 的标准 SOP — Windows build-apk.ps1 自动归档 / GitHub Actions 备用 / 装机 smoke / release 签名 / 失败回退。
---

# 技能：出 APK

## 当前推荐入口

Codex / Windows 本机优先跑：

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-apk.ps1
```

产物会自动归档到：

```text
{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-debug.apk
```

`build-apk.bat` 只负责 build + assemble 并提示手动复制；需要自动归档时用 `build-apk.ps1`。

## 让 zlbdh 出 APK 的标准回复

测试都过了之后（数字必须来自本次真实 `npm test -- --run` / `npm run build` 输出，不沿用历史样例）：

```
QA 全过 ✓ <N>/<N> 测试 / vite build <N> modules / <耗时>
vX.Y.Z 代码就绪。

请在 Windows 出 APK：

powershell -NoProfile -ExecutionPolicy Bypass -File {{PROJECT_ROOT}}\{{APP_REPO_DIR}}\build-apk.ps1

产物会在 {{APP_REPO_DIR}}\apk\{{PROJECT_NAME}}-vX.Y.Z-debug.apk。
```

## GitHub Actions 路（备用）

如果 zlbdh 现在不在 Windows，但有 GitHub repo：

1. 先按 [`操作系统/07_完整工作流/git流程.md`](../../操作系统/07_完整工作流/git流程.md) 和 ADR-016 核对 commit/push 6 条件。
2. 只有满足条件且 zlbdh 明确授权时，才由测试发布 PM「闭环者」执行提交与 push。
3. GitHub → Actions → "Build Android APK" → 手动 `Run workflow` → 等 8-12 分钟 → Artifacts 下载 APK。

当前 `build-apk.yml` 只保留 `workflow_dispatch`；`git push` 不会自动触发出包。

⚠️ 本 skill 不提供可直接复制的 `git add` / `git commit` / `git push` 裸命令，避免绕过 ADR-016。

## 装机后的 smoke test 必跑

按 `Docs/4-测试文档/手动测试用例.md` 单子过核心路径。

要 zlbdh 截图：
- Home
- Health
- Accounting
- Timeline
- Profile

存到 `Docs/4-测试文档/smoke截图/vX.Y.Z-任务名/`。

## release APK（vX.Y.Z / zlbdh 决策）

第一次走完整流程：

### 1. 出 keystore
```cmd
keytool -genkey -v -keystore zlbdh-release.keystore ^
  -alias mimi -keyalg RSA -keysize 2048 -validity 10000
```

### 2. 配 build.gradle
看 `Docs/5-运维文档/APK打包指南.md` 「打 release 签名 APK」段。

### 3. 出 release
```cmd
cd android
gradlew.bat assembleRelease
```

### 4. 拷到 {{APP_REPO_DIR}}/apk/
```
{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-release.apk
```

### 5. tag 归发布闭环处理

仅当代码、测试、build、APK、smoke、版本号、交接卡一致，并满足 ADR-016 6 条件时，才由测试发布 PM「闭环者」按 [`操作系统/07_完整工作流/git流程.md`](../../操作系统/07_完整工作流/git流程.md) / [`发布流程.md`](../../操作系统/07_完整工作流/发布流程.md) 处理常规版本 tag；不得删除 / 改写 / 移动已有 tag。

本 skill 不提供可直接复制的 tag / push 裸命令，避免绕过发布闭环。

## 出 APK 失败的紧急回退

如果当前版本装机崩 / 数据丢：

1. 让 zlbdh 立刻装回上一个 dev APK：
   - `{{APP_REPO_DIR}}/apk/{{PROJECT_NAME}}-vX.Y.Z-debug.apk`
2. 数据如果之前有备份能恢复
3. 咪咪修 bug → 出下一 patch 版本 dev APK
