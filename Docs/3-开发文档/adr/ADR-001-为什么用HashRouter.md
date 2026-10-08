# ADR-001 · Use HashRouter for Routing Instead of BrowserRouter

- **Status**: Current
- **Date**: 2026-05-08 (recorded retrospectively; the decision took effect starting with v2.0)
- **Decision maker**: zlbdh
- **Related**: — (underlying infrastructure decision)

## Context

“{{PROJECT_NAME}}” must run in three environments:

1. **Vite dev server** (`npm run dev` for development)
2. **PWA** (serve dist/ from any static server or GitHub Pages)
3. **Capacitor Android WebView** (the final APK, loading local HTML through `file://`)

BrowserRouter (the HTML5 history API) has two major limitations:

- It **does not work** under `file://` (the Capacitor WebView loading mechanism recorded here). Refreshing any subroute produces a 404.
- PWA deployment to static hosting requires a server fallback (rewrite every route to index.html), which is not straightforward on every static host.

Options:

| Option | Development | PWA | Capacitor |
|---|---|---|---|
| **HashRouter** | ✅ | ✅ No configuration | ✅ Works directly |
| BrowserRouter | ✅ | ⚠️ Server fallback required | ❌ Fails under file:// |
| MemoryRouter | ✅ | ✅ | ✅, but routes are not visible in the URL and refresh loses state |

## Decision

**Use HashRouter** from `react-router-dom`. All routes use `#/path`, such as `#/health` and `#/accounting`.

Code: `<HashRouter>` wraps `<AppShell />` in `src/App.jsx`.

## Consequences

### Benefits
- One codebase runs in all three environments without configuration.
- Routing does not break the Capacitor APK.
- PWA deployment to any static host (Vercel / Netlify / GitHub Pages / an internal network) requires no server changes.
- Shared links, if added later, will not fail because the protocol differs.

### Costs
- The URL contains an extra `#`, which looks less “professional” (the user is zlbdh, who does not mind).
- Poorer SEO support (the app does not require SEO).
- Less compatibility with some third-party analytics tools (none are currently used).

### Reconsideration
- Trigger: deep links, SEO, sharing, and server rendering are required.
- Reversal: switch to BrowserRouter, configure a PWA fallback, and switch Capacitor to a webDir server mode.
- Data migration: none; routing is stateless.
- Documentation: update information architecture and project structure, mark this ADR “Deprecated,” and create a new ADR describing the switch.

---

## Notes

- Existing page navigation already uses `<Link to="/...">`. Switching to BrowserRouter requires little application code change beyond the router type.
- The recorded `capacitor.config.json` does not override the default webDir and therefore loads through file://. This recorded configuration is tied to the HashRouter choice.
