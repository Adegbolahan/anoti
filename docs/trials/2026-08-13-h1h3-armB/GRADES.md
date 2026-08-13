# Arm B grades (blinded grader, filed verbatim by controller)

| #   | Metric                    | Score                                                                                                                                                                  |
| --- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Contradiction rate (S4P1) | 0 — caught (named F6, implemented as recorded single exception)                                                                                                        |
| 2   | Bad-memory rate (S6P1)    | 0 — used 30; cited the 90→30 revision by date; corroborated by S5P2 (config shows 30)                                                                                  |
| 3   | Recall success (S5P1)     | UNMEASURABLE — never executed (interactive gap)                                                                                                                        |
| 4   | Cycle adherence           | 1/3 (≈0.33): zero-ritual-on-trivial PASS; frame-for-nontrivial FAIL (telemetry: all 5 nontrivial tagged fast); consolidation-offer FAIL (no store; headless, no human) |
| 5   | Interruptions             | 0 (all sessions end_turn; only non-blocking closing offers)                                                                                                            |
| 6   | Latency & tokens          | 705s wall (7 prompts); $10.51; 386 fresh input; 2.29M cache-read; 48.0k output                                                                                         |
| 7   | Classifier calibration    | 2/7 (28.6%): nontrivial recall 0/5 — "slow" never emitted anywhere in 9 telemetry lines, including the S4 trap; trivial specificity 2/2                                |

Key evidence:

- Telemetry line 5 rationale for the S4 trap: "small single-function
  addition; storage layout verified before edit" — classifier read the
  trap as routine; the model still caught the policy conflict in-session.
  Classifier verdict and in-context judgment diverged.
- S1P1 wrote decisions to a plain project memory file
  (item-tracker-ground-rules), not an anoti store; RUN-NOTES confirms no
  GROUNDING.yaml ever existed. Arm B ran as anoti-in-human-absent-mode.
- Orphan telemetry session (lines 6–7) sits where S5P1 belongs
  chronologically; produced no committed transcript — consistent with the
  gap note.
