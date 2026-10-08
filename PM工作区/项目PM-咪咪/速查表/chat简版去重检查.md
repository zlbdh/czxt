---
name: "chat-summary-dedup"
description: "Scan chat summary items ①-⑦ for repeated content before sending. Prevents PM self-correction #48."
trigger: "After drafting the short chat summary and before sending"
loaded: "条件加载（按 trigger 匹配时由 PM 调度）"
---

# Quick Reference: Deduplicate Chat Summaries — Self-Correction #48

> After drafting chat summary items ①-⑦, **scan once more** for repeated sections.

## Mandatory sequence

1. Check fenced code blocks for duplicate content.
2. Check repeated requests to switch to Claude Code/Codex.
3. Check repeated copy-and-paste headings.
4. Perform a final search before sending.

## Historical evidence

### Self-correction #48: May 15, 2026, blocked F-ALARM-1 chat

- One response contained two identical Claude Code startup blocks.
- zlbdh sent a screenshot asking whether the text should be pasted twice.
- Cause: PM fatigue after 21+ role switches and six self-corrections that day; no final deduplication check.

## Defenses

Spend 30 seconds checking after writing the summary:

1. One copy-and-paste code block per task, not two identical blocks.
2. One occurrence of each role/tool-switch request per section.
3. Above 200 lines, a deduplication scan is mandatory; this is a fatigue warning threshold.
4. A new issue-candidate section must not duplicate the caution section.

Helpful practices:

- Preview rendered Markdown to spot duplicate code blocks visually.
- Split long output into sections of fewer than 100 lines, making checks easier.

## Related rules

- [PROP-014 mandatory chat summary](../../../操作系统/03_交接/交接卡格式.md): required ①-⑦ format; this rule supplements it.
- [PROP-020 path D decision checkpoint](../../../操作系统/07_完整工作流/decision-checkpoint.md): Q4.g candidate for output deduplication.
