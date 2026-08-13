# anoti — Design Spec

**Date:** 2026-08-12
**Status:** Approved in brainstorming; pending user review of this document
**Grounding:** Discoveries D001–D004 and open question Q001 in `GROUNDING.yaml`

## What this is

A Claude Code plugin that gives AI agents a human-shaped cognitive work cycle —
retrieve, attend, deliberate, act/inhibit, consolidate — implemented with
AI-native mechanics (context injection, skills, subagents, hooks), with the
human as a structural component of the architecture supplying what agents lack
per D003: goals, values, and deciding what is worth remembering. Knowledge
shared between human and agent is governed by scientific methodology: claims,
evidence, falsifiability, and evidence-driven status transitions.

## Why

- Agents start every session from zero and re-derive or contradict established
  facts (no long-term memory, D002).
- Instructions alone don't reliably shape agent behavior; priors dominate
  (D004). Structure (hooks) is needed at the points where agent design is
  missing an organ.
- Human and AI cognition diverge (D003); a shared epistemic protocol —
  scientific method — is required for the two to converge on truth rather than
  defer to each other.

## Design principles

1. **Dual-process, not rituals.** Every hook is a classifier with a fast path.
   Structure is always present (hooks always run); processing depth is
   proportional to novelty/ambiguity/consequence. Trivial prompts must incur
   zero visible overhead.
2. **Never fight the model's design.** Hooks compensate only for structural
   gaps (memory in/out, inhibition on risk); skills guide everything the model
   can already do well in-context.
3. **Human as component, not supervisor.** The human occupies defined roles in
   the cycle: goal disambiguation (attend), value judgment on consequential
   actions (inhibit), salience filter on memory (consolidate/review).
4. **Evidence over authority.** No claim is established without evidence; no
   contradiction is resolved by rank. Demotion is as legitimate as promotion.
5. **Degrade toward vanilla Claude Code, never toward blockage.** All hooks
   fail open. The only hard-block is catastrophic destructive patterns.

## The cognitive cycle

| Stage            | Human analog (D001)           | Implementation (D002-native)                                                                                                    | Human role (D003 gaps)                              |
| ---------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| 1. Retrieve      | Top-down priors from LTM      | SessionStart hook injects GROUNDING index + established claims + open questions                                                 | — (automatic)                                       |
| 2. Attend        | Attention bottleneck          | UserPromptSubmit classifier: routine → silent pass; novel/ambiguous/consequential → `attend` skill produces an attention frame  | Goal ambiguities escalated as questions             |
| 3. Deliberate    | Working-memory manipulation   | `deliberate` skill: hypothesis-before-test, subagents for parallel breadth, synthesis over accumulation                         | —                                                   |
| 4. Act + Inhibit | Selective response inhibition | PreToolUse hook, narrow matcher (destructive bash, deploy/publish, GROUNDING writes): "does this trace to the attention frame?" | Value judgment on escalated actions                 |
| 5. Consolidate   | Memory consolidation (sleep)  | Stop hook gate → consolidator subagent proposes claims; approved appends land as `status: probable`                             | Promotion to `established` via `/anoti:review` only |

## The epistemic engine

GROUNDING.yaml (schema v2, extended) operates as a scientific process:

- **Claims, not notes.** Every discovery is stated falsifiably. The
  consolidator must reject non-falsifiable candidates.
- **Evidence-driven status ladder.** `speculative` (no evidence) → `probable`
  (some evidence) → `established` (tested or independently confirmed). Schema
  gains an `evidence:` list per discovery: dated observations, experiments,
  sources. Demotion on contradicting evidence is symmetric and expected.
- **Open questions are the research agenda.** The attend stage checks whether
  the current task can cheaply generate evidence for an open question and says
  so (opportunistic experimentation).
- **Contradiction protocol.** New work contradicting an established claim never
  overwrites it: record a `contradicts` relationship, spawn an open question
  with a verification method, resolve by evidence.
- **Hypothesis before test.** In deliberation, predictions are stated before
  experiments run — for debugging, design choices, and benchmarks alike.

