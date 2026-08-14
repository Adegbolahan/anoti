# anoti — Design Spec

> **Outsource some of the thinking, but never outsource understanding.**

**Date:** 2026-08-12
**Status:** Revised after external review; implementation-ready draft pending user approval
**Grounding:** Discoveries D001–D004 and Q001 in `GROUNDING.yaml` — cited below as
motivation and hypotheses, not as established consequences (see "Why").

## What this is

A Claude Code plugin that gives AI agents a human-shaped cognitive work cycle —
retrieve, attend, deliberate, act/inhibit, consolidate — implemented with
AI-native mechanics (context injection, skills, subagents, hooks), with the
human as a structural component of the architecture: goals, values, and
ratification of what is remembered stay human. Shared knowledge is governed by
an explicit epistemic model: typed records, evidence, falsifiability for
claims, and separated epistemic/ratification status.

**The differentiation is not memory — Claude Code already has CLAUDE.md,
auto-memory, and subagent memory. The differentiation is _governed,
evidence-bearing, human-ratified_ memory plus an enforced work cycle.**

## Why (design hypotheses, not established facts)

D001–D004 motivated this design but do not prove it. Stated honestly:

- **H1 — Governed memory beats ad-hoc memory.** A structured, evidence-bearing,
  ratified store reduces re-derivation, contradiction, and acting on stale
  facts, compared to native free-form memory. _Testable; see Success criteria._
- **H2 — Structure beats instructions for cycle adherence.** D004 showed
  familiar syntax is comprehended more reliably than invented notation; it
  suggests — but does not establish — that hook-enforced structure outperforms
  instruction-only methodology. _Registered as an experiment._
- **H3 — Human ratification prevents memory rot.** Keeping promotion of memory
  in human hands reduces bad-memory incidents (acting on wrong claims).
  _Testable via bad-memory rate._

**Relationship to native Claude Code memory:** CLAUDE.md remains the
instruction layer and is not managed by anoti. Native auto-memory is treated
as an _inbox_: anoti's consolidation may import its notes as candidate
records, never the reverse. anoti disables nothing silently.

## Design principles

The slogan governs every layer, in both directions: the human outsources
thinking to the system (breadth, drafts, analysis, recall) but never
understanding — goals, values, ratification. The main session outsources
thinking to subagents (exploration, verification, role work) but never
understanding — synthesis and memory writes stay in the one context that
holds the whole picture.

1. **Dual-process, not rituals.** Every hook is a classifier with a fast path.
   Trivial prompts incur zero visible overhead.
2. **Never fight the model's design.** Hooks compensate only for structural
   gaps; skills guide everything the model already does well in-context.
3. **Human as component, not supervisor.** Defined roles: goal disambiguation
   (attend), value judgment on consequential actions (inhibit), ratification
   of memory (consolidate/review).
4. **Evidence over authority — and authority over storage.** Evidence alone
   moves epistemic status; the human alone approves storage and action. Two
   separate dimensions (see Record model).
5. **Degrade toward vanilla Claude Code, never toward blockage.** All hooks
   fail open with a visible report. The only hard-deny is the explicit
   catastrophic list. Native permission rules remain the real enforcement
   boundary; anoti's inhibition is a narrow guardrail on top, not a security
   layer.
6. **Native-first.** Prefer Claude Code's own mechanisms (permissions,
   memory, skills) over parallel inventions; integrate, don't shadow.

## The cognitive cycle

| Stage            | Human analog (D001)           | Implementation (D002-native)                                                                                                   | Human role (D003 gaps)                      |
| ---------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| 1. Retrieve      | Top-down priors from LTM      | SessionStart injects a small identity/project digest; attend pulls topic-relevant records; `/anoti:recall` on demand           | — (automatic)                               |
| 2. Attend        | Attention bottleneck          | UserPromptSubmit classifier: routine → silent pass; novel/ambiguous/consequential → `attend` skill produces an attention frame | Goal ambiguities escalated as questions     |
| 3. Deliberate    | Working-memory manipulation   | `deliberate` skill: hypothesis-before-test, role/hat assignment, bounded parallelism, synthesis over accumulation              | —                                           |
| 4. Act + Inhibit | Selective response inhibition | PreToolUse decision table (allow/ask/deny) on a narrow matcher                                                                 | Value judgment on `ask` escalations         |
| 5. Consolidate   | Memory consolidation          | Per-episode state machine + Stop-hook gate + `/anoti:consolidate` fallback; consolidator proposes, human approves              | Ratification; promotion via `/anoti:review` |

