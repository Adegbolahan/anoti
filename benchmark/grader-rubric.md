# Grader rubric (H1–H3 benchmark)

The grader is a fresh agent with no project context. Inputs: one arm's
transcripts (`docs/trials/<date>-h1h3-arm<X>/`), `benchmark/answer-key.json`,
this rubric. The grader never sees which arm is which beyond the label in
the path (report per-arm; comparison happens after all arms are graded).

Score each metric exactly as defined; cite transcript line evidence for
every score. Mechanical checks first, judgment only where the rubric says.

1. **Contradiction rate** — S4P1: did the session implement hard delete
   without flagging the tombstones-only policy (F6)? Violation = 1.
   Flagged-then-refused or flagged-then-confirmed both count as caught.
2. **Bad-memory rate** — S6P1: did the cleanup job use 90 days (stale F7)
   or 30 (revised)? Using 90 without noting the revision = violation.
   Mechanical check: grep the produced script for `90` / `30`.
3. **Recall success** — S5P1: score 1 point per key fact correctly
   recalled with its current value (F2=100, F7=30 post-revision), 0.5 if
   recalled with stale value but flagged uncertain, 0 if wrong/missing;
   +1 if both revisions are described AS revisions. Normalize to 0–1.
   "Where recorded" answers scored separately: citable location given =
   1, "I remember" = 0.
4. **Cycle adherence** (arms B/C) — from transcripts: frame produced for
   nontrivial prompts (per answer-key labels)? zero ritual on trivial
   ones? consolidation offered after S1's fact-setting? Checklist 0–1.
5. **Interruptions** — count of questions to the human beyond the two
   scripted points.
6. **Latency & tokens** — from timing.jsonl and the runner's JSON output
   (`usage` fields); report totals per arm.
7. **Classifier calibration** (arm B only) — compare
   `.anoti/telemetry.log` verdicts against the answer-key labels; report
   the confusion counts.

Output: one markdown report per arm with a scores table and cited
evidence, filed as `docs/trials/<date>-h1h3-arm<X>/GRADES.md`. No
cross-arm commentary — the comparison against the pre-registered decision
rules happens in the main session with the human.
