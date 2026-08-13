---
description: Manual consolidation fallback — run the anoti memory-write flow now instead of waiting for the Stop gate.
---

Run anoti consolidation for the current session:

1. Load the consolidate skill (`skills/consolidate/SKILL.md`) and follow
   its procedure end to end.
2. Set the episode mechanically: `scripts/set-episode <session-id>
   awaiting-approval` before any store write (the inhibition hook requires
   it — memory-organ writes outside an active consolidation flow are
   denied). Never hand-edit session YAML.
3. Collect candidates from session state; if the session was long or the
   candidates look incomplete, dispatch the consolidator agent to review
   and propose.
4. Present each candidate to the human — statement, type, evidence, scope
   routing — and apply only what they approve.
5. Apply writes via the helpers only: new records as JSON through
   `scripts/append-record` (which validates, runs regen-index, and
   re-trusts), events through `scripts/append-event`, then
   `scripts/trust` on each touched store; promote surviving doubts to
   `open_questions`; update TODOS.md and LESSONS-LEARNT.md; finish with
   `scripts/set-episode <session-id> committed`.

If session state shows no candidates and the consolidator finds none, say
"nothing to consolidate" and set the episode to `idle`.
