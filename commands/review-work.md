---
description: Review the current implementation before it ships — the work review (distinct from /anoti:review, the memory ratification ritual).
---

You are reviewing the current implementation. Never rubber-stamp.

## The contract

A pass means: a review report exists on disk, newer than the last source
edit, with every finding mapped to `file:line`. Any process can satisfy
it — this command, a stronger review tool, a human reading the diff. If
you have a stronger reviewer available, use it and point the report at
its output. **On the limits:** anything that can write a file can satisfy
this, including you. It is a guardrail against drift, not an adversarial
control. Fabricating a report is an integrity failure, not a workaround.
If you cannot honestly pass the review, say so and stop.

## Step 1: Scope

Read what changed (`git diff --stat`) and re-read the spec and plan
**properly** — the most common review failure is reviewing what you
remember building rather than what was asked. Decide which dimensions
below apply to this diff; reviewing inapplicable dimensions produces
noise, and noise trains people to skip reviews.

## Step 2: Review (every applicable dimension; findings need file:line)

- **Acceptance criteria** — map every AC to implementing code; any AC you
  cannot point at is a BLOCKER.
- **Correctness** — trace shadow paths (nil, empty, upstream failure);
  state transitions land in the expected state, not a stale one.
- **Error handling** — every failure retries, degrades actionably, or
  re-raises with context; swallowing catch-alls are defects.
- **Tests** — an applicable category with zero assertions is a BLOCKER:
  authorization, input validation, state transitions, error handling,
  edge cases.
- **Security** (where a trust boundary is touched) — authz on every
  protected path, no secrets in code/logs/errors, inputs validated, no
  injection vector.
- **Frontend** (where UI is touched) — loading/empty/error/success states
  exist; destructive actions confirm; keyboard + screen-reader access.

## Step 3: Build gate

Type check (zero errors), lint (zero warnings), tests (all pass) — any
failure joins the blockers.

## Step 4: Outcome

**Blockers exist:** fix every blocker in priority order and re-run. Do
not ask whether to fix — fix, then re-review. **Cycle cap (MANDATORY):
at cycle 3, STOP.** Report which blockers survived, what was tried, and
why it is not converging — a blocker that survives three attempts needs a
design decision, not a fourth attempt (see D011: fix rounds resume the
original builder; findings relayed verbatim).

**No blockers:** write the report to
`docs/reviews/us-XXX-cycle-N.md` FIRST (evidence before assertion), then
declare READY. Report format:

```
REVIEW: US-XXX — <title> (cycle N)
Dimensions reviewed: <which applied, and why the others did not>
ACs: X/Y met | Correctness/Errors/Tests/Security/Frontend: Pass|FAIL|NA
Build: type/lint/test counts
Blockers: numbered with file:line, or "none"
Status: READY / NOT READY (cycle N)
```

A stale report (source edited after the review ran) describes code that
no longer exists — re-review.
