---
name: skills-execution-index
scope: project
type: procedural
loaded: on-demand
description: Capability skills index — executable operating procedures shared across PM roles.
---

# Capability Skills — Operating Procedures

## Purpose

Each skill explains one specific capability, with concrete steps rather than a sequence of multiple capabilities.

Procedures that connect multiple skills belong in `workflows/`.

## Main entry points

| File | Purpose |
|---|---|
| [Build an APK](出APK.md) | Package a development APK through the Windows one-click script, GitHub Actions, or manual Gradle |
| [Run tests](跑测试.md) | Core QA: Vitest unit tests and Vite build; esbuild syntax checks remain a legacy Cowork fallback only |
| [Borrowing](借鉴.md) | Sole execution entry for connecting, evaluating, implementing, and auditing external reference sources |
| ⭐ [Project health check](项目体检.md) | P4a–P4t framework checks: byte thresholds, counts, handoffs, PM transitions, old conventions, PM workspaces, active Markdown links, remaining capability areas, governance semantic anchors, hooks configuration, template neutrality, and borrowing closure consistency |
| ⭐ [State inference](状态推断.md) | Ten checks covering APK completion, code changes, RETRO triggers, ADR consistency, cross-session handoffs, and state freshness; reconcile at implementation-loop startup and PROP archiving, without replacing the five AGENTS startup steps |

> Split detail files such as `项目体检-检查项*.md` and `状态推断-*` are linked from their main entries and are not repeated here. Use `rg --files 能力资产/skills` for the actual complete file list.

## Relationship to other groups

- `skills/`: one capability, such as building an APK or running tests.
- `操作系统/07_完整工作流/`: sequences of skills, such as tests → APK build → smoke checks for release.
- `操作系统/02_智能体/`: roles that use the skills.
- `rules/`: rules that apply while using them.

## Quick reference

| Goal | Skill | Tool |
|---|---|---|
| Build an APK | [Build an APK](出APK.md) | `{{APP_REPO_DIR}}/build-apk.ps1` with automatic archiving, or GitHub Actions after ADR-016 authorization |
| Run tests | [Run tests](跑测试.md) | `npm test` and `npm run build` |