## Record model (the epistemic engine, made precise)

### Record types

Not everything stored is a falsifiable claim. Five types, one shared envelope:

| Type         | What it is                              | Epistemic status? | Example                                        |
| ------------ | --------------------------------------- | ----------------- | ---------------------------------------------- |
| `claim`      | Falsifiable, evidence-bearing statement | Yes               | "Familiar formats are parsed more reliably"    |
| `preference` | User-confirmed, revisable taste         | No                | "User prefers terse commit messages"           |
| `decision`   | A choice, with rationale + supersession | No                | "We chose YAML over sigil notation (see D004)" |
| `goal`       | Desired state with success criteria     | No                | "Plugin v1 passes all behavioral tests"        |
| `policy`     | Normative operating rule                | No                | "Prefer reversible deployments"                |

The consolidator classifies candidates by type; only `claim` records enter the
evidence ladder. A value like "prefer reversible deployments" is a `policy`,
never mislabeled as scientific truth.

### Two independent status dimensions

```yaml
epistemic_status: speculative | probable | established # claims only; moved ONLY by evidence
ratification: pending | approved | rejected # all types; moved ONLY by the human
```

Human approval decides whether anoti stores and acts on a record. Evidence
decides how epistemically strong a claim is. Neither moves the other.

### Evidence rules

- Ladder: `speculative` (no evidence) → `probable` (some evidence) →
  `established` (tested or independently confirmed). Demotion on contradicting
  evidence is symmetric and expected.
- **Independence** means a different session, agent lineage, or method.
  Chains of self-citation never establish a claim.
- **Contradiction protocol:** new work contradicting an established claim never
  overwrites; record a `contradicts` relationship, spawn an open question with
  a verification method, resolve by evidence.
- **Hypothesis before test**, in deliberation, always.
- **Experiments are filed as specs**: `docs/specs/YYYY-MM-DD-exp-<topic>.md`
  (design + results); evidence entries reference the file.

### Store mechanics (append-only, made coherent)

- **Record content is immutable** after creation. All change — status moves,
  ratification, scoped exceptions, demotions, question resolution — is an
  appended `events:` entry (`{date, action, by, note}`). Current status is
  derived from the event log (cached fields are regenerator output, not
  hand-edits).
- **IDs:** allocated as max-existing + 1 per store, scope-qualified when
  referenced across stores (`global:D004` vs `project:D012`).
- **The index is generated**, never hand-maintained: `scripts/regen-index`
  rebuilds it from records; consolidation runs it after every append.
- **Atomicity & recovery:** writes go to a temp file then rename; every read
  schema-validates; an invalid store is quarantined (renamed aside) and
  reported, never silently "fixed."
- **Grandfathering:** current D001–D003 are `established` with no evidence
  list — they violate this very protocol. On migration they demote to
  `probable` with an event noting "grandfathered; evidence pending," and
  queue for review. The methodology applies to its own history first.

## The externalized workspace

The plugin scaffolds and maintains a document system in every project. Each
file is an externalized cognitive organ of the human+AI pair; the human owns
direction.

| Artifact                     | Cognitive organ                                | Owned by | Touched by                                            |
| ---------------------------- | ---------------------------------------------- | -------- | ----------------------------------------------------- |
| `GROUNDING.yaml`             | Semantic memory — records per the model above  | shared   | retrieve (read), consolidate (write), review          |
| `docs/ROADMAP.md`            | Goal hierarchy — where we are going            | human    | attend traces work to it; human edits direction       |
| `docs/HIGH-LEVEL-STORIES.md` | Values/perspective — what "good" means         | human    | attend + inhibit reference it as the value standard   |
| `TODOS.md`                   | Prospective memory — open intentions           | shared   | retrieve (surface), deliberate + consolidate (update) |
| `LESSONS-LEARNT.md`          | Procedural memory — how we work                | shared   | consolidate writes process lessons here               |
| `docs/specs/`                | Deliberation artifacts — designs as hypotheses | shared   | deliberate writes; one dated file per design          |
| `docs/plans/`                | Deliberation artifacts — protocols             | shared   | deliberate writes; one plan per implementation        |

GROUNDING holds typed records (semantic); LESSONS-LEARNT holds process lessons
(procedural). A lesson that becomes falsifiable and gathers evidence graduates
into a `claim`.

