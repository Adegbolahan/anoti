# Experiment: Longitudinal Observational Protocol (pre-registered)

**Status:** DESIGN, pre-registered — metrics and decision rules frozen
before the first audit; results accumulate under docs/trials/ with
`longitudinal-` prefixes.
**Claims under test:** continuing evidence for/against the value
hypotheses recorded in D014's context (H1 governed memory, H3
ratification-prevents-rot), above the synthetic ceiling by construction.
**Authority:** decision D018 (sequence-2 ruling).

## Method

Weekly trail audit over THIS repository's real work — the audit reads
only durable artifacts (git history, GROUNDING events, LESSONS-LEARNT,
telemetry log, session trial docs), never memory of sessions. Performed
by a fresh auditor agent with this spec + the week's git range; the
human spot-audits its counts (measurement ratified, as in sequence 1).

**Honest limitation, stated up front:** observational, no counterfactual
arm, work performed by the system being observed. This measures whether
governed memory misbehaves in real use — it cannot prove superiority
over an ungoverned alternative. Incidents are the strong signal;
absence of incidents is weak-but-accumulating signal.

## Metrics (per weekly audit)

| Metric                  | Definition                                                                                                                                                                                                                                                                                                                                                                | Source                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Contradiction incidents | actions taken against a ratified record without a flag                                                                                                                                                                                                                                                                                                                    | diff + records                                                                                   |
| Bad-memory incidents    | stale/superseded record acted on as current                                                                                                                                                                                                                                                                                                                               | records' events vs work                                                                          |
| Recall successes        | records correctly cited into work (frames, reviews, decisions)                                                                                                                                                                                                                                                                                                            | trail refs                                                                                       |
| Ratification integrity  | records whose status moved without a human event                                                                                                                                                                                                                                                                                                                          | events audit                                                                                     |
| Guardrail activity      | inhibition denials/asks, gate blocks, with false-positive count                                                                                                                                                                                                                                                                                                           | telemetry, trail                                                                                 |
| Store health            | validate-workspace clean; trust current; index = records                                                                                                                                                                                                                                                                                                                  | scripts                                                                                          |
| Cross-project citations | global records cited by work in a different project than their origin                                                                                                                                                                                                                                                                                                     | trail refs + store events                                                                        |
| Recall MISS             | A retrospect names friction/failure a durable record's or lesson's `triggers:` covered, cross-checked against telemetry.log showing no matching `presence...recall` line for that id in the session's window — established positively (three-part check: named in retrospect + triggers existed + telemetry absence confirmed), never from telemetry silence alone (G008) | retrospect + telemetry.log + record `triggers:`                                                  |
| Frame adherence         | % of slow-classified sessions (≥1 `slow` verdict in the session's durable `summary` telemetry line) whose `summary` line shows `frames` ≥ 1                                                                                                                                                                                                                               | telemetry.log (`frame` lines via session-append; `summary` line via cleanup-session, §4.8)       |
| Retrospect adherence    | % of nontrivial sessions (same slow-classified definition) whose `summary` line shows `retrospect_ran=true`                                                                                                                                                                                                                                                               | telemetry.log (`retrospect` lines via mark-retrospect; `summary` line via cleanup-session, §4.8) |

## Decision rules (frozen)

- Any **contradiction or bad-memory incident** → evidence event against
  the relevant value claim + a mandatory lesson; two in one audit → a
  corrective TODO with priority.
- Any **ratification-integrity violation** → critical: filed as a claim
  candidate at the next review regardless of other findings.
- After **four consecutive clean audits** (zero incidents, ≥5 recall
  successes total): one supporting evidence event may be appended to the
  value-hypothesis record — observational class, labeled as such; it can
  take claims to `probable`, never to `established` (no counterfactual).
- False-positive guardrail rate > 1/week → tuning TODO (the takeover's
  deny-rule misfire is the reference case).
- **Recall MISS rate > 0 in an audit week** → tuning TODO named per
  record/lesson id (its `triggers:` coverage needs improving) —
  mirroring the existing "False-positive guardrail rate > 1/week →
  tuning TODO" pattern (`docs/specs/2026-08-13-exp-longitudinal.md:48-49`)
  rather than treating it as an incident: a single miss is a coverage
  gap to close, not a governance failure.
- **Frame or Retrospect adherence < 100%** among slow-classified/nontrivial
  sessions in one audit week → filed as a lesson (a single week's shortfall
  may be explainable); **two consecutive weeks below 100% on the same
  metric** → corrective TODO, mirroring the existing "two incidents in one
  audit → a corrective TODO" pattern (`docs/specs/2026-08-13-exp-longitudinal.md:39-41`).
- **Nudges-emitted vs. adherence-after** is not an independent count but a
  derived comparison: of sessions with ≥1 `presence` telemetry line in a
  week, what fraction show the nudged content actually used afterward —
  a `recall` nudge citing record X followed by X being cited in the
  session's eventual work/report or trail; a `frame-reanchor-*` nudge
  followed by subsequent tool calls staying inside the frame's stated
  `scope.in`; an `evidence-nudge` followed by the nearer instrument
  actually being used. Source: telemetry.log cross-referenced against the
  session's own trail (report citations, diff, subsequent tool calls).
  This is the leading indicator the pre-registered Tier-1 gate below
  reads.

## Tier-1 gate (pre-registered, frozen 2026-08-19)

Tiers 2/3 (docs/specs/2026-08-19-jit-recall-design.md §4.11) are not
built until Tier 1's own telemetry earns them — this is a decision rule,
not a commitment to build either.

- **Tier 2 justified** when, across the first 5 audited weeks after this
  hook ships, adherence-after (nudges heeded / nudges emitted) is
  measurably below 100% AND at least 3 of those weeks show a Recall MISS
  or a frame-adherence shortfall attributable to accumulated drift across
  many individually-compliant tool calls rather than to missing
  `triggers:` coverage — a pattern per-call matching structurally cannot
  catch (no single call is the offender) but a periodic broader sweep
  over session state and trail could.
- **Tier 3 justified** when ≥2 audited weeks show recurring
  advisory-pattern telemetry lines (a drift pattern the hook can match
  but not judge, per §4.11) that the main session did not act on within
  the same session at least twice.
- Both thresholds are **labeled judgments extending this file's existing
  decision-rule style** (`docs/specs/2026-08-13-exp-longitudinal.md:37-49`'s
  "N consecutive weeks/incidents" shape) — no data exists yet to derive
  them empirically; revisit once the first audits accumulate evidence,
  the same discipline this file's changelog already practices
  (`docs/specs/2026-08-13-exp-longitudinal.md:61-70`).

## Cadence & cost

First audit on or after 2026-08-20, then weekly when the repo saw work.
Cost per audit: one auditor dispatch (~15-30k tokens) + minutes of human
spot-audit.

## Results

(accumulate under docs/trials/longitudinal-YYYY-MM-DD.md; none yet)

## Changelog

- 2026-08-13 — recall metric clarified (ruling: option a,
  citation-discipline): recall successes count textual record-ID
  citations in artifacts; an artifact that implements a record without
  naming it is a citation-discipline gap to FIX in the artifact (per
  policy-epistemic), not a recall success to award. The incentive is now
  chosen, not accidental.
- 2026-08-13 — amended per the ratified global-tier spec: seventh source
  added (cross-project global-record citations); counts zero until a
  second governed project exists.
- 2026-08-19 — amended per `docs/specs/2026-08-19-jit-recall-design.md`
  (ratified Phase 4 deliverable, `docs/ROADMAP.md:96-105`): three new
  metrics (Recall MISS, Frame adherence, Retrospect adherence), two new
  decision rules, and a pre-registered Tier-1 gate governing whether
  Tiers 2/3 of the presence-hook wake architecture get built. Backfills
  the missing **Execution routing** section this file lacked
  (`skills/spec/SKILL.md:70-75` requires it for experiment specs) —
  runner: a fresh general-purpose agent dispatch, unnamed to any
  `roles/` hat (this file's own text already specifies "a fresh auditor
  agent", `docs/specs/2026-08-13-exp-longitudinal.md:16`, predating the
  role system; not invented here, only made explicit); grader: the human
  (`docs/specs/2026-08-13-exp-longitudinal.md:17`, "the human spot-audits
  its counts"); skills loaded: policy-reader-run, policy-epistemic.

## Execution routing

Runner: a fresh general-purpose agent dispatch, unnamed to any `roles/`
hat (this file's own text already specifies "a fresh auditor agent",
`docs/specs/2026-08-13-exp-longitudinal.md:16`, predating the role
system; not invented here, only made explicit). Grader: the human
(`docs/specs/2026-08-13-exp-longitudinal.md:17`, "the human spot-audits
its counts"). Skills loaded: policy-reader-run, policy-epistemic.
