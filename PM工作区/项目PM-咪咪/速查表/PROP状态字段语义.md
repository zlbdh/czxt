---
name: "prop-status-semantics"
description: "Check completion criteria before changing PROP status. Prevents self-correction #44 across pending, approved, in_progress, completed, and rejected states."
trigger: "Before changing a PROP status field"
loaded: "条件加载（按 trigger 匹配时由 PM 调度）"
---

# Quick Reference: PROP Status Semantics — Self-Correction #44

> Before changing PROP status, **check the completion definition**.

## Mandatory status meanings

| Status | Meaning |
|---|---|
| Pending approval | zlbdh has not approved |
| Approved · In progress | Approved but not shipped |
| Approved · Completed | Every shipping condition met, including git push |
| Approved · Deprecated | The approach proved unsuitable during implementation |
| Rejected | Declined during review |

## Completed means every condition is satisfied

1. Code shipped through Claude Code.
2. Tests passed, build passed, and APK built.
3. Physical-device smoke 8/8, when applicable at L3+.
4. **Commit + push origin main through Codex.**
5. Move the PROP from `进行中/` to `已完成/`.
6. Update `确认改动/README.md` counts.

**Completed code does not mean a completed PROP.** In this workflow, wait for the Codex push before marking completed.

## Historical evidence

### Self-correction #44: May 14, 2026, PROP-021

- PM initially marked PROP-021 completed too early.
- Claude Code had finished code shipping, but Codex had not pushed; v3.5.8 release completion still intervened.
- PM corrected the status back to in progress.
- Marked completed only after Codex pushed `a1a8322`.

## Defenses

Before updating status, spend 30 seconds checking:

1. Has the Codex push finished? Verify Git status and commit hash.
2. Are README counts updated?
3. Has the PROP moved to `已完成/`?
4. Did all applicable physical-device smoke checks pass?

Mark completed only when all checks pass.

## Related rules

- [Approval and archiving](../../../操作系统/07_完整工作流/审批与归档.md): PROP state machine.
- [Implementation loop](../../../操作系统/07_完整工作流/实施循环.md): DoD.
- Decision-checkpoint Q4.c: candidate PROP-status semantic boundary.
