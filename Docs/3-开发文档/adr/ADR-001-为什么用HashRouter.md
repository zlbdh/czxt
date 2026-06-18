# ADR-001 · 路由用 HashRouter 而不是 BrowserRouter

- **状态**：现行
- **日期**：2026-05-08（追溯写入，决策实际发生在 v2.0 起）
- **决策人**：zlbdh
- **关联**：—（底层基础设施决策）

## 背景

「{{PROJECT_NAME}}」要同时跑在三个环境：

1. **Vite dev server**（开发用 `npm run dev`）
2. **PWA**（把 dist/ 放到任意静态服务器或 GitHub Pages）
3. **Capacitor Android WebView**（最终 APK 形态，用 `file://` 协议加载本地 HTML）

BrowserRouter（HTML5 history API）有两个硬伤：

- 在 `file://` 协议下 **不工作**（Capacitor WebView 的真实加载方式）。任何子路由刷新会直接 404。
- PWA 部署到静态服务器需要服务端 fallback 配置（所有路由 rewrite 到 index.html），不是所有静态托管都好做。

候选方案：

| 选项 | dev | PWA | Capacitor |
|---|---|---|---|
| **HashRouter** | ✅ | ✅ 零配置 | ✅ 直接能用 |
| BrowserRouter | ✅ | ⚠️ 需服务端 fallback | ❌ file:// 下崩 |
| MemoryRouter | ✅ | ✅ | ✅，但 URL 不可见、刷新丢状态 |

## 决定

**用 HashRouter**（`react-router-dom`）。所有路由用 `#/path` 形式（如 `#/health`、`#/accounting`）。

涉及代码：`src/App.jsx` `<HashRouter>` 包裹 `<AppShell />`。

## 后果

### 好处
- 三个环境零配置，一份代码同时跑
- Capacitor APK 不会因为 router 崩
- PWA 部署到任意静态托管（Vercel / Netlify / GitHub Pages / 内网）都不用改服务端
- 用户 share 链接（如果未来要做）也不会因协议不同失效

### 代价
- URL 里多个 `#`，肉眼看不"专业"（但用户是 zlbdh 自己，不在乎）
- SEO 友好性差（但 APP 不需要 SEO）
- 跟一些第三方分析工具兼容性差（目前没用）

### 后续如果反悔了
- 翻案触发条件：需要做深度链接 + SEO + share + 服务端渲染
- 撤销路径：换 BrowserRouter 同时给 PWA 配 fallback、给 Capacitor 改用 webDir 服务模式
- 数据迁移：无（路由是无状态的）
- 文档影响：信息架构 + 项目结构 + 这条 ADR 标"已弃用"，新建 ADR 描述切换

---

## 备注

- 现有所有页面跳转都已经用 `<Link to="/...">` 形式，迁移到 BrowserRouter 时代码层无需大改，只需改 router 类型。
- Capacitor `capacitor.config.json` 没有覆盖默认 webDir，所以是按 file:// 加载的。这点跟 HashRouter 选择是绑定的。
