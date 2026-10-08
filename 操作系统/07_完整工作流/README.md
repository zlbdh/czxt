---
name: workflows-index
scope: project
type: procedural
loaded: on-demand
description: Complete workflow entry — decision checkpoints, implementation loop, definition of done and appendices.
---
# Complete Workflows — Multistep Processes

**Before completing a change, read the DoD section at the end of the [implementation loop](实施循环.md). Read its [appendix](实施循环-附录.md) for less frequent stage details. Read [approval and archival](审批与归档.md) before changing PROP status.**

## Purpose

These workflows sequence multiple steps, usually across roles, calling skills and rules as needed. Each workflow defines a complete path, emphasizing order and stage outputs.

## Files

| File | Purpose |
|---|---|
| [Decision checkpoint](decision-checkpoint.md) | Mandatory Q1-Q7 checks, including agent-instantiation decisions |
| [Decision criteria](decision-checkpoint-判定细则.md) | Q4-Q7 trigger, scale, cross-PM and agent-instantiation details |
| [Decision appendix](decision-checkpoint-附录.md) | Examples and supplementary material without duplicating the main rules |
| [Implementation loop](实施循环.md) | Session startup, workflow priority, handoff matrix, stage overview, and DoD quick reference |
| [Implementation appendix](实施循环-附录.md) | Less frequent design, code, test, APK, smoke, and runtime-capability details |
| [Implementation DoD](实施循环-DoD.md) | Separate completion checklist referenced by the implementation loop |
| [Approval and archival](审批与归档.md) | Five PROP states: pending approval, in progress, completed, abandoned, rejected; ID lookup in section C |
| [Requirements intake](需求接收.md) | Seven steps for starting a new requirement |
| [Release workflow](发布流程.md) | Compile, test, APK, release notes |
| [Git workflow](git流程.md) | Repository boundaries, A/B/C authority, six commit-push conditions, commit messages, branch and tag rules |
| [Hooks operating procedure](hooks-运行SOP.md) | Manual and automatic operation, sources of truth, key boundaries and acceptance entry |
| [Hooks appendix](hooks-运行SOP-附录.md) | Less frequent install/removal commands, event tables, watcher health codes, troubleshooting |
| [Borrowing lifecycle](借鉴闭环.md) | Role flow, state flow and failure recovery for source intake, assessment, implementation and audit |

## Relationship to other groups

- **workflows/**: ordered multistep processes.
- **skills/**: individual capabilities.
- **rules/**: decision standards, rather than procedures.
- **操作系统/02_智能体/**: the responsible actors.

## Trigger reference

| Trigger | Workflow |
|---|---|
| New idea | 需求接收.md |
| zlbdh approves a PROP | 审批与归档.md section A |
| zlbdh rejects a PROP | 审批与归档.md section B |
| Start an L3/L4 change | 实施循环.md |
| Complete a change | 实施循环.md DoD section + 实施循环-DoD.md |
| Prepare a version release | 发布流程.md |
| Borrow, reference, compare, or incorporate | [Borrowing lifecycle](借鉴闭环.md) |
