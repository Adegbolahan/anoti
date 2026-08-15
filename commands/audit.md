---
description: Run the longitudinal audit + staleness sweep over this project's anoti trail. Schedulable — wire with /loop 7d /anoti:audit or a scheduled routine.
---

Run the weekly audit per the pre-registered protocol
(docs/specs/2026-08-13-exp-longitudinal.md) — its metrics, decision
rules, and honest limitations govern; this command is the executable
form. **Spec:** docs/specs/2026-08-13-exp-longitudinal.md — in a
governed project with no local copy, resolve it from the newest
installed plugin root (the plugin's copy is authoritative). **Cadence:**
the spec freezes the start date and weekly rhythm — check them before
running; an early or off-schedule run is recorded in the report as an
out-of-cadence deviation, never silently normalized.

1. **Scope the week:** the git range since the last audit report in
   docs/trials/longitudinal-*.md (or since the protocol's start date if
   none). Read only durable artifacts — git history, GROUNDING events,
   LESSONS-LEARNT, telemetry log, trial docs — never session memory.
2. **Score the seven protocol metrics** exactly as the spec's table
   defines them (contradiction incidents, bad-memory incidents, recall
   successes, ratification integrity, guardrail activity with
   false-positive count, store health, cross-project citations), citing
   trail evidence for every count.
3. **Staleness sweep** (the audit's freshness dimension):
   - records past their `reverify_after_days` window (default 180; per
     the store's meta.policy) → list for the next /anoti:review;
   - direction docs whose `Last Updated` predates the newest phase
     transition → flag as due-an-audit per the direction skill's rule;
   - TODOS items raised >30 days ago with no linked progress → list;
     items the trail shows satisfied → tick mechanically with
     `scripts/complete-todo <TODOS.md> <match> "<evidence ref>"` inside
     the episode flow — the sweep can now close what it opens;
   - abandoned session files in the state dir → list;
   - plugin release drift: compare the newest installed plugin version
     (plugin cache) against the anoti repo's newest release tag
     (`git ls-remote --tags`); a newer release means field fixes this
     project lacks → recommend the plugin update + /anoti:update;
   - probable claims older than 14 days (the digest already nudges;
     the audit records the queue's depth over time).
4. **Apply the frozen decision rules** — incidents produce evidence
   events + mandatory lessons; four clean audits may append one
   observational supporting event (probable-cap); ratification-integrity
   violations are critical.
5. **File the report** to docs/trials/longitudinal-YYYY-MM-DD.md; the
   human spot-audits the counts (measurement ratified). Organ writes
   (store, TODOS.md, LESSONS-LEARNT.md) go through the consolidate flow
   as usual — open the episode first (scripts/set-episode) or the
   inhibit gate will correctly refuse; the mechanical one-liners are
   scripts/append-todo, scripts/complete-todo, and scripts/append-lesson.

**Scheduling:** the human wires the cadence — `/loop 7d /anoti:audit`
for an in-terminal loop, or a scheduled cloud routine where available.
The audit never schedules itself; recurring token spend is the human's
call, once.
