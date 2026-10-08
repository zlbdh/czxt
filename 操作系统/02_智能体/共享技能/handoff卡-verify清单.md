---
name: verify-checklist-handoff
description: Seven checks before handoff/ship cards, based on issue CD and self-corrections #51–54.
trigger: Before writing a handoff, ship card, or PROP.
loaded: on-demand
---

# Handoff Verification Checklist — Issue CD Candidate

## Historical triggers

Four self-corrections:

- #51: AC2 changed from 50 to 100 characters after evidence replaced an arbitrary limit.
- #52: AC7 user control, philosophy v3.0 section 22.
- #53: empty MiMo thinking responses related to max_tokens and runtime postprocessing.
- #54: handoff step 8 contradicted AC2 because caller import style was not verified.

## Seven checks

Run these during the minute before writing a handoff, ship card, or PROP:

- [ ] Verify actual code: caller imports, module entries, tab configuration, and path conventions.
- [ ] Ground acceptance numbers in evidence; avoid arbitrary character/minute limits, following issue CC.
- [ ] Cross-check consistency between procedural steps, hard acceptance constraints, and warnings.
- [ ] Use this project's `main` branch name rather than `master`; the historical guidance references GitHub's default change after 2020.
- [ ] Use a measured historical APK size, not a guess.
- [ ] Keep the execution prompt at ten lines or fewer, following reflection 3.
- [ ] Under philosophy v3.0, new features require a settings toggle for user control, rule 25.

## Escalation status

Issue CD remains in the candidate pool after RETRO-013. See the [candidate meta-rule pool](../../01_架构/元规则池-候选.md).

## Authoritative sources

- `操作系统/05_记忆/INDEX.md`, section 2, reflection 4.
- RETRO-011's self-correction #54 case study.
- `PM工作区/项目PM-咪咪/PM自纠/INDEX.md` and records `PM自纠-54.md`, `PM自纠-58.md`, `PM自纠-59.md`, `PM自纠-60.md`, and `PM自纠-61.md`.
