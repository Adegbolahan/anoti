# anoti Roadmap

<!-- Human-owned. Agents propose edits via draft-for-ratification; only the
     human merges direction. Ratified 2026-08-13 ("proceed to phase three"). -->

## Phase 1 — Does the cycle function? ✅ complete

Substrate (0.1.0), cognition layer (0.2.0), live dogfooding across four
sessions. Done when: every mechanism observed working live.
Evidence: D009 (established), D005/D008. Closed 2026-08-13.

## Phase 2 — Can the substrate be trusted? ✅ substantially complete; carry-overs open

Goal: memory that cannot be quietly corrupted; claims that carry real
evidence.

- [x] Mechanical write helpers (0.3.0) — hand-serialized YAML eliminated
- [x] Split-scalar corruption repaired; validator detects the class
- [x] End-of-session retrospective policy (universal, session-level)
- [ ] Carry-over: evidence backfill for D001–D003 → re-promotion via /anoti:review
- [ ] Carry-over: rulings on Q002 (advisory-phase wording) and Q003 (tools/effort fields)
- [ ] Carry-over: unreadable-state stderr note; helper adoption verified live

Done when: no open data-integrity TODOs; no grandfathered claim remains
evidence-less.

## Phase 3 — Is it worth it? ← current

Goal: the falsifiable version of anoti's value.

- [ ] Design and file the benchmark experiment spec
      (docs/specs/YYYY-MM-DD-exp-h1-h3-benchmark.md): H1 governed memory,
      H2 structure-over-instructions, H3 ratification-prevents-rot —
      measured against vanilla Claude Code on contradiction rate, recall
      success, bad-memory rate, interruptions, latency, token cost
- [ ] Run the benchmark; record results as evidence on H1–H3 claims —
      promoted or demoted, either outcome honored
- [ ] Fast-path calibration from .anoti/telemetry.log (classifier
      eagerness vs outcomes)
- [ ] Q001 format-comprehension experiment rides along

Done when: H1–H3 each carry benchmark evidence and their claims have
moved on the ladder accordingly.

## Phase 4 — Is it shareable? (later; gated on Phase 3's verdict)

Global memory opt-in UX, v1.1 roles validated at working scale,
marketplace publication.
