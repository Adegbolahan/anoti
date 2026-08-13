# Todos

<!-- Shared prospective memory. Checked items are history; do not delete them. -->

- [ ] Backfill evidence for D001–D003: attach real citations (cognitive-science
      and transformer-architecture sources) so /anoti:review has grounds to
      re-promote the grandfathered claims. (raised 2026-08-13)
- [ ] Plan 3: dogfood behavioral tests + H1–H3 comparative benchmark against
      vanilla Claude Code. (raised 2026-08-13)
- [x] v1.1 role set (13 remaining roles) after core-10 prove out. (raised 2026-08-13;
      done 2026-08-13 — gate overridden by explicit human instruction; see D006/D007,
      Q002–Q004)
- [ ] Consider renaming /anoti:consolidate command if the skill/command name
      collision causes ambiguity in practice. (raised 2026-08-13, minor)
- [x] Bug: session-state classification log duplicated entries when the model
      re-serialized the YAML list instead of appending — add a mechanical
      append helper (scripts/log-classification) and have attend/classify use
      it. Observed live 2026-08-13. (raised 2026-08-13; done 2026-08-13 —
      four helpers shipped in 0.3.0: append-classification, set-episode,
      append-event, append-record; all skills/commands rewired)
- [ ] Fast-path calibration: analyze .anoti/telemetry.log (fast/slow verdicts
      + reasons, now durably logged) during Plan 3 to measure classifier
      eagerness against outcomes. (raised 2026-08-13)
- [ ] If D011 survives /anoti:review, codify fix-round continuation (resume
      the original builder vs fresh spawn) in the deliberate skill's cascade
      section. (raised 2026-08-13, sample-app cascade)
- [ ] Extend the session-state helper case (see classification-log bug) to all
      hand-edited state sections: a structurally bad Edit made yq fail and the
      inhibition hook silently degraded to episode=idle, denying a legitimate
      consolidation write with a misleading reason. Consider the helper
      validating the whole file after each write. Observed live 2026-08-13.
      (raised 2026-08-13)
