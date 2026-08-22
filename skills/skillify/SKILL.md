---
name: skillify
description: anoti skill extraction — examine the session (and the retrospective's skillify queue in TODOS) for a procedure performed twice or once with obvious generality, and write it as a reusable skill the agent can invoke next time. Invoke when a procedure just recurred, when TODOS carries a `skillify:` entry, or when the retrospective names a candidate.
---

# Skillify

Turn a procedure this session proved into a skill the next session can
invoke. The retrospective asks "what should be skillified" every session
and files candidates to TODOS; this skill consumes that queue and writes
the skill — so the same steps are never re-derived from scratch a third
time. (Workspace scaffolding is the **bootstrap** skill; until 0.5.29 it
wore this name.)

## Inputs

1. **The session trail** — what was actually run: commands, file edits,
   the order, the checks that proved it worked, the mistakes on the way.
   A skill is written from evidence, not from how the procedure "should"
   go (policy-epistemic).
2. **The skillify queue** — TODOS entries prefixed `skillify:` (filed by
   policy-retrospect question 3), each naming the repeatable steps.
3. **An explicit ask** — the human says "make this a skill".

## Extraction test (all four, or stop)

- **Recurred or general:** performed twice (this session or across
  sessions — cite both moments), or once with obvious generality (name
  the other situations it covers).
- **Deterministic core:** the steps can be written as commands and
  checks another session can follow without re-deriving them. Judgment
  steps are allowed only when named as judgment with the criteria.
- **Not already a skill:** list `skills/` (plugin), `.claude/skills/`
  (project), `~/.claude/skills/` (personal); a near-match is amended,
  never twinned.
- **Verifiable:** the skill carries a way to tell it worked (a command
  whose output differs between done and not-done — G004).

A one-off, a procedure whose steps are still being discovered, or one
whose only content is "use tool X carefully" fails the test: leave the
TODOS entry open with a one-line reason, and stop.

## Where it lives (scope routing, like memory)

| Scope                                 | Home                               | Gate                                              |
| ------------------------------------- | ---------------------------------- | ------------------------------------------------- |
| This project only                     | `.claude/skills/<name>/SKILL.md`   | write it; commit with the work (git skill)        |
| Every project of this user            | `~/.claude/skills/<name>/SKILL.md` | **human-gated** — propose, the human says yes     |
| anoti's own craft (governed-workflow) | `skills/<name>/` in the plugin     | via the **feedback** skill — an issue, not a push |

Claude Code loads `.claude/skills/` and `~/.claude/skills/` live — no
restart — and invokes a skill on its `description`, so the description
is the trigger: write it as the situations that should summon the skill,
not as a summary of its contents; keep `description` + `when_to_use`
under 1,536 characters (the listing truncates there).

## Shape of the written skill

```
---
name: <kebab-case, matches the directory>
description: <when to invoke: the situations, the symptoms, the ask>
---
# <Name>
**When:** the trigger situations, one line each.
**Procedure:** numbered steps with the exact commands and paths; every
judgment step labeled "(judgment: <criteria>)".
**Verify:** the command(s) whose output proves it worked.
**Pitfalls:** the mistakes made while discovering it, each with the fix.
**Binds:** which anoti skills or policies apply when running it.
```

Supporting files (a script, a checklist) sit beside `SKILL.md` and are
referenced as `${CLAUDE_SKILL_DIR}/<file>`. Scripts stay small and
idempotent; a skill that needs a helper the plugin should own goes
through the feedback skill instead.

## Procedure

1. **Pick the candidate** — from the queue or the trail; cite both
   occurrences (or the generality argument).
2. **Run the extraction test** above; record a failing candidate's
   reason on its TODOS entry and stop.
3. **Write the skill** in the shape above, from the trail, into the
   scope-routed home. Project and personal homes are created with
   `mkdir -p`; a personal write waits for the human's yes.
4. **Verify it from cold:** read the written skill as a stranger and run
   its Verify step once — a skill that cannot be followed from its own
   text is rewritten, not shipped.
5. **Consume the queue entry:** `scripts/complete-todo <todos> "<match>"
"written: <path>"` — the TODOS entry is the record that the candidate
   became a skill.
6. **Commit** the project skill with the work it came from (git skill);
   a personal skill is not in any repo — say where it landed.

## Rules

- Helpers and organs stay the plugin's: a project skill never hand-edits
  GROUNDING.yaml, TODOS.md, LESSONS-LEARNT.md, or session state — it
  calls `scripts/anoti <action>` like everything else.
- A skill encodes procedure; a **lesson** encodes insight and a
  **policy record** encodes a boundary — route each to its organ
  (policy-retrospect). When a skill's first step is "remember that…",
  that line is a lesson, not a step.
- Never skillify the act of reading memory or running the cycle — those
  are anoti's, and a duplicate drifts.

**Binds:** policy-retrospect (files the queue), consolidate step 11
(routes to it), the git skill (commits it), the feedback skill (anoti-
craft candidates), policy-escalate-destructive (the personal-scope gate).
