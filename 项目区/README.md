---
name: project-zone-index
scope: template
type: semantic
loaded: on-demand
description: Local project area. The template repository tracks only its instructions and registry.
---

# Local Project Area

This directory holds local project instances managed by the operating system template or used for trial installations.

## Rules

- `本地实例/` may hold actual project directories, trial installations, or clones.
- Actual project content is excluded from the `czxt` template repository by default.
- Start project metadata by copying `项目配置/_模板.project.json` into a local project directory or `本地实例/<project>/`. Concrete project cards are excluded from template commits by default.
- Before using a project for ongoing template validation, register it in `清单.md`, then decide whether to initialize the operating system for it.

## Suggested structure

| Path | Purpose |
|---|---|
| `README.md` | Instructions for this area |
| `清单.md` | Project registry |
| `本地实例/<project>/` | Local project instance, ignored by Git by default |

## Relationship to project configuration

- `项目区/` holds local project instances and trial results.
- `项目配置/` contains only `_模板.project.json` in the template repository. Concrete project cards remain local by default.
- `实例化项目.ps1` uses explicit project card paths or manually supplied parameters. It does not automatically scan this directory.
