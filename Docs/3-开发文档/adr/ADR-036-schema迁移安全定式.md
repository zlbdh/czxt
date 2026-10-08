# ADR-036 · Safe schema migration (four edits for a new table + zero-data-loss device smoke)

- **Status**: Current
- **Date**: 2026-06-09
- **Decision maker**: zlbdh approved; Knowledge PM drafted, PROP-043.
- **Related**: RETRO-020, E weight chart v15 + M deviation records v16; meta-rule DS; follows ADR-014, habit backfill without a version bump.

## Context

About 28 changes deliberately avoided Dexie version bumps through schemaless profile spreads or reuse of existing tables. E weight charts, v3.41 / IndexedDB v140→v150, intentionally broke that pattern; M deviation records, v3.42 / v150→v160, followed. Both demonstrated a safe upgrade pattern on-device and a serious trap: omitting the new table from exportAllData loses backup data, adjacent to a Class C prohibition. Every future schema bump needs a mandatory checklist.

## Decision

- **DS: Safe schema migration**. Adding a Dexie table requires all four edits and one device check, without exception:
  1. `schema.js`: `V_N_STORES = {...V_{N-1}_STORES, newTable}` + `db.version(N).stores()`. 🔴 **No .upgrade() callback**: this is a new empty table; Dexie's incremental upgrade creates it without touching old tables, preserving data. Never change existing store definitions.
  2. `snapshot.js · exportAllData`: **Add the new table name to the tables array**. Omitting it excludes the data from backups and loses it after export/import, adjacent to a Class C boundary.
  3. `snapshot.js · loadSnapshot`: Fault-tolerant `db.newTable?.toArray().catch(()=>[]) || []`, returning an empty array for an old database without the table.
  4. `useAppData.js`: Add `newTable: []` to initial state as a setData fallback.
  5. 🔴 **Zero-data-loss device smoke**: Install the old version, create data, install the new version over it, and verify every old-table item remains and the IndexedDB version advanced correctly.
- Scope: This pattern covers new tables only. **Changing existing structures or migrating data with .upgrade() sharply increases risk: stop for dedicated design and ultracode review**. It is outside this expedited path.

## Consequences

### Benefits
- Schema bumps become checklist-driven safe operations, with two zero-loss device demonstrations.
- Removing the self-imposed schemaless restriction enables features needing data infrastructure, such as daysLeft / monthly reports.

### Costs
- Four edits and an upgrade smoke test for every bump, more work than schemaless changes.
- ultracode review is still required under ADR-037.

### If the decision is reversed later
- Reversal is difficult once user data exists in the new schema and requires migration. Confirm necessity before a bump; prefer schemaless changes where feasible, following ADR-014.

---

## Notes
This does not conflict with ADR-014. ADR-014 says to avoid Dexie version bumps when possible; ADR-036 explains safe bumps when necessary. Together they govern Dexie versions.
