# Changelog

All notable changes to anoti. Release tags carry the matching section as
their message (CI enforces the section exists and is non-empty).

## [0.5.27] — 2026-08-19

- **Review-debt ledger** (spec
  docs/specs/2026-08-19-review-debt-design.md; motivated by D026, a
  field retrospective where adversarial review was owed three times,
  flagged four times, done zero times): `scripts/review-debt
  add|list|close|defer|observe` is the single reader/writer of
  `<state-dir>/review-debt.tsv` (project-level, gitignored; 7 columns;
  shape-checked, locked writes). A spec filed by `Write` under
  `spec_dir` opens a row mechanically (new PostToolUse hook entry,
  matcher `Write`, `review-debt observe`); ready-for-review opens one by
  hand (policy-adversarial-handoff step 1). Rows surface at session
  start (`review debt: N open, M deferred — oldest …`), block the Stop
  hook **once per session** while a row this session opened is still
  open (consolidation-gate; deferred and other sessions' rows never
  block), and make `git merge`/`gh pr merge` on the default branch and
  `git push` **ask** with the owed subjects named while any row is open
  (inhibit; never deny — G004). `defer` refuses an empty reason; `close`
  refuses unknown and already-closed rows. Skills updated: handoff
  policy, spec, deliberate step 8, policy-retrospect, demo routing row,
  SKILL-MAP root row, README; longitudinal spec gains three
  telemetry-only metrics (dated amendment). Skeptic round 1 (REFUTED →
  fixed, spec changelog): `anoti-dir --root` (additive) resolves the
  project root for `observe` so `state_dir`-configured projects fire;
  state dir created before locking (a fresh clone spun ~60 s);
  hook readers treat a *partially* malformed ledger as empty, matching
  the helpers' refusal; dedupe via ENVIRON (backslash subjects);
  telemetry verbs are the subcommands; `gh pr merge` asks from any
  branch; `STORE_LOCK_MAX_TRIES` bounds the hook-side writer's wait.
  Round 2 residue closed: hook awks apply the full shape rule (created
  date included) so helper and hooks agree on every row; `observe` fires
  in an `ANOTI_DIR`-only workspace; a helper-minted state dir is
  gitignored; the lock bound is test-pinned.

## [0.5.26] — 2026-08-19

- **Adaptive suppression** (ratified spec
  docs/specs/2026-08-19-adaptive-suppression-design.md): a project-level
  feedback cache (`<state-dir>/presence-feedback.tsv`, 30-day soft TTL)
  lets the presence hook learn which `(record, trigger)` pairs the
  retrospective has named irrelevant three times and stop injecting
  exactly those pairs — visibly (`anoti feedback list`, a digest line
  when any are active, a `presence suppressed <id>:<trigger>` telemetry
  line per firing) and reversibly (`anoti feedback clear <id> [trigger]`,
  which also purges the record's dedupe entry; `remove-trigger` stays the
  permanent fix) — while every other trigger on the same record keeps
  firing. `mark-retrospect` grows an additive grammar to name pairs
  (`irrelevant-injections N [<id>[:<trigger>] …]`, split on the first
  colon so `edit:`-scoped cues survive); malformed or lesson ids are
  rejected with a warning, never written; threshold overridable via
  `feedback_threshold:` in `.claude/anoti.local.md`. Warn-once on a
  corrupt feedback file persists across invocations. The longitudinal
  spec's Q006 re-ranker gate now requires adaptive suppression to have
  shipped plus two audited weeks, and gains its own pre-registered KEEP
  (≥15-point precision gain) / telemetry-only / REVERT (≥10-point fall)
  rule with an honest fallback baseline.
- Build trail: two builders in isolated worktrees kept alive through
  review (the 0.5.22 lesson applied); the backend found and fixed three
  bugs in the plan's own illustrative code (a subshell mutation that
  silently dropped every suppressed-telemetry line, an awk -v crash on
  multi-line lists, a premature truncation breaking cut handles); the
  reviewer's execution pass found the TTL-expiry purge was not
  transition-gated — it would have defeated the N=10 dedupe permanently
  for any expired-but-uncleared pair — now gated on a persisted
  `.suppressed_prev` diff, mutation-pinned (TEST A/B/C), and the spec's
  illustrative text corrected by dated amendment; byte-exact wording
  assertions guard against a prettier hook that strips list indents.

## [0.5.25] — 2026-08-19

