---
name: plan
description: anoti plan standard — the required shape for implementation plans and cascade plans filed to docs/plans/. Invoke before writing either; execution quality is capped by plan quality.
---

# Plan

Where: `docs/plans/YYYY-MM-DD-<topic>.md` (implementation) or
`docs/plans/YYYY-MM-DD-<topic>-cascade.md` (ratified cascade plans, per
the deliberate skill's lifetime rule: durable work files its plan before
dispatch; ephemeral work stays in session state).

## Implementation plan — required sections

1. **Goal** — one sentence: what exists when this is done.
2. **Architecture** — 2–3 sentences on approach; the tech stack with
   version constraints.
3. **Global constraints** — project-wide requirements copied verbatim
   from the spec, one line each; every task implicitly includes them.
4. **File structure** — which files created/modified, each with one
   responsibility, before any task is defined.
5. **Tasks** — smallest units carrying their own test cycle. Each task:
   files touched, interfaces consumed/produced (exact names and
   signatures — a later task's implementer learns them only here), and
   TDD steps: failing test (shown, not described) → run to confirm RED →
   minimal implementation → run to confirm GREEN → commit with the exact
   message.

## Cascade plan — required fields

Roadmap needed/exists (cited); agent sequence with produces/consumes and
which steps hit human gates; unknowns, each with an assigned research
role; spawn arithmetic against the budget (≤3 concurrent, ≤8/session)
with one-line justification per spawn; conditional branches named in
advance so mid-flight judgment executes the plan instead of improvising.

## Rules

- **No placeholder** content: "TBD", "similar to task N", "add error
  handling", steps that describe without showing — plan failures, all.
- Assume the executor has zero context and questionable taste: exact
  values, exact commands, expected outputs.
- Self-review against the spec before filing: every requirement maps to
  a task; types and names consistent across tasks; fix inline.
- Plans of consequence get adversarial review before execution begins.
