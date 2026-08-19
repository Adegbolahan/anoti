---
name: demo
description: anoti orientation — learn the workflows by routing table and a runnable hands-on tour. Invoke when new to a governed project, when unsure which anoti skill or command a situation calls for, or to teach a fresh subagent the system in one read.
---

# Demo

anoti in one sentence: **outsource some of the thinking, but never
outsource understanding** — the model does retrieval, deliberation, and
drafting; the human owns goals, values, and what enters shared memory.

## The cycle (what fires, and who fires it)

```
retrieve ──▶ attend ──▶ deliberate ──▶ act/inhibit ──▶ consolidate
(hook,       (skill,     (skill,        (hook gates     (skill, at the
 automatic)   slow path)  framed work)   risky tools)    Stop gate)
```

Hooks are automatic: session start injects the memory digest, every
real prompt is offered fast/slow classification (machine notifications
are exempt; the verdict is yours to log), risky tool calls —
Bash/Write/Edit/NotebookEdit — hit the inhibition table, and the Stop
gate blocks when memory candidates await, and every matched
Bash/Write/Edit/NotebookEdit call also fires the presence hook (JIT
recall, periodic frame re-anchor, an evidence-kind nudge) — silent
unless something actually matches. Skills are invoked: they carry the
procedures the hooks point you into.

## When to use what

| Situation                              | Use                                 | Why                                                                                                     |
| -------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Novel, ambiguous, or consequential ask | attend skill                        | frame before work; everything later traces to it                                                        |
| Multi-step or multi-role work          | deliberate skill                    | hypotheses, hat assignment, spawn budget, cascade                                                       |
| Building a feature end-to-end          | /anoti:implement                    | the full cycle with spec and review gates wired                                                         |
| About to commit anything               | git skill                           | branches (never the default branch), staging, finishing                                                 |
| Discovery worth remembering            | consolidate skill                   | typed candidates, helpers only, human ratifies                                                          |
| Need memory mid-task                   | /anoti:recall                       | query the stores instead of re-deriving                                                                 |
| Memory should fire by itself next time | append-trigger (consolidate step 2b) | encode the cue at consolidation — "what would I have needed to see?" — and the presence hook surfaces the record at tool-use time |
| See what the session-start digest says | `scripts/anoti digest`              | the SessionStart hook's output as plain text — stores, organs, recall coverage, drift                  |
| Quick keyword search, both stores      | `scripts/anoti recall <keywords>`   | the pull-side twin of the presence hook: same matcher, ranked, [global]-labelled                       |
| Implementation ready to ship           | /anoti:review-work                  | pre-ship drift check (not an adversarial control — that is policy-adversarial-handoff's reviewer spawn) |
| Drafting or amending ROADMAP / stories | direction skill                     | both direction organs are human-owned; format + freshness rules                                         |
| Pending records / promotions           | /anoti:review                       | the human ratification ritual                                                                           |
| Weekly health / staleness              | /anoti:audit                        | longitudinal metrics + staleness sweep                                                                  |
| anoti itself misbehaved                | feedback skill                      | field report → human-gated issue on the anoti repo                                                      |
| New or drifted workspace               | /anoti:new, /anoti:update, skillify | scaffold, migrate by ratified diff                                                                      |

## The three whys behind every rule

1. **Human structural role**: goals, ratification, and integration are
   the human's — new records enter marked `pending`/`speculative` and
   only the human promotes or approves them; nothing leaves the repo
   without the human's ruling.
2. **Epistemic discipline**: every claim cited or labeled judgment;
   hypothesis before test (policy-epistemic).
3. **Mechanical writes**: state and stores are written by helpers,
   never hand-edited — the helpers quote, validate, and stay atomic.

## Hands-on tour (5 minutes, scratch state only)

Run against a temp dir so the demo never touches real project state:

```
export ANOTI_DIR="$(mktemp -d)/.anoti"     # scratch — the whole point
P=<plugin-root>/scripts
$P/anoti-dir    # MUST print the scratch path. If it prints ".anoti",
                # the export did not take — STOP, or you write real state
$P/append-classification demo-tour slow "learning the cycle"
printf '{"id":"F1","goal":"learn anoti","status":"active"}' | $P/session-append demo-tour frames
printf '{"id":"c1","type":"lesson","statement":"helpers, not hand-edits"}' | $P/session-append demo-tour candidates
$P/set-episode demo-tour awaiting-approval
$P/session-consume demo-tour candidates --ids c1   # mark-applied, never deletion
$P/set-episode demo-tour committed
unset ANOTI_DIR                            # leave the sandbox
```

Then see memory act at the moment of use (reads the real stores, writes
nothing):

```
$P/anoti recall "falsifiable"      # pull side: both stores, ranked
# push side: run any Bash command containing a trigger phrase of a
# record you have triggers on — the presence hook injects the record
# into your next turn and logs a 'presence recall <id>' telemetry line
```

That was the session-state half of the lifecycle: classify → frame →
candidate → episode → consume. The store-write half (append-record into
GROUNDING.yaml, dedup, scope routing, the never-store filter) is
deliberately absent here — ANOTI_DIR redirects session state only, and
store helpers write to whatever file you name — so learn it in the
consolidate skill, where the human ratifies.

## Deeper

docs/SKILL-MAP.md (every path in and out), the design spec in
docs/specs/, docs/HIGH-LEVEL-STORIES.md (the value standard the frames
trace to).