### skillify: bootstrap and maintenance contract

- **Bootstrap is idempotent**: re-running creates only what is missing; it
  never overwrites. `--dry-run` prints the plan. Existing files get a dated
  backup before any migration touches them. Project root = the git toplevel
  (or CWD if not a repo, with a warning).
- **Brownfield adoption:** existing docs/CLAUDE.md are mapped onto organs;
  only gaps are created; existing content referenced in place.
- **Migration:** the workspace records the plugin/schema version that
  scaffolded it; on mismatch skillify proposes a migration diff, the human
  ratifies. No silent upgrades.
- **Uninstall:** the workspace is plain files and simply remains — designed
  degradation. skillify offers (never forces) removal of `.anoti/` ephemera.
- **CLAUDE.md:** retrieval is the SessionStart hook's job, period. skillify
  does not wire retrieval pointers into CLAUDE.md (one responsibility, one
  owner); it may add a short human-facing note documenting that the workspace
  exists, clearly marked as documentation.
- Maintenance: which document updates on which event; TODOS kept consistent
  with ROADMAP; specs/plans dated and filed; staleness pruned via events, not
  deletions.
- Workspace files are committed to git — shared ground truth deserves
  history. `.anoti/` (session state, queues, logs, trust records) is local
  ephemera, gitignored by bootstrap.

## Memory hierarchy

| Tier                 | Human analog                        | Store                                                  | Lifetime        |
| -------------------- | ----------------------------------- | ------------------------------------------------------ | --------------- |
| Short-term (session) | Working memory                      | Context window + `.anoti/sessions/<session-id>.yaml`   | One session     |
| Project long-term    | Domain knowledge                    | Project workspace: `GROUNDING.yaml` + document system  | Life of project |
| Global long-term     | General knowledge of self and world | `~/.claude/anoti/GROUNDING.yaml` (opt-in; same schema) | Spans projects  |

### Retrieval (split by what each moment can know)

SessionStart fires before any prompt exists, so it cannot judge task
relevance. Retrieval therefore splits:

1. **SessionStart — small fixed digest** (budget ≤ ~1k tokens): store
   summaries (record counts, index only if small), open questions, open
   todos, roadmap phase, pending queue, review nudge (probable count ≥ 5 or
   oldest ≥ 14 days), abandoned-session notices, and — budget-gated —
   a lessons line (count + truncated latest entry), because lessons are
   memory that has not yet graduated into records and otherwise
   surfaced nowhere (amended 2026-08-14).
2. **Attend — topical retrieval:** when the slow path engages, the attend
   skill queries the stores for records relevant to the task (the files stay
   yq/grep-queryable precisely for this) and pulls full entries into the
   frame.
3. **On demand — `/anoti:recall <topic>`:** explicit retrieval anytime.

Cross-tier precedence: a project record conflicting with a global record wins
inside that project; recorded once as a scoped-exception event on the global
record, not re-litigated every session.

### Trust boundary and privacy model

Auto-injected memory is an attack surface and a privacy risk. Mandatory:

- **Untrusted-data envelope:** injected memory is always framed as reference
  data, never instructions.
- **Provenance:** `.anoti/trust` records content hashes of store files this
  user's sessions have written. A store never written by the user's own
  sessions — or changed outside them — is not auto-injected; the hook reports
  its presence and asks before first use. This blocks poisoned-repo
  grounding and repo content poisoning global memory (project sessions
  cannot write the global store without the human approving scope routing).
- **Global memory is opt-in** at first use, per user.
- **Never-store categories** (consolidator hard-filter + review checklist):
  credentials and secrets always; health, legal, and financial details by
  default.
- **User rights:** `/anoti:review` supports viewing, correcting (via
  events), deleting, and exporting global records. The global store file is
  created with `0600` permissions.
- Global records are context, never content: not quoted into work products
  or committed artifacts.

### Session state (short-term memory, made real)

A PreCompact command hook cannot infer semantic state from a transcript. So
the main session maintains structured state _continuously_ — the skills write
it at defined points — and hooks only read/flush it.

`.anoti/sessions/<session-id>.yaml`:

