---
name: qa-role-legacy
scope: project
type: semantic
loaded: on-demand
description: 历史档案：QA 测试帽子（vitest/vite build/cap sync 3 层验证 + 回归矩阵），已吸收到新 9 PM playbook（测试PM-质量门户 + 测试发布PM-闭环者）
---

# QA Playbook · 测试角色

> 历史档案：当前测试入口是 [`测试PM-质量门户.md`](测试PM-质量门户.md) + [`测试发布PM-闭环者.md`](测试发布PM-闭环者.md)。本文保留旧 QA 帽子样本，不作为现行执行规则；文内命令和 QA 流程不可直接复制执行。

咪咪验证代码时戴这顶帽子。目的：在 zlbdh 拿到坏 APK 之前抓 bug。

## 触发条件

历史 Dev 步骤 4 完成后曾要求完整 QA；当前执行入口改为测试 PM 定策略、测试发布 PM 跑闭环。

## 历史样例：3 层验证（不可复制执行）

### Layer 1：vitest 单元测试

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
npm test -- --run
# 期望：所有 test files passed, total tests >= last_known_count
```

如果有 fail：
- 修复 → 不把 PRD 标完成
- 是新功能 break 旧测试？→ 修代码或修测试（看是否符合新 AC）
- 是新加测试本身错？→ 修测试
- 常见原因：import 名打错、JSX 标签未闭合、测试契约未同步

### Layer 2：vite build 生产构建

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
npm run build
# 期望：✓ built in Xs，无 error
```

警告（warnings）：
- `Some chunks are larger than 500 kB` — 已知，charts 重，可忽略
- `Module not found` — 必须修

### Layer 3：历史样例 — Capacitor 同步 / APK（当前交测试发布 PM）

```powershell
cd {{PROJECT_ROOT}}\{{APP_REPO_DIR}}
npx cap sync android
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-apk.ps1
```

发布闭环继续交给测试发布 PM「闭环者」执行真机安装 / CDP smoke / logcat。

可选 Layer 4：手动 smoke

启动 `npm run dev` 后，手动跑过 5 个 tab：
1. Home：打卡、+1 喝水、点任务出弹窗、生成 AI 简报、聊聊发一条
2. Health：填体重、记一餐、记训练、AI 分析（需 key）
3. Accounting：「午餐35」、看饼图、改预算
4. Timeline：写一条文字 / 链接、点星标、AI 整理
5. Profile：改档案、复制 AI key、导出备份、模拟设备

## 测试报告模板

每次 QA 结束输出：

```markdown
## QA 报告 v3.X

- 改动文件：N
- 新增测试：M
- Layer 1 vitest：✓ N/N
- Layer 2 vite build：✓ 在 Xs 完成
  - JS bundle: XXX KB / gzip XXX KB
  - 增量 ΔX KB
- Layer 3 cap sync / APK：✓ / 跳过（说明原因）
- 手动 smoke：✓ / 跳过

风险/已知问题：
- ...
```

## 回归测试矩阵

每次大改后必跑：

| 流程 | 输入 | 期望 |
|---|---|---|
| 首次启动 | 清空 IndexedDB | 看到默认习惯 + 主账本 |
| Legacy 迁移 | 有 v1 localStorage | profile/任务/聊天迁入 IndexedDB |
| 离线打卡 | 飞行模式 | 全部本地操作正常 |
| AI 缺 key | 清掉 LLM_STORAGE_KEY | 显示友好错误，不崩 |
| 备份导出 | 点导出 | 下载 JSON，包含全部表 |
| 备份导入 | 粘贴 JSON | 数据全恢复 |

## 不要跳过

> 以下是旧 QA 执行样例中的提醒，不是现行职责分配；当前开发期本地自测归开发 PM，发布/ship gate 归测试发布 PM。

- 不要因为「只是改了样式」就跳过 vitest
- 不要因为「上次构建过了」就跳过 vite build
- 不要因为「测试全过」就标 PRD 完成 — 还要确认 AC 全打勾
