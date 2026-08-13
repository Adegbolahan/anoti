# anoti Roadmap

<!-- Human-owned. Agents propose edits via draft-for-ratification; only the
     human merges direction. Ratified 2026-08-13 ("proceed to phase three"). -->

## Phase 1 — Does the cycle function? ✅ complete

Substrate (0.1.0), cognition layer (0.2.0), live dogfooding across four
sessions. Done when: every mechanism observed working live.
Evidence: D009 (established), D005/D008. Closed 2026-08-13.

## Phase 2 — Can the substrate be trusted? ✅ complete 2026-08-13

Goal: memory that cannot be quietly corrupted; claims that carry real
evidence.

- [x] Mechanical write helpers (0.3.0) — hand-serialized YAML eliminated
- [x] Split-scalar corruption repaired; validator detects the class
- [x] End-of-session retrospective policy (universal, session-level)
- [x] Carry-over: evidence backfill for D001–D003 → re-promotion via /anoti:review
      ✅ 2026-08-13 — D001/D002 promoted (verify-then-promote); D003 held by independence rule
- [x] Carry-over: rulings on Q002 and Q003 ✅ 2026-08-13 — class-based rewording; tools/effort deferred (D013)
- [x] Carry-over: unreadable-state stderr note ✅ 2026-08-13; helper adoption verified live this session

Done when: no open data-integrity TODOs; no grandfathered claim remains
evidence-less.

## Phase 3 — Is it worth it? ← current

Goal: the falsifiable version of anoti's value.

- [x] Design and file the benchmark experiment spec ✅ 2026-08-13
      (docs/specs/2026-08-13-exp-h1-h3-benchmark.md — pre-registered:
      three arms incl. instructions-only for H2 isolation, planted answer
      key, blinded grader with human spot-audit, decision rules fixed
      before any run)
- [x] Run the benchmark (sequence 1) ✅ 2026-08-13 — verdicts recorded
      honestly: H1 against-with-ambiguity (ceiling effect; recall
      unmeasurable), H2 against-with-ambiguity (arm B degraded), H3
      untestable; defects found and fixed in 0.3.1 (D014/D015).
      Sequence 2 pending human decision
- [ ] Fast-path calibration from .anoti/telemetry.log (classifier
      eagerness vs outcomes)
- [ ] Q001 format-comprehension experiment rides along

Done when: H1–H3 each carry benchmark evidence and their claims have
moved on the ladder accordingly.

## Phase 4 — Is it shareable? (later; gated on Phase 3's verdict)

Global memory opt-in UX, v1.1 roles validated at working scale,
marketplace publication.
