---
name: spec
description: anoti spec standard — the required shape for design specs and experiment specs filed to docs/specs/. Invoke before writing either; the format is the contract.
---

# Spec

Where — two naming families, one rule:

- **Standalone documents** (project designs, experiments): date-first —
  `docs/specs/YYYY-MM-DD-<topic>-design.md` /
  `docs/specs/YYYY-MM-DD-exp-<topic>.md` — a chronological register.
  `docs/specs/` is the default home; a workspace that adopted an
  existing organ records it as `spec_dir:` in `.claude/anoti.local.md`
  and that mapping wins (issue #16).
- **Story-scoped specs**: story-first — `docs/specs/us-XXX-<name>.md` —
  the US-id is the stable key so a story's spec, plan, and reviews sort
  together; the date lives inside the document and in git.

One file per spec; amendments after acceptance get dated changelog
entries, not silent edits.

## Design spec — required sections

1. **What this is** — one paragraph; the differentiation stated plainly.
2. **Why** — motivations as claims or hypotheses, cited; never overstate
   what grounding records establish.
3. **Design principles / constraints** — the rules that bind every later
   choice, with exact values.
4. **The design** — components with one responsibility each, interfaces,
   data flow. Every "same as X" relationship stated explicitly.
5. **Failure behavior** — what degrades, toward what, and what never
   breaks.
6. **Testing** — how each requirement will be verified; behavioral
   requirements get observable pass conditions.
7. **Out of scope** — named exclusions, so absence reads as decision.
8. **Success criteria** — measurable, checkable when the work claims done.
9. **Execution routing** — name who performs the work this spec
   defines, one line of why per assignment:
   - **plan owner**: the role that decomposes this spec into the plan —
     architect for technical decomposition, project-manager for
     sequencing (the plan skill then requires an owner-role per task);
   - **builder hats**: one role per component, from the roles register;
   - **skills each hat loads**: test-driven, git, direction, benchmark
     harness — whatever the work touches.
   How to choose: read the roles register (`roles/` — one file per hat,
   each states what it owns) and `docs/SKILL-MAP.md` (every skill's
   inbound paths) — **both live in the plugin root, not the governed
   project**: resolve them from the newest installed plugin root when
   there is no local copy. A project with its own agent register may
   route from that instead, flagging the substitution inline. Pick the
   narrowest hat that owns the component.
   The spec suggests; the deliberate skill assigns — but a spec that
   names no route leaves every implementer guessing.

## Experiment spec — required sections (pre-registration discipline)

1. **Status: DESIGN, pre-registered** — metrics and decision rules frozen
   before any run; post-hoc changes get dated changelog entries and
   invalidate cross-run comparison.
2. **Claims under test** — which records/hypotheses, by id.
3. **Method** — arms, fixtures, ground truth (planted answer key where
   possible), human-interaction protocol stated honestly.
4. **Metrics** — table: definition + source, mechanical where possible.
5. **Decision rules** — outcome → ladder movement, both directions
   honored; ambiguity handling named in advance.
6. **Cost estimate** — tokens and human time, honest.
7. **Results** — empty at filing, by construction; raw outputs filed
   under `docs/trials/` with the spec's date prefix.
8. **Execution routing** — who runs it: the role per arm or stage, the
   grader/reviewer role (independent of the runner —
   policy-adversarial-handoff), and the skills each loads
   (policy-reader-run for fixture sessions, the benchmark harness,
   policy-epistemic always). Chosen the same way as design-spec
   routing: roles register + `docs/SKILL-MAP.md`, narrowest hat wins.

## Rules

- No placeholders: "TBD", "add validation later", unnamed thresholds are
  filing failures.
- Every factual assertion cited (policy-epistemic); judgments labeled.
- Self-review before filing: placeholder scan, internal consistency,
  scope check, ambiguity check — fix inline.
- Specs of consequence get adversarial review before "done"
  (policy-adversarial-handoff); self-graded specs are the failure mode
  this skill exists to prevent.
