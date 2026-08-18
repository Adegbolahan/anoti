# JIT Recall Cascade — a presence hook that draws the agent back to anoti's workflow

**Spec:** none — authority: human directive 2026-08-18 (field review) + D001
`{GROUNDING.yaml:122-149}`. **A design spec is the first artifact this
cascade produces, and it gates everything else** — nothing named below as
"implementation" is built until that spec passes adversarial review and,
where it touches `docs/ROADMAP.md`, the human ratifies. This document plans
the cascade _up to and including_ the spec; the implementation plan is a
separate, later artifact the spec's own "Execution routing" section will
name an owner for (`skills/spec/SKILL.md:38-54`).

This is spawn 1 of this cascade's session budget (the conductor's own
dispatch counts, per the attention frame).

## 0. Frame trace

**Goal (frame, verbatim intent):** make anoti's memory act at the moment of
use — recall today is a table of contents (SessionStart) and a one-shot
topical query (attend, task start); the failures that motivated this
(cd-chain, stale Vite modules, popover z-index) happened mid-task, at
tool-use time, and the records that would have prevented them — including
global `G004`/`G005`/`G008` — existed and never surfaced.

**Three coordinator amendments arrived mid-research and are bound in below,
not treated as a restart:**

1. Both the pull-side recall search and the push-side hook must query the
   global store, the project store, and LESSONS-LEARNT — reusing
   `scripts/retrieve`'s existing two-store + trust + lessons pattern rather
   than reinventing it — plus a pull-side `anoti recall <keywords>` helper,
   same matcher as the hook, two entry points. (§3, §4)
2. Items 1–2 of the original frame are one mechanism, not two: a single
   budget-bounded, silent-by-default PostToolUse **presence hook** with
   four duties — JIT recall, frame re-anchoring, an evidence-kind nudge,
   and a telemetry line per nudge — plus a pre-registered adherence metric
   added to item 3. Carrot over stick: the field review showed
   over-blocking makes agents route around guardrails. (§5)
3. A three-tier reading of "something that draws the agent back to anoti's
   workflow": Tier 1 is the presence hook itself (always-on, zero LLM
   cost); Tier 2 is an opt-in `/anoti:presence` command wired to `/loop`,
   mirroring `/anoti:audit`'s existing pattern exactly; Tier 3 is
   evidence-gated triggered dispatch of the _existing_ consolidator/skeptic
   agents when the hook pattern-matches drift it cannot itself judge.
   Tier 1's own telemetry decides whether Tier 2/3 get built at all — this
   is a pre-registered decision rule, not a promise to build them. (§6)

None of these amendments changes the spawn count this cascade proposes
(§8) — Tier 2/3 are documented as deferred inside the same spec, not built.

## 1. Roadmap — needed, not present (cited)

```
$ grep -n -i "recall\|trigger\|just-in-time\|jit\b" docs/ROADMAP.md
(no output)
```