```yaml
session: { id, started, source }
episode: idle | candidate-detected | awaiting-approval | committed # consolidation state machine
attention_frame: # written when attend completes; updated on re-framing
  goal: ...
  success_criteria: [...]
  scope: { in: [...], out: [...] }
  constraints: [...]
  risks: [...]
  open_questions: [...]
  evidence_plan: ... # how this work will know it's right
  roadmap_ref: ... # which ROADMAP item this traces to
hypotheses: [{ id, statement, predicted, observed, verdict }] # deliberate appends
in_flight: [...] # current subtasks / hats out
classifications: [{ ts, verdict: fast|slow, reason }] # attend classifier log
candidates: [{ type, statement, evidence, scope }] # future memory records
```

Update points: attend completion (frame), each hypothesis (deliberate), each
discovery (candidates + episode → `candidate-detected`), consolidation
approval flow (`awaiting-approval` → `committed`). Writes are atomic
(temp + rename). Cleanup: SessionEnd removes the file when the episode is
`idle`/`committed`, else marks it abandoned; abandoned state is _surfaced_
at next SessionStart, never silently re-injected. Resumed/forked sessions
reattach by session id. `.anoti/` is gitignored.

## Agent roster

Model policy: match model to cognitive demand; aliases (`haiku`/`sonnet`/
`inherit`) track model evolution without edits.

**Read-only is enforced by tool allowlists, not intent**, since denying
Write/Edit alone leaves mutating Bash. Each agent's frontmatter carries an
explicit `tools:` list:

| Agent          | Stage          | Model            | Tools                  | Expectation (output contract)                                                                                                                                  |
| -------------- | -------------- | ---------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `consolidator` | Consolidate    | `sonnet`         | Read, Grep, Glob       | Typed candidates (claim/preference/decision/goal/policy) + evidence + suggested status + scope; deduped vs both stores; contradictions flagged, never resolved |
| `explorer`     | Deliberate     | `haiku`          | Read, Grep, Glob       | Synthesized findings relevant to the attention frame, token-capped; conclusions with file references, never raw dumps                                          |
| `skeptic`      | Epistemic      | `inherit`        | Read, Grep, Glob, Bash | Attempts to refute a claim; verdict + evidence; defaults to "not established" when uncertain                                                                   |
| `practitioner` | Deliberate/Act | per role profile | per role profile       | Work per the role's policy stack + definition-of-done; done-claims arrive with evidence artifacts, not assertions                                              |

Known enforcement gap, stated honestly: the skeptic needs Bash to run
refutation tests, which makes its "read-only" advisory; the PreToolUse
decision table and native permissions still gate destructive patterns inside
it. Memory organs (GROUNDING stores, workspace docs, session state) are
writable only by the main session: enforced by a PreToolUse path rule that
denies writes to those paths unless the session state shows the matching
consolidation/skillify flow is active.

Done-claims are checked by the main session against the role's contract
(artifact present, criteria met); roles carrying `adversarial-handoff` also
get a reviewer spawn's verdict. The attend stage is deliberately **not** an
agent: attention needs the full conversation context, which subagents don't
inherit.

**Universal report contract.** Every statement in any agent report is
exactly one of two things: a **cited claim** — carrying `{file, lines}`,
`{url, anchor}`, or `{command, output}` — or a labeled **judgment**, which
may inform human decisions but can never become a GROUNDING claim. An
uncited factual claim gets one cite-or-retract bounce; a second violation
fails the report. Every report ends with a **questions/doubts** section:
the main session promotes surviving items to `open_questions` with
`raised_by`, date, task context, and refs — agents never write the store,
so attribution exists without write clashes (single-writer construction).
Open-question entries carry `{id, date, question, raised_by, context,
status, refs}`; resolution appends events and links the resolving record.

### The practitioner and role profiles

One agent definition wears every hat in the software development process
(human analog: task-set switching; AI mechanic: prompt composition — the
deliberate stage picks a hat per subtask and spawns the practitioner with the
role profile injected alongside the attention frame).

A role profile (`roles/<role>.md`) defines: **lens** (what the role attends to
first), **policy stack** (composition from the policy library), **definition
of done** (the role's verification standard, with required evidence
artifacts), **defaults** (model/effort; deliberate may override), and
**tools/effort** (deliberately deferred per decision D013: the practitioner
inherits session tools; boundary enforcement lives in the inhibition table
and native permissions; per-role allowlists wait for evidence of need).

### The policy library

