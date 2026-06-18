# Sprint 1 技术拆解

📌 这份文档是 PM→Dev 的交接产物，含技术细节、文件清单、估算、风险。
对应业务 PRD：`Docs/1-需求文档/Sprint-1需求清单.md`。

---

## F-205 · ErrorBoundary 不崩降级 ⭐ P0

**等级**：L3（新功能 / 跨多文件 / 走完整三件套）
**业务 PRD**：`Docs/1-需求文档/Sprint-1需求清单.md` F-205 段
**状态**：已完成（2026-05-08，Windows + 真机 smoke 已验证）

### 数据层

- 复用现有 `db.deviceEvents` 表，**无 schema 变化**（所以是 L3 不是 L4）
- 新事件类型：
  ```js
  {
    type: 'error',
    raw: null,
    parsed: null,
    payload: {
      tab: 'health' | 'accounting' | 'timeline' | 'profile' | 'home',
      message: string,
      stack?: string,
      componentStack?: string,
      url: string,        // location.hash
      ts: ISO string,
    },
    status: 'caught',
    createdAt: ISO,
  }
  ```
- useAppData actions 复用现有 `addRecord('deviceEvents', {...})`

### UI 层

#### 新组件：`src/shared/ErrorBoundary.jsx`

- **必须是 class component**（React hooks 不支持 `componentDidCatch`）
- props：
  - `children`
  - `tabName`：用于错误日志区分哪个 tab 崩
  - `onError(payload)`：可选，用于写入 deviceEvents
- fallback UI：
  - 米白卡片，居中
  - 文案：「咪咪打了个嗝 🫧 切到其他 tab 试试？」
  - 按钮「返回首页」（清错误 state 让 Home 重新挂载）
  - 隐藏区域显示 message + stack（开发用，UI 上折叠）

#### 集成：`src/app/AppShell.jsx`

每个 Route 用 ErrorBoundary 包：
```jsx
<Route path="/" element={
  <ErrorBoundary tabName="home" onError={logError}>
    <HomePage store={store} />
  </ErrorBoundary>
} />
```

`logError` 从 `store.actions.addRecord('deviceEvents', { type: 'error', payload })` 来。

#### Profile 页（`src/features/profile/Profile.jsx`）

新增 Card「最近的小问题」：
- 位置：在「设备扩展」Card 下方
- 显示：取 `data.deviceEvents.filter(e => e.type === 'error').slice(0, 5)`
- 每条：日期 / tab 名 / message 简短
- 空状态：「最近一切顺利 🌿」
- 不暴露 stack（折叠 / 不显示），避免吓到 zlbdh

### 文件清单

```
+ src/shared/ErrorBoundary.jsx          新增 ~70 行
+ src/shared/ErrorBoundary.test.js      新增 ~30 行
M src/app/AppShell.jsx                  +10 行（import + 5 Route 包裹 + logError 闭包）
M src/features/profile/Profile.jsx      +20 行（新 Card 渲染最近 5 条 error）
```

不动数据库 schema，不动 useAppData，不动 useAppData.js 的 actions。

### 估算

| 维度 | 估值 |
|---|---|
| 工作量 | **M（半天）** |
| 影响文件 | 4 |
| 改 schema | 否 |
| 跨 feature | 否（component-only + 一个集成点 + 一个 UI 入口） |

### 风险

| 风险 | 缓解 |
|---|---|
| class component 在 Vite Fast Refresh 下行为异常 | 加 `// @refresh reset` 顶部，或忽略（class 不参与 HMR） |
| `componentDidCatch` 里调 `actions.addRecord` 是异步的，会丢错误 | 用 `setTimeout(() => actions.addRecord(...), 0)` 解耦渲染 |
| 子组件 reset 后还会循环报错 | 给 fallback「返回首页」按钮一个 key 重置 + Hash navigate to /，强制 unmount |
| ErrorBoundary 自己崩 | 不可能，但 fallback UI 用最简单 div + style，不依赖 Card 等可能崩的组件 |

### 测试覆盖（vitest）

- `src/shared/ErrorBoundary.test.js`：
  - 正常子组件 → 渲染 children ✓
  - 子组件 throw → 渲染 fallback ✓
  - 子组件 throw → 调用 `onError` prop ✓
  - 点「返回首页」→ state 重置 ✓

### 验收

复用业务 PRD（`Docs/1-需求文档/Sprint-1需求清单.md` 的 F-205 验收清单 5 条）。

---

(后续 F-203 / F-001 / F-006 / F-002 / F-003 / F-LAYOUT-1 / F-LAYOUT-2 技术拆解
开工时再加进来。这份文档随 Sprint 推进逐步填充。)


---

## SPLIT-001 · 拆分大文件（PROP-001 B3 实施）

**对应 PROPOSAL**：`确认改动/已审批/PROP-001-2026-05-08-拆分大文件.md`
**等级**：L3（多文件 + 不动 schema/架构）
**方案**：B3 全拆（zlbdh 2026-05-08 选定），分阶段

### 范围（5 个 ≥ 8KB 源文件）
- `{{APP_REPO_DIR}}/src/shared/components.jsx` (12137B)
- `{{APP_REPO_DIR}}/src/features/home/Home.jsx` (13208B)
- `{{APP_REPO_DIR}}/src/features/timeline/Timeline.jsx` (9594B)
- `{{APP_REPO_DIR}}/src/features/health/Health.jsx` (9133B)
- `{{APP_REPO_DIR}}/src/features/profile/Profile.jsx` (8579B)

### 阶段 1：components.jsx 拆 6 文件（已完成）

| 新文件 | 含组件 | 预估大小 | imports |
|---|---|---:|---|
| `components.jsx` (核心) | Card / PageHeader / SectionTitle / EmptyState | ~1.9KB | C |
| `buttons.jsx` | PillButton / PrimaryButton / GhostButton | ~1.1KB | C |
| `inputs.jsx` | TextInput / TextArea | ~0.6KB | C |
| `stats.jsx` | StatRow / Stat | ~1.3KB | C |
| `MonthCalendar.jsx` | MonthCalendar + 内部 helpers | ~3.8KB | useMemo, useState, ChevronLeft/Right, C |
| `TaskDetailModal.jsx` | TaskDetailModal | ~2.7KB | useEffect, X, C |

### import 影响范围

所有 `features/*` 文件里 `from '../shared/components.jsx'` 需要按用到的组件细分。
- 5 个 features 文件 + 可能 AppShell.jsx
- TaskDetailModal 只用在 Home
- MonthCalendar 用在 Health/Timeline/Profile

### 验证

- 沙箱：括号平衡 + import 路径解析 + 各文件大小 < 6KB
- Windows：`npm test`（33 tests 全过）+ `npm run build`（0 error）

### 阶段 2-6

已完成：Home.jsx → Timeline → Health → Profile → Accounting.jsx。每阶段拆分后独立做静态检查，最终统一跑 `npm test` 和 `npm run build`。

最终状态：`{{APP_REPO_DIR}}/src/` 下暂无 ≥6500B 源码文件，最大文件约 6.3KB。
