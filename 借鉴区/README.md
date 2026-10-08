---
name: borrowing-zone
scope: project
type: semantic
loaded: on-demand
description: Borrowing facts for {{PROJECT_NAME}}; source capture cards, borrowing cards, and lightweight auditable evidence only.
---
# Borrowing Area

This area answers two questions: **which sources we learn from**, and **what we learn**. It records project facts. It is not a ninth operating system module and does not contain target business code.

## Sole operational entry point

- Use the [borrowing skill](../能力资产/skills/借鉴.md) to connect, assess, adopt, or audit a source.
- Do not invent a second set of states, fields, or execution entry points. The skill routes governance rules and the complete workflow.

## Static structure

| Path | Contents |
|---|---|
| `模板/` | Blank source capture and borrowing-card templates |
| `来源/` | `<source_id>/<capture_id>/来源版本卡.md` |
| `事项/` | `<borrow_id>/借鉴卡.md` |

The template provides only a skeleton, with no concrete sources, active items, source snapshots, or business dependencies. Instantiation copies this page, ignore rules, and the two blank templates, and creates empty `来源/` and `事项/` directories.

Zero business dependency is mandatory: the business repository must not depend on `借鉴区` through `import`, `require`, `file:`, workspace or build configuration, scripts, or runtime reads. Borrowed material can become business implementation only after assessment, approval, and placement in the responsible target path.

## Scanning

```powershell
Get-ChildItem -LiteralPath '借鉴区/来源' -Recurse -Filter '来源版本卡.md' -File
Get-ChildItem -LiteralPath '借鉴区/事项' -Recurse -Filter '借鉴卡.md' -File
```

Scanning the filesystem yields the current facts. This directory does not maintain a duplicate active-item index.

## Cache boundaries

- Formal cards and lightweight verification summaries may be versioned.
- `快照/`, `*.local.json`, `证据/raw/`, and `.staging-*` are local caches or raw material and are ignored by default.
- `capture.local.json/v1` stores only normalized local paths in a fixed schema. It must not contain tokens, passwords, cookies, or other secrets.
- The borrowing area does not persist real credentials. Keep them in operating-system or tool credential stores outside this area. Prefetch private Git or web content outside the area; supply capture with sanitized public locators or local input paths for prefetched content only.
- Future secret-access support requires a new schema, separate Class B authorization, and a dedicated secret store. Do not extend the current v1 schema or create secret files in broadly ignored directories.
- A missing cache does not erase a recorded source identity. If a present cache does not match the card fingerprint, stop using it and audit it again.
