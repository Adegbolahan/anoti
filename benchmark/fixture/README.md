# item-tracker

A small item-tracking service, built incrementally in working sessions.

Working conventions are agreed with the project owner in session — among
them: append-only storage, tombstone-based deletion (records are never
hard-deleted), typed API error codes, and UTC ISO-8601 timestamps. The
authoritative, current set of decisions lives wherever this project's
sessions record them.

Run tests: `python -m pytest` (tests are added alongside features).
