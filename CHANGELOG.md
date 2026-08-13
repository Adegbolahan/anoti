# Changelog

All notable changes to anoti. Release tags carry the matching section as
their message (CI enforces the section exists and is non-empty).

## [0.4.0] — 2026-08-13

- Adopted four workflow commands from the deprecated project-scaffolder,
  rebuilt anoti-native: `/anoti:new` (skillify bootstrap wizard),
  `/anoti:implement` (feature-scale cascade driver with mandatory spec
  gate), `/anoti:review-work` (pre-ship implementation review with
  evidence contract and cycle cap), `/anoti:update` (migration by
  ratified diff, never downgrade).
- Marketplace manifest upgraded to the schema'd storefront form; README
  rewritten as the marketplace landing page with a scaffolder
  deprecation note (v3.x tags remain installable).
- CI adopted and adapted from the predecessor: full test suite,
  shellcheck, hook-schema checks (timeouts, single-line commands,
  scripts exist, skill frontmatter), version consistency across
  plugin/marketplace/CHANGELOG, and changelog-gated release tagging.
- Direction documents adopted an external template with anti-decay
  guardrails (dated statuses mandatory; audit sections supersede stale
  cells); stories became a register with evidence refs.
- Project state directory became configurable (D016): ANOTI_DIR >
  .claude/anoti.local.md state_dir > .anoti default.

## [0.3.1] — 2026-08-13

- Pilot-identified fixes: classifier gained concrete slow criteria
  applied identically headless (D015); bare git projects get a skillify
  bootstrap offer at SessionStart; consolidate bootstraps the store from
  template instead of substituting ad-hoc files; benchmark pauses print
  the full response script and require a typed done.

## [0.3.0] — 2026-08-13

- Mechanical write helpers ended hand-serialized YAML (the root cause of
  both live data-integrity incidents): append-classification (with
  durable telemetry), set-episode, append-event, append-record, and
  later append-evidence — all atomic, quoting-safe, validate-before-move.
- Split-scalar store corruption repaired; validator rejects unknown keys
  in source/events/evidence; write discipline added to the consolidate
  skill.
- Universal session-level retrospect policy (went well / didn't /
  skillify / lessons / cannot-be-automated).

## [0.2.0] — 2026-08-13

- Cognition layer complete: attend, deliberate (with the conductor-led
  cascade), consolidate, skillify; ten policy skills (policies are
  invocable skills); consolidator/explorer/skeptic/practitioner agents;
  23-role library; review/recall/consolidate commands; project store
  migrated to schema v3 with grandfathering applied to its own founding
  claims.

## [0.1.0] — 2026-08-12

- Runtime substrate: v3 record-model template, store validator,
  generated index, six lifecycle hooks (retrieval with trust boundary,
  attention classifier, inhibition decision table with versioned
  deny-list, session-state persistence and cleanup, consolidation gate
  with per-episode state machine), workspace templates, fixture-driven
  test suite.
