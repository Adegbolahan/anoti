# Skill & Policy Reachability Map

<!-- Verified 2026-08-13 by audit; enforced permanently by
     tests/test_reachability.sh (every skill needs ≥1 referrer; the
     cycle's spine is explicitly chained). Regenerate the counts with the
     greps in that test. -->

## Entry points (roots)

| Root                                             | Fires                                             | Leads to                                                                                                |
| ------------------------------------------------ | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| SessionStart hook (`retrieve`)                   | every session                                     | memory digest; demo-skill orientation line; skillify offer (bare repos); `/anoti:review` nudge          |
| UserPromptSubmit hook (`classify`)               | every prompt                                      | fast path (silence) or **attend**                                                                       |
| PreToolUse hook (`inhibit`)                      | matched tools                                     | allow / ask / deny; deny message routes to `/anoti:consolidate`                                         |
| Stop hook (`consolidation-gate`)                 | candidate episodes                                | `/anoti:consolidate`                                                                                    |
| PostToolUse/PostToolUseFailure hook (`presence`) | matched tool calls (Bash/Write/Edit/NotebookEdit) | JIT recall (filtered by adaptive suppression); periodic frame re-anchor; evidence-kind nudge; telemetry |
| `scripts/feedback` (list/clear)                  | on demand, or via `mark-retrospect`'s named pairs | inspect/undo adaptive suppression — presence-feedback.tsv (project-level, gitignored)                   |
| Human commands                                   | on demand                                         | new, implement, review-work, update, review, recall, consolidate; anoti recall (mechanical pre-check)   |

## The spine (explicitly chained, never description-luck)

```
classify ──▶ attend ──▶ deliberate ──▶ practitioner(role + policies)
                │            │                    │
                │            ├─ cascade: conductor ▶ gates ▶ roles
                │            └─ lifetime rule ──▶ plan skill
                └─ story_ref/roadmap_ref ──▶ direction docs
gate/inhibit ──▶ /anoti:consolidate ──▶ consolidate skill ──▶ policy-retrospect
                                              └─ helpers ▶ store ▶ /anoti:review
```

## Core & document skills — inbound paths

| Skill       | Reached from                                                                                                    |
| ----------- | --------------------------------------------------------------------------------------------------------------- |
| attend      | classify hook; implement; policy-trace-to-frame                                                                 |
| deliberate  | **attend (handoff)**; implement (multi-component note); plan skill; practitioner; policy-parallel-breadth       |
| consolidate | Stop gate; inhibit deny message; /anoti:consolidate; implement; consolidator agent; skillify; policy-retrospect |
| skillify    | retrieve bootstrap offer; /anoti:new; /anoti:update; direction skill                                            |
| spec        | implement (spec gate); skillify maintenance map; **architect role**                                             |
| plan        | deliberate lifetime rule; conductor role; skillify maintenance map                                              |
| direction   | visionary, product-manager, requirements-analyst roles; skillify                                                |
| feedback    | policy-retrospect (anoti-friction routing); SessionStart digest (pending.md surfaces queued drafts)             |
| git         | implement (commit time); deliberate (execution step); every builder role before committing                      |
| demo        | SessionStart digest (orientation line); /anoti:new (post-scaffold); self-serve for new sessions and subagents   |

## Policies — inbound paths (role stacks use bare names)

| Policy                 | Role stacks                        | Other referrers                                          |
| ---------------------- | ---------------------------------- | -------------------------------------------------------- |
| epistemic              | all 23                             | practitioner; consolidator; direction skill              |
| trace-to-frame         | all 23                             | inhibit's frame check; attend                            |
| escalate-destructive   | all 23                             | inhibition decision table                                |
| retrospect             | none — **session-level by design** | consolidate skill (its reflective step)                  |
| draft-for-ratification | 11 (advisory)                      | direction skill; cascade gates                           |
| test-driven            | 8 (builders)                       | implement Phase 3                                        |
| adversarial-handoff    | 7 (builders)                       | spec/plan skills ("documents of consequence"); implement |
| parallel-breadth       | 2 (architect, ux-researcher)       | deliberate                                               |
| visual-verify          | 2 (frontend, mobile)               | —                                                        |
| reversible-change      | 2 (database, devops)               | /anoti:update spirit                                     |
| reader-run             | 1 (technical-writer)               | —                                                        |

## Known-thin branches (reachable, single-path — watch, don't fix)

- `reader-run` rides only technical-writer; `visual-verify` misses
  ui-designer's stack (reachable via frontend/mobile). Amend role stacks
  when live use shows the gap matters — evidence first, per the house
  rules.
