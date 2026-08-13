# High-Level Stories

<!-- Human-owned; format: the direction skill (register + statements,
     dated statuses mandatory). Ratified 2026-08-13. -->

## Overview

| Status (verified 2026-08-13) | Count |
| ---------------------------- | ----- |
| ✅ Verified live             | 8     |

Audit rule: every status cell carries its verification date; a dated
audit section supersedes any older cell it contradicts.

## Register

| ID     | Title                                    | Priority    | Status        | Evidence                                                         |
| ------ | ---------------------------------------- | ----------- | ------------- | ---------------------------------------------------------------- |
| US-001 | Knowledge in context unasked             | 🔴 Critical | ✅ 2026-08-13 | D005; retrieval digest live in every session                     |
| US-002 | Zero overhead on trivial asks            | 🔴 Critical | ✅ 2026-08-13 | armA/B/C trivial prompts; telemetry fast verdicts                |
| US-003 | Nothing enters memory unratified         | 🔴 Critical | ✅ 2026-08-13 | every D-record's ratified event; inhibit denials (D009)          |
| US-004 | Work traced to goals and values          | 🟠 High     | ✅ 2026-08-13 | frames with roadmap_ref/story_ref; D008                          |
| US-005 | Destructive actions gated                | 🔴 Critical | ✅ 2026-08-13 | inhibition table live denials (D009); deny-list tests            |
| US-006 | Memory is trustworthy data               | 🔴 High     | ✅ 2026-08-13 | trust boundary refusals; validator quarantine; corruption repair |
| US-007 | Claims carry evidence, survive challenge | 🟠 High     | ✅ 2026-08-13 | D001/D002 demote→earn-back; D014 against-verdicts recorded       |
| US-008 | Failures become fixes                    | 🟠 High     | ✅ 2026-08-13 | LESSONS-LEARNT → 0.3.x fixes; retrospect policy                  |

## Stories

- **US-001** — As a developer starting a session, I need established
  knowledge already in context, so I never re-derive or contradict what
  we agreed. Done means: the digest arrives unasked.
- **US-002** — As a developer making a trivial request, I need zero
  methodology overhead. Done means: no visible ritual on small asks.
- **US-003** — As the human owner, I need everything entering shared
  memory to pass through my ratification. Done means: no approved record
  without my decision recorded as an event.
- **US-004** — As a developer mid-task, I need work traced to goals and
  values. Done means: frames cite roadmap and story refs; untraceable
  work stops.
- **US-005** — As the human owner, I need destructive or outward actions
  gated by judgment. Done means: matched actions ask; absence never
  authorizes.
- **US-006** — As a future session or different agent, I need memory to
  be trustworthy data. Done means: validated, provenance-checked,
  injected as reference-never-instructions.
- **US-007** — As the project owner, I need claims to carry evidence and
  survive challenge. Done means: status moves only on cited evidence;
  demotion as legitimate as promotion.
- **US-008** — As a maintainer, I need methodology failures to become
  fixes. Done means: retrospectives file lessons; recurring lessons
  become skills.
