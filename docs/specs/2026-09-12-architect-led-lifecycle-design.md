# Architect-led implementation lifecycle

<!-- Design spec. Format: the spec skill. Filed 2026-09-12. -->

## What this is

`/anoti:implement` becomes an architect-led lifecycle instead of a linear
single-session checklist. The architect owns design and drives research
through explorer/skeptic dispatches; `requirements-analyst` produces testable
acceptance criteria; `qa` authors the acceptance tests as a failing suite
**before** any implementation exists; the architect **ratifies those tests**;
and the builder's task is reduced to turning red green. The differentiation:
today's command writes code first and audits it afterwards, so the definition
of done is discovered late. Here the definition of done is executable before
the first line of implementation.

## Why

- **The roles exist and are unused.** `commands/implement.md` dispatches no
  role at all: the only role word in the file is "conductor", once, at line
  51 of the pre-0.6.0 file. `roles/` holds 23 hats including `architect`, `qa`, `ui-designer` and
  `requirements-analyst`; `agents/explorer.md` and `agents/skeptic.md` are
  first-class agents. `skills/deliberate/SKILL.md:54` already routes research
  to them, and `roles/architect.md:14-16` already tells the architect to
  survey via explorer spawns. Nothing invokes any of it from implement.
- **Tests today are written by the party they are meant to falsify.** Phase 2
  says "Tests alongside implementation"; Phase 3 has a reviewer check that
  test categories carry assertions. A test authored by the implementer, after
  the implementation, is shaped by the code rather than by the requirement.
- **Observed in this repo, not hypothesised.** Review rows R4/R5 record three
  adversarial cycles against 0.5.32/0.5.33 in which the code was clean every
  time and every blocker was a claim asserted before it was verified. The
  generalisable failure is authoring-then-checking; moving verification ahead
  of authoring is the structural answer. `LESSONS-LEARNT.md` carries the same
  shape twice: the e5a7b5e time-bomb test, and the state-dir invariant tested
  through one creator out of seven.
- **Design is only ever reviewed, never decided.** `ui-designer` exists and
  implement never consults it; `commands/review-work.md` inspects a Frontend
  dimension after the fact, which cannot recover a wrong interaction model.

## Design principles / constraints

1. **Every phase boundary is a contract.** A phase declares what it
   `requires`, what it `produces` and in what shape, how the consumer
   `verifies` it, and the single owner it `rejects to`. Prose handoffs are the
   thing this replaces: a phase output that does not satisfy its contract is
   rejected, not absorbed.
2. **One shared source of truth: the interface contract.** The architect
   publishes component boundaries, exact signatures and data shapes, error
   modes, and invariants. QA writes tests **against the contract**, the builder
   implements **to the contract**, and neither renegotiates it informally.
   Changing it re-enters Phase 2 — it is not adjusted at the keyboard.
3. **The main session is the only dispatcher and the only writer.** The
   architect never spawns anything; it names what it needs and the main
   session dispatches (`skills/deliberate/SKILL.md`, `agents/practitioner.md`
   hard boundaries). Every artifact is written by the main session.
4. **Spawn budget: <= 3 concurrent, <= 8 per session**, raised only by explicit
   human instruction — and this lifecycle usually does not fit. Six spawns are
   mandatory (`requirements-analyst`, `architect`, `qa`, gap-hunt `skeptic`,
   builder, `reviewer`), plus one per unknown the architect names and one more
   when UI is touched. Two unknowns reach 8 — the cap exactly — and UI makes 9,
   which exceeds it. One architect spawn serves both Phase 2 and the Phase 3
   gate, resumed rather than re-dispatched; a fresh architect at the gate would
   make the mandatory count seven. The count is stated at Phase 0 and a count
   over 8 is put to the human as an explicit raise, or the later phases sequence
   into a second session. Never silently exceed it, and
   never skip a phase to fit.
5. **Entry test.** Feature work only: a change altering behaviour across more
   than one component, or introducing a new interface. A single-file change
   behind an existing interface goes directly to `/anoti:review-work`, because
   six mandatory spawns for a one-line change contradicts US-002 (zero overhead
   on trivial asks). The practical test is whether an interface contract is
   worth writing down.
6. **Role classes are binding.** `architect` and `ui-designer` are advisory —
   analysis and contracts, never code. `qa` is builder-class but writes tests
   and test infrastructure only, and never fixes the code under test.
   `reviewer` never edits. Fix rounds resume the original builder (D011).
7. **Human gates are preserved exactly.** Story and spec ratification go
   through `policy-draft-for-ratification`; the plan blocks for approval;
   acceptance is the human's. Silence never authorises.
8. **RED before GREEN is evidence, not ceremony.** QA returns a transcript in
   which each new test fails for the stated reason. A test that has never
   failed is not evidence it can fail.
9. **Organ homes are resolved once** from `.claude/anoti.local.md`
   (`story_path:`, `roadmap_path:`, `spec_dir:`, `plan_dir:`, `reviews_dir:`)
   and used everywhere after; `docs/` is only the default.
