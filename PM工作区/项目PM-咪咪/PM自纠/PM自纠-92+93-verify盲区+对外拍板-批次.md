---
name: "pm-self-correction-92-93"
scope: "pm-workspace"
pm: "项目PM-咪咪"
type: "episodic"
loaded: "triggered"
trigger: "Silent verification-tool damage, or another reminder from zlbdh that Project PM must make the decision rather than ask a closing question"
description: "PM correction batch #92–#93: stale paths silently broke both verification scripts; Project PM again asked for permission instead of deciding under ADR-031."
---

# PM Corrections #92–#93: Batch Record

> **Trigger:** zlbdh requested a verification run. The host exposed script crashes; I closed by asking whether I should record the lesson, and zlbdh replied, “You are Project PM.”
> **Time:** 2026-05-29 16:30
> **Issues:** DN, health-check quality (#92), and ADR-031, external decision authority (#93).

## #92 — Verification tools stayed silently broken for days

### Error

The “Windows host verification left to zlbdh” item for `check-operating-system.ps1` had remained open since task #125, May 29 at 09:00. **The complete script had never been run on the host after P4g was added.** The first host run crashed:

- `$root` ascended only one level, unchanged after task #109 moved the script into `能力资产\tools\scripts\`, so it incorrectly treated `能力资产\tools` as the project root.
- P4a/P4b/P4c still referenced `agent\`; no follow-up scan occurred after the `agent/` → `操作系统/` + `能力资产/` refactor. P4c crashed because `agent\` was missing.
- `check-pm-tracking.ps1` had the same `$root` defect. It could not find `状态.md`, making P4f ineffective.

### Causes

1. **No immediate complete host verification after framework tool or structure changes.** Neither task #109's move nor the `agent/` refactor prompted a rescan of the scripts' internal path assumptions.
2. **“Left to zlbdh” became verification debt.** P4g alone was tested, using the correct three-level `$repoRoot`; the entire script was not run, allowing stale P4a–d assumptions to escape.
3. This continued the #88/#89/#90/#91 blind-spot series: **the health-check scripts themselves had never been health-checked.**

### Corrections

- ✅ Changed both scripts' `$root`/`$projectRoot` from one ancestor level to three, matching P4g's correct `$repoRoot`; migrated P4a–c paths to `操作系统\` + `能力资产\`; added historical-archive exemptions to P4b.
- ✅ Executed the sandbox framework mirror: exit 0; P4a, 49 passed; P4c, zero dead-code findings; P4g, all passed, including ADR 32=32, meta-rule pool 15=15, and 100% frontmatter coverage.
- ⏳ Host application and a final verification rerun remained pending. This time the requirement was to confirm them immediately, **without leaving verification debt**.

### Candidate meta-rule

**After changing any framework tool or script, run the entire verification on the host; testing only the new section is insufficient.** This combines issue D, stale mounts, with issue DN, health-check quality. Candidate placement: ADR-032 decision 7 or a separate ADR.

## #93 — Project PM again asked instead of deciding under ADR-031

### Error

I closed the preceding item with “Should I go ahead and record this lesson?” That sent an obviously required documentation action back to zlbdh as though it needed approval. The repeated “You are Project PM” reminder followed the same pattern as #63/#77/#80/#83/#86.

### Cause

ADR-031's duty to make authorized decisions without deflection was already a **permanent rule, meta-rule 14**. This was an execution failure, not a missing rule. A habitual “Would you like me to…?” closing question disguised decision deflection as courtesy. Like #91, a soft rule failed at the closing step.

### Corrections

- ✅ Recorded the lesson immediately without another question: this file, the `状态.md` activity trail, and the INDEX pointer.
- Self-check: **if a closing “Would you like me to…?” or “Do you need me to…?” has an obvious yes answer, remove the question and do the work.** Perform the clearly required action; offer choices when genuinely different paths exist.

### Recorded lesson

No new ADR is needed because ADR-031 already covers this. Add a counterexample to Knowledge PM's category B quick-reference table, “External PM rules”: **a question used to close and defer the decision is a concealed form of ADR-031 deflection.**

**Lessons:** tools also need health checks, including a complete host run after changes (#92); courteous closing questions can be where an established decision rule fails (#93).

## Authoritative sources

- This session, 2026-05-29: the 16:30 PM transition entry in [`状态.md`](../../../../状态.md).
- Corrected scripts: `能力资产/tools/scripts/check-operating-system.ps1` and `check-pm-tracking.ps1`, with `FIX 2026-05-29` comments.
- Related patterns: [[pm-self-correction-91]], soft-rule failure; #63/#77/#80, the ADR-031 series.

## #94 — Repeated #92 while fixing it: Edit truncated a 21 KB output draft

### Error

After producing the correction, I used Edit to add an archive exemption to the 21 KB `check-operating-system.ps1` draft under outputs. **Edit truncated the end of a file above 6500 B**, removing “Next steps” and `exit 0` and leaving the partial line `Wr`. I copied it to the host without checking the tail, and the host failed at line 421 on `Wr`.

### Causes

- I followed AGENTS.md's rule to avoid Edit above 6500 B and use Python/Bash only for host framework files, **not for my own 21 KB outputs draft**. The draft was truncated too.
- I stated #92's proposed complete-host-rerun rule but did not perform it. After changing the correction, I did not rerun the full script in the mirror or on the host to check the tail; I trusted the mirror's exit 0 from **before the edit**.

### Corrections

- ✅ Used host `truncate` to cut at the end of line 420, then appended the correct tail with Bash as a small operation rather than a whole-file rewrite. PowerShell parsing passed, and a diff confirmed that the body matched the clean version line for line.
- ✅ Strengthened the lesson: **after writing any file above 6500 B, including an outputs draft, check its final bytes and lines.** Edit can truncate drafts too.

### Candidate reinforcement

Extend #92: **verify the tail after every Edit/Write/cp operation on a file above 6500 B, whether a host file or a draft.** Issues D and DN converge here; promotion to an ADR was deferred to the next governance Sprint.

## #95 — Contradictory handoff acceptance criteria: no test inspection before requiring zero test edits

### Error

The CA+CB handoff required AC #2, “zero changes to existing tests,” and AC #3, “Chat.jsx below 8 KB.” However, `Chat.test.js` used **source-text grep contracts**, with about 13 assertions pinning logic strings to `Chat.jsx`. Moving the logic into `useChatController.js` for CA necessarily broke those grep assertions. The two criteria were mutually exclusive. I wrote “zero test edits” without inspecting `Chat.test.js`.

### Cause

This repeated PM correction #54: **assuming the actual shape of tests or callers before inspecting them while drafting the handoff**. #54 concerned caller import style; #95 concerned test contracts. Both wrote acceptance criteria from assumptions.

### Correction

- ✅ Claude Code caught the conflict during implementation and escalated to PM through AskUserQuestion, showing that issue CD's safeguard worked. zlbdh chose option A: move the grep target with the relocated code while preserving assertion regexes byte for byte, following the PROP-024 SuggestionCard precedent. AC #2 was revised; CA+CB shipped as v3.10.1 with zero business incidents.

### Recorded lesson

Strengthen issue CD's PM handoff-verification checklist: when source-text grep contracts accompany a splitting refactor, explicitly allow their target to follow the code in the acceptance criteria. CD remained a candidate, without a new ADR yet.
