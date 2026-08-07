---
description: Review the implementation before commit, and satisfy the commit gate
---

You are reviewing the current implementation before it can be committed. Never
rubber-stamp.

## The contract

The commit gate does not care who reviews. It cares about one thing:

> the phase is `review_passed`, set with `--evidence` pointing at a review report
> that exists and is newer than the last source edit.

That is the whole interface. **Any** process can satisfy it: this command, a
deeper review tool you already run, a human reading the diff. The gate records
the evidence path and a content hash so a pass is traceable to what produced it.

**If you have a stronger reviewer available, use it instead of this file.** Run
it, have it write a report, and point `--evidence` at that report. This command
is the reference implementation, not the only one — it exists so the gate is
satisfiable on a machine with nothing else installed.

**On the limits.** Anything that can write a file can satisfy this check,
including you. It is a guardrail against drift and accident, not an adversarial
control. Fabricating a report to get past the gate is an integrity failure, not
a clever workaround. If you cannot honestly pass the review, say so and stop.

---

## Step 0: Enter review

```bash
.claude/project/workflow-state.sh advance under_review
```

Source edits are warned against while this is set.

## Step 1: Scope the review

Read the active story and what changed:

```bash
STORY=$(.claude/project/workflow-state.sh get-story)
CYCLE=$(.claude/project/workflow-state.sh get-review-cycle)
git diff --stat
```

Read the feature spec at `.claude/project/features/us-*.md` and the plan at
`.claude/project/plans/us-*-plan.md`. **Re-read them properly.** The most common
review failure is reviewing what you remember building rather than what was
asked for.

Decide which dimensions below actually apply to this diff. A CLI tool has no
frontend; a docs change has no security surface. Reviewing a dimension that does
not apply produces noise, and noise trains people to skip reviews.

## Step 2: Review

For every dimension that applies, map each finding to a specific `file:line`.
A finding without a location is not a finding.

**Acceptance criteria.** Map every AC in the spec to the code that implements
it. Any AC you cannot point at is a BLOCKER.

**Correctness.** Trace the shadow paths, not just the happy one: nil input,
empty input, upstream failure. Check state transitions leave the entity in the
state you expect, not a stale one.

**Error handling.** Every failure mode either retries, degrades with a message
the user can act on, or re-raises with added context. Catch-alls that swallow
and continue are a defect. Ask what the user actually sees.

**Tests.** Check these categories, and treat any applicable one with zero
assertions as a BLOCKER:

- authorization: unauthorized access is rejected
- input validation: malformed input returns a proper error
- state transitions: after action X, the entity is in state Y
- error handling: expected failures return the right status and message
- edge cases: empty, boundary, concurrent

**Security**, where the diff touches a trust boundary: authorization on every
protected path, no secrets in code or logs or error messages, input validated
and sanitized, no injection vector introduced.

**Frontend**, where the diff touches UI: loading, empty, error and success
states all exist; destructive actions confirm; keyboard and screen-reader
access work.

## Step 3: Build gate

These must pass regardless of what the review found:

1. Type checking — zero errors
2. Lint — zero warnings
3. Tests — all pass

Add any failure to the blocker list.

## Step 4: Record the outcome

### If blockers exist

```bash
.claude/project/workflow-state.sh set-findings '["blocker one","blocker two"]'
.claude/project/workflow-state.sh advance changes_requested
```

Then fix every blocker in priority order and run `/review` again. Do not ask
whether to fix — fix, then re-review.

**Cycle cap (MANDATORY).** Before re-running:

```bash
.claude/project/workflow-state.sh get-review-cycle
```

**If it is 3 or higher, STOP.** Do not re-review. Report which blockers survived
every cycle, what you tried each time, and why you think it is not converging.
Then wait for direction. A blocker that survives three attempts needs a design
decision, not a fourth attempt. The commit stays blocked, which is correct.

### If there are no blockers

Write the report to disk first — the gate requires it as evidence.

```bash
mkdir -p .claude/project/reviews
REPORT=".claude/project/reviews/$(echo "$STORY" | tr '[:upper:]' '[:lower:]')-cycle-${CYCLE}.md"
```

Write the full report (format below) to `$REPORT`, then:

```bash
.claude/project/workflow-state.sh set-findings '[]'
.claude/project/workflow-state.sh advance review_passed --evidence "$REPORT"
```

If that command fails, do not work around it. All three failures are real:

- `requires --evidence` — you did not write a report. Write it.
- `evidence file not found` — the path is wrong.
- `evidence predates the last source edit` — source changed after the review
  ran, so the report describes code that no longer exists. Re-review.

## Report format

Write this to `$REPORT`, and print it:

```
REVIEW: US-XXX — [Story Title] (cycle N)

Dimensions reviewed: [list the ones that applied, and why the others did not]

ACs:        X/Y met
Correctness: Pass/FAIL — [details]
Errors:     Pass/FAIL — [details]
Tests:      Pass/FAIL — [categories covered: N/5]
Security:   Pass/FAIL/NA — [details]
Frontend:   Pass/FAIL/NA — [details]
Build:      Pass/FAIL — [type, lint, test counts]

Blockers: [numbered, each with file:line, or "none"]
Warnings: [numbered, or "none"]

Status: READY / NOT READY (cycle N)
```
