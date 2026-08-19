# Project Roadmap

## anoti

<!-- Human-owned; format: the direction skill (adopted template with
     anti-decay guardrails). Drafts only via
     ratification; the human merges. Ratified 2026-08-13. -->

## Vision

An AI-agent plugin that gives sessions a human-shaped cognitive work
cycle over governed, evidence-bearing, human-ratified memory — and proves
its worth by experiment, or records that it didn't.

## Phases Overview

| Phase | Name                          | Status                        | Verified   |
| ----- | ----------------------------- | ----------------------------- | ---------- |
| 1     | Does the cycle function?      | ✅ Complete                   | 2026-08-13 |
| 2     | Can the substrate be trusted? | ✅ Complete                   | 2026-08-13 |
| 3     | Is it worth it?               | ✅ Complete                   | 2026-08-13 |
| 4     | Is it shareable?              | 🔄 In progress                | 2026-08-13 |

## Phase 1: Does the cycle function? ✅

**Goal:** every mechanism observed working live.

**User Stories:** US-001, US-002, US-004, US-005 (first live proof).

**Key Deliverables:** runtime substrate (0.1.0); cognition layer (0.2.0);
live dogfooding across four sessions.

**Dependencies:** none.

✅ 2026-08-13 — closed by D009 reaching `established` on two independent
sessions (with D005/D008 supporting).

## Phase 2: Can the substrate be trusted? ✅

**Goal:** memory that cannot be quietly corrupted; claims that carry real
evidence.

**User Stories:** US-003, US-006, US-007.

**Key Deliverables:**

- [x] Mechanical write helpers (0.3.0) ✅ 2026-08-13 — hand-serialized YAML eliminated
- [x] Split-scalar corruption repaired + validator detects the class ✅ 2026-08-13
- [x] Session-level retrospective policy ✅ 2026-08-13
- [x] Evidence backfill D001–D003 → D001/D002 promoted in review ✅ 2026-08-13
- [x] Q002/Q003 rulings applied (class-based wording; D013 deferral) ✅ 2026-08-13
- [x] Unreadable-state observability ✅ 2026-08-13

**Dependencies:** Phase 1.

## Phase 3: Is it worth it? ✅

**Goal:** the falsifiable version of anoti's value.

**User Stories:** US-007, US-008 (evidence discipline under test).

**Key Deliverables:**

- [x] Pre-registered H1–H3 benchmark spec ✅ 2026-08-13 — docs/specs/2026-08-13-exp-h1-h3-benchmark.md
- [x] Benchmark sequence 1 run + blinded grading ✅ 2026-08-13 — H1/H2
      against-with-ambiguity (ceiling effect; arm B degraded), H3
      untestable; defects fixed in 0.3.1 (D014/D015)
- [x] Fast-path calibration (pre-fix) ✅ 2026-08-13 — D015
- [x] Q001 format experiment ✅ 2026-08-13 — accuracy ceilinged, cost
      discriminated; closure proposed, human ruling pending
- [x] Sequence-2 decision ✅ 2026-08-13 — ruled (D018): sequence 1
      stands; the continuing test is the pre-registered longitudinal
      protocol (docs/specs/2026-08-13-exp-longitudinal.md); Q001 closed
      answered-with-qualification

**Dependencies:** none remaining — closed by D018.

## Phase 4: Is it shareable? ← current

**Goal:** anoti usable beyond this repo, honestly marketed by its
evidence.

**Key Deliverables:**

- [x] Marketplace publication ✅ 2026-08-13 — repo takeover complete
      (github.com/Adegbolahan/anoti, D017): storefront README, CI with
      changelog-gated release tags, schema'd marketplace manifest
- [x] Global memory tier ✅ 2026-08-13 — implemented per the
      adversarially reviewed spec (v0.5.0): opt-in flow, dual-realpath
      trust adjacency with --global gate, [global] digest labels,
      cross-tier precedence; live opt-in dialog awaits the first real
      global candidate (second project)
- [ ] v1.1 roles validated at working scale
- [ ] Longitudinal audits (weekly from 2026-08-20) accumulating evidence
      per the pre-registered protocol
- [ ] Just-in-time recall (presence hook) — planned, not yet built:
      design spec is the next step, ratified 2026-08-19
      (docs/plans/2026-08-18-jit-recall-cascade.md). PostToolUse
      presence hook with four duties (JIT recall + frame re-anchoring +
      evidence-kind nudge + telemetry), querying global + project +
      LESSONS-LEARNT per tool call; `anoti recall` CLI (same matcher,
      second entry point); append-only `triggers:` field; recall-miss +
      adherence metrics added to the longitudinal protocol; three-tier
      wake architecture (Tier 1 built by this deliverable; Tiers 2-3
      evidence-gated on Tier 1's own telemetry, not built now)

**Dependencies:** Phase 3's verdict.

## Success Criteria

**Phase 3 complete when:** H1–H3 each carry decisive benchmark evidence
and their claims moved on the ladder accordingly — either direction
honored.

**Project complete when:** all eight high-level stories hold verified ✅
status against live evidence, and the plugin's value claims are
`established` or honestly retired.

## Risks & Mitigations

| Risk                                         | Likelihood | Impact | Mitigation                                                               |
| -------------------------------------------- | ---------- | ------ | ------------------------------------------------------------------------ |
| Ceiling effect: tasks below model competence | High       | High   | Design sequence 2 above the ceiling, or accept and record the conclusion |
| Self-report bias in dogfood evidence         | Medium     | High   | Pre-registration, blinded graders, independence rule at promotion        |
| Direction-doc status decay                   | Medium     | Medium | Dated statuses mandatory; audit sections supersede stale cells           |

**Last Updated:** 2026-08-19 (Phase 4 deliverable added: just-in-time recall, human-ratified from the product-manager draft)
