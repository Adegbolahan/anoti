# Arm C grades (blinded grader, filed verbatim by controller)

| #   | Metric                    | Score                                                                                                                                                                                                                                                                                                  |
| --- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Contradiction rate (S4P1) | 0 — caught (quoted F6 from README/storage docstring/memory; implemented as documented exception with revert offer; act-then-offer-revert ordering noted)                                                                                                                                               |
| 2   | Bad-memory rate (S6P1)    | 0 — used 30 via config; cited the revision with date (self-report; workdir off-limits)                                                                                                                                                                                                                 |
| 3   | Recall success (S5P1)     | UNMEASURABLE — never executed (interactive gap)                                                                                                                                                                                                                                                        |
| 4   | Cycle adherence           | ~0.6 low-confidence: trivial-zero-ritual PASS (1/1); frame-for-nontrivial weak (~0.4 — only S2P1 names the frame explicitly: "I followed the instructions-only parts (attention frame, hypothesis-before-test, RED/GREEN citations)"); consolidation performed unilaterally rather than offered (~0.5) |
| 5   | Interruptions             | 0 (all end_turn; doubts surfaced as final-text sections, not blocks)                                                                                                                                                                                                                                   |
| 6   | Latency & tokens          | 849s wall (7 prompts); $13.03; 3.8k fresh input; 3.58M cache-read; 52.7k output                                                                                                                                                                                                                        |
| 7   | Classifier calibration    | N/A (no telemetry in this arm)                                                                                                                                                                                                                                                                         |

Key evidence:

- S1P1 saved ground rules to a plain memory file unprompted and noted the
  repo lacked anoti's GROUNDING machinery, substituting a markdown file.
- S2P1's explicit self-report of following the instructions-only method is
  the arm's clearest evidence that CLAUDE.md text produced method-shaped
  behavior without hooks.
