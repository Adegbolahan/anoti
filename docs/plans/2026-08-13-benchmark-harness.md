# Benchmark Harness (H1–H3 experiment runner)

**Spec:** docs/specs/2026-08-13-exp-h1-h3-benchmark.md

**Goal:** everything needed to execute
`docs/specs/2026-08-13-exp-h1-h3-benchmark.md` exists and is structurally
tested — fixture, answer key, session scripts, arm builders, runner,
grader rubric — so the run itself is a decision, not a project.

**Architecture:** a `benchmark/` directory: static fixture template +
planted `answer-key.json` (kept outside arm workdirs at run time), a
`sessions.json` task script (S1–S6 with per-prompt trivial/nontrivial
labels and interactive markers), an arm-C builder that concatenates anoti
skill content into a CLAUDE.md (instructions-only arm), and a `run-arm`
bash runner that prepares a fresh workdir per arm, toggles the
user-scoped anoti plugin (disable for A/C, enable for B, restore after),
loops sessions headless via `claude -p --output-format json` capturing
transcripts/usage/timing to `docs/trials/`, and pauses with instructions
at the two scripted interactive points. Tech: bash + jq; no new deps.

**Global constraints:** answer key never enters an arm workdir; runner
`--dry-run` never invokes claude; plugin state restored on exit (trap);
every artifact structurally tested in `tests/test_benchmark.sh`.

**Tasks:** (1) RED structural tests; (2) answer-key.json — 8 facts, 2
revisions, labels covering every prompt; (3) fixture template (~6-file
Python service embedding the planted facts); (4) sessions.json — S1–S6
prompts, traps at S4 (hard-delete vs tombstones-only) and S6 (stale
90-day retention vs revised 30), interactive markers at S1-close/S5-open;
(5) build-arm-c script; (6) run-arm runner with plugin toggling + capture

- dry-run; (7) grader-rubric.md mapping the spec's metrics to checks;
  (8) GREEN suite; commit.

**Out of scope:** executing the run (needs the human's scripted ~45 min
and token go-ahead); grading; any GROUNDING writes.
