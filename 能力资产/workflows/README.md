---
name: capability-workflows-index
scope: project
type: semantic
loaded: on-demand
description: Reserved execution-workflow inventory, created by PROP-029 v2 and currently empty.
---

# Execution Workflows: Reserved

This directory is **currently empty**, reserved during the PROP-029 v2 physical split.

## Relationship to collaboration workflows

- `操作系统/07_完整工作流/`: PM decision and collaboration procedures, including decision-checkpoint, implementation Definition of Done, and approval/archiving.
- `能力资产/workflows/`: future automated execution sequences, such as pre-ship checks, draft release-gate orchestration, or retrospective draft preparation.

## Criteria for expansion

Consider adding a workflow after the same execution sequence occurs at least five times, has fixed steps, and can be scripted.

First pass [decision-checkpoint](../../操作系统/07_完整工作流/decision-checkpoint.md) Q1-Q7 and the three-class behavior rules. Sensitive actions—version bumps, commits, tags, pushes, release distribution, secrets, baseUrl changes, or user-data deletion—may appear only as checklists or draft sequences, **not automatic execution chains**. Release closure remains centralized in the Test and Release PM “Closer” main session under ADR-016.
