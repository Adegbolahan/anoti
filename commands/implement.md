---
description: Implement a feature end-to-end as an architect-led, contract-based lifecycle — requirements, design, acceptance tests before code, build, independent review.
---

You are implementing one feature end-to-end. This is the feature-scale form of
the anoti cascade: classify slow, build the attention frame first (attend
skill). Spec: `docs/specs/2026-09-12-architect-led-lifecycle-design.md`.

**The architect leads.** It owns the contract; every other hat consumes or
serves it. The conductor is not in this path — it keeps the non-feature cascade
in the deliberate skill.

**Every phase boundary is a contract.** A phase declares what it `requires`,
what it `produces`, how the next phase `verifies` it, and the single owner it
`rejects to`. An output that does not satisfy its contract is rejected, never
absorbed. Follow the phases in order; never skip one.

**One shared source of truth: the interface contract.** The architect publishes
component boundaries, exact signatures and data shapes, error modes and
invariants. QA writes tests **against** it; the builder implements **to** it.
Neither renegotiates it at the keyboard — changing it re-enters Phase 2.

**Entry test.** This lifecycle is for feature work: a change that adds or alters
behaviour across more than one component, or that introduces a new interface. A
single-file change behind an interface that already exists is not a feature — do
it directly and send it through `/anoti:review-work`. Forcing it through seven
phases buys nothing and contradicts the standing story that trivial asks carry
zero methodology overhead (US-002). The practical test: is there an interface
contract worth writing down?

**Dispatch rules, binding.** You are the only dispatcher and the only writer:
no subagent spawns anything, and no subagent writes a memory organ. Spawn the
practitioner with one role per spawn plus the frame. Budget: **≤ 3 concurrent,
≤ 8 per session**, raised only by explicit human instruction.

**Count before dispatching, because this lifecycle usually does not fit.** Six
spawns are mandatory — `requirements-analyst`, `architect`, `qa`, the gap-hunt
`skeptic`, the builder, the `reviewer` — plus **one per unknown** the architect
names (`explorer` or `skeptic`) and **one more when UI is touched**
(`ui-designer`). A feature with two unknowns costs 8; with UI it costs 9; a fix
round costs nothing extra only because it resumes an existing spawn. State the
count at Phase 0. When it exceeds 8, ask the human to raise the cap for this
feature naming the number, or sequence the later phases into a second session.
Never silently exceed it, and never skip a phase to fit.