10. **The conductor is retained for non-feature cascades.** `deliberate`'s
   cascade keeps its conductor-led shape; implement no longer routes through
   it. One lifecycle owner per entry point.

## The design

Seven phases, each a contract. `rejects to` names exactly one owner, so a
failure never diffuses into "someone should look at this".

**Phase 0 — Discovery.** Owner: main session.
- requires: the request, and `.claude/anoti.local.md` read once.
- produces: organ homes, the story id this serves, the roadmap phase, recalled
  records for the topic.
- verified by: a named story id (or an explicit "none, and why"), per `attend`.
- rejects to: — (entry phase).

**Phase 1 — Requirements.** Owner: `requirements-analyst` (advisory).
- requires: Phase 0 output.
- produces: the **AC contract** — each acceptance criterion as given/when/then
  with one observable outcome, plus the edge cases that will actually occur
  (empty, duplicate, concurrent, hostile) and the non-functional constraints
  that bind. Each AC carries an id.
- verified by: every AC is individually observable; ambiguity is surfaced as a
  question, never resolved by assumption.
- rejects to: `requirements-analyst`.
- gate: a story that does not exist yet is drafted and **blocks for the human**.

**Phase 2 — Design.** Owner: `architect` (advisory), with `ui-designer` when UI
is touched and explorer/skeptic per unknown.
- requires: the AC contract.
- produces: the **interface contract** (components with one responsibility,
  exact signatures and data shapes, error modes, invariants), the spec per the
  spec skill, and the plan per the plan skill with file order and an owner hat
  per component.
- verified by: every AC id maps to at least one named interface element, and
  every interface element has an owner hat. An unmapped AC or an ownerless
  element is a contract failure.
- rejects to: `architect`.
- gate: the human approves spec + plan.
- research: the architect states every unknown it cannot answer from the frame;
  the main session dispatches one `explorer` per repo-fact question and one
  `skeptic` per load-bearing claim, within budget, and returns cited findings.
  When UI is touched, `ui-designer` produces the design system and component
  states first and the architect folds them into the contract.

**Phase 3 — Acceptance tests.** Owner: `qa` (builder-class, tests only).
- requires: the AC contract and the interface contract, both approved.
- produces: one failing test per AC, each citing its AC id and the interface
  element it exercises, plus a RED transcript giving the failure reason per
  test.
- verified by: **the architect's ratification** (below).
- rejects to: `qa` when a test is wrong; `requirements-analyst` when a criterion
  cannot be made to fail, which is a defect in the AC contract rather than the
  test, capped at two bounces before the human decides.

**Phase 3-gate — the architect ratifies the tests.** Owner: `architect`.
- requires: QA's suite and RED transcript.
- produces: a recorded verdict — ratified, or findings against named AC ids.
- verified by: the verdict is written down by the main session; an unrecorded
  gate has not happened, and silence is not a pass.
- Four steps, in order: (1) the architect reads the suite against the contract
  and answers *if these tests pass, is the feature correct against the
  contract?*, checking that every AC id appears, that each test fails for the
  stated reason, and that no test reaches for internals the contract does not
  name; (2) a `skeptic` is dispatched against the suite to refute the claim
  "passing these means the feature is correct" — which AC could still fail with
  everything green; (3) fix rounds **resume the original `qa` spawn** (D011),
  with the architect's findings and the skeptic's verdict relayed verbatim,
  re-ratifying after each round; (4) on acceptance the builder is dispatched
  with **fresh context**, so it implements to the contract and the suite rather
  than to QA's reasoning about them — a builder that has read QA's deliberation
  can rationalise a weak test instead of satisfying the contract.
- rejects to: `qa` — never to the builder, and the builder does not begin until
  this gate passes. Rationale: the architect owns the contract, so it is the
  party able to judge whether the tests encode it; and a suite corrected after
  implementation has already lost its independence.
- cycle cap: 3, matching `commands/review-work.md`.

**Phase 4 — Build.** Owner: the builder hat the plan assigns per component.
- requires: a ratified failing suite and the interface contract.
- produces: implementation in the plan's file order, turning RED to GREEN.
- verified by: the suite passes with **no edits to the tests**. A builder that
  believes a test is wrong files it back through the Phase 3 gate; it does not
  change QA's tests.
- rejects to: the builder.

**Phase 5 — Independent review.** Owner: `reviewer`, via `/anoti:review-work`.
- requires: GREEN, and the contracts.
- produces: a report under `reviews_dir` with findings at `file:line`.
- verified by: no blockers outstanding.
- rejects to: the original builder, findings relayed verbatim (D011).

**Phase 6 — Close.** Owner: main session.
- requires: a passed review.
- produces: the story's register row as a draft, plan status, commit per the
  git skill, consolidation of discoveries.
- verified by: the human integrates. Integration is never inferred.
- rejects to: — (terminal; a human who declines integration names the phase to
  re-enter, since "not yet" is not a phase).

## Failure behavior

- **QA cannot make a test fail for an AC** -> that AC is unobservable as
  written. It returns to `requirements-analyst` for restatement. It is never
  waived, and never handed to the builder unobserved.
