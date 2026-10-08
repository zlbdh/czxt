---
name: pm-self-correction-trigger
description: Self-correction triggers and immediate durable records under PROP-030, applicable to every PM.
trigger: Any PM discovers an incorrect direction or receives a corrective question from zlbdh.
loaded: on-demand
---

# PM Self-Correction: Triggers and Immediate Action

## Five signals

1. zlbdh asks a corrective question such as “Why did you…?” or “Isn't this…?”.
2. A PM discovers that a decision made at least five minutes earlier was wrong.
3. RETRO drafting reveals the same pattern across Sprints.
4. A role-switch checkpoint prompts reflection, especially Q1–Q3.
5. zlbdh asks to stop and check the operating system.

## Immediate procedure — complete within five minutes

### 1. Determine ownership and number

For Project PM identity, global collaboration, framework rules, or cross-PM problems, inspect `PM工作区/项目PM-咪咪/PM自纠/INDEX.md` and assign max+1.

For private PM knowledge, return to `PM工作区/<PM名>/`. If it lacks a self-correction directory, Project PM dispatches that role to establish one or receives the matter back. Do not force it into Project PM's index.

### 2. Record the trace

The triggering PM records ownership and a draft. Project PM's main session, or an allowlisted Operating System PM, finalizes the role-transition row in `状态.md`:

```text
| YYYY-MM-DD HH:MM | <from> | <to> | **PM self-correction #N — one sentence** ... | ✅ | ✅ |
```

### 3. Create the artifact — issue CN / PROP-030

Use the ownership established in step 1. Global/Project PM issues use `PM工作区/项目PM-咪咪/PM自纠/PM自纠-N.md`.

Include a one-sentence summary, trigger with time and step, root cause, implemented defense and location, recurrence evidence, candidate meta-rule, and authoritative source.

### 4. Update the index

Add one pointer to that PM's self-correction index or workspace README. Project PM dispatches cross-PM private-directory work; do not reorganize another PM's workspace without authority.

### 5. Assess escalation

- Three or more recurrences of the same pattern: candidate meta-rule pool.
- A rule already implemented in its authoritative location: direct mandatory rule, without adding it to the pool.

## Required chat section ⑦ — PROP-027 v2

“⑦ PM role transitions: N rows added this session (`状态.md L<line>`).”

## Authoritative sources

- `PM工作区/项目PM-咪咪/PM自纠/INDEX.md`.
- `操作系统/03_交接/交接卡格式.md`, section ⑦.
- `操作系统/05_记忆/INDEX.md`, section 2, reflection 7.
