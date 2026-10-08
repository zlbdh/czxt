---
name: "pm-self-correction-74-87-batch"
scope: "pm-workspace"
pm: "项目PM-咪咪"
type: "episodic"
loaded: "triggered"
trigger: "Reviewing Sprint-8/9 PM corrections or issue CN v2 batch recording"
description: "Batch of PM corrections #74–#87: 12 Sprint-8/9 cases, recorded together under issue CN v2 instead of individual high-frequency artifacts."
---

# PM Corrections #74–#87: Sprint-8/9 Batch — Issue CN v2

> **Context:** Twelve frequent corrections occurred during May 22–28, 2026: Sprint-8 F-F1 and Sprint-9 F-F2+F-F4.
> **Issue CN v2:** Individual Markdown artifacts under PROP-030 could not keep pace; this batch uses one summary.
> **Common theme:** Collaboration blind spots exposed during the first cross-tool use of the v4.0 nine-PM/four-layer architecture.

## Batch inventory

| # | Finding | Issue | Cause category |
|---|---|---|---|
| #74 | Knowledge PM addressed zlbdh directly as “Curator recommends”; only Project PM should speak externally | DF | Meta/lead external-identity boundary |
| #77 | Project PM shifted a decision back through AskUserQuestion; zlbdh reminded it that it was Project PM and should decide | DH | Second recurrence of #63 |
| #78 | Cross-tool dispatch gave no complete startup prompt, only an instruction to start a new session | DI | Incomplete protocol |
| #79 | Handoff cited PRD MAX_TOKENS as 800 when it was 2000 | DJ | Issue G: literal recall versus actual checking |
| #80 | An 80-line startup prompt violated issue CO Progressive Context Loading | DK | Minimal entry-point failure |
| #81 | Token estimates failed repeatedly; raising 800 to 2000 was still insufficient | DJ | Continuation of #79; unverified estimates |
| #82 | Bash mount-cache grep/wc read old content and reported zero; Read verification was required | DG | Complements issue BK; wrong verification tool |
| #83 | Completed code was reported as a user-usable feature without distinguishing four states | DL | Ambiguous external reporting |
| #84 | F-F1 selected the minimum viable code implementation rather than minimum viable user value, producing an incomplete feature | DM | Product-decision blind spot |
| #85 | API-key Class C rule held; zlbdh's test did not trigger disclosure | — | Successful defense, not a correction |
| #86 | External reports overused F-F1/issue IDs; zlbdh could not understand them | DK extension | Failure to use plain language |
| #87 | Reflection on F-F1's incompleteness came after blockage rather than before the decision | DM extension | Decision timing |

## Shared causes: Knowledge PM cross-PM review

### External-identity rule failed repeatedly: #74/#77/#80/#83/#86

Five related recurrences followed #63: unauthorized attribution, avoiding decisions, long output, ambiguous reporting, and internal codes. Project PM's sole external identity also governs communication: plain language, brevity, four distinct states, and independent decisions.

### Missing reflection before decisions: #84/#87

F-F1 selection optimized the smallest code implementation instead of minimum viable user value. Reflecting only after blockage wasted nine Claude Code files of work plus Codex smoke testing.

### Unverified parameters/protocols: #78/#79/#81

Handoff parameters came from memory rather than actual checks. Issue CC was already permanent through ADR-030.

### Verification tool selection: #82

Bash mount-cache results were misleading. Use the Read tool with line numbers; this complements issue BK and forms issue DG.

## Proposed permanent rules: RETRO-013 assessment

| Issue | Candidate | RETRO-013 recommendation |
|---|---|---|
| DF | Internal meta-PM signals versus external Project PM speech | P1: promote to ADR-031, sharing origins with ADR-026 |
| DH | Project PM makes decisions without shifting responsibility | P0: three occurrences of #63's pattern |
| DK | Concise plain-language reporting with four distinct states | P0: three cases, #80/#83/#86; applies issue CO |
| DM | Reflect on minimum viable user value before decisions | P1 |
| DG | Verify through Read rather than trusting bash mount cache | P2: complements issue BK |
| DJ | Token-budget verification already covered by ADR-030 | Already permanent |

## Issue CN v2: improve the recording mechanism

Individual correction files under PROP-030 could not keep up with the recorded pace of 12 in a day.

- Batch related corrections from one Sprint into one summary plus an INDEX link.
- Retain individual files for major ⭐⭐⭐ corrections such as #63 external identity and #72 Knowledge PM's meta-level position.
- Submit issue CN v2 to RETRO-013 for possible ADR promotion.

This historical batch contains 12 entries and is the first trial of issue CN v2. DF/DH/DK/DM were awaiting RETRO-013 assessment for ADR-031 and later decisions.