- **Architect rejects the tests twice** -> the ambiguity is in the ACs or the
  design, not the tests. Escalate to the human with both readings named.
  Cycle cap 3, matching `commands/review-work.md`.
- **Spawn budget exhausted** -> sequence the remaining phases; if the feature
  still does not fit, stop and report, since exceeding the budget needs
  explicit human instruction.
- **explorer/skeptic unavailable or inconclusive** -> the architect records
  the unknown as an `open_questions` entry through the main session and states
  the design's exposure to it. It never guesses silently.
- **No UI touched** -> `ui-designer` is skipped and the skip is recorded in the
  plan, so absence reads as a decision rather than an omission.
- **Degradation floor:** every gate that cannot be satisfied stops the
  lifecycle with a stated reason. Nothing downgrades to "proceed anyway".

## Testing

| Requirement | Observable pass condition |
|---|---|
| Every phase names its owner role | `tests/test_commands.sh` asserts `implement.md` names `requirements-analyst`, `architect`, `qa`, `reviewer`, `explorer`, `skeptic` |
| QA precedes the builder | the acceptance-test phase appears before the build phase in the file, asserted by line order |
| The architect ratifies the tests | the file states the gate and that findings return to QA, not the builder |
| Dispatcher rule survives | the file states the main session is the only dispatcher |
| Spawn budget is stated | the file carries the `<= 3` / `<= 8` values |
| Existing contract intact | the four strings `docs/HIGH-LEVEL-STORIES.md`, "spec skill", `review-work`, "git skill" still present (current assertions at `tests/test_commands.sh:18`, `tests/test_core_skills.sh:67`) |
| RED evidence required | the file requires a failing-test transcript from QA |
| Every phase declares its contract | each phase in the file carries `requires`, `produces`, `verified by` and `rejects to` |
| `rejects to` is single-owner | no phase names more than one rework target |
| The interface contract is named as shared truth | the file states QA tests against it and the builder implements to it |
| Tests are not editable by the builder | the file states a builder returns a disputed test through the Phase 3 gate |
| AC ids are traceable into tests | the file requires each test to cite its AC id |
| The gate commissions a gap hunt | the file and `roles/architect.md` both name a `skeptic` dispatched against the suite |
| Fix rounds resume the same QA spawn | the file cites D011 and requires findings relayed verbatim; `roles/qa.md` states findings return to that spawn |
| The builder starts fresh | the file and `roles/qa.md` state the builder is dispatched with fresh context and never sees QA's reasoning |
| Budget arithmetic is honest | the file names 6 mandatory spawns, per-unknown and UI additions, and requires a human raise above 8 |
| An entry test exists | the file routes single-file work behind an existing interface to `/anoti:review-work` and cites US-002 |
| Phase 3 names both rework owners | the contract block names `qa` and `requirements-analyst`, with the second bounce capped |

## Out of scope

- Removing the conductor from `skills/deliberate/SKILL.md` — it keeps the
  non-feature cascade.
- Aligning `templates/board-workflow.yaml` with these phases. The board is
  uncommitted in-flight work; changing it here would absorb someone else's
  deliverable.
- Raising the spawn budget.
- Any executable orchestration. This is a command document; no code dispatches
  these phases, and claiming otherwise would overstate what ships.
- New roles or agents. The wiring uses what already exists.

## Success criteria

1. `/anoti:implement` names an owner for all seven phases, and a reader can
   tell who performs each without inferring.
2. The acceptance tests exist and fail before Phase 4 begins, with a RED
   transcript attached.
3. The architect's ratification of the tests is a stated gate with a named
   rework target (QA) and a cycle cap.
4. The three human gates (story/spec, plan, acceptance) are unchanged in
   force from the current command.
5. `bash tests/run.sh` green, including new assertions for 1-4.
6. The command never instructs a subagent to spawn, and never instructs
   anyone but the main session to write an organ.
7. Every phase in the command declares all four contract fields, and each
   `rejects to` names its owner explicitly — one owner, or where a second
   legitimate path exists (Phase 3's criterion bounce) both owners and a cap.
8. The test gate runs all four steps — read, gap-hunt, resume-QA, dispatch
   builder fresh — and no step is optional.
9. A reader can answer "who fixes this?" for any phase failure without
   inferring, and "what does the next phase receive?" without reading prose.

## Execution routing

- **Plan owner:** `architect` — the change is a decomposition of one document
  into phase contracts, which is technical decomposition, not sequencing.
- **Builder hats:** `technical-writer` owns the command prose (the deliverable
  is a document); no code hat is required, since no executable changes.
- **Skills each hat loads:** `spec` and `plan` (this spec and its plan),
  `direction` (the command cites the direction organs), `git` (commit
  discipline), `policy-epistemic` and `policy-trace-to-frame` throughout,
  `policy-adversarial-handoff` for the review before done.
- **Review:** independent `reviewer`-class spawn against this spec and the
  resulting command, per `policy-adversarial-handoff`; filing this spec under
  `spec_dir` opens a review-debt row mechanically.
