---
name: 测试pm-质量门户-readme
scope: pm-workspace
pm: 测试PM-质量门户
type: semantic
loaded: on-demand
description: "Test PM \"Quality Gate\" workspace entry point: decision layer and acceptance strategy."
---

# Test PM "Quality Gate": Meta-Memory Center

> 🌱 **New placeholder** (2026-05-21 / issue CM): quick references will be developed through practice.

## Role definition

See the [Test PM playbook](../../操作系统/02_智能体/测试PM-质量门户.md).

## Path allowlist

| Category | Path |
|---|---|
| Primary responsibility | Read + Grep across the project; **neither writes nor runs tests** |
| Prohibited | ❌ Writing `*.test.js` / ❌ Running vitest or smoke tests / ❌ Other PMs' private workspaces |

## Quick references to develop

Create a quick-reference file when the same PM self-correction pattern occurs a third time. Current candidates:

- Evidence-based acceptance criteria SOP: issue CC candidate meta-rule; passing unit tests does not imply passing on a real device.
- Mandatory device smoke checklist SOP: a Codex verification requirement.
- Issue P three-state user-input boundary: three-layer consistency verification SOP, ADR-024.

## Practice reviews to develop

- F-NIGHT-1 v1 passed unit tests but failed device AC2 at 70 characters, PM self-correction #51: 2026-05-20.
- W-3 v1 passed unit tests but ordinary device chat failed, W-3 PM self-correction: 2026-05-20.

## PM self-corrections to collect

- Candidate: promote issue CC's evidence-based acceptance criteria to a standalone meta-rule.

📌 This directory is maintained by the **Test PM**. Other PMs must not reorganize it: PM self-correction #59.