## The externalized workspace

The plugin scaffolds and maintains a document system in every project it is
installed into. These files are not paperwork: each one is an externalized
cognitive organ of the human+AI pair — durable where both human working memory
and agent context windows are volatile. The plugin's hooks and skills read and
write them; the human owns their direction.

| Artifact                | Cognitive organ                                | Owned by | Touched by                                            |
| ----------------------- | ---------------------------------------------- | -------- | ----------------------------------------------------- |
| `GROUNDING.yaml`        | Semantic memory — what is true                 | shared   | retrieve (read), consolidate (write), review          |
| `ROADMAP.md`            | Goal hierarchy — where we are going            | human    | attend traces work to it; human edits direction       |
| `HIGH-LEVEL-STORIES.md` | Values/perspective — what "good" means         | human    | attend + inhibit reference it as the value standard   |
| `TODOS.md`              | Prospective memory — open intentions           | shared   | retrieve (surface), deliberate + consolidate (update) |
| `LESSONS-LEARNT.md`     | Procedural memory — how we work                | shared   | consolidate writes process lessons here               |
| `specs/`                | Deliberation artifacts — designs as hypotheses | shared   | deliberate writes; one dated file per design          |
| `plans/`                | Deliberation artifacts — protocols             | shared   | deliberate writes; one plan per implementation        |

Division of memory: GROUNDING holds falsifiable claims about the world
(semantic); LESSONS-LEARNT holds process lessons about how to work
(procedural). A lesson that becomes falsifiable and gathers evidence graduates
into a GROUNDING claim.

The **`skillify` skill** is the organ-maintenance function: invoked to
bootstrap the workspace in a fresh project (create all artifacts from
templates, wire CLAUDE.md) and to maintain it afterward — which document
updates on which event, keeping TODOS consistent with ROADMAP, dating and
filing specs/plans, and pruning staleness.

## Memory hierarchy

Three tiers, mirroring human memory scopes; all long-term stores share the
GROUNDING schema:

| Tier                 | Human analog                        | Store                                                                                                                       | Lifetime        |
| -------------------- | ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | --------------- |
| Short-term (session) | Working memory                      | Context window + `.anoti/session.md` (attention frame, active hypotheses, in-flight state)                                  | One session     |
| Project long-term    | Domain knowledge                    | Project workspace: `GROUNDING.yaml` + the document system above                                                             | Life of project |
| Global long-term     | General knowledge of self and world | `~/.claude/anoti/GROUNDING.yaml`: claims about the user, their preferences, and cross-project lessons about how agents work | Spans projects  |

- **Retrieval order** (SessionStart): global first (who am I working with),
  then project (what do we know here), then session scratch on resume (what
  was I doing). Inject digests — indexes, established claims, open questions,
  open todos — never full files.
- **Scope routing** (consolidation): each approved claim is routed by scope —
  about-this-project → project store; about-the-user or about-how-agents-work
  → global store. The human confirms routing; misfiled memory is worse than no
  memory.
- **Compaction survival:** a PreCompact hook persists the session's short-term
  state to `.anoti/session.md` so context compaction cannot lobotomize an
  in-flight task; SessionStart re-injects it on resume.

## Agent roster

Model policy: match the model to the cognitive demand of the stage; use
aliases (`haiku`/`sonnet`/`inherit`) so the plugin tracks model evolution
without edits. Agents divide into two classes. **Memory-facing agents**
(consolidator, explorer, skeptic) are strictly read-only — they analyze and
propose; only the main session mutates state. **The work-facing agent**
(practitioner) writes work products (code, configs, docs under construction)
but never memory organs — GROUNDING, the workspace documents, and session
state remain main-session-only for every agent, always. Each agent's
definition states its expectation as an output contract, checked by the main
session before use.