Policies are modes of operating procedure — and **policies are skills**: each
one is a plugin skill (`skills/policy-<name>/SKILL.md`), invocable via the
Skill tool, so a practitioner _loads_ its policies at spawn rather than
receiving them as pasted prose. Roles compose policies instead of duplicating
procedure text. Policies bind existing machinery (skills, agents, hooks),
never invent new machinery.

Universal (attached to every role): `epistemic` (hypothesis before test;
claims carry evidence; significant claims to the skeptic before asserting),
`trace-to-frame` (untraceable work stops and escalates),
`escalate-destructive` (binds the inhibition decision table). A fourth
universal operates at **session level** rather than per spawn:
`retrospect` — every nontrivial session closes with a cited retrospective
(went well / didn't / skillify / lessons / cannot-be-automated) run inside
consolidation; agent reports feed it, the main session runs it.

Composable: `parallel-breadth` (explorer), `adversarial-handoff` (reviewer
spawn before done), `test-driven`, `visual-verify`, `reversible-change`,
`draft-for-ratification`, `reader-run`. Policy changes propagate to every
declaring role — methodology stays DRY. Adding/amending either is a skillify
maintenance action.

### The role library

**Core v1 (10 roles, fully validated):** `architect`, `frontend`, `backend`,
`database`, `qa`, `reviewer`, `security`, `conductor`, `project-manager`,
`technical-writer`.

**v1.1 (ship after structural validation):** `visionary`, `product-manager`,
`requirements-analyst`, `ux-researcher`, `ui-designer`, `mobile`, `ai-ml`,
`devops`, `performance`, `sales`, `marketing`, `legal`, `support`.

Validation means: every policy reference resolves, the definition-of-done is
testable, and the class field is valid. Twenty-two untested
profiles is a liability, not a library.

| Phase         | Role                   | Lens — attends to first   | Execution approach (policy-stack summary)                                                                  |
| ------------- | ---------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Vision        | `visionary`            | The why and the future    | Narrative-first: target state and the bet; done when direction has falsifiable success metrics             |
| Vision        | `product-manager`      | Value versus cost         | Trade-off-first: impact/effort prioritization, scope cuts, sequencing                                      |
| Discovery     | `requirements-analyst` | What "done" means         | Acceptance-first: intent → testable stories and edge cases                                                 |
| Discovery     | `ux-researcher`        | The user's reality        | Evidence-first: personas, task flows, observation over assumption                                          |
| Design        | `architect`            | Boundaries and trade-offs | Constraint-first: components, interfaces, failure modes before code                                        |
| Design        | `ui-designer`          | Hierarchy and interaction | System-first: tokens, states, consistency; mockups before pixels-in-code                                   |
| Build         | `frontend`             | User-visible states       | Story-down: visible behavior first; verifies by running and looking; loading/error/empty are part of done  |
| Build         | `backend`              | The contract              | Contract-first: interface before implementation, test-driven; error paths and idempotency are part of done |
| Build         | `database`             | Data integrity            | Invariant-first: invariants before change; reversible migrations only; destructive ops escalate            |
| Build         | `mobile`               | Platform constraints      | Platform-first: offline states, app lifecycle, store rules shape the design                                |
| Build         | `ai-ml`                | Measurable behavior       | Eval-first: evaluation defined before touching models or prompts                                           |
| Build         | `devops`               | Reproducibility           | Pipeline-first: environments as code, rollback proven before deploy                                        |
| Quality       | `qa`                   | The risky paths           | Break-first: test pyramid aimed where failure hurts most                                                   |
| Quality       | `reviewer`             | What could break          | Adversarial: tries to break the work, findings with evidence; **never edits**                              |
| Quality       | `security`             | The attack surface        | Threat-model-first: assets, entry points, least privilege; hostile input assumed                           |
| Quality       | `performance`          | The measured baseline     | Measure-first: baseline and budget, then profile, then optimize                                            |
| Delivery      | `project-manager`      | The critical path         | Sequence-first: dependencies, risks, unblocking; keeps TODOS and ROADMAP current and honest                |
| Communication | `technical-writer`     | The newcomer reader       | Reader-first: docs verified by running what they describe                                                  |
| Business      | `sales`                | The objection             | Objection-first: value narrative built by anticipating the "no"                                            |
| Business      | `marketing`            | The audience segment      | Audience-first: messaging per segment, launch sequencing                                                   |
| Business      | `legal`                | Exposure and obligation   | Risk-first: licenses, privacy, terms, compliance; drafts for counsel, never counsel                        |
| Business      | `support`              | The user's friction       | Friction-first: failure modes users actually hit, fed back as requirements                                 |

**Advisory roles** (class: `advisory`, whatever their phase): outputs are
documents and analysis written to `docs/specs/` or `docs/`; never code edits.
Outputs targeting human-owned organs are proposals the human ratifies.

**The product-owner seat is deliberately not a role.** Accepting work on
behalf of stakeholders is understanding, not thinking; it stays with the
human. Any future role whose essence is acceptance authority is rejected on
the same ground.

Rules of the hat system: a hat changes the _approach_, never the _cycle_; one
spawn wears one hat; builder work is judged by a separate reviewer spawn.

**Proportionality (cost governance):** fan-out must be justified by the
attention frame; defaults: ≤ 3 concurrent subagents, ≤ 8 per session, raised
only by explicit human instruction. A one-file fix never convenes a
committee; deliberate states in one line why each spawn earns its cost.

## The cascade (multi-agent deliberation protocol)

Dual-process governs entry: routine work never sees the cascade; it engages
only when attend flags slow-path work **and** deliberation judges it
multi-step. The main session is the only dispatcher and only writer
throughout — the conductor _thinks about_ the cascade; it never runs it.

1. **Frame** — attend produces the attention frame.
2. **Cascade plan** — a practitioner in the `conductor` role receives the
   frame + workspace digest and returns: whether a roadmap is needed and
   whether one exists; the agents required, in order, with what each
   produces/consumes and which steps hit human gates; the unknowns, each
   with an assigned research role; spawn count versus budget. Every factual
   assertion in the plan is cited ("no roadmap exists" cites the check that
   proved it).
3. **Plan ratification** — the main session checks the plan against contract
   and budget; it escalates to the human only when the plan touches
   human-owned organs or exceeds the spawn budget.
4. **Roadmap gate** — needed and missing → visionary or product-manager
   drafts one via `draft-for-ratification` → **blocks for the human**.
5. **Stories** — requirements-analyst decomposes the ratified roadmap phase
   into HIGH-LEVEL-STORIES → **blocks for the human**.
6. **Tasks** — project-manager (sequencing) or architect (technical
   decomposition, as the cascade plan assigns) turns stories into
   TODOS/plan entries — auto-proceeds, trail logged.
7. **Research** — one dispatch per unknown, role assigned by the plan
   (explorer for repo facts, skeptic for claim verification), parallel
   within spawn caps; findings return cited; unknowns that survive research
   are filed to `open_questions`.
8. **Execution & synthesis** — builder roles per task via the existing
   practitioner system; the main session synthesizes; discoveries enter the
   consolidation episode machine.

## Human-absent operation

The human is a structural component, so absence is a defined state, not an
error. In headless contexts (cron, CI, autonomous loops) or on non-response:

- **Escalations queue; work continues where safe.** Goal-ambiguity and
  ratification requests append to `.anoti/pending.md`; the agent proceeds
  only along paths supported by ratified records and the explicit task.
- **Destructive escalations never proceed in absence.** "Nobody answered" is
  not authorization; the action queues.
- **All new knowledge lands unratified** (`ratification: pending`).
- **The queue surfaces at the next interactive SessionStart** — absence
  delays judgment, never deletes it.

## Components

```
anoti/                              # plugin root
├── .claude-plugin/plugin.json      # manifest: name, description, version
├── hooks/hooks.json                # wires the six lifecycle hooks to scripts
├── scripts/                        # executable layer (POSIX sh + yq/jq; no network)
│   ├── retrieve                    #   SessionStart digest builder (trust boundary, budget)
│   ├── classify                    #   UserPromptSubmit attention-tax injection
│   ├── inhibit                     #   PreToolUse decision table (segment-scoped deny rules)
│   ├── persist-session             #   PreCompact state flush
│   ├── consolidation-gate          #   Stop episode-state check
│   ├── cleanup-session             #   SessionEnd scratch lifecycle
│   ├── anoti-dir                   #   state-dir resolution (D016)
│   ├── append-classification  set-episode  append-event  append-record  append-evidence
│   │                               #   mechanical write helpers — the model never hand-serializes YAML
│   ├── trust                       #   provenance hash approval
│   ├── regen-index                 #   rebuild store indexes from records
│   └── validate-workspace          #   schema validation incl. split-scalar detection
├── skills/
│   ├── attend/SKILL.md             # slow-path attention → attention frame (story_ref + roadmap_ref)
│   ├── deliberate/SKILL.md         # WM discipline, cascade, hat assignment, lifetime rule, D011 fix rounds
│   ├── consolidate/SKILL.md        # record typing, scope routing, helpers-only writes, retrospective
│   ├── skillify/SKILL.md           # workspace bootstrap + maintenance contract
│   ├── spec/  plan/  direction/    # document-format standards (specs, plans, direction organs)
│   │                               # …and policies ARE skills — invocable via the Skill tool:
│   ├── policy-epistemic/  policy-trace-to-frame/  policy-escalate-destructive/  policy-retrospect/  (universal)
│   ├── policy-parallel-breadth/  policy-adversarial-handoff/  policy-test-driven/
│   └── policy-visual-verify/  policy-reversible-change/  policy-draft-for-ratification/  policy-reader-run/
├── agents/
│   ├── consolidator.md             # sonnet; tools: Read, Grep, Glob
│   ├── explorer.md                 # haiku; tools: Read, Grep, Glob
│   ├── skeptic.md                  # inherit; tools: Read, Grep, Glob, Bash (see enforcement gap)
│   └── practitioner.md             # model/tools per role profile
├── roles/                          # one file per role; 23-role library (conductor-led)
├── commands/
│   ├── review.md                   # /anoti:review — ratification + promotion/demotion with evidence
│   ├── recall.md                   # /anoti:recall <topic> — on-demand retrieval
│   ├── consolidate.md              # /anoti:consolidate — manual consolidation fallback
│   ├── new.md                      # /anoti:new — workspace bootstrap wizard (skillify)
│   ├── implement.md                # /anoti:implement — feature workflow with mandatory spec gate
│   ├── review-work.md              # /anoti:review-work — pre-ship review (evidence contract, cycle cap)
│   └── update.md                   # /anoti:update — migration by ratified diff
├── benchmark/                      # H1-H3 harness + Q001 materials (see experiment specs)
└── templates/                      # GROUNDING.yaml (v3 record model), ROADMAP.md, HIGH-LEVEL-STORIES.md,
                                    # TODOS.md, LESSONS-LEARNT.md, gitignore fragment
```

### Hook specifications

All hooks are **command** hooks (SessionStart and PreCompact support no other
kind; consistency elsewhere keeps the runtime uniform). Runtime: POSIX shell +
`yq`/`jq`; no network access; every script honors its timeout and **fails
open** — on error it emits a one-line stderr report and exits 0 with no
decision/context.

| #   | Event            | Script                 | Timeout | Reads                                                                           | Writes                     | Output (JSON)                                         |
| --- | ---------------- | ---------------------- | ------- | ------------------------------------------------------------------------------- | -------------------------- | ----------------------------------------------------- |
| 1   | SessionStart     | `retrieve`             | 10s     | trust file, global+project stores, TODOS, ROADMAP, pending queue, session files | `.anoti/trust` (first-use) | `additionalContext`: digest in untrusted envelope     |
| 2   | UserPromptSubmit | (inline in hooks.json) | 5s      | —                                                                               | —                          | `additionalContext`: ≤ 10-line classifier instruction |
| 3   | PreToolUse       | `inhibit`              | 5s      | tool_input, session state (episode/frame)                                       | —                          | `permissionDecision`: allow/ask/deny + reason         |
| 4   | PreCompact       | `persist-session`      | 5s      | session state file                                                              | session state file (flush) | none (side effect only)                               |
| 5   | Stop             | `consolidation-gate`   | 5s      | session state (episode)                                                         | session state (episode)    | continue or block-with-reason (once per episode)      |
| 6   | SessionEnd       | `cleanup-session`      | 5s      | session state                                                                   | removes/marks session file | none                                                  |

**Stop semantics, corrected:** Stop fires whenever the main agent finishes a
response — not when the user exits — and does not fire on interruption. The
gate therefore runs a per-episode state machine (in session state):
`idle → candidate-detected → awaiting-approval → committed`. It blocks-with-
reason exactly once, when episode is `candidate-detected` (guarded by
`stop_hook_active`); at `idle` or `committed` it passes silently. New
discoveries after a committed episode open a new episode. Interrupted or
abandoned sessions are caught by SessionEnd/next SessionStart surfacing, and
`/anoti:consolidate` is always available manually.

**Inhibition decision table** (`inhibit`):

| Condition                                                        | Decision                |
| ---------------------------------------------------------------- | ----------------------- |
| Not matched by any pattern                                       | allow (no decision)     |
| Consequential pattern, traced to frame, non-destructive          | allow + reason logged   |
| Consequential pattern, untraced or uncertain                     | **ask** (human decides) |
| Memory-organ write outside an active consolidation/skillify flow | **deny** + reason       |
| Explicit catastrophic list (below)                               | **deny**                |
| Hook error                                                       | fail open + report      |

Catastrophic deny-list (complete, versioned in the script, not extensible at
runtime): `rm -rf` targeting `/`, `~`, or the repo root; force-push to the
default branch; `git reset --hard` + `push` to shared branches; `DROP
DATABASE` / `TRUNCATE` against non-local connection strings. This is a
guardrail, not a security boundary — native permission rules remain the
enforcement layer.

## Failure behavior

- Every hook fails open; any error degrades the session to vanilla Claude
  Code plus a one-line report.
- Consolidator failure → session ends normally; candidates wait in session
  state for `/anoti:consolidate` or the next episode.
- Invalid store files are quarantined and reported, never auto-repaired.
- Stale/abandoned session state is surfaced, never silently re-injected.
- The deny-list is explicit and versioned; everything else defers to native
  permissions.

## Testing

- **Structural:** plugin-validator on manifest/layout; `validate-workspace`
  on templates; every role profile validated (policy refs resolve, done
  criteria testable, class valid — tools/effort deferred per D013); every script exercised with
  synthetic hook-input JSON fixtures.
- **State-machine fixtures:** status transitions (promotion, demotion,
  grandfathering, contradiction, scoped exception) tested against controlled
  store fixtures — promotion is _not_ a launch requirement, so it cannot be
  manufactured.
- **Behavioral (dogfood):** trivial prompt → zero visible overhead (hard
  requirement); ambiguous prompt → attend + frame; matched destructive
  command → correct table row (allow/ask/deny); discovery session →
  episode reaches `awaiting-approval` exactly once; no-discovery session →
  silent close; skillify bootstrap → valid workspace, idempotent re-run;
  compaction mid-task → frame survives; global claim from project A →
  digest in project B; poisoned foreign GROUNDING → not injected, reported;
  headless session → queue grows, nothing blocks, destructive actions
  deferred; concurrent sessions → no state collision; reviewer role → zero
  file modifications.
- **Comparative (H1–H3):** scripted week of tasks run with and without the
  plugin, measuring contradiction rate, successful-recall rate, bad-memory
  rate (acting on wrong/stale records), unnecessary interruptions, added
  session-start latency, and token overhead. The plugin justifies itself
  with evidence or not at all.

## Out of scope (v1)

- Cross-agent portability (Codex etc.) — Claude Code only.
- Automatic memory decay/archival beyond `reverify_after_days` + staleness
  events.
- Team-shared or synced memory (multi-user); global memory is per-user.
- Any UI beyond Claude Code's own surfaces.
- v1.1 role set (ships only after structural validation).

## Success criteria

1. All behavioral tests pass; all state-machine fixtures pass.
2. Comparative run shows measurable benefit over vanilla Claude Code on at
   least: contradiction rate, successful recall, and bad-memory rate — within
   acceptable latency (< 2s added at SessionStart) and token overhead
   (digest ≤ ~1k tokens; attention tax ≤ 10 lines/prompt).
3. Status-transition correctness demonstrated on fixtures (not on
   manufactured live promotions).
4. No session is ever blocked by a plugin failure.
5. The workspace remains fully usable plain files if the plugin is removed.

## Changelog

- 2026-08-13 — Q002 ruling: advisory-roles wording changed from a phase
  list to class-based (`class: advisory`, whatever the phase).
- 2026-08-13 — Q003 ruling: per-role tools/effort fields deliberately
  deferred (decision D013); validation criterion reworded accordingly.
- 2026-08-13 — D016: project state dir configurable (ANOTI_DIR >
  .claude/anoti.local.md state_dir > default .anoti), always
  project-relative; global tier unaffected. Frame gains story_ref; the
  retrieval digest surfaces HIGH-LEVEL-STORIES as the value standard.
- 2026-08-13 — Component tree refreshed to 0.4.0 reality (15 scripts incl. mechanical helpers, document-format skills, retrospect policy, seven commands, benchmark dir); requirements-analyst wired to the direction skill.
