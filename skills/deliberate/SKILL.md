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
- **Hat assignment:** each subtask gets exactly one role from `roles/`;
  spawn the practitioner with the role profile + the attention frame
  injected. One spawn, one hat; builder work judged by a separate
  reviewer spawn (policy-adversarial-handoff).
- **Spawn budget:** ≤ 3 concurrent subagents, ≤ 8 per session, raised only
  by explicit human instruction. Every spawn carries a one-line
  justification against the frame. A one-file fix never convenes a
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
8. **Execution & synthesis** — builder roles per task; the main session
   synthesizes; discoveries enter the consolidation episode machine
   (episode → candidate-detected in session state).

Record each hypothesis under `hypotheses` and each spawn under `in_flight`
in session state as you go — short-term memory that survives compaction is
written state, not context.
