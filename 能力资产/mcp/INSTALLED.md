---
name: mcp-installed
scope: project
type: semantic
loaded: on-demand
description: Single project MCP/connector declaration, core and optional capabilities, cross-runtime consistency, and maintenance under issue CG.
---

# Project MCP and Connector Declaration

**Single source of truth:** register capabilities required by this project or used historically here.

**Boundary:** this is not a live installation report. Actual availability follows tools and plugins exposed by the current runtime.

Established May 20, 2026, during the enhanced Class C framework self-check, PROP-026 / issue CG on storage outside the project.

## 1. Why keep this inventory?

Cowork, Codex, and Claude Code each manage MCP, plugin, and connector installations. Without a project record:

- Configuration knowledge is lost after device changes or reinstalls.
- Required project capabilities are unclear across runtimes.
- New PMs and conversations lack the complete capability matrix.
- The record is not versioned in Git, repeating the framework-storage problem seen with AppData memory.

This is a **declaration document**. It does not replace installation configuration, and current availability requires verification.

## 2. Capability matrix

The matrix reflects requirements and historical use. It does not assert that anything is installed now. Actual configuration belongs to each client, connector, or plugin manager.

### Core requirements: equivalent capabilities, not mandatory same-named MCPs

| Capability | Typical implementation | Trigger |
|---|---|---|
| Local files and command execution | Codex shell / Claude Code shell / Cowork workspace | File inspection, script health checks, builds, tests |
| Browser or desktop control | Codex Browser / Chrome / Computer Use / Cowork computer-use | Device smoke tests, screenshots, page interaction |
| Automated reminders | Runtime automation or scheduled-tasks | PM reminders, scheduled shipping cards |
| Historical context | Runtime thread/session features; project status and handoff files as needed | Prior conversations and cross-session continuation |
| File sharing and artifact presentation | Runtime artifact, present, or connector capabilities | Screenshots, documents, reports |

### Occasional, on-demand use

| MCP | Purpose | Trigger |
|---|---|---|
| brand-voice | Brand dictionary and content generation | Issue BI, Operations Mimi v0.1 candidate |
| slack-by-salesforce | Slack integration | Future issue BI team collaboration |
| figma | Figma operations | Future F-SHARE-1 visual design |
| canvas-design / theme-factory | Visual design and themes | Future UI design assistance |

### Seen historically or in external runtimes, not currently required

| MCP / plugin category | Status |
|---|---|
| bio-research: biorxiv / c-trials / chembl / consensus / pubmed / ot | Unrelated in the historical health-app context, which used Xiaomi MiMo rather than biomedical databases |
| finance / sales / marketing / data / hr business plugins | Unrelated |
| adobe-for-creativity / cloudinary | Possible future use, Sprint-9+ F-SHARE-1 |
| legal / engineering / design / pdf-viewer | Unrelated |
| daloopa / lseg / bigdata / sp-global / zoominfo / common-room | Unrelated finance/sales capabilities |
| zoom / docusign / box / sanity / miro / intercom | Unrelated |
| brightdata / postiz / fastly / cockroachdb / prisma | Unrelated |
| searchfit-seo / customer-support / operations / finance | Unrelated |
| product-tracking / common-room / apollo | Unrelated |

Many historical or external-runtime capabilities are unrelated to the project. zlbdh may later clean up actual clients as appropriate; issue CH tracks this candidate.

## 3. Usage agreements

### Cross-runtime consistency

| Tool | Configuration location | Guidance |
|---|---|---|
| Cowork | Cowork user settings | Historical primary working environment |
| Codex | Codex configuration / app plugins and connectors | Follow current tools/plugins; keep core capabilities replaceable |
| Claude Code | Claude Code configuration | Follow current tools/plugins; keep core capabilities replaceable |

Equivalent connectors can substitute for capabilities, but lifecycle hooks are not interchangeable. Follow the [hook event matrix](../../操作系统/06_工具治理/hooks-事件矩阵.md) for Codex / Claude Code differences.

### Core alignment checklist

When configuring a new Codex or Claude Code environment, confirm these capabilities without requiring identical MCP names:

- Local shell, file access, and script execution.
- Browser or desktop interaction when device smoke tests or screenshots require it.
- Automated reminders when scheduling is needed.
- Historical context access; otherwise continue from `状态.md` and `交接区/`.

Historical Cowork-specific features such as computer-use, mounts, and present are replaceable with current runtime equivalents; they are not mandatory Codex or Claude Code installations.

Selection boundaries: prefer Codex Browser for local pages or localhost; use Chrome when the user's Chrome login session is needed; use Computer Use for Windows desktop apps.

## 4. Maintenance

When installing or uninstalling an MCP:

1. Update this inventory.
2. For a core capability, record its purpose and trigger.
3. Use the PROP process for major changes, such as removing a core integration.

For device synchronization:

- Version this declaration in Git so a new device can use it as a configuration reference after cloning.
- Business runtime API keys belong only in `{{APP_REPO_DIR}}/.env.local` under ADR-022 safeguards. Connector/OAuth tokens stay in client credential storage. Writing any local secret requires explicit user confirmation; secrets never enter tracked files.

## 5. Version history

- v1, May 20, 2026: Operating System PM framework self-check and external-storage governance, PROP-026 / issue CG.

See behavior rule 6 in section 2 of the [memory index](../../操作系统/05_记忆/INDEX.md).
