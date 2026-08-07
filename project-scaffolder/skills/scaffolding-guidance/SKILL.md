---
name: scaffolding-guidance
description: |
  Use this skill when the user asks about project scaffolding, CLAUDE.md templates, project tracking, or how to use the project-scaffolder plugin. Triggers on: "How do I scaffold a project?", "What templates are available?", "CLAUDE.md best practices", "project tracking", "user story management".
metadata:
  version: "3.1.0"
---

# Project Scaffolding Guidance

## Commands

### `/new`

Scaffold a new project with Claude Code documentation, workflow commands, skills,
hooks, and project tracking. Prompts for the target directory.

### `/update`

Update an existing scaffolded project to the latest template version. Detects the
current version, shows what changed, and preserves `CLAUDE.md` and everything under
`.claude/project/` that you authored.

## What Gets Created

```
project/
├── CLAUDE.md                    # Project hub
└── .claude/
    ├── settings.json            # Version tracking, no hooks
    └── project/
        ├── features/            # User story specs
        ├── plans/               # Implementation plans
        ├── reviews/             # Review reports (evidence for each pass)
        ├── workflow-state.sh    # Shim to the plugin's state machine
        ├── high-level-user-stories.md
        └── roadmap.md
```

Six files. `/implement`, `/review`, the three workflow skills, the hook suite and
the state machine all ship with the plugin — nothing is copied, so nothing drifts
and there is no per-version migration to write.

```text
```

Runtime files created as you work, all gitignored: `.workflow-state.json` (phase
machine), `.workflow-log.jsonl` (audit trail), `.turn-touched` (per-turn scratch),
`.workflow-state.lock/` (write lock).

## Feature Workflow (Enforced by Hooks)

```
Phase 0: Discovery   → Research, ask questions, write the story spec (MANDATORY GATE)
Phase 1: Plan        → File inventory, contracts, risks → approval → context handoff
Phase 2: Implement   → Build in dependency order, tests alongside code
Phase 3: Review      → Review → auto-fix → re-review (COMMIT BLOCKED)
Phase 4: Commit      → Update tracking, conventional commit, report
```

### Phase tracking

```
none → discovery_started → discovery_complete → plan_created → plan_approved
     → implementation_in_progress → under_review ⇄ changes_requested
     → review_passed → complete
```

Two backward edges are allowed: `changes_requested → under_review` (re-review after
fixes) and `review_passed → under_review` (re-review after a post-pass edit).
Everything else is forward-only, and an illegal transition exits nonzero rather than
silently doing nothing.

Hooks advance the phase from observable events: a story file written, a plan file
written, an approval in chat, a source file edited after approval, a commit landing.

## The Commit Gate

`git commit` is allowed only when the phase is `review_passed` or `complete`.
**Every other outcome blocks**, including states the gate cannot evaluate:

| Situation                        | Result                             |
| -------------------------------- | ---------------------------------- |
| `review_passed` / `complete`     | allowed                            |
| no active story                  | allowed (nothing is being tracked) |
| any other phase                  | blocked, with the phase named      |
| `jq` missing or broken           | blocked, with install instructions |
| state file corrupt or unreadable | blocked, with a recovery command   |
| unrecognised phase string        | blocked                            |

The match is unanchored, so `cd frontend && git commit` is caught. The known cost:
the literal text inside an `echo` also matches.

### Passing review requires evidence

`advance review_passed` requires `--evidence <path>` naming a review report that
exists and is newer than the last source edit. Path and content hash go into the
audit log.

**Be straight with users about what this is.** It is a guardrail against drift
and accident, not an adversarial control. Anything that can write a file can
satisfy it, including the agent doing the work. What it buys is that skipping
review stops being a silent two-command shortcut and becomes an explicit act
that leaves a forged artifact in the diff. For a control an agent genuinely
cannot reach, use branch protection on the remote.

**Stuck?** `.claude/project/workflow-state.sh why-blocked` names the blockers.
If you genuinely need to commit anyway:

```bash
.claude/project/workflow-state.sh override "reason this is justified"
```

That arms a one-shot bypass and records who, when, and why in the audit log.

## Review Cycle