| Agent          | Stage          | Model                     | Expectation (output contract)                                                                                                                  |
| -------------- | -------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `consolidator` | Consolidate    | `sonnet`                  | Falsifiable claims + evidence + suggested status + scope (project/global); deduped against both stores; contradictions flagged, never resolved |
| `explorer`     | Deliberate     | `haiku`                   | Synthesized findings relevant to the attention frame, token-capped; conclusions with file references, never raw dumps                          |
| `skeptic`      | Epistemic      | `inherit` (session model) | Attempts to refute a claim; verdict + evidence; defaults to "not established" when uncertain                                                   |
| `practitioner` | Deliberate/Act | per role profile          | Work executed per the assigned role's approach and definition-of-done, verified before return; reviewer role returns findings only, no edits   |

The attend stage is deliberately **not** an agent: attention needs the full
conversation context, which subagents don't inherit. It stays a skill in the
main loop.

### The practitioner and role profiles

One agent definition wears every engineering hat. The human analog is task-set
switching: a person is one cognitive architecture that loads different
professional schemas — the same mind thinks _as_ a reviewer differently than
it thinks _as_ a builder. The AI-native mechanic is prompt composition: the
deliberate stage decomposes work, picks a hat per subtask, and spawns the
practitioner with the matching **role profile** injected alongside the
attention frame.

A role profile (one markdown file per role in `roles/`) defines four things:

1. **Lens** — what this role attends to first (frontend: user-visible states;
   database: data integrity; reviewer: what could break).
2. **Execution approach** — how this role works, and these genuinely differ:
   - _frontend_: story-down — start from the user-visible behavior; verify by
     running the app and looking; loading/error/empty states are part of done.
   - _backend_: contract-first — define the interface before implementing;
     test-driven; error paths and idempotency are part of done.
   - _database_: invariant-first — state data-integrity invariants before any
     change; schema changes only as reversible migrations; destructive
     operations always escalate (the inhibition hook applies inside subagents
     too).
   - _reviewer_: adversarial — try to break the work; report findings with
     evidence; **never edits** (the hat that judges must not hold the pen).
3. **Definition of done** — the role-specific verification standard the
   practitioner must satisfy before returning.
4. **Defaults** — suggested model/effort for the role (deliberate may override
   per task complexity).

Rules of the hat system: a hat changes the _approach_, never the _cycle_ —
every role still states hypotheses before tests and traces work to the
attention frame. One practitioner instance wears one hat; a subtask needing
two hats is two spawns (builder's work can then be judged by a reviewer spawn
with clean separation). Adding a role to the library is a `skillify`
maintenance action — a new profile file, never a new agent.

## Components

```
anoti/                              # plugin root
├── .claude-plugin/plugin.json      # manifest: name, description, version
├── hooks/hooks.json                # wires the five lifecycle hooks
├── skills/
│   ├── attend/SKILL.md             # slow-path attention → attention frame
│   ├── deliberate/SKILL.md         # WM discipline, hypothesis-before-test, parallelism, hat assignment
│   ├── consolidate/SKILL.md        # memory-write protocol (claim shape, dedupe, scope routing, append mechanics)
│   └── skillify/SKILL.md           # workspace bootstrap + maintenance rules
├── agents/
│   ├── consolidator.md             # sonnet, read-only: session review → claims + evidence + scope
│   ├── explorer.md                 # haiku, read-only: parallel breadth for deliberation
│   ├── skeptic.md                  # inherit, read-only: adversarial claim verification
│   └── practitioner.md             # model per role: one worker, parameterized by role profile
├── roles/                          # role profiles for the practitioner (lens, approach,
│   ├── frontend.md                 # definition-of-done, defaults); extensible via skillify
│   ├── backend.md
│   ├── database.md
│   └── reviewer.md
├── commands/review.md              # /anoti:review — promotion/demotion ritual with evidence displayed
└── templates/                      # GROUNDING.yaml (schema v2 + evidence:), ROADMAP.md,
                                    # HIGH-LEVEL-STORIES.md, TODOS.md, LESSONS-LEARNT.md, specs/, plans/
```

### Hook specifications

1. **SessionStart (Retrieve).** Reads the memory tiers in order — global
   grounding, project grounding, open TODOS, current ROADMAP phase, and (on
   resume) `.anoti/session.md` — and injects digests as context. Missing
   workspace → inject a one-line offer to bootstrap via `skillify`. Malformed
   YAML → report and skip; never crash. Replaces the manual CLAUDE.md pointer
   convention.
