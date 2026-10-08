---
name: capability-agents-index
scope: project
type: semantic
loaded: on-demand
description: Reserved execution-agent inventory, created by PROP-029 v2 and currently empty.
---

# Execution Agents: Reserved

This directory is **currently empty**, reserved during the PROP-029 v2 physical split.

Project PM “Mimi” centrally assigns available runtime worker/explorer agents. Authority to create agents and accept their work is not delegated; other PMs do not independently launch agents. This directory holds reusable execution-agent assets only after they become established. Actual runtimes follow the tool matrix.

## Relationship to other agent concepts

- `操作系统/02_智能体/`: playbooks for nine PM roles—Project, Knowledge, five decision roles, Development, and Test and Release—for collaboration and orchestration. See the [role index](../../操作系统/02_智能体/README.md).
- `能力资产/agents/`: future callable, single-purpose execution agents, such as testing or source-search agents.
- Runtime subagents: temporary execution instances assigned by Project PM “Mimi” under the [agent delegation mechanism](../../操作系统/01_架构/子agent调度机制.md). They do not automatically become assets in this directory.

## Criteria for expansion

Consider an asset when a task is frequently repeated manually, has one purpose, and can be standardized.

Before establishing an agent, pass `decision-checkpoint` Q1-Q7 and the three-class behavior rules. For commits, pushes, tags, versions, API keys, baseUrl, user-data deletion, or release closure, retain only checks, drafts, or diagnostic assistance. **Do not establish agents that automatically perform high-risk actions.**

Backlog monitoring: issue CC became ADR-030 and meta-rule 13. A future candidate is an agent that verifies whether unit tests cover actual device call paths.
