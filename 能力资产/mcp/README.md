---
name: mcp-config-index
scope: project
type: semantic
loaded: on-demand
description: Project MCP and connector capability index; INSTALLED.md is the single declaration source.
---

# MCP and Connector Capabilities

This group declares the project's Model Context Protocol (MCP), connector, and plugin capabilities and explains their uses.

## Current status

**Documented:** [INSTALLED.md](INSTALLED.md) is the single source for project capability declarations. Each Cowork, Codex, or Claude Code client manages its actual installations. This directory records required capabilities, historical use, and considerations when adding capabilities.

## Ongoing maintenance

- Maintain the core, on-demand, and unused capability matrix in `INSTALLED.md`.
- If an MCP integration can perform sensitive actions such as writing files, Git operations, or external sending, classify them under A/B/C in `操作系统/01_架构/三类行为铁律.md`. Ordinary commits and pushes are conditional Class B under ADR-016; force pushes, rebase, tag deletion, GitHub Releases, and similar actions remain Class C.

## Update triggers

Immediately update `INSTALLED.md` and, as needed, this index when:

1. First adding an MCP integration, such as Slack, GitHub, or Linear.
2. First encountering an MCP bug that affects development.
3. MCP capabilities conflict with AI action boundaries: ordinary pushes are Class B; force pushes, rebase, deleting tags, and Releases are Class C.
4. Different MCP configurations across sessions produce inconsistent results.

Any trigger requires the server inventory, uses, and boundaries to be documented promptly.

## Responsibility of this group

`mcp/` declares which MCPs, connectors, or plugins the project needs, when they are used, and whether availability must be checked in the current environment. Other groups define behavioral rules.