2. **UserPromptSubmit (Attend classifier).** Injects a small instruction (a few
   lines; it runs on every prompt so its token cost is the permanent
   "attention tax"): classify the prompt — routine → proceed; novel, ambiguous,
   or consequential → invoke `attend` first.
3. **PreToolUse (Inhibition).** Matcher limited to: destructive bash
   (`rm -rf`, force-push, drop/truncate), deploy/publish commands, and writes
   to `GROUNDING.yaml`. Injects a trace-to-frame check and escalates to the
   human when uncertain. Warns rather than blocks, except catastrophic
   patterns (`rm -rf /`-class), which hard-block.
4. **PreCompact (Working-memory persistence).** Before context compaction,
   persists the session's short-term state — attention frame, active
   hypotheses, in-flight work — to `.anoti/session.md` so compaction cannot
   lobotomize the task. SessionStart re-injects it on resume.
5. **Stop (Consolidation gate).** Asks once per session (stop-loop guarded):
   any unrecorded discoveries? No → silent pass. Yes → run the consolidator,
   present its proposals (with scope routing: project vs global) to the human;
   candidates the human okays are appended by the main session as `probable`.
   Consolidation also updates TODOS (done/new items) and LESSONS-LEARNT
   (process lessons). Status stays `probable` regardless — promotion to
   `established` happens only later, in `/anoti:review`, with evidence
   displayed.

### Component boundaries

- The consolidator subagent is **read-only**: it analyzes and proposes; the
  main session writes. The thing that analyzes memory never mutates it.
- Skills contain all methodology prose; hooks contain only classification and
  wiring. Changing the methodology means editing skills, not hook logic.
- GROUNDING.yaml remains a plain, tool-queryable file (yq/grep verified);
  the plugin depends on its schema, not vice versa.

## Failure behavior

- All hooks fail open; any hook error degrades the session to vanilla Claude
  Code behavior plus a visible one-line report.
- Consolidator failure → session ends normally; discoveries wait for the next
  session or manual `/anoti:review`.
- Stop gate fires at most once per session (loop guard).
- Hard-block list is explicit, short, and reviewed as part of the spec — not
  extensible at runtime.

## Testing

- **Structural:** plugin-validator agent on manifest/layout; hook configs
  exercised with synthetic transcripts.
- **Behavioral (dogfood on anoti itself):**
  - trivial prompt → zero visible overhead (hard requirement);
  - ambiguous prompt → attend engages, attention frame produced;
  - matched destructive command → inhibition fires exactly once;
  - session with a genuine discovery → consolidation proposal appears;
  - session without discoveries → silent close;
  - `skillify` bootstraps a fresh project → full workspace passes structural
    validation;
  - compaction mid-task → attention frame and in-flight state survive via
    `.anoti/session.md`;
  - claim routed to global memory in one project → surfaces at SessionStart in
    a different project;
  - practitioner in reviewer role → findings with evidence, zero file
    modifications;
  - practitioner in a builder role → work satisfies that role's
    definition-of-done before returning.
- **Epistemic:** Q001 (format-comprehension experiment) is the first
  registered experiment run under the methodology; behavioral test results are
  recorded in GROUNDING as evidence for claims about the plugin itself.

## Out of scope (v1)

- Cross-agent portability (Codex etc.) — Claude Code only, per deliverable
  decision.
- Automatic memory decay/archival beyond the existing `reverify_after_days`.
- Team-shared or synced memory (multi-user); global memory is per-user.
- Any UI beyond Claude Code's own surfaces.

## Success criteria

1. All ten behavioral tests pass.
2. GROUNDING.yaml in a dogfooded project accumulates claims with evidence, and
   at least one claim traverses the full ladder (speculative → established) or
   is demoted by evidence during initial dogfooding on this project.
3. The attention tax stays under ~10 lines of injected context per prompt.
4. No session is ever blocked by a plugin failure.
