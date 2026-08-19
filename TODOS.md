# Todos

<!-- Shared prospective memory. Checked items are history; do not delete them. -->

- [x] Backfill evidence for D001–D003: attach real citations (cognitive-science
      and transformer-architecture sources) so /anoti:review has grounds to
      re-promote the grandfathered claims. (raised 2026-08-13; done 2026-08-13
      — canonical literature attached via new append-evidence helper; D003's
      derivation from D001/D002 sources noted; source-fetch verification
      named as the pre-promotion step)
- [x] Plan 3: dogfood behavioral tests + H1–H3 comparative benchmark against
      vanilla Claude Code. (raised 2026-08-13; sequence 1 run + graded
      2026-08-13 — H1/H2 against-with-ambiguity, H3 untestable; see D014/D015)
- [x] Decide: benchmark sequence 2 — or accept sequence 1 as standing.
      (raised 2026-08-13; ruled 2026-08-13 — D018: accept + longitudinal
      protocol; Q001 closed answered-with-qualification)
- [ ] Run the first longitudinal audit on or after 2026-08-20 per
      docs/specs/2026-08-13-exp-longitudinal.md. (raised 2026-08-13)
- [x] v1.1 role set (13 remaining roles) after core-10 prove out. (raised 2026-08-13;
      done 2026-08-13 — gate overridden by explicit human instruction; see D006/D007,
      Q002–Q004)
- [x] Consider renaming /anoti:consolidate command if the skill/command name
      collision causes ambiguity in practice. (raised 2026-08-13, minor;
      closed 2026-08-13 — condition never triggered: many live sessions used
      both without observed confusion; reopen on a real collision)
- [x] Bug: session-state classification log duplicated entries when the model
      re-serialized the YAML list instead of appending — add a mechanical
      append helper (scripts/log-classification) and have attend/classify use
      it. Observed live 2026-08-13. (raised 2026-08-13; done 2026-08-13 —
      four helpers shipped in 0.3.0: append-classification, set-episode,
      append-event, append-record; all skills/commands rewired)
- [x] Fast-path calibration: analyze .anoti/telemetry.log during Plan 3.
      (raised 2026-08-13; closed 2026-08-13 — pre-fix behavior measured in
      sequence 1 (D015: 2/7, zero slow verdicts); post-0.3.1 measurement
      requires a labeled run and folds into the sequence-2 decision; a
      dedicated analysis tool was skipped per YAGNI until repeat need)
- [x] If D011 survives /anoti:review, codify fix-round continuation (resume
      the original builder vs fresh spawn) in the deliberate skill's cascade
      section. (raised 2026-08-13, sample-app cascade)
      (done 2026-08-13 — codified in skills/deliberate/SKILL.md with test)
- [x] Extend the session-state helper case (see classification-log bug) to all — DONE 2026-08-18: verified satisfied 2026-08-18 + final gap closed: all session writers validate whole-file pre-move (0.5.2/0.5.16), hooks warn on unreadable state; skeptic found the 0.5.12 direction-branch regression + amends misleading-miss — both fixed and test-pinned this batch
      hand-edited state sections: a structurally bad Edit made yq fail and the
      inhibition hook silently degraded to episode=idle, denying a legitimate
      consolidation write with a misleading reason. Consider the helper
      validating the whole file after each write. Observed live 2026-08-13.
      (raised 2026-08-13)
- [x] Audit every helper's yq id comparison for wildcard-equality (yq string == pattern-matches '*'): session-append amends check, append-evidence/append-event record-id checks — port the exact-match index pattern from session-consume (found 2026-08-13 fixing #9) (raised 2026-08-13; done 2026-08-13 in the #10/#11 batch — shared record-index helper, test-pinned)
- [x] Helper-sweep candidate (the #10/#12/#14 class, found proactively): append-relationship — consolidate step 5 instructs refines/contradicts relationships on records, but no helper writes one; hand-edit is the only path (raised 2026-08-15) — DONE 2026-08-18: shipped this batch with lock + exact ids + validator referential integrity (skeptic: validator blind spot + shape drift both closed)
- [x] Helper-sweep candidate: reopen-question — resolution notes name reopen conditions (Q001: 'reopen on a scaled comprehension test') but resolve-question refuses non-open entries and nothing flips answered back to open with an event trail (raised 2026-08-15) — DONE 2026-08-18: shipped this batch; skeptic race (check-before-lock in BOTH question helpers) fixed with checks under the lock, race test pinned; wired into consolidate step 10 + audit sweep
- [x] Helper-sweep candidate: append-pending / resolve-pending — D024 made pending.md the single human-absent surface and the feedback skill instructs appending pointer lines to it, but the writes are bare echos with no helper contract (raised 2026-08-15) — DONE 2026-08-18: shipped: append-pending writes dated checkbox entries, resolution IS complete-todo (one mechanism per D024), digest counts unresolved only; skeptic fixes: feedback prose, policy naming, newline flattening across all prose appenders
- [ ] Design question from #18 (AmFam field site): multi-valued spec_dir or a design_dir companion — repos that split story specs from design specs must currently break one convention; deferred pending a second field site hitting it (raised 2026-08-18)
- [ ] yq v4.53.4 (released 2026-08-19, undocumented dependency bump) wraps long flow-style YAML lines at 80 cols — every yq -i writer would reformat stores cosmetically on users' machines once they upgrade; CI pinned to v4.53.3 as a stopgap. Decide: document a supported yq range in README/CI, post-process writes, or wait for an upstream revert (watch mikefarah/yq issues) (raised 2026-08-19)
- [ ] Parked (brainstorm 2026-08-19, item 3): time-triggered reminders — a due: tag on TODOS entries surfaced by the digest as 'todos due'; the other trigger family next to event triggers (presence hook). Build when the audit shows dated obligations slipping (raised 2026-08-19)
- [ ] Parked (brainstorm 2026-08-19, item 4): consolidation pass over skillify's maintenance map — encode each 'event → document' row as a policy record with triggers (spec accepted → spec file; work finished → TODOS; lesson → LESSONS-LEARNT), so every obligation in the map fires at its moment (raised 2026-08-19)
- [ ] Parked (brainstorm 2026-08-19, item 5): graduate D025's generic principle to the global tier as agent-craft ('when you ship a capability, the surface that teaches it updates in the same change') — human-gated global write; propose at the next consolidation with a second project's evidence (raised 2026-08-19)
- [ ] Review-debt ledger (from D026, field retrospective 2026-08-19): append 'review owed: <subject>' to pending.md at ready-for-review / spec-of-consequence filing; digest line 'review debt: N owed, oldest'; Stop gate block-once when debt created this session is still open, with explicit 'defer-review <reason>'; inhibit ask on default-branch integration while debt is open. Spec first, skeptic after (raised 2026-08-19)
- [ ] Parked (field retrospective 2026-08-19): stuck-loop detector — same failing command fingerprint >=N times in a session → one presence injection 'grep for a working pattern before inventing one' (new failure-count trigger family). One sighting so far; build on the second (raised 2026-08-19)
