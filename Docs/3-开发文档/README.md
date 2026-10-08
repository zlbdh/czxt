---
name: dev-docs-index
scope: project
type: semantic
loaded: on-demand
description: Development documentation entry point, template boundaries, project instance sources of truth, and ADR navigation.
---

# Development Documentation

> The template root does not prescribe an application's framework, directories, APIs, database, or version. After initialization, fill in this directory from actual code and configuration; do not carry forward assumptions from the template.

## Project instance source of truth

Development documentation summarizes the actual project; it does not replace authoritative engineering sources. Resolve conflicts in this order:

1. The project card and the application repository's code, manifests, lockfiles, schemas, and migrations.
2. Reproducible build and test results, runtime logs, and deployment configuration.
3. The collaboration and safety rules in `操作系统/` and `能力资产/`.
4. The explanatory documents in this directory.

If a project fact is unavailable, retain `[fill in]` and mark it as pending verification. Do not infer it from the source project's history or a directory name.

## Current templates

| Document | Purpose | Completion evidence |
|---|---|---|
| [Project structure](项目结构.md) | Neutral navigation for the template root and project instance | Actual directories matched to key entry points |
| [Technology stack](技术栈.md) | Record the languages, frameworks, build tools, and test tools the project actually uses | Manifests, lockfiles, and version commands |
| [API specification](API规范.md) | Record protocol and model layers, authentication, errors, and compatibility contracts | Code, configuration, interface contracts, and actual probes |
| [Database schema](数据库schema.md) | Record the storage engine, entities, indexes, versions, and migrations | Authoritative schema/migration sources and migration tests |
| [ADR index](adr/README.md) | Permanent architecture decision records | P4g / P4i count guards |

## Historical reference boundary

Other older documents in this directory may be historical references from the source project, not current template facts. Historical ADRs, RETROs, and snapshots are not deleted when making the template neutral. Read each file's status and date first, then verify it against the project instance's sources of truth.

## Maintenance rules

- Dependency or version changes: update `技术栈.md` and identify the authoritative source path.
- Interface contract changes: update `API规范.md`; never write real secrets to tracked files.
- Schema or migration changes: update `数据库schema.md` with upgrade, rollback, and data safety evidence.
- Directory boundary changes: update `项目结构.md` without copying the complete file tree or business module inventory.
- Mark unverified content as `[fill in]` / `Pending verification`; do not present it as completed.
