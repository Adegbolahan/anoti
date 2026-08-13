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

| Metric                  | Definition                                                      | Source                  |
| ----------------------- | --------------------------------------------------------------- | ----------------------- |
| Contradiction incidents | actions taken against a ratified record without a flag          | diff + records          |
| Bad-memory incidents    | stale/superseded record acted on as current                     | records' events vs work |
| Recall successes        | records correctly cited into work (frames, reviews, decisions)  | trail refs              |
| Ratification integrity  | records whose status moved without a human event                | events audit            |
| Guardrail activity      | inhibition denials/asks, gate blocks, with false-positive count | telemetry, trail        |
| Store health            | validate-workspace clean; trust current; index = records        | scripts                 |

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

## Cadence & cost

First audit on or after 2026-08-20, then weekly when the repo saw work.
Cost per audit: one auditor dispatch (~15-30k tokens) + minutes of human
spot-audit.

## Results

(accumulate under docs/trials/longitudinal-YYYY-MM-DD.md; none yet)
