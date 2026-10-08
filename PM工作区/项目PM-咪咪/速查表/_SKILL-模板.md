---
name: "skill-template"
description: "Standard SKILL.md template under PROP-031 for PM quick references, using Progressive Context Loading."
loaded: "参考文档（不会被加载，仅作为模板）"
---

# SKILL.md Template: Progressive Context Loading

> 📚 PROP-031 implementation: May 21, 2026 / task #83.

## Standard YAML frontmatter: four required fields

```yaml
---
name: unique-kebab-case-identifier # Example: chat-summary-dedup
description: |
  Core purpose within 30 characters, the PM self-correction prevented,
  and trigger keywords.
trigger: When X / before Y / while deciding Z
loaded: Conditional loading; the PM dispatches when the trigger matches.
---
```

## Writing rules

| Field | Required | Guidance |
|---|---|---|
| `name` | Yes | Globally unique kebab-case; describe the scenario, not the action |
| `description` | Yes | Core purpose within 30 characters plus the self-correction prevented |
| `trigger` | Yes | Keywords identifying when, before, or after an event |
| `loaded` | Yes | Always state conditional loading by PM dispatch when the trigger matches |

## Body

Suggested structure after frontmatter:

1. Mandatory/core rule, with emoji for emphasis.
2. Decision flow/checklist.
3. Repeated-pattern evidence/source PM self-corrections.
4. Authoritative knowledge-source links.

## File-size principle

- Keep entry points short and scannable. Above roughly 2 KB, first reconsider whether the content still fits a quick reference.
- Actual size thresholds follow tool-specific layers in AGENTS / P4b health checks; 2 KB is not a hard limit.

## Progressive-loading benefit check

During role-switch decision-checkpoint Q1-Q3, add Q4:

> Which quick-reference triggers match this task?
> One match: load that reference only. Two or three: load every match.
> No matches: skip; the INDEX entry is sufficient.

The original estimate is a 5–10× context saving for 30 quick references.

---

📌 Copy this file to `PM工作区/<X-PM>/速查表/<scenario>.md`, update frontmatter/body, and add it to that PM workspace's INDEX.