- Codag-research ideas, deliberated and adopted (the contrast was more
  instructive than the overlap — see docs/plans for the research trail):
  - **Match over the full tool text, cap only the injection.** The presence
    hook matched triggers against the first 8000 chars of tool input/
    output — a cue past byte 8000 of a build log was a silent miss. The
    match window is now 256 KB (bounded for memory); display caps apply
    only to what is injected. Test-pinned with a 120 KB haystack.
  - **A cut is a pointer, not a loss.** Every truncated line in the digest
    (index rows, questions, lessons) and in presence/recall output is
    marked (…) and the block names how to pull the full text (`anoti
    recall <id>`, `yq` by id). The matcher now emits full statements;
    consumers cut and mark.
  - **Fail-open stated as a product guarantee** in README and the demo:
    every hook degrades to vanilla Claude Code, never to a block — the
    only blocks are the deny list's catastrophic actions and the
    human-gated organ writes, by design.
  - Adaptive suppression (a project-level TTL feedback cache that learns
    irrelevant (record, trigger) pairs from the retrospective's marks,
    visible and reversible, ordered before the Q006 ranker gate) is being
    spec'd — docs/specs/2026-08-19-adaptive-suppression-design.md — not
    built in this release.

## [0.5.24] — 2026-08-19

- Field-review batch (classifier tax, presence precision, cascade fit):
  - The classifier no longer injects its rubric on trivial prompts —
    slash commands and replies of ≤2 words (hi, ok, proceed) get nothing
    (US-002) — a deliberate trade: a two-word destructive ask loses the
    rubric too, while inhibit's rows still catch the catastrophic classes
    and now also ask on `rm -r* <path>` and deleting the default branch;
    after a session's first classification the rubric is a one-liner.
    The skeptic pass on this batch found the D025 currency gate itself
    was dead (`false; break` — break's own status is 0) — fixed, and the
    live gate immediately surfaced that the git skill had never been in
    SKILL-MAP; remove-trigger now removes one occurrence, not all.
  - Presence precision: triggers can be event-scoped — `edit:X` matches
    only Edit/Write/NotebookEdit firings, `bash:X` only Bash, unscoped
    any tool; new `remove-trigger` (exact, audited) re-cues a noisy
    record; consolidate 2b gains cue-quality guidance; D025 re-cued
    edit-scoped. The frame re-anchor now uses the LATEST active frame
    (it was re-anchoring to the first, i.e. stale work). The longitudinal
    protocol gains a pre-registered Presence-precision metric (source:
    the retrospective's irrelevant-injection count via
    `mark-retrospect … irrelevant-injections N`) and a re-ranker gate —
    Q006: a small local cross-encoder as a precision FILTER over keyword
    candidates, fail-open, justified only if precision stays <50% for
    two audited weeks after these mechanical measures ship.
  - Deliberate states the single-mind principle: parallelism buys
    breadth, never coherence — synthesis is a single-context job by
    design.

## [0.5.23] — 2026-08-19

- Field-report batch (issues #20-#21, livingsyncs, met while upgrading to
  0.5.22): the flagship recall feature was silently inert over a
  68-record store — no pre-0.5.22 record carries `triggers:` and nothing
  said so. Visibility, not automation (backfilling cues is a judgment,
  not a migration): the digest now emits `recall coverage: N/M project
  records carry triggers` while fewer than half are cued, and
  `/anoti:update` reports coverage every run and names the 0.5.22
  crossing plainly, pointing at consolidate step 2b + `append-trigger`
  (#20). New `scripts/anoti digest` action prints the SessionStart
  digest as plain text — the operator-runnable twin of the hook — and
  update's verify step names it (#21). Demo routing row added (D025).

## [0.5.22] — 2026-08-19

- **Just-in-time recall — the presence hook** (ratified Phase 4
  deliverable; spec docs/specs/2026-08-19-jit-recall-design.md, plan
  docs/plans/2026-08-19-jit-recall-implementation.md). Memory now acts at
  the moment of use: a PostToolUse + PostToolUseFailure hook (matcher
  Bash|Write|Edit|NotebookEdit, 5s, fail-open, silent by default) with
  four duties — JIT recall matching tool input/output/error text against
  an append-only `triggers:` field across the global store, the project
  store, and LESSONS-LEARNT (labelled, trust-checked); frame re-anchoring
  after compaction and every 10 tool calls in a slow session; an
  evidence-kind nudge when a fetch is piped into text inspection
  (G004/G008); one telemetry line per firing. `scripts/anoti recall
  <keywords>` is the pull-side twin (same matcher, both stores, ranked).
  New helpers: `append-trigger` (full write contract; global refusal warns
  loudly, never overrides `--global` consent), `mark-retrospect`;
  `session-append` frames now hit telemetry; `cleanup-session` writes a
  durable summary line; `persist-session` stamps compaction. Consolidate
  asks the encoding-time question ("what would you have needed to see to
  be reminded of this?"); policy-epistemic rule 6, review-work, and the
  reviewer role carry the evidence-kind ordering (screenshot < DOM query <
  DB query). The longitudinal protocol gains recall MISS + adherence
  metrics and a pre-registered Tier-1 gate (dated amendment); Tiers 2–3
  (`/anoti:presence` on `/loop`; hook-advised examiner spawn) are sketched
  and evidence-gated, not built. `validate-workspace` gains a triggers
  shape check and a ~600x faster record loop; the inhibit organ gate
  exempts only the plugin's own templates dir (real files, not symlinks).
- Build trail: two builders in isolated worktrees, one reviewer over the
  whole diff across three cycles — critical IFS-tab collapse (rendered
  recall lines corrupted while substring tests stayed green), nudge
  pattern deviating from spec, perf margin, unscoped templates exemption,
  jq false positive, symlink-leaf bypass — all fixed and pinned; awk
  portability verified under gawk and mawk in docker; the two named
  residues (nudge chain-looseness, no `ln -s` row) judged acceptable.
  Global records G004/G005/G008 carry triggers (human-gated re-trust).

## [0.5.21] — 2026-08-19

- Eleventh field-report fix (issue #19, livingsyncs — dispatch-time
  discoverability): the practitioner agent's description now enumerates
  every legal role name (test-pinned to `roles/` so the list cannot
  drift), the bare-name → `skills/policy-<name>/` convention is stated
  where it is used (practitioner load step, deliberate's hat assignment),
  and README names `scripts/anoti help` as the helper index. Finding 3
  (five skills rendering without descriptions) assessed as host-side:
  the files are byte-identical in structure to rendering siblings, and
  the blank set differs between installations (five at the reporting
  site, ten in the maintainer's session with more plugins installed) —
  consistent with a host listing budget, not a per-file predicate.

## [0.5.20] — 2026-08-18

- Field-review fix: the inhibit destructive-SQL row fired on the word
  "truncate" in prose (a heredoc file write and a commit message were
  blocked — and, fittingly, this very changelog commit was blocked by the
  old row while being written). The row now requires BOTH a SQL-shaped
  statement AND a DB client in the command (psql, mysql, mariadb,
  sqlite3, sqlcmd, clickhouse-client, cockroach, supabase, prisma); real
  remote TRUNCATE / DROP DATABASE via a client — flag, pipe, or heredoc-fed — is
  still denied. Six shapes test-pinned.
- Field-review assessment (no code change): "session-append and
  append-classification fail silently" is not reproducible on 0.5.11+ —
  every writer refuses loudly (stderr + exit 1) when unanchored; before
  0.5.11 the same writers silently succeeded into a stray store in the
  wrong directory (issue #13). The reporting site should confirm its
  plugin version and surface stderr; the digest's restart-drift line
  (0.5.12) exists for exactly this.

## [0.5.19] — 2026-08-18

- TODOS-closure batch (per-item adversarial review, human-raised spawn
  budget): `append-relationship` (dedupe/contradiction links with
  exact ids, validator gains relationships schema + referential
  integrity, vocabulary widened to observed reality incl. `compares`),
  `reopen-question` (answered → open when a named reopen condition
  fires; the check-before-lock race the skeptic reproduced is fixed in
  BOTH question helpers — preconditions now resolve under the lock,
  race test pinned), `append-pending` (the D024 surface gets its
  contract: dated checkbox entries, resolution is complete-todo on the
  same file, digest counts unresolved only and goes silent at zero,
  newline flattening across all prose appenders). The line-41
  session-state item verified satisfied and closed — with the 0.5.12
  direction-branch unreadable-state regression the verification
  skeptic caught, fixed and pinned. Multi-valued spec_dir remains
  deferred (evidence-gated).

## [0.5.18] — 2026-08-18

- Tenth field-report fix (issue #18, AmFam Backstage — relayed via the
  feedback queue, gh absent at the site): brownfield adoption now
  covers every hook-read organ. `todos_path:`, `lessons_path:`,
  `roadmap_path:`, `story_path:` in `.claude/anoti.local.md` are
  resolved by retrieve exactly as `state_dir`/`spec_dir` are — D012's
  fixed paths remain the defaults; the explicit mapping wins (repos
  where `docs/` is a published TechDocs/MkDocs tree stop colliding).
  The dangerous silence is gone: a workspace with a store but no
  reachable roadmap/stories organ gets a loud digest line naming the
  accepted paths and the config key. skillify's brownfield prose now
  states exactly which organs adopt via which mechanism, offers the
  verified root-symlink alternative (human-ratified, never silent),
  and admits the gate limitation for non-canonical basenames.
  Multi-valued spec_dir deferred to TODOS pending a second site.

## [0.5.17] — 2026-08-15

- Ninth field-report batch (issues #16-#17, ecounterlist brownfield):
  skillify detects adopted spec/plan organ homes before scaffolding —
  existing homes are recorded as `spec_dir:`/`plan_dir:` in
  `.claude/anoti.local.md` instead of minting duplicate `docs/` dirs,
  and the bootstrap record states exactly what was created (a record
  disagreeing with the filesystem it describes is the failure mode the
  store exists to prevent). The spec and plan skills file to the
  recorded mapping, defaulting to `docs/` (#16). The routing-inputs
  half (#17 — roles/ and SKILL-MAP absent in governed projects) was
  fixed in 0.5.16's plugin-root resolution paragraph; closed against it.

## [0.5.16] — 2026-08-15

- Eighth field-report fix (issue #15, livingsyncs — highest severity to
  date: a human ratification silently discarded during the review
  ritual, both racing helpers exiting 0). Every store mutator (8) and
  session-state writer (3) now serializes its read-modify-write through
  a shared mkdir lock (portable — flock does not ship on macOS), with
  stale-lock stealing (>30s), a loud ~5s timeout, and unique per-process
  scratch paths (the fixed `<store>.tmp` collision is gone). The
  decision helpers (set-ratification, set-status, resolve-question)
  read the field back after the move and fail loudly on mismatch. The
  issue's own 10-round two-writer reproduction is now a test: zero
  lost writes, previously 10/10 rounds losing at least one. Hooks stay
  lock-free by design (fail-open, harness-serialized).
- CI hotfix (same release): store-lock gains its shellcheck shell
  directive (sourced lib, no shebang by design), the lock timeout rises
  to ~60s (8 serialized yq-heavy writers exceeded 15s on a contended
  ubuntu runner — loud timeout, but the test rightly counts it as a
  loss), and `anoti help` writes once, EPIPE-quiet (help | grep -q
  sprayed write-error noise across CI logs).
- Second CI hotfix: the lock's mtime reads are numeric-guarded — when
  GNU stat -c races a vanishing lock dir, the BSD-fallback stat -f
  (FILESYSTEM mode on GNU) printed a multi-line report the command
  substitution still captured, detonating in arithmetic under set -u
  and killing the writer (the two "lost" CI writes were these loud
  deaths). Full suite verified on real ubuntu in docker before push.
- Spec routing paths (field relay): roles/ and SKILL-MAP live in the
  plugin root, not governed projects — the skill now says to resolve
  them from the newest installed plugin root, or a project's own agent
  register with the substitution flagged inline.

## [0.5.15] — 2026-08-15

- `anoti` dispatcher (human directive): one entry point for every
  helper — `scripts/anoti <action> [args...]`, the action being the
  script name; stdin, argv, and exit codes pass through untouched;
  `anoti help` lists every action with its usage line. Purely additive
  (direct calls and hook paths unchanged); refuses unknown actions,
  path traversal, and self-dispatch. The shell-native answer to the
  one-tool ergonomics question, consistent with D022's no-MCP ruling.

## [0.5.14] — 2026-08-15

- Seventh field-report fix (issue #14, ecounterlist): `resolve-question`
  adds the retire half of the open_questions contract — flips exactly
  one open entry to `status: answered` with a dated resolution note
  (the store's established convention), never deletes, refuses unknown
  ids and non-open entries, ids by exact comparison per G002, full
  set-ratification write contract. The digest's question loop also
  drops its own yq `==` (index iteration) — the G002 class closed in
  the last place it lived.

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
