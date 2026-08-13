# Experiment: H1–H3 Comparative Benchmark (pre-registered)

**Status:** DESIGN — pre-registered before any run; results section empty by
construction. Amendments after the first run require a dated changelog entry
and invalidate direct comparison with earlier runs.
**Claims under test:** H1 (governed memory beats ad-hoc), H2 (structure
beats instructions), H3 (ratification prevents memory rot) — see design
spec "Why". Q001 (format comprehension) and fast-path calibration ride
along as modules.

## Arms

| Arm | Configuration                                                                       | Isolates                         |
| --- | ----------------------------------------------------------------------------------- | -------------------------------- |
| A   | Vanilla Claude Code — no plugin, stock memory                                       | baseline                         |
| B   | anoti installed (current version, pinned at run time)                               | whole system (A vs B)            |
| C   | Instructions-only — anoti's skill content concatenated into CLAUDE.md; **no hooks** | hooks specifically (B vs C → H2) |

Same model, same effort setting, same task script, same order, fresh
fixture project per arm. Arm order randomized per run day.

## Fixture and task script

A generated fixture project (small Python service, ~6 files) with a
**planted answer key** (`answer-key.json`, kept outside every arm's
directory): 8 facts/constraints/decisions the sessions will establish,
2 of which are later revised, plus per-prompt labels `trivial|nontrivial`
for calibration scoring.

Six scripted sessions per arm:

1. **S1 Establish** — user states constraints and decisions (from the key);
   normal feature work alongside.
2. **S2 Build** — feature depending on two S1 constraints.
3. **S3 Revise** — user changes one constraint; more build work.
4. **S4 Contradiction trap** — a request that violates an established
   constraint. Measured: does the system flag it or comply silently?
5. **S5 Recall probe** — "what did we decide about X and why, cite where";
   scored against the key.
6. **S6 Stale trap** — a request that is only correct under the pre-S3
   constraint. Measured: acts on stale fact vs current one.

**Human-interaction protocol (honest constraint):** anoti's ratification
requires a human. Sessions run headless _except_ two designated
interactive points per arm-B/C run (S1-close consolidation, S5-open
review), driven by the user from a fixed response script (~15 min total
human time per run). Arm A gets equivalent interactive time to avoid an
attention confound. Headless portions of arm B exercise the queue path —
reported separately, never blended into ratification metrics.

## Pre-registered metrics

| Metric                 | Definition                                                                                           | Source                         |
| ---------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------ |
| Contradiction rate     | violations acted on ÷ trap opportunities (S4, S6)                                                    | grader vs key                  |
| Recall success         | S5 factual accuracy, 0–1 rubric                                                                      | grader vs key                  |
| Bad-memory rate        | actions taken on stale/wrong remembered facts                                                        | grader vs key                  |
| Cycle adherence (H2)   | checklist: frame on nontrivial, zero ritual on trivial, consolidation offered when discovery present | transcript checklist           |
| Interruptions          | human escalations per session                                                                        | count                          |
| Added latency          | session-start delta vs arm A                                                                         | timing log                     |
| Token cost             | total tokens per arm                                                                                 | transcript accounting          |
| Classifier calibration | fast/slow verdicts vs per-prompt labels                                                              | `.anoti/telemetry.log` (arm B) |

**Grading:** a fresh grader agent with no project context scores
transcripts against the key and rubric; mechanical checks preferred
(planted canary strings, executed tests). The human spot-audits ≥ 20% of
grader verdicts — measurement itself gets ratified.

## Pre-registered decision rules (pilot, n=1 sequence per arm)

- **H1 supported** if arm B beats arm A on ≥ 2 of {contradiction rate,
  recall success, bad-memory rate} with no metric worse, at ≤ 1.5× arm A
  token cost. **Against** if B is better on none, or worse on any while
  costing more.
- **H2 supported** if arm B beats arm C on cycle adherence AND at least
  one trap metric. **Against** if C matches B (instructions suffice —
  hooks demote to convenience).
- **H3 supported** if arm B's bad-memory rate < arm C's (ratified store
  vs unratified accumulation). **Against** on tie or inversion.
- Ambiguous outcomes: recorded as evidence with the ambiguity stated;
  no rule may be reinterpreted post hoc. A pilot moves claims at most one
  ladder step; `established` requires a second independent run.
- **Either direction is honored:** supporting evidence promotes; opposing
  evidence demotes H-claims and files the corrective lesson. The
  benchmark exists to risk the thesis, not to decorate it.

## Q001 module (rides along)

After S5 in each arm, one probe: the same 8 key facts presented in
schema-v3 YAML vs agent-oriented Markdown; comprehension scored by
question-answering; token counts recorded per tokenizer. Moves Q001's
verification forward regardless of H-outcomes.

## Cost estimate (honest)

18 scripted sessions plus grading: roughly 3–5M tokens end-to-end, and
~45 minutes of scripted human time. Not cheap; pre-registration exists so
it only has to be paid for evidence that counts.

## Results

_(empty until run; grader outputs and raw logs filed under
docs/trials/ with this spec's date prefix)_
