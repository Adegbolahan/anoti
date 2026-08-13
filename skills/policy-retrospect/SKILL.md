---
name: policy-retrospect
description: Universal anoti session-close policy — structured retrospective at consolidation, every session. What went well, what didn't, what to skillify, what to learn, what cannot be automated.
---

# Policy: retrospect

**Applies:** always — universal, at **session level**: it runs once, at
consolidation time, over the whole session's trail and every agent
report. (Spawn-level agents feed it through their reports; they do not
each run it.)

**Procedure — answer five questions, each with citations to the trail:**

1. **What went well** — mechanisms, decisions, or moves that earned their
   cost; cite the moment that shows it.
2. **What didn't** — friction, wrong turns, misleading signals; cite the
   moment. A retrospective that finds no friction in nontrivial work is
   suspect, not clean.
3. **What should be skillified** — any procedure performed twice, or
   performed once with obvious generality: candidate for a skill, policy,
   or helper script. File as a TODOS entry naming the repeatable steps.
4. **What should become a lesson** — process insight worth surviving the
   session: write to LESSONS-LEARNT with why + how-to-apply. A lesson
   that becomes falsifiable and gathers evidence graduates into a
   GROUNDING claim.
5. **What cannot be automated** — judgment that must remain with the
   human or the in-context model: name it explicitly so the system stops
   trying to mechanize it. Recurring items are candidates for a `policy`
   record ratified into GROUNDING — the boundary itself becomes memory.

**Routing:** lessons → LESSONS-LEARNT.md; skillify candidates → TODOS.md;
cannot-automate boundaries → LESSONS-LEARNT.md (promotable to `policy`
records via consolidation + ratification); anything falsifiable →
candidate claim. **Friction caused by anoti itself** (helper errors,
hook false positives, unclear skills, guardrail misfires) → route via
**the feedback skill** (skills/feedback/): cited field report, dedup
against existing issues, human-gated `gh issue create` — issue creation
stays outward-facing and escalate-gated; the procedure lives there, in
one place. This is how every governed project feeds
anoti's own improvement loop.

**Fast path:** a genuinely trivial session with nothing to report reports
nothing — the retrospective's silence is itself the fast-path verdict.
Never manufacture reflection for a session that carried no weight.

**Binds:** the consolidate skill (the retrospective is its reflective
step), LESSONS-LEARNT, TODOS, skillify (consumes the skillify queue).

**Violation handling:** a nontrivial session closed without a
retrospective reopens at the next session start (the abandoned-state
surfacing path); repeated skips are themselves a lesson to file.
