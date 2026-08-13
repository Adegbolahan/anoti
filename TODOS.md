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
- [ ] Extend the session-state helper case (see classification-log bug) to all
      hand-edited state sections: a structurally bad Edit made yq fail and the
      inhibition hook silently degraded to episode=idle, denying a legitimate
      consolidation write with a misleading reason. Consider the helper
      validating the whole file after each write. Observed live 2026-08-13.
      (raised 2026-08-13)