Phase 4 is current (`docs/ROADMAP.md:22,78`) and its only open deliverables
are "v1.1 roles validated at working scale" and "Longitudinal audits...
accumulating evidence" (`docs/ROADMAP.md:93-95`) — neither covers
moment-of-use recall. Phase 4's goal is "anoti usable beyond this repo,
honestly marketed by its evidence" (`docs/ROADMAP.md:80-81`); this work is
closer in kind to Phase 1's "does the cycle function" retrieval mechanism
(`docs/ROADMAP.md:24-27`) than to shareability, but Phase 1 is closed
(`docs/ROADMAP.md:19,35-36`) and re-opening a closed phase is a bigger move
than this work needs. **Judgment (labeled):** the cleanest fit is a new
Phase 4 deliverable line — the mechanism serves the existing vision
("governed... memory" that "proves its worth by experiment",
`docs/ROADMAP.md:11-13`) rather than changing the bet, which is why §8
routes the draft to **product-manager** ("drafts prioritization and
sequencing changes", `skills/direction/SKILL.md:55`) and not visionary
("drafts... new phases, changed bets", `skills/direction/SKILL.md:54`).

**story_ref:** `US-001` (frame-assigned) — "Knowledge in context unasked...
Done means: the digest arrives unasked" (`docs/HIGH-LEVEL-STORIES.md:19,30-32`),
verified `✅ 2026-08-13` for SessionStart delivery. **Doubt (labeled, not
mine to resolve):** the field review shows the same knowledge does not
arrive at tool-use time — US-001's evidence line may be due a dated
re-verification note at the roadmap-gate step. I am not amending it here;
flagged for the human alongside the roadmap draft.

**Mechanical enforcement of the gate:** `scripts/inhibit:19-25` denies
Write/Edit to `*ROADMAP.md`/`*HIGH-LEVEL-STORIES.md` outside an
`awaiting-approval`/`committed` episode — the roadmap step below cannot be
skipped by construction, only by an explicit human override.

## 2. Roles register consulted (owner-role citations)

Read in full to assign every task below: `roles/conductor.md`,
`roles/architect.md`, `roles/product-manager.md`, `roles/visionary.md`,
`roles/requirements-analyst.md`, `roles/reviewer.md`,
`roles/technical-writer.md`, `roles/backend.md`, `roles/devops.md`;
`docs/SKILL-MAP.md` (routing precedent: "spec | reached from:... **architect
role**", `docs/SKILL-MAP.md:38`; "direction | reached from: visionary,
product-manager, requirements-analyst roles", `docs/SKILL-MAP.md:40`).
`docs/plans/2026-08-12-anoti-runtime-substrate.md` (Tasks 5/6/8, the hook
scripts this repo already shipped) names no owner-role per task — there is
**no in-repo precedent** for who writes hook scripts; §8's choice of
**backend** (`roles/backend.md:16-24`: "the contract... routes, signatures,
schemas... test-driven... idempotency... error paths") over **devops**
(`roles/devops.md:16-25`: "reproducibility... pipeline-first... rollback")
is a labeled judgment — this work is a stdin/stdout JSON contract over the
plugin's own data model, not an environment/pipeline concern.

## 3. Already verified — narrows the unknown list before any spawn (conductor's own research, cited)

### 3a. PostToolUse supports `hookSpecificOutput.additionalContext` — verified, not merely hypothesized

- `hooks/hooks.json:1-71` registers zero PostToolUse hooks today (matches
  the coordinator's claim). `docs/specs/2026-08-12-anoti-plugin-design.md:509-519`'s
  hook table lists the same six events this plugin has ever used —
  PostToolUse is new ground for this codebase.
- `{url: https://code.claude.com/docs/en/hooks, anchor: "Decision Control"
table + "PostToolUse additionalContext" section}` (fetched 2026-08-18):
  PostToolUse's decision field **is** `additionalContext`; example payload
  `{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"..."}}`
  — the identical shape already used by `scripts/retrieve:161` and
  `scripts/classify:24`.
- `{url: https://github.com/anthropics/claude-code/issues/24788}`: a real
  user's working PostToolUse+`additionalContext` payload; the reporter
  states the hook "work[s] correctly when tested manually" — the bug is
  scoped to **MCP tool-call matching only**, closed as not planned. This
  hook's matcher targets `Bash|Write|Edit|NotebookEdit` (mirroring
  `hooks/hooks.json:27`'s existing PreToolUse matcher) — non-MCP, outside
  the known gap.
- The event structurally cannot block (`docs/specs` fetch: "Cannot block –
  exit code 2 is honored but only shows stderr to Claude; the tool already
  ran") — this makes the "carrot over stick" requirement (coordinator
  amendment 2) a property of the mechanism, not just a design intent.
- **Residual, genuinely open:** the exact stdin field name(s) carrying
  tool output/error text on PostToolUse (`tool_response`? `tool_output`?)
  were not recoverable from the fetched (truncated) docs page. → **U1**,
  §7.

### 3b. An optional `triggers:` field is schema-v3-compatible — verified by direct read, with one correction

- `scripts/validate-workspace:1-53` (read whole file): no check anywhere
  enumerates a closed set of record-level top keys — only _nested_ keys
  under `source`/`events`/`evidence`/`relationships` are checked against
  closed lists (`scripts/validate-workspace:27-36`). A new top-level
  optional field is not rejected by anything this validator does today.
- `scripts/append-record:13`: `yq '.records += [strenv(REC) | fromjson]'`
  passes the given JSON through untouched — no key filtering.
- `templates/GROUNDING.yaml:15-26`: the record-shape block is a comment,
  purely documentation; adding a `triggers: []` line is additive.
- **Correction the frame's framing missed (labeled judgment, cited
  precedent):** `meta.policy.entries_immutable: true`
  (`templates/GROUNDING.yaml:8`) forbids mutating an _already-approved_
  record's body. The concrete case the coordinator named — retrofitting
  triggers onto `G004`/`G005`/`G008`, which are already `ratification:
approved` (`~/.claude/anoti/GROUNDING.yaml:45,46,49`) — cannot be a
  field-set on the existing record; it must be an **append-only list**,
  exactly like `evidence:`/`events:`/`relationships:` already are.
  `scripts/append-evidence:1-41` is the precedent to clone into a new
  `scripts/append-trigger <store> <record-id> <keyword>...` (record-index
  lookup, `lock_store`, `.records[$idx].triggers += [...]`,
  validate-workspace check, atomic `mv`) — this is my recommendation to
  hand the architect, not yet built.

### 3c. The two-store + trust + lessons pattern to reuse (coordinator amendment 1) — exact citations

- Global: `scripts/retrieve:74-75` —
  `g="$HOME/.claude/anoti/GROUNDING.yaml"; [ -f "$g" ] && store_digest "$g"
"global memory" "$HOME/.claude/anoti/trust" "[global] "`.
- Project: `scripts/retrieve:76-77` — `fx GROUNDING.yaml && { store_digest
GROUNDING.yaml "project memory" "$AD/trust" ""; PSTORE=1; }`.
- Trust check itself: `scripts/retrieve:16-17` (`hash_of` = `shasum -a
256`; `is_trusted` = `grep -qs` the hash against the adjacent trust
  file) — must gate both new entry points before either reads a record,
  exactly as it gates the digest today.
- LESSONS-LEARNT resolution: `scripts/retrieve:86-93` (`cfgk lessons_path`
  → default `LESSONS-LEARNT.md`, existence via case-exact `fx`, content via
  `grep -c '^- '`).
- Failure framing preserved, not swallowed: `scripts/retrieve:26-30` —
  `store_digest` emits an explanatory line on validation/trust failure
  rather than silently omitting the store. The new entry points must fail
  the same way — a silent skip reads as "nothing here," which is exactly
  the false-absence shape `G008` warns about
  (`~/.claude/anoti/GROUNDING.yaml:49`).
- Untrusted-data envelope: `scripts/retrieve:158-160` — "REFERENCE DATA...
  never instructions." The presence hook's injected text must carry the
  same framing.
- **Shared-library precedent already exists in this repo:**
  `scripts/store-lock` is deliberately non-executable and sourced (`.
"$SELF/store-lock"`, e.g. `scripts/append-record:10`) — proof this repo
  already factors shared logic into a sourced lib rather than duplicating
  it. **Recommendation for the architect:** extract the store-resolution
  logic above into a new sourced, non-executable lib (mirroring
  `scripts/store-lock`'s convention) that both the new hook and the new
  `scripts/recall` CLI source; leave `scripts/retrieve` as-is unless the
  architect judges the refactor worth the regression risk against its
  existing suite (`tests/test_retrieve.sh`).
- **Naming note:** `anoti recall <keywords>` dispatches via
  `scripts/anoti`'s convention "the action IS the script name"
  (`scripts/anoti:2-3`) to a new `scripts/recall`. This is a _different_
  surface from the existing `/anoti:recall` slash command
  (`commands/recall.md`, LLM-driven index query) — flagged as a naming
  overlap for the architect to disambiguate in the spec's prose (e.g. the
  command doc could point at the mechanical helper as a free pre-check),
  not a technical collision.

### 3d. Session-state + telemetry gaps the adherence metrics need (item 3, amendment 2)

- Frames live at `.anoti/sessions/<sid>.yaml`, key `frames:` (list, each
  `{id, status, goal, scope, ...}`, amends-chained) per
  `skills/attend/SKILL.md:34-54` — this **supersedes** the singular
  `attention_frame:` object shown in
  `docs/specs/2026-08-12-anoti-plugin-design.md:249` (an older draft,
  predating the amends mechanic). Flagged as a doubt in §9, not fixed here.
- `scripts/append-classification:23` already writes a durable
  `ts\tsid\tverdict\treason` telemetry line on every classification — the
  existing precedent for counting "slow-classified sessions."
- **Gap found:** `scripts/session-append:1-41` (the writer of `frames:`)
  never touches `telemetry.log`. Session YAML is gitignored and **deleted**
  at clean SessionEnd (`scripts/cleanup-session:13`, `rm -f "$sf"` when
  episode is idle/committed). Once a session ends cleanly, there is no
  durable trace a frame was ever written. "% slow-classified sessions with
  a frame" is **unmeasurable today** from durable artifacts.
- **Gap found:** nothing durable distinguishes "retrospective ran, found
  nothing" (the legitimate fast path, `skills/policy-retrospect/SKILL.md:43-45`)
  from "retrospective never fired." "% nontrivial sessions with a
  retrospect" has the identical gap.
- "Nontrivial" is already this repo's own term, roughly synonymous with
  slow-classified: `docs/specs/2026-08-13-exp-h1-h3-benchmark.md:58`
  ("frame on nontrivial"); `docs/trials/2026-08-13-h1h3-armB/GRADES.md:8`
  ("frame-for-nontrivial FAIL (telemetry: all 5 nontrivial tagged fast)").
  Carry this definition forward rather than inventing a new one.
- **Recommendation for the architect (labeled judgment, built on cited
  gaps):** (1) extend `scripts/session-append` to also emit a
  `ts\tsid\tframe\t<frame-id>` telemetry line when `key=frames`, mirroring
  `scripts/set-episode:19`'s existing pattern exactly; (2) extend
  `scripts/cleanup-session` to emit one durable summary line per session
  before deleting/archiving state (`ts\tsid\tsummary\tslow=<n>\tframes=<n>\tretrospect_ran=<bool>\tepisode=<final>`),
  with `retrospect_ran` set by a new tiny helper the consolidate skill's
  step 11 calls even on the "found nothing" path. This closes the same
  false-absence shape `G008` names.

## 4. Global/project/lessons contract both new entry points must share

Per coordinator amendment 1, **both** the push-side presence hook (§5) and
the pull-side `scripts/recall` CLI **must**:

1. Resolve the project store exactly as `scripts/retrieve:76-77` does
   (case-exact `fx`, `validate-workspace`, `is_trusted` against
   `$AD/trust`).
2. Resolve the global store exactly as `scripts/retrieve:74-75` does
   (`$HOME/.claude/anoti/GROUNDING.yaml`, trust-checked against its
   adjacent `$HOME/.claude/anoti/trust`), labeling every global-sourced hit
   `[global] ` — this is the literal mechanism that would have surfaced
   `G004`/`G005`/`G008` at tool-use time had it existed.
3. Resolve LESSONS-LEARNT exactly as `scripts/retrieve:86-93` does
   (`cfgk lessons_path` → default).
4. Preserve the untrusted-data envelope (`scripts/retrieve:158-160`) and
   the report-don't-silently-skip behavior on validation/trust failure
   (`scripts/retrieve:26-30`).
5. Share one matcher between the two entry points (coordinator: "same
   matcher, two entry points") — the architect's spec names the single
   function/lib both call (§3c's recommended sourced lib is the concrete
   proposal).

## 5. The presence hook — one PostToolUse touchpoint, four duties (coordinator amendment 2)

Duties, each independently budget-bounded and testable within the spec:

- **(a) JIT recall.** Match the tool's command/file/error text against
  `triggers:` (project + global + LESSONS-LEARNT, §4) and inject hits as
  `additionalContext`, budget-bounded, no LLM cost. Consolidation gains the
  encoding-time question "what would you have needed to see to be reminded
  of this?" so triggers are authored where D001's pipeline places encoding
  (`GROUNDING.yaml:143-144`: "Perception & encoding..."; `:146`: "Retrieval
  & response... generating feedback that restarts the cycle") — **labeled
  inference**: D001 does not name "encoding specificity" as a term, but its
  staged pipeline (encoding stage feeding a retrieval stage cued by the
  same features) is the cited grounding for writing cues at write-time
  rather than relying on retrieval-time reconstruction alone.
- **(b) Frame re-anchoring**, two sub-mechanisms (design split, not a
  research unknown):
  - _Compaction recovery_ reuses the **existing** SessionStart/PreCompact
    hooks rather than needing the new one: `scripts/retrieve:10`
    (`cat >/dev/null 2>&1 || true # consume stdin; digest does not depend
on it`) shows retrieve today **ignores** the `source` field entirely —
    extending it to branch on `source == "compact"` is additive, not a
    rewrite. `scripts/persist-session:17` already stamps
    `.session.flushed` on every PreCompact firing; stamping a
    `.session.compacted_at` marker there, read back by the extended
    retrieve, is the minimal path — confirms the coordinator's own framing
    ("SessionStart source=compact via retrieve... or first PostToolUse
    after a compaction marker") in favor of the lower-risk option.
  - _Periodic mid-session re-anchoring_ ("lightly every N tool calls in a
    slow-classified session") is the genuinely new PostToolUse duty: read
    a tool-call counter from session state, re-inject the active frame's
    `goal`/`scope` (the `frames:` list, `status: active`,
    `skills/attend/SKILL.md:34-54`) every N calls.
- **(c) Evidence-kind nudge.** On a verification-shaped tool call (a
  screenshot read, a text-extraction grep) emit a short nudge toward the
  nearer-to-ground-truth instrument, citing `G004`
  (`~/.claude/anoti/GROUNDING.yaml:45`, "verification-predicate-must-be-falsifiable")
  and its sibling `G008` (`:49`, "absence-needs-exhaustion-not-one-look").
  This is item 2 of the original frame, folded into the same touchpoint.
- **(d) Telemetry line per nudge** — one tab-separated line per firing
  (which duty, which record/pattern matched), mirroring the
  `set-episode`/`append-classification` precedent (§3d), feeding both the
  longitudinal audit and the new adherence metric (§6).

**Constraints bind identically to every other hook in this plugin:** fail
open, ≤5s, POSIX shell + `yq`/`jq`, no network
(`docs/specs/2026-08-12-anoti-plugin-design.md:507-509`, "every script
honors its timeout and **fails open** — on error it emits a one-line
stderr report and exits 0"); silence is the default output on trivial/fast
sessions (US-002, `docs/HIGH-LEVEL-STORIES.md:33-34,20`) — the hook must be
inert (no telemetry, no injected text) when nothing matches, the same
contract `scripts/inhibit` already honors for "not matched by any pattern"
(`docs/specs/2026-08-12-anoti-plugin-design.md:527`, decision table row 1).

## 6. Three tiers, only one built now (coordinator amendment 3)

**Harness facts bound in, cited from repo-internal evidence** (no
subagent in this repo's own roster carries a timer or self-wake field —
`agents/explorer.md`, `agents/skeptic.md`, `agents/consolidator.md`,
`agents/practitioner.md` frontmatter has none; every hook in
`hooks/hooks.json` only ever emits `additionalContext`/`permissionDecision`/
`decision` or exits silently — none invokes an agent dispatch
(`docs/specs/2026-08-12-anoti-plugin-design.md:509-519`'s Output column));
recurring/scheduled execution is a **main-session** capability
(`loop`/`schedule` skills in this session's own skill listing), not
something a hook or a subagent can initiate.

- **Tier 1 (default, zero LLM cost, built by this cascade's downstream
  spec):** the presence hook itself, §5 — always awake, mechanical only.
  Extend its pattern set to house-craft drift too, not just recall: "slow
  session, no frame yet → suggest attend" (traces to `US-004`,
  `docs/HIGH-LEVEL-STORIES.md:38-40`), "N edits, no test run → surface
  policy-test-driven" (`skills/policy-test-driven/SKILL.md`).
- **Tier 2 (opt-in, human-wired, not built by this cascade):** an
  `/anoti:presence` command examining session state + telemetry + recent
  trail for skill/workflow suggestions, run on cadence via `/loop` —
  **exact existing precedent**: `commands/audit.md:56-58`, "the human
  wires the cadence — `/loop 7d /anoti:audit`... The audit never schedules
  itself; recurring token spend is the human's call, once." Tier 2 is the
  same pattern, new command.
- **Tier 3 (evidence-gated, later, not built by this cascade):** Tier 1,
  on a drift pattern it can match but not judge, emits one advisory
  telemetry/context line naming the pattern; the **main session** (never
  the hook) decides whether to spawn the existing consolidator or skeptic
  agent against the trail — triggered, not timed, and consistent with
  "hooks cannot spawn agents."
- **Pre-registered gate (folds into item 3's spec amendment, §8 spawn
  #4):** Tier 1's own telemetry (nudges emitted vs. adherence measured
  after) is the evidence that decides whether Tier 2/3 get built at all —
  a decision rule, not a commitment. This is exactly the discipline
  `docs/specs/2026-08-13-exp-longitudinal.md`'s changelog already practices
  (dated amendment entries, `:61-70`) and what `TODOS.md:32-36` calls
  skipping a tool "per YAGNI until repeat need."

## 7. Unknowns — each with an assigned research role

| ID  | Unknown                                                                                                                                                                                                                                                                                                                                                                                                                                        | Why it's still open                                                                                                                  | Role                                                                                                                                                                                                                                                                                                               | Spawn                                                                                         |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| U1  | Exact stdin field name(s) for tool output/error text on PostToolUse (`tool_response`? other?), AND live confirmation that `additionalContext` actually surfaces in the next model turn for a non-MCP tool in _this_ installation — doc claims (§3a) are strong but per **G005** ("documentation is not evidence... verified only against the artifact... or a live query", `~/.claude/anoti/GROUNDING.yaml:46`) they are not yet a live query. | Docs page truncated before the PostToolUse-specific input schema; no PostToolUse usage exists anywhere in this repo to cite instead. | **skeptic** (empirical: build a throwaway PostToolUse test hook, trigger a real matched tool call, capture+inspect the actual stdin JSON, confirm the emitted `additionalContext` appears in the following turn)                                                                                                   | #3                                                                                            |
| U2  | Attempted refutation of §3b's compatibility claim and §3b's immutability correction (the `triggers:` design) before the spec asserts either as more than speculative — policy-epistemic point 3: a significant claim other tasks build on goes to the skeptic first.                                                                                                                                                                           | I verified both by direct read, but I built the hook's entire schema story on them — they are load-bearing.                          | **skeptic** (re-attack: re-read `scripts/validate-workspace`, `scripts/append-record`, `templates/GROUNDING.yaml`, `~/.claude/anoti/GROUNDING.yaml` for the append-only-list precedent; try to construct a case where an unvalidated `triggers:` field DOES break something, e.g. `regen-index` or `record-index`) | #3 (same spawn as U1 — related "verify the technical foundation" claims, one focused session) |

U1 and U2 are folded into **one** skeptic spawn (#3) — both are
"verify the technical foundation before the spec is written on top of it,"
and splitting them would spend a spawn on overlap rather than breadth. No
**explorer** dispatch is needed for either: explorer's toolset is
`Read, Grep, Glob` only (`agents/explorer.md:5`) — it cannot fetch
`code.claude.com` or run a live hook capture, so it cannot make progress on
U1 beyond what I've already read in-repo; skeptic carries `Bash`
(`agents/skeptic.md:5`) and is the only research role that can actually run
the empirical test.

**Everything else in §3/§4/§5/§6 is either resolved by direct citation
above, or is explicitly a design decision handed to the architect (§8,
spawn #4) rather than a fact to research** — naming a decision as an
"unknown" when it is really a choice would misroute it to a research role
that cannot decide it.

## 8. Agent sequence — produces/consumes, human gates, spawn arithmetic

Budget: ≤3 concurrent, ≤8 per session. This cascade proposes **5 spawns
total** (this plan is #1); implementation spawns (backend, technical-writer,
further review) are **out of scope for this document** — they depend on
content the spec (not yet written) will contain, and on the human's
roadmap-gate decision (not yet made). They are named as a follow-on cascade
in §8's closing note, not dispatched here.

| #              | Spawn                             | Role                | Produces                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Consumes                                                                                                                            | Concurrency                                                                | Justification (1 line)                                                                                                                                                                                                                                   |
| -------------- | --------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1              | This document                     | conductor           | `docs/plans/2026-08-18-jit-recall-cascade.md`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | attention frame, workspace digest                                                                                                   | —                                                                          | Required by the deliberate skill's cascade step 2 before any dispatch; counted per the frame's own instruction.                                                                                                                                          |
| 2              | Roadmap amendment draft           | **product-manager** | Draft: new Phase 4 deliverable line (JIT recall/presence hook), + the US-001 re-verification note as a flagged option for the human                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | §1's grep evidence, `docs/ROADMAP.md`, `skills/direction/SKILL.md`                                                                  | runs **concurrently with #3**                                              | Roadmap gate blocks everything downstream (§1); nothing else in this cascade depends on its _content_, only on the human's eventual ratification, so it need not wait in line.                                                                           |
| 3              | Technical-foundation verification | **skeptic**         | Verdict + evidence on U1 (live PostToolUse capture) and U2 (schema-compatibility refutation attempt)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | §3a/§3b's citations, live Bash access to run a throwaway hook test                                                                  | runs **concurrently with #2**                                              | Policy-epistemic point 3: a significant claim (the whole hook design rests on it) gets an attempted refutation before the spec builds on it as settled.                                                                                                  |
| **HUMAN GATE** | Roadmap ratification              | —                   | Ratified/amended/rejected `docs/ROADMAP.md` Phase 4 line                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | #2's draft                                                                                                                          | —                                                                          | Mechanically enforced (`scripts/inhibit:19-25`); only human gate in this cascade per the frame's constraint.                                                                                                                                             |
| 4              | Design spec                       | **architect**       | `docs/specs/2026-08-18-jit-recall-cascade-design.md` — the unified presence-hook design (§5), the `triggers:`/`append-trigger` schema (§3b), the shared store-resolution lib (§3c), the `scripts/recall` CLI (§4), the session-state/telemetry extensions (§3d), the evidence-kind checklist wording for `skills/policy-epistemic/SKILL.md` + `commands/review-work.md`/`roles/reviewer.md` (item 2), the longitudinal-spec amendment text + the new adherence metric + the Tier-1-telemetry pre-registered gate (item 3, §6), and the Tier 1/2/3 map (§6) with Tier 2/3 explicitly out of scope for the spec's own build | Ratified roadmap line, #3's verdict, all of §3/§4/§5/§6's citations and recommendations (handed off as input, not as dictated text) | — (sequential; needs the ratified roadmap_ref and the verified foundation) | `roles/architect.md:19-20`: "this role handles technical decomposition"; `docs/SKILL-MAP.md:38` names architect as the spec skill's entry point; the unification (coordinator amendment 2) makes ONE coherent spec the right shape, not three fragments. |
| 5              | Spec adversarial review           | **reviewer**        | Findings report (compliant / issues / cannot-verify), `{file,lines}` per finding                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | The spec (#4), this cascade plan (to check spec answers what was asked)                                                             | — (sequential; reviews #4's output)                                        | `skills/spec/SKILL.md:84-85`: "Specs of consequence get adversarial review before 'done'"; policy-adversarial-handoff mandates a fresh spawn, never self-review.                                                                                         |

**Follow-on cascade (not dispatched here, named for continuity):** if
review #5 returns compliant, the spec's own "Execution routing" section
(spec skill requirement, `skills/spec/SKILL.md:38-54`) names the plan owner
and builder hats for implementation — expected to be **architect or
project-manager** for technical decomposition into an implementation plan,
then **backend** for the hook/CLI/helper scripts (§2's reasoning),
**technical-writer** for the policy/role/command text edits (item 2), and
**reviewer** again before merge (policy-adversarial-handoff). That
follow-on cascade is a separate conductor dispatch, budgeted separately,
once the spec exists to plan against.

## 9. Conditional branches (named in advance)

**Branch A — roadmap gate (after spawn #2):**

- Human ratifies the draft as proposed → proceed to spawn #4 citing the
  ratified line as `roadmap_ref`.
- Human amends the wording → proceed with the human's merged text as
  `roadmap_ref`; no new product-manager spawn (the human's edit IS the
  ratification, `skills/policy-draft-for-ratification/SKILL.md:14-16`
  paraphrase — draft is a proposal, not a fixed text).
- Human **rejects** the amendment (decides this is out of scope for Phase
  4 now) → **the cascade stops here.** Per policy-trace-to-frame
  (`skills/policy-trace-to-frame/SKILL.md:12-16`), spawns #4/#5 would have
  nothing ratified to trace to; report the rejection and file it, do not
  silently reroute to "no roadmap needed."

**Branch B — technical-foundation verdict (after spawn #3):**

- **Survives** (live capture confirms `additionalContext` surfaces for a
  non-MCP tool; `triggers:` refutation attempts fail) → spawn #4 proceeds
  on the design as scoped in §5.
- **Refuted** (the mechanism does not work as documented in this
  installation, or the schema claim breaks something concrete) → escalate
  as a critical finding to the main session; spawn #4's brief pivots to
  the nearest working alternative named in advance: enrich the
  **already-proven** PreToolUse `inhibit` hook's `permissionDecisionReason`
  text (`docs/specs/2026-08-12-anoti-plugin-design.md:516`) for the
  evidence-kind nudge (duty c) and fall back to SessionStart-only frame
  re-anchoring (duty b's compaction path only, dropping the periodic
  mid-session path) for JIT recall — a strictly smaller but still
  frame-serving mechanism, not a dead end.
- **Undetermined** (sandbox/environment prevents a live hook test in the
  skeptic's execution context) → proceed to spawn #4 on the doc-based
  evidence alone, but the spec must label the PostToolUse contract
  `probable`, not `established`, and name the live test as the first item
  of the eventual implementation plan's verification step.

**Branch C — spec review outcome (after spawn #5):**

- **Compliant** → done for this cascade; report readiness for the
  follow-on cascade (§8's closing note) to the main session.
- **Findings/blockers** → per D011 (`skills/deliberate/SKILL.md:82-90`),
  resume the **same** architect spawn (#4) with findings relayed verbatim
  — never a fresh spawn, never self-fix by the reviewer. Cap at 3 review
  cycles by analogy to `commands/review-work.md:51-54`'s cycle cap; a
  blocker surviving three rounds is a design decision for the human, not a
  fourth attempt.

## 10. Per-task owner-role summary (plan-skill rule: every task names one hat)

| Task                                                         | Role                         | Policies it loads (from its role stack)                                                                                                   |
| ------------------------------------------------------------ | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Roadmap amendment draft                                      | product-manager              | epistemic, trace-to-frame, escalate-destructive, draft-for-ratification                                                                   |
| Technical-foundation verification                            | skeptic                      | (agent-level contract, `agents/skeptic.md`) — not a `roles/` hat; the deliberate skill's research-role slot, not the practitioner cascade |
| Design spec                                                  | architect                    | epistemic, trace-to-frame, escalate-destructive, parallel-breadth                                                                         |
| Spec adversarial review                                      | reviewer                     | epistemic, trace-to-frame, escalate-destructive                                                                                           |
| _(follow-on, not dispatched)_ implementation decomposition   | architect or project-manager | per spec's Execution routing                                                                                                              |
| _(follow-on, not dispatched)_ hook/CLI/helper scripts        | backend                      | epistemic, trace-to-frame, escalate-destructive, test-driven, adversarial-handoff                                                         |
| _(follow-on, not dispatched)_ policy/role/command text edits | technical-writer             | epistemic, trace-to-frame, escalate-destructive, reader-run, draft-for-ratification                                                       |
| _(follow-on, not dispatched)_ implementation review          | reviewer                     | epistemic, trace-to-frame, escalate-destructive                                                                                           |

## 11. Questions/doubts (policy-epistemic)

- **US-001's "done" status may be stale, not wrong.** Its evidence line
  (`docs/HIGH-LEVEL-STORIES.md:19`) verifies SessionStart delivery, which
  is still true; the field review shows a _different_ moment (tool-use
  time) is where it currently fails. I flagged this in §1 rather than
  drafting a story amendment myself — the frame named US-001 as the
  `story_ref`, not "draft a new story," and I don't have authority to
  decide which reading the human intends.
- **The presence-hook design in §5/§6 is my synthesis of three
  successive coordinator messages plus my own research, handed to the
  architect as a brief, not as pre-written spec text.** I could not find
  any place in this repo where a spec was written by the conductor rather
  than the architect, so I deliberately stopped short of drafting the
  spec's actual prose — if that boundary is wrong for this case, the
  architect spawn is cheap to redirect.
- **U1's empirical test may not be runnable inside the skeptic's sandbox**
  (registering a hook typically requires editing a `settings.json` the
  harness reads at startup, not mid-session) — I named this as Branch B's
  "undetermined" case rather than assuming the test will succeed; if it
  can't run at all, the fallback in Branch B still lets the cascade
  proceed on labeled `probable` evidence.
- **`docs/specs/2026-08-13-exp-longitudinal.md` itself lacks the
  "Execution routing" section the current `skills/spec/SKILL.md:70-75`
  requires for experiment specs.** I did not treat this as blocking §7's
  amendment task (architect adds the recall-miss metric + the new
  adherence metrics + the Tier-1 pre-registered gate as dated changelog
  entries, per the spec skill's amendment rule, `skills/spec/SKILL.md:20-21`)
  — but the architect may reasonably choose to backfill that missing
  section in the same pass, since they're already amending the file.
- **Whether the human wants Tier 2/3 even sketched in the spec, versus
  deferred to a future spec entirely,** is a judgment call I made in favor
  of "sketch now, build later" (§6) because the coordinator described all
  three tiers in one breath and a spec that's silent on Tiers 2/3 would
  leave the architect's scope boundary implicit — but this is exactly the
  kind of scope decision that belongs to the human's read of the roadmap
  draft (#2), not to me.
- **I did not verify** whether `regen-index` or `record-index`
  (`scripts/regen-index`, `scripts/record-index`) do anything with
  unexpected record keys that could break on a new `triggers:` array —
  I read `validate-workspace` and `append-record` closely but not these
  two; this is explicitly folded into skeptic spawn #3's U2 mandate rather
  than left silently unchecked.
