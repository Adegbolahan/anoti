---
description: Implement a feature end-to-end under the anoti cycle — discovery, spec gate, plan, build, review-work, consolidation.
---

You are implementing one feature end-to-end. Follow the phases exactly;
never skip one. This is the feature-scale form of the anoti cascade —
classify slow, build the attention frame first (attend skill).

## Phase 0: Discovery (every time — do not rush)

- Read `docs/HIGH-LEVEL-STORIES.md` (find or draft the story; which US-id
  does this serve?) and `docs/ROADMAP.md` (which phase; what is already
  delivered). Read the memory digest's relevant records via
  `/anoti:recall` if the topic has history.
- If a spec exists in `docs/specs/`, read it; if a plan exists in
  `docs/plans/`, read it.
- **Pattern research:** read 2-3 existing modules; match structure,
  naming, error handling, and test patterns exactly. Note exact versions
  before adding any dependency.
- **Integration analysis:** for every story this depends on, verify the
  implementation actually exists (endpoints return the expected shape,
  types importable, schema present). Anything missing is a prerequisite
  fix, flagged before proceeding.
- **Gap & risk analysis:** list what the acceptance criteria do NOT cover
  (error/empty states, permissions, concurrency); surface assumptions;
  ask the human about genuine ambiguity — never guess requirements.

## Phase 0-gate: Spec (MANDATORY)

A spec file MUST exist before Phase 1. If missing: ask all clarifying
questions, wait for answers, then write it per the **spec skill**
(`skills/spec/SKILL.md`) to `docs/specs/us-XXX-<name>.md` (story-first
naming) with
testable acceptance criteria. Register the story in
`docs/HIGH-LEVEL-STORIES.md` (draft-for-ratification — the human merges).
Then write a TodoWrite checklist of every AC + prerequisite + gap.

## Phase 1: Plan

Multi-component features (several roles, parallel research): run the
cascade via the deliberate skill instead of planning inline — the
conductor's plan then feeds this phase.

Per the **plan skill**: file inventory in dependency order, exact
integration contracts, risks with mitigations. Save to
`docs/plans/us-XXX-plan.md`; present the summary and **wait for
approval**. After approval, produce the context handoff (story, ACs,
contracts, prerequisites, mitigations, file order) so nothing is lost to
compaction — persist it in session state.

## Phase 2: Implement

Follow the file order strictly. Type-check every few files. Tests
alongside implementation (policy-test-driven where declared). Search for
reusable components before creating new ones.

## Phase 3: Validate — run `/anoti:review-work`

Before it: verify every applicable test category has assertions
(authorization, input validation, state transitions, error handling,
edge cases) — an applicable category with zero assertions gets tests NOW.
Then run the review-work cycle to completion; fix blockers and re-review
per its cycle cap. Builder work does not count as done without it
(policy-adversarial-handoff).

## Phase 4: Close

Update the plan status; update the story's register row (dated status +
evidence ref) as a draft; conventional commit `feat: <desc> (US-XXX)`;
let consolidation capture any discoveries (Stop gate or
`/anoti:consolidate`). Report test count, files changed, follow-ups.

## Error recovery (never retry blindly)

| Error                 | Do this                                                    |
| --------------------- | ---------------------------------------------------------- |
| Migration fails       | Read migration scripts and docs before retrying            |
| Unknown CLI flag      | Read `--help` for the actual tool                          |
| Type error            | Read the actual type definition — never cast to `any`      |
| Pre-commit hook fails | Read hook config, fix the root cause — never `--no-verify` |
| Test fails            | Read the test and the code it tests — don't guess          |
| Import not found      | Glob for the actual export path                            |
