---
name: spec
description: anoti spec standard — the required shape for design specs and experiment specs filed to docs/specs/. Invoke before writing either; the format is the contract.
---

# Spec

Where — two naming families, one rule:

- **Standalone documents** (project designs, experiments): date-first —
  `docs/specs/YYYY-MM-DD-<topic>-design.md` /
  `docs/specs/YYYY-MM-DD-exp-<topic>.md` — a chronological register.
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
9. **Execution routing** — name the roles (`roles/`) and skills the
   implementing cascade should engage, one line of why per assignment
   (e.g. "architect: decomposition crosses two organs; git skill: the
   work commits"). The spec suggests; the deliberate skill assigns —
   but a spec that names no route leaves every implementer guessing.

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

## Rules

- No placeholders: "TBD", "add validation later", unnamed thresholds are
  filing failures.
- Every factual assertion cited (policy-epistemic); judgments labeled.
- Self-review before filing: placeholder scan, internal consistency,
  scope check, ambiguity check — fix inline.
- Specs of consequence get adversarial review before "done"
  (policy-adversarial-handoff); self-graded specs are the failure mode
  this skill exists to prevent.
