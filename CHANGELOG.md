# Changelog

All notable changes to anoti. Release tags carry the matching section as
their message (CI enforces the section exists and is non-empty).

## [0.5.7] — 2026-08-13

- Demo skill: one-read orientation for agents and new sessions — the
  cycle with who-fires-what, a when-to-use-what routing table (one-line
  pointers, never copied procedure), the three governing whys, and a
  5-minute hands-on tour that runs the whole lifecycle (classify →
  frame → candidate → episode → consume) against ANOTI_DIR scratch
  state so it can never touch a real store — with a mandatory anoti-dir
  sandbox check before any write. The SessionStart digest now carries a
  one-line orientation pointer to it (governed workspaces only — bare
  dirs stay silent). Referenced from /anoti:new post-scaffold; SKILL-MAP
  rows added. Adversarial review corrected the draft: review-work is a
  drift check not an adversarial control, the direction skill joined
  the routing table, inhibit gates matched tools not every tool, and
  the tour's closing claim now states honestly that it exercises the
  session-state half of the lifecycle only.

## [0.5.6] — 2026-08-13

- Third field-report batch (issues #7–#9, livingsyncs):
  `session-consume` closes the candidate-consumption gap that lost a
  real memory candidate — mark-applied semantics (`applied: true` +
  date, never deletion, D021), `--ids` or all-unapplied, loud failure
  on unknown ids; the consolidate skill collects only unapplied
  candidates and names the consume step (#9). `append-evidence` joins
  the JSON-stdin convention (2-arg form reads `{type, note, date?,
  refs?}`; positional unchanged; prose-line helpers stay text-args by
  design) (#8). The classify hook exempts machine-generated turns —
  bracketed system notifications and task-notifications are
  continuation of already-framed work, not prompts (#7).

## [0.5.5] — 2026-08-13

- Feedback skill: the field-report → human-gated GitHub issue procedure
  (which produced 0.5.2 and 0.5.4) as a standalone invocable skill —
  capture at the friction moment, cited field-report format with plugin
  version and evidence, dedup against existing issues before proposing,
  the send always human-gated, and a `<state-dir>/feedback/` queue for
  headless or gh-less sessions (gate deferred, never skipped).
  policy-retrospect now routes anoti friction through it; SKILL-MAP row
  added.

## [0.5.4] — 2026-08-13

- Default-branch edit protection (D020, human directive): the inhibition
  hook now denies Edit/Write/NotebookEdit on tracked files while HEAD is
  on main/master — implementation happens on a feature branch or
  worktree. Gitignored paths and episode-gated organ writes pass;
  override is `touch <state-dir>/allow-default-branch`. Matcher widened
  to NotebookEdit.
- Second field-report batch (issues #1–#6): telemetry now logs episode
  transitions and inhibit denials (#1); the organ-write denial names the
  unblock path (#1); audit says organ writes — store, TODOS,
  LESSONS-LEARNT — go through the consolidate flow, with the two new
  mechanical one-liners `append-todo` and `append-lesson` (#2, #5);
  audit resolves its spec from the newest plugin root in governed
  projects and surfaces the frozen cadence (#3); recall metric ruled
  citation-discipline — policy-epistemic gains "artifacts cite what they
  implement, by ID" and the longitudinal spec a dated clarification
  (D019, #4a); `session-append` validates `amends:` targets and fails
  loudly on typos (#5); skillify names `<state-dir>/backups/` as the
  migration-backup home (#6).

## [0.5.3] — 2026-08-13

- Git craft skill: branches (never on main without consent), worktrees
  (per-checkout anoti state and trust — provenance per checkout),
  finishing discipline (suite green on the integrated tree; integration
  is the human's decision, always), commit messages (conventional,
  why-first bodies; attribution trailers never added unless asked,
  existing trailers never stripped), explicit staging (cf730d6
  codified), CI-only tags. Wired into implement and the cascade.

## [0.5.2] — 2026-08-13

- Field-report fixes from the first second-project session (livingsyncs):
  atomic store writers now preserve file mode (0600 global stores stayed
  0600 — regen-index/append-record/event/evidence/question); new
  `session-append` helper covers every session-state list the skills
  instruct (frames/hypotheses/in_flight/candidates) and frames became a
  LIST — interleaved workstreams no longer clobber; new `append-question`
  helper for the open_questions promotion consolidate mandates; digest
  zero-count newline bug fixed (the "0 / 0" double-print); attend gains
  the extend-frame affordance (amends: <id> instead of full re-attend);
  consolidate documents instruction-is-ratification; practitioner
  resolves bare role names from the newest plugin root (version-pinned
  paths went stale mid-upgrade); reviewer role codifies the optional
  empirical RED-transcript-via-scratch-copy evidence.

## [0.5.1] — 2026-08-13

- Feedback loop: the retrospective now routes anoti-caused friction to
  human-gated GitHub issues on the anoti repo — every governed project
  feeds the plugin's improvement loop, never automatically.
- /anoti:audit: the pre-registered longitudinal audit + staleness sweep
  (reverify windows, direction-doc freshness, aging TODOS and probables,
  abandoned sessions) as a schedulable command — wire with /loop 7d or
  a scheduled routine; the audit never schedules itself.
- attend mirrors an active /goal into the frame and escalates prompts
  that conflict with it.

## [0.5.0] — 2026-08-13

- Global memory tier implemented per its adversarially reviewed spec:
  opt-in store at ~/.claude/anoti/GROUNDING.yaml (0700/0600, umask-safe
  creation ordering); trust adjacency with dual-realpath comparison, an
  explicit --global gate on the machine-wide path, missing-file guard,
  and atomic writes; retrieval digests the global store with [global]
  labels on every sourced line and reports meta.scope/location drift;
  validator warns on scope drift; consolidate skill carries the opt-in
  flow, routing classes, and cross-tier precedence (scoped-exception
  events); longitudinal protocol gains its dated seventh source
  (cross-project citations). Auto-trust remains project-only by design.

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
