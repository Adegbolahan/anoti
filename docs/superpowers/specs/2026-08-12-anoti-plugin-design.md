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

## Components

```
anoti/                              # plugin root
├── .claude-plugin/plugin.json      # manifest: name, description, version
├── hooks/hooks.json                # wires the four lifecycle hooks
├── skills/
│   ├── attend/SKILL.md             # slow-path attention → attention frame
│   ├── deliberate/SKILL.md         # WM discipline, hypothesis-before-test, parallelism
│   └── consolidate/SKILL.md        # memory-write protocol (claim shape, dedupe, append mechanics)
├── agents/consolidator.md          # read-only session reviewer; proposes claims + evidence + status
├── commands/review.md              # /anoti:review — promotion/demotion ritual with evidence displayed
└── templates/GROUNDING.yaml        # schema-v2 template (with evidence: field) for bootstrapping
```

### Hook specifications

1. **SessionStart (Retrieve).** Reads project `GROUNDING.yaml`; injects index,
   established claims, and open questions as context. Missing file → inject a
   one-line offer to bootstrap from template. Malformed YAML → report and skip;
   never crash. Replaces the manual CLAUDE.md pointer convention.
2. **UserPromptSubmit (Attend classifier).** Injects a small instruction (a few
   lines; it runs on every prompt so its token cost is the permanent
   "attention tax"): classify the prompt — routine → proceed; novel, ambiguous,
   or consequential → invoke `attend` first.
3. **PreToolUse (Inhibition).** Matcher limited to: destructive bash
   (`rm -rf`, force-push, drop/truncate), deploy/publish commands, and writes
   to `GROUNDING.yaml`. Injects a trace-to-frame check and escalates to the
   human when uncertain. Warns rather than blocks, except catastrophic
   patterns (`rm -rf /`-class), which hard-block.
4. **Stop (Consolidation gate).** Asks once per session (stop-loop guarded):
   any unrecorded discoveries? No → silent pass. Yes → run the consolidator,
   present its proposals to the human; candidates the human okays are appended
   by the main session as `probable`. Status stays `probable` regardless —
   promotion to `established` happens only later, in `/anoti:review`, with
   evidence displayed.

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
  - session without discoveries → silent close.
- **Epistemic:** Q001 (format-comprehension experiment) is the first
  registered experiment run under the methodology; behavioral test results are
  recorded in GROUNDING as evidence for claims about the plugin itself.

## Out of scope (v1)

- Cross-agent portability (Codex etc.) — Claude Code only, per deliverable
  decision.
- Automatic memory decay/archival beyond the existing `reverify_after_days`.
- Multi-project shared grounding; each project has its own GROUNDING.yaml.
- Any UI beyond Claude Code's own surfaces.

## Success criteria

1. All five behavioral tests pass.
2. GROUNDING.yaml in a dogfooded project accumulates claims with evidence, and
   at least one claim traverses the full ladder (speculative → established) or
   is demoted by evidence during initial dogfooding on this project.
3. The attention tax stays under ~10 lines of injected context per prompt.
4. No session is ever blocked by a plugin failure.
