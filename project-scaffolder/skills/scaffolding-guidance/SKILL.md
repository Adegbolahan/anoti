---
name: Scaffolding Guidance
description: |
  Use this skill when the user asks about project scaffolding, CLAUDE.md templates, project tracking, or how to use the project-scaffolder plugin. Triggers on: "How do I scaffold a project?", "What templates are available?", "CLAUDE.md best practices", "project tracking", "user story management".
version: 2.1.0
---

# Project Scaffolding Guidance

## Commands

### `/new`

Scaffold a new project with Claude Code documentation, workflow commands, skills, and project tracking.

```
/new
```

Prompts for target directory and project name. Creates full project structure.

### `/update`

Update Claude Code files in an existing scaffolded project to the latest version.

```
/update
```

Detects current version, shows what's changed, lets you choose what to update. Preserves CLAUDE.md and project tracking files.

## What Gets Created

```
project/
├── CLAUDE.md                    # Project hub
└── .claude/
    ├── settings.json            # Hooks for formatting, safety, workflow, commit gate
    ├── commands/                # 2 workflow commands
    │   ├── implement.md         # Full 5-phase feature workflow
    │   └── review.md            # Sub-agent review with auto-fix loop
    ├── skills/                  # 3 interactive skills
    │   ├── development-workflow/
    │   ├── project-standards/
    │   └── exploration-helpers/
    └── project/                 # Project tracking
        ├── features/            # User story specs
        ├── plans/               # Implementation plans
        ├── workflow-state.sh    # Phase state machine (with review cycle)
        ├── high-level-user-stories.md
        └── roadmap.md
```

## Feature Workflow (Enforced by Hooks)

When you ask to build a feature, the hooks enforce a 5-phase workflow:

```
Phase 0: Discovery   → Research, ask questions, create story spec (MANDATORY GATE)
Phase 1: Plan        → File inventory, contracts, risks → save plan → approval → context handoff (MANDATORY)
Phase 2: Implement   → Build in dependency order, tests alongside code
Phase 3: Review      → Sub-agent review → auto-fix → re-review loop (COMMIT BLOCKED until passed)
Phase 4: Commit      → Update tracking, conventional commit, report
```

**Mandatory gates:**

- No Phase 1 without a written story file
- No Phase 2 without plan approval AND a context handoff summary
- No Phase 4 (commit) without review passing — hooks BLOCK `git commit` until `review_passed`

### Workflow Phase Tracking

Phase progression is automated via hooks and tracked by `workflow-state.sh`:

```
none → discovery_started → discovery_complete → plan_created → plan_approved → implementation_in_progress → under_review ↔ changes_requested → review_passed → complete
```

Hooks auto-advance phases based on file operations (story written, plan written, code edited, committed). The review cycle (`under_review ↔ changes_requested`) is the only allowed backward transition.

### Review Cycle

The `/review` command:

1. Sets state to `under_review`
2. Launches 4 parallel sub-agent review tracks (backend, frontend, tests, security)
3. If blockers found → sets `changes_requested`, stores findings, auto-fixes, re-runs review
4. If clean → sets `review_passed`, unblocks commit

Commits are BLOCKED by hooks during `implementation_in_progress`, `under_review`, and `changes_requested`.

## Project Tracking

| File                         | Purpose                       |
| ---------------------------- | ----------------------------- |
| `high-level-user-stories.md` | Progress tracker - START HERE |
| `roadmap.md`                 | Phased implementation plan    |
| `features/us-XXX-name.md`    | User story specifications     |
| `plans/us-XXX-plan.md`       | Implementation plans          |
| `workflow-state.sh`          | Phase state machine           |

### File Naming

- **Filenames:** lowercase (`us-001-feature-name.md`)
- **Display:** UPPERCASE (`US-001`)

## Workflow Commands

| Command      | Purpose                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| `/implement` | Full feature workflow: discovery → plan → implement → review cycle → commit      |
| `/review`    | 4-track sub-agent review with automated fix loop until all blockers are resolved |

## Hook Suite

The scaffolded `settings.json` includes:

| Hook Event               | Purpose                                                                             |
| ------------------------ | ----------------------------------------------------------------------------------- |
| SessionStart             | Shows branch info and current workflow phase                                        |
| UserPromptSubmit         | Suggests /implement for feature requests; detects plan approval                     |
| PreToolUse (Bash)        | Blocks force-push, --no-verify, git reset --hard; **commit gate** enforces review   |
| PreToolUse (Edit/Write)  | Blocks editing secrets; warns on source edits before plan approval or during review |
| PostToolUse (Edit/Write) | Auto-formats code; runs tsc on TS files; advances workflow phases; tracks fixes     |
| PostToolUse (Bash)       | Detects git commit → marks story complete (only from `review_passed`)               |
| Stop                     | Warns about uncommitted changes; shows next workflow action                         |

## Skills

| Skill                  | Location          | Triggers                       |
| ---------------------- | ----------------- | ------------------------------ |
| `development-workflow` | `.claude/skills/` | Feature process, git, planning |
| `project-standards`    | `.claude/skills/` | User stories, documentation    |
| `exploration-helpers`  | `.claude/skills/` | Database, codebase, types      |

## Existing Directories

When scaffolding into an existing directory:

- **Merge** - Skip existing files, add only missing
- **Overwrite** - Replace all Claude Code files
- **Abort** - Cancel scaffolding

## Customization

After scaffolding, ask the `template-customizer` agent:

> "Help me customize these templates for [your-tech-stack]"
