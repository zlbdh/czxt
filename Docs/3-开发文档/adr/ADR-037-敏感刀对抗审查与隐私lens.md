# ADR-037 · Adversarial review of sensitive changes + a privacy lens

- **Status**: Current
- **Date**: 2026-06-09
- **Decision maker**: zlbdh approved; Knowledge PM drafted, PROP-043.
- **Related**: RETRO-017, armedClear bypass and five allergy paths; RETRO-020, Bacillus cereus in packed rice and M deviation privacy; meta-rule DT.

## Context

Pre-shipping ultracode adversarial review repeatedly found real problems in data, safety, and irreversible changes: armedClear confirmation bypass, v3.27; five missing allergy-injection paths, v3.29; packed-rice Bacillus cereus toxins that reheating cannot remove, "fried rice syndrome," a real harm risk in v3.39; and sensitive M deviation behavior records, made individually deletable in v3.42. These are safety/privacy boundaries, not ordinary feature bugs. The framework needs permanent rules for mandatory review and privacy checks on data changes.

## Decision

- **DT: Mandatory adversarial review of sensitive changes**. Before shipping, **ultracode adversarial review is required**, using multiple adversarial lenses rather than self-review, if any condition applies:
  - User-data deletion or irreversible operations, such as armedClear.
  - Health or food-safety advice: food, reheating, storage, exercise load.
  - Data-schema migration, in addition to ADR-036.
  - Sensitive user data injected into LLM prompts.
- **Privacy lens for data changes**, a mandatory DT dimension when sensitive data is involved:
  - Minimize: Truncate raw sensitive content by code point to avoid splitting emoji.
  - Local only: Store sensitive data in local IndexedDB; only aggregated, de-identified data may enter prompts. Original wording/reason must never enter a prompt or the network.
  - User control: Each sensitive record must be individually deletable.
  - Neutral tone: Use "understand your own rhythm," not punishment/failure language.
- Purely deterministic, copying-only, or UI-display changes without data, safety, or irreversible effects are exempt to maintain speed.

## Consequences

### Benefits
- Harm/privacy boundary violations are intercepted before shipping. Rice toxins or omitted allergy constraints could cause real incidents.
- A fixed sensitive-data checklist replaces ad hoc privacy decisions.

### Costs
- One additional adversarial-review round before sensitive changes ship.
- Four privacy-lens requirements constrain data-change design.

### If the decision is reversed later
- Removing mandatory review returns to self-review but reintroduces the risk of shipping safety violations. Strongly discouraged: this is a user-safety baseline.

---

## Notes
This ADR connects to the three behavior classes. Class C defines what must never be touched; DT requires review when adjacent areas are involved. ultracode's multi-lens mechanism is a tool capability; this ADR specifies when it is mandatory.
