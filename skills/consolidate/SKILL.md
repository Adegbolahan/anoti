---
name: consolidate
description: anoti memory-write protocol — type candidates, cite evidence, route scope, append records and events, regenerate the index. Invoke when the Stop gate blocks or via /anoti:consolidate.
---

# Consolidate

The only path by which anything enters shared memory. The main session is
the single writer; agents (including the consolidator) only propose.

## Procedure

0. **No store? Bootstrap first.** If GROUNDING.yaml does not exist,
   create it from the plugin template (copy, then validate-workspace,
   regen-index, trust) before any candidate work — never substitute an
   ad-hoc memory file; ungoverned memory is the failure mode this skill
   exists to prevent (pilot finding, arm B).
1. **Collect candidates** from session state (`candidates:`) — or dispatch
   the consolidator agent to review the session and propose them.
2. **Type every candidate** — exactly one of: `claim` (falsifiable,
   evidence-bearing), `preference` (user taste), `decision` (choice +
   rationale), `goal` (desired state + success criteria), `policy`
   (operating rule). A value is never mislabeled as a claim.
3. **Citations:** a claim without evidence references is `speculative` at
   best; a claim whose statement cannot be falsified is rejected as a
   claim (retype or drop).
4. **Never-store filter:** credentials and secrets always rejected;
   health, legal, and financial details rejected by default.
5. **Dedupe** against both stores (`yq '.index'` on each). A near-duplicate
   becomes an evidence entry or a `refines` relationship on the existing
   record, not a new record. A contradiction is flagged (`contradicts`
   relationship + new open question), never resolved by overwrite.
6. **Scope routing:** about-this-project → project store; about-the-user
   or about-how-agents-work → global store. The human confirms routing —
   misfiled memory is worse than no memory.
7. **Present to the human:** statement, type, evidence, suggested scope.
   Approved candidates append as `ratification: approved` only if the
   human said so explicitly; otherwise `pending`. Claims enter at
   `speculative`/`probable` per their evidence — promotion to
   `established` happens only in /anoti:review.
8. **Append mechanics — always via the helpers, never hand-written:**
   records are immutable; every change is an appended `events:` entry.
   New records: build the record as JSON and pipe to
   `scripts/append-record <store>` (validates, runs regen-index and
   trust automatically). Status/ratification changes:
   `scripts/append-event <store> <id> <action> <by> "<note>"`. Episode
   transitions: `scripts/set-episode <session-id> <state>`. IDs allocate
   as max-existing + 1.
9. **After event appends:** run `scripts/trust <store>` (append-record
   does this itself; append-event leaves trust to the flow's end).
10. **Questions:** promote surviving report doubts to `open_questions`
    with `{id, date, question, raised_by, context, status, refs}`.
11. **Run the session retrospective** (policy-retrospect, universal):
    what went well, what didn't, what to skillify, what to learn, what
    cannot be automated — each cited to the trail. Route: lessons →
    LESSONS-LEARNT.md; skillify candidates → TODOS.md; cannot-automate
    boundaries → LESSONS-LEARNT.md (promotable to `policy` records).
    Trivial sessions route nothing — silence is the fast path.
12. **Close the episode:** `scripts/set-episode <session-id> committed`.
    Also update TODOS.md (done/new items) and LESSONS-LEARNT.md (a lesson
    that becomes falsifiable and gathers evidence graduates into a claim
    later).

In human-absent contexts: candidates queue in session state, everything
that would need ratification waits, and nothing lands above `pending`.

## Write discipline (YAML flow scalars)

In flow-style maps, any scalar containing `", "` or `": "` MUST be
double-quoted — unquoted, YAML silently splits it into spurious keys and
the corruption looks valid. Prefer block style for long notes. The
validator rejects unknown keys in `source`/`events`/`evidence`, which
catches this class after the fact; quoting prevents it.
