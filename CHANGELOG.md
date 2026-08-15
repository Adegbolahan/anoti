# Changelog

All notable changes to anoti. Release tags carry the matching section as
their message (CI enforces the section exists and is non-empty).

## [0.5.13] — 2026-08-15

- Spec routing completed (human review caught 0.5.12's version landing
  incomplete): the Execution-routing section now names the plan owner
  (architect vs project-manager), builder hats per component, and the
  skills each hat loads; says HOW to choose (roles register +
  SKILL-MAP, narrowest hat that owns the component); names the handoff
  (the plan skill requires an owner-role per task downstream); and
  experiment specs get their own routing section (runner per arm,
  independent grader per adversarial-handoff, reader-run and harness
  skills). A spec now suggests its performers on both templates, not
  one.

## [0.5.12] — 2026-08-15

- Gap-closure batch (self-audit, human-commissioned):
  - Organ-aware inhibition (#10/#12 class closed proactively): direction
    organs (ROADMAP, HIGH-LEVEL-STORIES) get a denial that tells the
    truth — draft via the direction skill, hand-edit with the episode
    open is the sanctioned mode, no mechanical helper by design; memory
    organs keep the helper route. No denial promises a helper that does
    not exist.
  - macOS CI job: the case-insensitivity tests (#11 class) now execute
    on a case-insensitive filesystem in CI instead of only on the
    author's machine.
  - Restart-drift digest line: when the session runs an older plugin
    version than the newest installed in the cache, the digest says so
    and nudges a restart — offline, no network. The audit gains the
    networked half: newest installed vs newest released tag.
  - Lesson graduation routed: consolidate's scope routing now names the
    global-tier graduation class for agent-craft lessons (precedent
    G002/G003 — yq wildcard equality and state-resolution anchoring,
    graduated this release).
  - Document routing (human directive): the spec standard gains a
    required Execution-routing section (name the roles and skills the
    implementing cascade should engage) and the plan standard requires
    an owner-role per task — the document suggests, deliberate assigns.
  - Adversarial fix round: direction-organ denial reconciled with the
    direction skill and policy-draft-for-ratification (apply only a
    human-ratified draft — no invented hand-edit mode), consolidate's
    scope-routing prose repaired (splice garble, regression-pinned),
    the drift line's newest-version computation filters to
    version-shaped names, tests-macos gates the release, and the weak
    guards the skeptic proved vacuous by mutation are now non-vacuous.
- Review ritual ran live for the first time (data commit): D005/D008
  promoted on multi-project field evidence, D014/D015 promoted as
  closed historical claims, D003/D004/D010 kept with dated review
  events, D022 (no-MCP ruling), D023 (adversarial-review efficacy,
  probable), D024 (single pending surface) recorded.

## [0.5.11] — 2026-08-15

- Sixth field-report fix (issue #13, livingsyncs polyrepo): state
  resolution anchors to the project root. `anoti-dir` walks up from cwd
  to the nearest marker (.claude/anoti.local.md `state_dir`,
  GROUNDING.yaml, `.anoti/` — case-exact per #11) and returns absolute
  paths, so a helper run from a subdirectory hits the project's store
  instead of silently reading — or minting — a stray one. Writers
  (append-classification, session-append, session-consume, set-episode)
  pass `--require` and refuse loudly when unanchored: a wrong cwd is
  now a clear error about location, never a wrong-store "not found" or
  a phantom success. The classify hook goes silent in unanchored
  directories, matching retrieve's silence contract (US-002) — the
  attention tax stops minting stray telemetry in ungoverned dirs.
  ANOTI_DIR still overrides everything verbatim; plain reads keep the
  back-compat default. Adversarial review closed two further stray-store
  paths the sweep missed — persist-session (an automatic PreCompact
  write in ANY dir) now fails open unanchored, and trust anchors at the
  store's own directory, refusing a bare yaml outside any workspace —
  plus an inhibit stderr leak and state_dir trailing-whitespace edge.
  Design-spec resolution rule amended (dated).

## [0.5.10] — 2026-08-15

- Fifth field-report fix (issue #12, livingsyncs): `complete-todo` adds
  the tick half of the TODOS contract — flips exactly ONE matching
  unchecked item to `- [x] … — DONE <date>: <note>`, fixed-string
  matching only (match text never meets a pattern engine), refuses zero
  and multiple matches loudly (a silent no-op looks like closure), and
  never deletes. The inhibit denial's "write via the helpers" now names
  a real route for every guarded organ operation; the audit's staleness
  sweep can mechanically close the todos it opens.

## [0.5.9] — 2026-08-14

- Lessons surfacing: LESSONS-LEARNT.md was the one write-only organ —
  collected, never pushed, never pulled. The SessionStart digest now
  carries a budget-gated lessons line (count + truncated latest;
  enrichment by design — it carries content, so it yields under budget
  pressure), resolved case-exactly, and attend's topical-retrieval step
  mandates grepping the lessons organ alongside the index query:
  lessons are memory that has not yet graduated into records, so they
  surface at attention time or nowhere. Design-spec digest enumeration
  amended (dated); case-exactness mutation-guarded in tests.

## [0.5.8] — 2026-08-13

- Fourth field-report batch (issues #10-#11, ecounterlist):
  `set-ratification` and `set-status` make the review ritual able to
  actually effect decisions — each writes its field AND the audit event
  atomically with append-record's full contract (validate, mode-preserve,
  regen-index, re-trust); append-event alone never moved a field, so
  ratifications silently did nothing (#10). `retrieve` resolves organs
  (GROUNDING, ROADMAP, HIGH-LEVEL-STORIES, TODOS) by exact-case
  directory listing so case-insensitive filesystems stop adopting a
  project's own `roadmap.md` as the organ, and skillify now detects
  case-insensitive collisions before any template write (#11).
- Wildcard-equality audit closed (TODO from the #9 batch): new shared
  `record-index` resolver — exact comparison in shell, ids never meet a
  yq `==` — now backs append-event, append-evidence, set-ratification,
  set-status; session-append validates `amends:` targets literally.

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
