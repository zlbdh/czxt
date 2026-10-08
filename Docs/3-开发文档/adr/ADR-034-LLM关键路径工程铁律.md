# ADR-034 · LLM critical-path engineering rules (deterministic guard + marker acceptance + aligned multilayer gates + bounded prompt verbs)

- **Status**: Current
- **Date**: 2026-06-09
- **Decision maker**: zlbdh approved; Knowledge PM drafted, PROP-043.
- **Related**: RETRO-018, four-round sodium feature saga; RETRO-019, five-round G-F6 recurring-booking effort; meta-rules DO + DP.

## Context

This session's sodium feature, v3.34 with four smoke rounds, and G-F6 recurring bookings, v3.36 with five rounds, both repeatedly passed real Node calls and failed on devices: nine rounds in total. Root-cause review found that this was not implementation quality but **putting LLM output on a critical path without observability or determinism**. Sodium control remained invisible model reasoning that smoke tests could not verify. Recurrence was requested from the LLM instead of computed from canonical input. Updating only one layer of the prefilter RE → prompt → normalize → fallback chain caused G-F6 to fail again. These lessons must become permanent critical-path design rules.

## Decision

Every feature change involving an LLM call follows four rules. DO/DP become meta-rules; the other two are details of this ADR:

- **DO: Deterministic guard, with canonical machine-readable input regex as authority and LLM as fallback**. For structured fields such as day N of each month, month M/day N each year, or numbers, use authoritative regex from the first implementation to override null, malformed, or wrong-frequency LLM output: `extract(original) || normalize(llm)`. Remove the LLM from the critical path; use it only for noncanonical input.
- **DP: Marker acceptance criteria for LLM behavior constraints**. From the first implementation, define the visible output fields/keywords required by acceptance and decide smoke criteria on the same card. Hidden constraints without a smoke-testable artifact are prohibited.
- **Align vocabulary throughout multilayer gates**. Adding or removing anchor terms in any prefilter RE, prompt example list, normalizer, or fallback requires a matching update across the chain. G-F6 added the haircut term only to RE layer 1 and omitted prompt layer 2, causing a repeat failure.
- **Bound action-inducing prompt verbs**. Verbs such as replace, delete, or avoid must include boundaries such as "do not displace the original; supplement only." In v3.34, "replace" induced MiMo to remove sodium-containing seasonings entirely, causing the missing-seasoning bug.

## Consequences

### Benefits
- Critical paths use deterministic calculation and verifiable markers instead of uncertain model behavior, addressing the root cause of Node-pass/device-fail debugging.
- Defining marker acceptance immediately gives smoke tests observable artifacts and avoids three to five rounds of rework.

### Costs
- Higher initial design cost for each LLM change: canonical boundaries and markers must be defined.
- Guard regex requires maintenance when canonical input patterns expand.

### If the decision is reversed later
- Reversal is cheap because these are prompt/pure-function conventions: remove the deterministic guard and return to pure LLM handling. This reintroduces unobservable edge behavior and is not recommended.

---

## Notes
DP complements ADR-030's CC token-budget device evidence: CC governs headroom; DP governs behavior observability. DO shares ADR-033's principle of distrusting uncontrolled sources and using deterministic safeguards.
