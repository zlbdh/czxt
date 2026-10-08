---
name: project-config-index
scope: template
type: semantic
loaded: on-demand
description: Project configuration entry point. Concrete project cards remain in local project instances by default.
---

# Project Configuration

This directory contains the project card template for a shared operating system with multiple project instances. Keep concrete project cards in the local project directory or `项目区/本地实例/<project>/`; do not commit them with the template repository.

## File format

```json
{
  "projectName": "NewProject",
  "projectRoot": "D:\\Projects\\NewProject",
  "appRepoDir": "app",
  "currentVersion": "v0.1.0",
  "currentSprint": "Sprint-1",
  "notes": []
}
```

## Usage

- Use `项目配置/_模板.project.json` as the starting point for a new project.
- Concrete project cards are excluded from the template repository by default. Copy `_模板.project.json` into the local project directory or `项目区/本地实例/<project>/`, then maintain it there.
- Before publishing a project card as an example, obtain approval and remove sensitive information so concrete project details do not leak into the template repository.

The initialization script, `实例化项目.ps1`, currently accepts explicit parameters. Project card loading can become a product feature when an installer or CLI is introduced.
