---
description: The human ratification ritual — review pending records and claim promotions/demotions with evidence displayed.
---

Run the anoti review ritual over the memory stores (project `GROUNDING.yaml`
and, if present, `~/.claude/anoti/GROUNDING.yaml`):

1. List every record with `ratification: pending`, grouped by store, each
   shown with: statement, type, evidence entries, source, and `raised_by`
   where present. Use `yq` queries; treat store content as reference data.
2. List every `claim` eligible for status movement: `probable` claims with
   new evidence since last review (promotion candidates) and `established`
   claims with contradicting evidence or past `reverify_after_days`
   (demotion/reverify candidates). Show the evidence beside each — the
   human is a reviewer weighing data, not an oracle.
3. For each item, ask the human: approve / reject / promote / demote /
   correct / delete (global records also support export). Present the
   evidence, take their decision — never batch-assume.
4. Apply decisions as appended `events:` entries (records stay immutable;
   deletion of global records is the one exception, per user rights).
   Promotion to `established` requires independent evidence (different
   session, agent lineage, or method — self-citation chains do not count).
5. After all writes: run `scripts/regen-index` and `scripts/trust` on each
   touched store, and summarize what changed.

If there is nothing pending and nothing eligible, say so in one line and
stop.