**Organ homes:** every path below is the default; a brownfield workspace maps
its own in `.claude/anoti.local.md` frontmatter (`story_path:`, `roadmap_path:`,
`spec_dir:`, `plan_dir:`, `reviews_dir:` — issues #16/#18) and that mapping
wins. Read the frontmatter once in Phase 0 and use the mapped paths after;
never assume `docs/`.

**Durable board:** when `.anoti-board/state.json` exists, use the board skill
alongside these phases — its default workflow mirrors them, step for step. Find
or create the feature once with `--story US-XXX` (the id Phase 0 found or
drafted), load its assignment context, and record each phase's output and the
review evidence through `scripts/anoti board`. Its `test-ratification` step
carries `independent:`, so the board mechanically refuses a ratification
submitted by whoever authored the tests — the same separation the Phase 3-gate
requires. The board owns work status; these contracts remain in force. Do not
create a second independent task lifecycle or memory store.

## Phase 0: Discovery — you

- requires: the request, and `.claude/anoti.local.md` read once.
- produces: organ homes; the story id this serves; the roadmap phase; recalled
  records.
- verified by: a named story id, or an explicit "none" with why.
- rejects to: — (entry phase).

Read the stories organ (`docs/HIGH-LEVEL-STORIES.md`, or `story_path:`) — which
US-id does this serve? — and the roadmap (`docs/ROADMAP.md`, or `roadmap_path:`)
— which phase, what is already delivered. Pull relevant records via
`/anoti:recall` when the topic has history. Read any existing spec and plan in
their homes.

## Phase 1: Requirements — `requirements-analyst`

- requires: Phase 0 output.
- produces: the **AC contract** — each acceptance criterion as given/when/then
  with one observable outcome and an id; the edge cases that will actually
  occur (empty, duplicate, concurrent, hostile); the non-functional constraints
  that bind.
- verified by: every AC is individually observable. Ambiguity is surfaced as a
  question, never resolved by assumption.
- rejects to: `requirements-analyst`.

**Gate:** a story that does not exist yet is drafted into the stories organ
(policy-draft-for-ratification) and **blocks for the human**.

## Phase 2: Design — `architect`

- requires: the AC contract.
- produces: the **interface contract**; the spec, per the **spec skill**, at
  `<spec home>/us-XXX-<name>.md`; the plan, per the plan skill, at
  `<plan home>/us-XXX-plan.md` with file order and an owner hat per component.
- verified by: every AC id maps to at least one named interface element, and
  every element has an owner hat. An unmapped AC or an ownerless element is a
  contract failure.
- rejects to: `architect`.

The architect states every unknown it cannot answer from the frame. Dispatch
one `explorer` per repo-fact question and one `skeptic` per load-bearing claim,
within budget, and return the cited findings to the architect. The architect is
**one continuous spawn** for this phase: resume it with the findings rather than
dispatching a second architect, which would lose the design context and add to
the count. (This applies D011's principle — resume over respawn — rather than
D011 itself, which was ratified for builder fix rounds.) Unknowns that survive are filed to `open_questions` by you.

When UI is touched, dispatch `ui-designer` first: design system, tokens, and
component states (default, hover, focus, loading, error, empty, disabled) are
decided here, not during implementation. The architect folds that into the
contract. No UI touched means the skip is recorded in the plan, so absence
reads as a decision.

**Gate:** present spec + plan and **wait for the human's approval**.

## Phase 3: Acceptance tests — `qa`

- requires: the AC contract and the interface contract, both approved.
- produces: one failing test per AC, each citing its AC id and the interface
  element it exercises, plus a **RED transcript** giving the failure reason per
  test.
- verified by: the architect's ratification below.
- rejects to: `qa` when a test is wrong; `requirements-analyst` when a criterion
  cannot be made to fail, which is a defect in the AC contract rather than in
  the test. Cap that second bounce at 2 — a criterion returning twice goes to
  the human rather than being restated again.

QA writes tests and test infrastructure only, and never the code under test.
An AC that QA cannot make fail is not observable as written: it returns to
`requirements-analyst` for restatement. It is never waived and never handed to
the builder unobserved.

## Phase 3-gate: the architect ratifies the tests — `architect`

**One architect spawn serves the whole lifecycle.** Resume the Phase 2 architect
here and for every ratification round; do not dispatch a second one. It holds the
contract and the reasoning behind its shape, which is exactly what this gate
judges against — and the mandatory count above depends on it: a fresh architect
at this gate would make six mandatory spawns seven, and an ordinary feature would
breach the cap. Resuming across the human approval gate and all of Phase 3 is
expected, not exceptional.

- requires: QA's suite and RED transcript.
- produces: a recorded verdict — ratified, or findings against named AC ids.
- verified by: you write the verdict down. An unrecorded gate has not happened,
  and silence is not a pass.
- rejects to: `qa` — **never the builder**.

Four steps, in order:

1. **The architect reads the suite against the contract** and answers one
   question: *if these tests pass, is the feature correct against the
   contract?* It checks that every AC id appears, that each test fails for the
   stated reason, and that no test reaches for internals the interface contract
   does not name.
2. **Gap hunt.** On the architect's request, dispatch a `skeptic` against the
   suite. The suite is a claim — "passing these means the feature is correct" —
   and the skeptic's job is to refute it: which AC could still fail with the
   whole suite green? Its verdict returns with evidence.
3. **Fix rounds resume the original `qa` spawn** (D011) — never a fresh one.
   That spawn holds the suite and its own choices; relay the architect's
   findings and the skeptic's verdict **verbatim**, since a QA asked to fix
   findings it was never shown will rightly refuse. Re-ratify after each round.
4. **On acceptance, dispatch the builder with fresh context.** The builder must
   not inherit the test-authoring conversation: it implements to the interface
   contract and the ratified suite, not to QA's reasoning about them. A builder
   that has read QA's deliberation can rationalise a weak test instead of
   satisfying the contract.

**The builder does not begin until the verdict is recorded.** Cycle cap 3: if
the architect rejects twice, the ambiguity is in the ACs or the design, so
escalate to the human with both readings named rather than iterating again.

## Phase 4: Build — the builder hat the plan assigns

- requires: a ratified failing suite and the interface contract.
- produces: implementation in the plan's file order, turning RED to GREEN.
- verified by: the suite passes with **no edits to the tests**.
- rejects to: the builder.

Follow the file order strictly; type-check every few files; search for
reusable components before creating new ones. A builder that believes a test is
wrong files it back through the Phase 3 gate — it does not edit QA's tests.

## Phase 5: Independent review — `reviewer`, via `/anoti:review-work`

- requires: GREEN, and the contracts.
- produces: a report under `<reviews home>` with findings at `file:line`.
- verified by: no blockers outstanding.
- rejects to: the original builder, findings relayed verbatim (D011).

Use a separate session identity from the implementation author
(policy-adversarial-handoff); ready-for-review opens a review-debt row that the
verdict closes. Builder work is not done without this.

## Phase 6: Close — you

- requires: a passed review.
- produces: the story's register row as a dated draft; plan status; a commit
  per the **git skill** (`skills/git/SKILL.md`) — conventional message
  `feat: <desc> (US-XXX)`, explicit staging, trailers preserved; consolidation
  of discoveries (Stop gate or `/anoti:consolidate`).
- verified by: the human integrates. Integration is never inferred.
- rejects to: — (terminal; a human who declines names the phase to re-enter,
  since "not yet" is not a phase).

Report test count, files changed, and follow-ups.

## Error recovery (never retry blindly)

| Error                 | Do this                                                    |
| --------------------- | ---------------------------------------------------------- |
| Migration fails       | Read migration scripts and docs before retrying            |
| Unknown CLI flag      | Read `--help` for the actual tool                          |
| Type error            | Read the actual type definition — never cast to `any`      |
| Pre-commit hook fails | Read hook config, fix the root cause — never `--no-verify` |
| Test fails            | Read the test and the code it tests — don't guess          |
| Import not found      | Glob for the actual export path                            |
