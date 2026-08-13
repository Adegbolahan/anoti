---
name: feedback
description: anoti feedback loop — capture plugin-caused friction as a cited field report and route it, human-gated, to GitHub issues on the anoti repo. Invoke the moment anoti itself misbehaves (helper errors, hook false positives, unclear skills, guardrail misfires) or when the retrospective surfaces such friction.
---

# Feedback

The improvement loop US-008 promises, pointed at anoti itself: every
governed project is a field site, and friction unreported is a fix
nobody gets. Two field-report batches produced releases 0.5.2 and 0.5.4
— this skill is that procedure, made invocable.

## When

- **The moment anoti misbehaves**: helper errors, hook false positives
  or negatives, unclear or contradictory skill instructions, guardrail
  misfires, digest noise, stale paths. Capture at the friction moment —
  evidence evaporates by session end.
- **At retrospect time**: policy-retrospect's "what didn't" routes
  anoti-caused friction here.
- **Never for the governed project's own bugs** — those belong to the
  project's tracker, not anoti's.

## Field report (one per distinct friction)

1. **Symptom** — one observable sentence.
2. **Expected vs actual** — what the skill/helper/hook promised versus
   what happened.
3. **Version** — the plugin version the friction occurred under (the
   newest dir in the plugin cache). Before reporting, check whether the
   anoti repo's newest release already fixes it — report against the
   fix if unsure whether it landed.
4. **Evidence** — exact paths, commands, telemetry lines, transcript
   moments. A report without evidence is an anecdote
   (policy-epistemic: cite it or label it judgment).
5. **Impact** — what it cost this session: time, wrong output, a block.
6. **Suggested direction** — optional, labeled judgment.

## Routing — human-gated, always

1. **Dedup first**: `gh issue list -R Adegbolahan/anoti --state all
--search "<keywords>"`. Comment on an existing open issue instead of
   duplicating; a closed issue that regressed gets the new evidence and
   a reopen proposal, not a twin.
2. **Draft** the issue title + body from the field report and present
   the draft in full.
3. **The human gates the send.** Issue creation is outward-facing
   (policy-escalate-destructive): **never file without** the human's
   explicit approval of the drafted text in this conversation — then
   `gh issue create -R Adegbolahan/anoti`.
4. **Human absent, or gh unavailable**: queue the draft —
   `mkdir -p "<state-dir>/feedback"` then write it to
   `<state-dir>/feedback/YYYY-MM-DD-<slug>.md` (the state dir is
   gitignored; cleanup-session touches only session files, so the queue
   survives), and append one pointer line to `<state-dir>/pending.md`
   (`- queued feedback draft: <path> — propose when a human is
present`). pending.md is the **single** human-absent surface — the
   SessionStart digest already announces it — so queued drafts resurface
   every session until proposed; `feedback/` only stores the documents.
   The gate is deferred, never skipped.

## Binds

policy-retrospect (routes friction here), policy-epistemic (evidence
discipline), policy-escalate-destructive (the send gate and the
pending.md queue-and-defer rule), the SessionStart digest (pending.md
line surfaces queued drafts).
