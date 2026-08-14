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
4. Apply decisions mechanically — never hand-edit:
   - approve / reject / reopen → `scripts/set-ratification <store> <id>
     <approved|rejected|pending> "<note>"` — writes the field AND the
     audit event atomically (append-event alone never moved the field:
     issue #10);
   - promote / demote → `scripts/set-status <store> <id>
     <speculative|probable|established> "<note citing the evidence>"`.
     Promotion to `established` requires independent evidence (different
     session, agent lineage, or method — self-citation chains do not
     count);
   - other trail entries (correct, delete rationale) → `scripts/append-event
     <store> <id> <action> human "<note>"`. Statements stay immutable;
     deletion of global records is the one exception, per user rights.
5. The set-* helpers validate, regen the index, and re-trust on their
   own — **except the global store**, where machine-wide trust requires
   explicit consent: they warn on stderr and you must run
   `scripts/trust --global ~/.claude/anoti/GROUNDING.yaml` after global
   decisions. Run `scripts/regen-index` + `scripts/trust` only after
   bare append-event writes. Summarize what changed.

If there is nothing pending and nothing eligible, say so in one line and
stop.
