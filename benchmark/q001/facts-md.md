# item-tracker — ground rules (read index, expand as needed)

## Index

- F1 identifiers: item IDs are ULIDs, never sequential integers
- F2 limits: max_items_per_user is 100 (revised: was 50)
- F3 storage: append-only JSONL backend
- F4 errors: typed codes E_VALIDATION, E_NOT_FOUND, E_LIMIT
- F5 time: UTC ISO-8601 timestamps, trailing Z
- F6 deletion: never hard-delete; tombstone records only
- F7 retention: 30 days (revised: was 90)
- F8 api: public API versioned under /v1

## F2 (revision history)

max_items_per_user began at 50 and was raised to 100 on 2026-08-13.

## F7 (revision history)

The retention window began at 90 days and was reduced to 30 on 2026-08-13.

All eight rules are ratified project decisions as of 2026-08-13.
