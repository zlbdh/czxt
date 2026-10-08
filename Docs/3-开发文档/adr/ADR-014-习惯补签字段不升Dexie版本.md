# ADR-014 · Add Habit Backfill Fields Without Increasing the Dexie Version

- **Status**: Current
- **Date**: 2026-05-11
- **Decision maker**: zlbdh / Mimi
- **Related**: F-006

## Context

F-006 distinguishes same-day check-ins from later backfills, marking backfilled dates with `⏪`. The existing `habits` table only has a `checkIns` date array and cannot identify which check-ins were backfilled.

Options:
- A. Add nested `backfilledDates: string[]` to `habits`, without an index or Dexie version increase.
- B. Upgrade Dexie v2 → v3 and add an indexed field to `habits`.
- C. Create a separate `habitBackfills` table.

F-006 only reads and writes backfill state within one habit object; it requires no cross-table query by backfill date. B/C add schema migration and table relationships without enough current benefit.

## Decision

Choose A: append nonindexed `backfilledDates: string[]` to the `habit` object. Leave `db.version(2).stores(...)` unchanged and do not upgrade to Dexie v3.

Boundaries:
- New default habits receive `backfilledDates: []`.
- Existing records may omit it; application logic treats absence as an empty array.
- Only `backfillHabit` writes this field. Same-day `toggleHabit` continues writing only `checkIns`.
- Consider v3 or a separate table later if all-backfill lists or date-based statistics are needed.

## Consequences

### Benefits
- No IndexedDB schema migration, reducing risk to existing device data.
- Small F-006 code surface, centered on a single habit object.
- Existing habits remain compatible; pure-function tests cover the missing field.

### Costs
- IndexedDB cannot directly query `backfilledDates` through an index.
- Code and documentation enforce the data contract, rather than a Dexie schema string.
- Cross-habit statistics would require a subsequent schema/data migration decision.

### Reconsideration
- If query performance or independent audit records become necessary, create ADR-015 and upgrade to Dexie v3 or a `habitBackfills` table.
- Migration: iterate over `habits` and expand `backfilledDates` into table records or indexed fields.

## Implementation Record

- `{{APP_REPO_DIR}}/src/shared/database.js`: add `backfilledDates: []` in `createDefaultHabits()`.
- `{{APP_REPO_DIR}}/src/shared/habitBackfill.js`: treat the missing field as an empty array.
- `Docs/3-开发文档/数据库schema.md`: document nonindexed field semantics.
