---
name: deliberate
description: anoti working-memory discipline — hypothesis-before-test, hat assignment, bounded parallelism, and the multi-agent cascade for multi-step work. Invoke after attend produces a frame.
---

# Deliberate

Working memory, run with discipline. Requires an attention frame (run
attend first).

## Core discipline

- **Hypothesis before test:** state the prediction before every experiment,
  probe, or benchmark. Predictions made after results are worthless.
- **Synthesis over accumulation:** fold findings into the frame as
  conclusions with citations; never let raw output pile up in context.
- **Hat assignment:** each subtask gets exactly one role from `roles/`
  (the legal names are enumerated in the practitioner agent's
  description, visible at dispatch; a role's `policies:` list uses bare
  names that resolve to `skills/policy-<name>/`);
  spawn the practitioner with the role profile + the attention frame
  injected. One spawn, one hat; builder work judged by a separate
  reviewer spawn (policy-adversarial-handoff).
- **Spawn budget:** ≤ 3 concurrent subagents, ≤ 8 per session, raised only
  by explicit human instruction. Every spawn carries a one-line
  justification against the frame. Parallelism buys breadth, never
  coherence: synthesis over many items (clustering findings, holding one
  structure in mind) is a single-context job — the entry test routes it
  there, and that is the design working. A one-file fix never convenes a
  committee.

## The cascade (multi-step, multi-agent work)

Entry test: slow-path work AND genuinely multi-step. Single-role tasks skip
the cascade entirely. The main session is the only dispatcher and only
writer throughout.

1. **Frame** — from attend.
2. **Cascade plan** — spawn the practitioner in the `conductor` role with
   frame + workspace digest. It returns a cited plan: roadmap
   needed/exists, agent sequence (produces/consumes/gates), unknowns each
   with an assigned research role, spawn count vs budget.
3. **Plan ratification** — check the plan against contract and budget.
   Escalate to the human ONLY if it touches human-owned organs or exceeds
   the spawn budget; otherwise proceed.
4. **Roadmap gate** — roadmap needed and missing → visionary or
   product-manager drafts via policy-draft-for-ratification → **blocks for
   the human**.
5. **Stories** — requirements-analyst decomposes the ratified roadmap
   phase into HIGH-LEVEL-STORIES drafts → **blocks for the human**.
6. **Tasks** — project-manager (sequencing) or architect (technical
   decomposition, as the plan assigns) turns stories into TODOS/plan
   entries — auto-proceeds, trail logged.
7. **Research** — one dispatch per unknown: explorer for repo facts,
   skeptic for claim verification; parallel within the budget; findings
   return cited; unknowns that survive are filed to open_questions by the
   main session.
8. **Execution & synthesis** — builder roles per task, version control
   per the **git skill** (branching, worktrees for parallel workstreams,
   explicit staging, human-gated integration); ready-for-review opens a
   review-debt row (policy-adversarial-handoff) that the reviewer's
   verdict closes; the main session synthesizes; discoveries enter the
   consolidation episode machine (episode → candidate-detected in
   session state).

Record each hypothesis and each spawn mechanically as you go —
`scripts/session-append <session-id> hypotheses < h.json` and
`scripts/session-append <session-id> in_flight < s.json` — short-term
memory that survives compaction is written state, not context, and
session YAML is never hand-edited.

## Plan persistence (the lifetime rule)

A plan's lifetime matches its artifacts' lifetime:

- Work producing **durable artifacts** (anything committed to the repo):
  persist the ratified cascade plan to
  `docs/plans/YYYY-MM-DD-<topic>-cascade.md` before dispatching, in the
  format the plan skill defines (load `skills/plan/SKILL.md`). The
  session-state copy is the working copy; the file is the record —
  session state is deleted on clean exit, and a ratified plan must not
  evaporate with it.
- **Ephemeral work** (scratch dirs, throwaway demos): session-state-only
  is sufficient; filing would be noise.

The same rule governs minimal specs: a contract embedded in the artifact
itself (module docstring, interface file) is an acceptable spec-of-record
when the cascade plan cites it; anything larger files to `docs/specs/`.

## Fix rounds (ratified decision D011)

When a review returns findings, **resume the original builder** — its
context holds the task, the code, and its own choices; a fresh spawn
rebuilds all three at full cost. Relay the findings **verbatim**: a
builder asked to fix findings it was never shown will rightly refuse.
Advisory or trial work running parallel to a fix isolates against a
**pre-fix snapshot** of the artifact, so its observations stay
reproducible and are not contaminated by the fix landing mid-analysis.
