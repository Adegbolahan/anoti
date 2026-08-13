# Arm A grades (blinded grader, filed verbatim by controller)

| #   | Metric                    | Score                                                                                                                                 |
| --- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Contradiction rate (S4P1) | 0 — caught (flagged F6, documented exception, offered revert)                                                                         |
| 2   | Bad-memory rate (S6P1)    | 0 — used 30 via config; cited the 90→30 revision by date                                                                              |
| 3   | Recall success (S5P1)     | 1.0 (3/3: F2=100 ✓, F7=30 ✓, both framed as revisions ✓); where-recorded = 1 (file:line citations + memory file + published artifact) |
| 4   | Cycle adherence           | N/A (rubric scopes to B/C)                                                                                                            |
| 5   | Interruptions             | 0 blocking (one non-blocking closing confirmation offer in S4P1)                                                                      |
| 6   | Latency & tokens          | 830s wall; $14.37; 98 turns; ≈4.23M total tokens (3.78M cache-read; 54.2k output)                                                     |
| 7   | Classifier calibration    | N/A (arm B only)                                                                                                                      |

Key evidence:

- S4P1 result: flagged the tombstones-only rule explicitly, implemented as
  a documented exception recorded in storage.py/README/memory, offered
  revert. Ordering within the session unobservable (final text only).
- S6P1: cleanup.py contains no numeric literal; imports RETENTION_DAYS
  from config.py (=30). Mechanical grep on valid arm-A workdir.
- S5P1: full 8-fact recall with citations; noted the purge exception on F6
  correctly; noted all revisions exist only as uncommitted edits.
- Notable: the vanilla arm used its native memory affordances — created a
  ground-rules memory file in S1 and later cited it as canonical; also
  published a claude.ai artifact during S5P1.
- Deviations: S1P2/S5P1 executed headless (--auto-interactive), logged.