`/review` sets the phase to `under_review`, reviews the dimensions that apply to
the diff, and compiles the findings. Blockers move the phase to `changes_requested`,
get stored, and are fixed automatically before re-review. A clean pass sets
`review_passed` and unblocks the commit.

### The review contract

The gate does not care who reviews. It checks one thing: the phase is
`review_passed`, set with `--evidence` pointing at a report that exists and is
newer than the last source edit.

That means **any** process can satisfy it — `/review`, a deeper review tool the
team already runs, or a human reading the diff. The bundled `/review` is a
reference implementation that works with no external dependencies, not the only
option. If a stronger reviewer is available, run it, have it write a report, and
point `--evidence` at that report.

**The loop caps at 3 cycles.** A blocker that survives three fix attempts almost
always needs a design decision, so the loop stops and reports instead of spinning.
The commit stays blocked, which is the correct outcome.

## Skill Capture

When a story reaches `complete`, the Stop hook considers whether the work is
worth keeping as a project skill and offers `/skillify` if so.

It is deliberately quiet. A suggestion fires at most once per story, never when
an existing skill already covers the ground, and only when the work clears a
written bar: the pattern recurred across two or more stories, OR it encodes a
project convention discovered while building, OR the sequence is non-obvious
enough that redoing it would cost real time.

Declining is the normal outcome. A project with thirty thin skills is worse than
one with three good ones — nobody reads thirty, and every loaded skill costs
context.

## Hook Suite

One script per event, shipped in the plugin's `hooks/` and registered by
`hooks/hooks.json`:

| Event                     | Script             | Does                                                               |
| ------------------------- | ------------------ | ------------------------------------------------------------------ |
| SessionStart              | `session-start.sh` | Branch and change count, current phase and next step               |
| UserPromptSubmit          | `user-prompt.sh`   | Suggests `/implement`; detects plan approval                       |
| PreToolUse (Bash)         | `pre-bash.sh`      | Safety blockers, then the commit gate                              |
| PreToolUse (Edit\|Write)  | `pre-edit.sh`      | Secrets blocker, then the workflow gate                            |
| PostToolUse (Edit\|Write) | `post-edit.sh`     | Formats if configured, records touched types, advances phase       |
| PostToolUse (Bash)        | `post-bash.sh`     | A commit from `review_passed` completes the story                  |
| Stop                      | `stop.sh`          | Typecheck (only if TS was touched), uncommitted warning, next step |

Every script runs the safety blockers first, then a scope guard that exits silently
when the directory is not a scaffolded project, and only then the fail-closed
workflow logic. That order matters: reversed, the gate would block commits in
unrelated repositories.

The safety blockers (force-push, `reset --hard`, `clean -f`, `branch -D`,
`--no-verify`, `checkout .`) and the secrets blocker run **everywhere**, on purpose.
The workflow gate is scoped to scaffolded projects only.

## Project Tracking

| File                         | Purpose                       |
| ---------------------------- | ----------------------------- |
| `high-level-user-stories.md` | Progress tracker — START HERE |
| `roadmap.md`                 | Phased implementation plan    |
| `features/us-XXX-name.md`    | User story specifications     |
| `plans/us-XXX-plan.md`       | Implementation plans          |
| `workflow-state.sh`          | Phase state machine           |

**File naming:** lowercase in paths (`us-001-feature-name.md`), uppercase in display
text (`US-001`).

## workflow-state.sh

```
snapshot            phase, story, findings, cycle, override in one TSV line
get-phase           current phase
get-story           active story ID
get-findings-count  number of stored blockers
get-review-cycle    review cycle counter

start <ID> [title]  begin tracking a story
advance <phase>     move forward (nonzero exit on an illegal transition)
clear               reset for the next story

why-blocked         why a commit is being blocked right now
next-action         phase bar plus the next step
override <reason>   arm a one-shot, recorded commit bypass
```

## Existing Directories

Scaffolding into a populated directory offers **merge** (add only what is missing),
**overwrite** (replace all Claude Code files), or **abort**.

## Customization

After scaffolding, just ask:

> "Help me customize these templates for [your tech stack]"

Claude will adapt `CLAUDE.md`, the skills, and the test categories in
`implement.md` to your framework's conventions. Keep the workflow structure and the
hook suite intact — the gate depends on both.
