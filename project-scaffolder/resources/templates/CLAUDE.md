# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**[PROJECT_NAME]** is a [DESCRIPTION].

**Vision:** "[One-sentence future-state vision that guides decisions]"

**Current State:** This repository is **scaffolded and ready for development**. Documentation, workflow commands, and skills are in place.

### Target Users

**Primary Market:** [Define target user personas]

**Why This Matters:**

- [Key constraint affecting development]
- [Critical feature or dependency]
- [Success metric]

---

## General Principles

- **Verify before fixing** — Always read the actual code before claiming something is broken or unimplemented. Never confirm or deny claims about the codebase without thorough examination.
- **Minimal targeted fixes** — Do not modify config files, schemas, or infrastructure unless the fix specifically requires it. When in doubt, ask before making broad changes.
- **Never fabricate details** — Never guess secret names, ARNs, environment variable names, or API endpoints. Always read the actual configuration files to find correct values.
- **Match existing patterns** — When fixing tests, match the existing test setup patterns and mocking conventions already in the project.

---

## ⚠️ CRITICAL: Read Skills BEFORE Coding

**BEFORE implementing ANY feature, Claude will automatically activate relevant skills based on context.**

### 📖 Available Skills

Skills are interactive documentation that Claude activates on-demand:

1. **`.claude/skills/development-workflow/`** ⭐ CORE
   - Feature development process (5-phase workflow with mandatory gates)
   - Git workflow and conventions
   - Implementation planning templates
   - **Triggers:** "How do I implement features?", "Git workflow?", "Create implementation plan"

2. **`.claude/skills/project-standards/`**
   - User story format and acceptance criteria
   - Documentation conventions
   - Code review standards
   - **Triggers:** "User story format?", "Documentation standards?", "Acceptance criteria?"

3. **`.claude/skills/exploration-helpers/`**
   - Database exploration patterns
   - Codebase navigation guidance
   - Type validation approaches
   - **Triggers:** "Explore the database", "Understand codebase", "Validate TypeScript types"

### 🚨 Why Skills Matter

- **On-demand:** Claude activates them when context matches
- **Interactive:** Ask questions, get detailed guidance
- **Maintainable:** Update skills as patterns evolve
- **Consistent:** Same knowledge base for all development

### 🔧 Skills Maintenance (IMPORTANT)

**Claude MUST keep skills accurate and up-to-date.**

**After completing any feature, review affected skills:**

1. **Add** new patterns discovered during implementation
2. **Update** outdated information that no longer applies
3. **Remove** incorrect or misleading guidance
4. **Consolidate** redundant sections

**When to update skills:**

- New tech stack patterns established
- Better approaches discovered
- Original guidance caused issues
- Project conventions changed

**How to propose skill updates:**

```
"I noticed the [skill-name] skill says X, but we're actually doing Y.
Should I update the skill to reflect this?"
```

**Never let skills become stale** - they should always reflect current project reality.

---

## Quick Start for Claude

### Key Files & Purposes

| File/Directory          | Purpose                                     |
| ----------------------- | ------------------------------------------- |
| `CLAUDE.md`             | This file - project hub and quick reference |
| `.claude/settings.json` | Hooks for formatting, safety, and workflow  |
| `.claude/commands/`     | Workflow commands for feature development   |
| `.claude/skills/`       | Interactive skills for guidance             |
| `.claude/project/`      | Project tracking (features, plans, roadmap) |

### Project Tracking

All project management files are in `.claude/project/`:

| File                         | Purpose                                                   |
| ---------------------------- | --------------------------------------------------------- |
| `high-level-user-stories.md` | ⭐ **START HERE** - Progress tracker for all user stories |
| `roadmap.md`                 | Phased implementation plan                                |
| `features/`                  | User story specifications (`us-XXX-name.md`)              |
| `plans/`                     | Implementation plans (`us-XXX-plan.md`)                   |
| `workflow-state.sh`          | Workflow phase state machine (used by hooks)              |

### Tech Stack

**[Update with your actual tech stack]**

- **Frontend:** [Framework, version]
- **Backend:** [Framework, version]
- **Database:** [Database, version]
- **Testing:** [Test framework]

### Development Commands

```bash
# Install dependencies
[package_manager install]

# Start development
[dev command]

# Run tests
[test command]

# Build
[build command]
```

---

## Feature Development Workflow

This project follows a structured 5-phase workflow (see `development-workflow` skill):

```
Phase 0: Discovery   → Research, ask questions, create story spec (MANDATORY GATE)
Phase 1: Plan        → File inventory, contracts, risks → save plan → get approval → context handoff (MANDATORY)
Phase 2: Implement   → Build in dependency order, tests alongside code
Phase 3: Review      → Sub-agent review → auto-fix → re-review loop (COMMIT BLOCKED until passed)
Phase 4: Commit      → Update tracking, conventional commit, report
```

**Mandatory gates:**

- **No Phase 1 without a written story file** in `.claude/project/features/`. Resolve all questions first, then create the spec.
- **No Phase 2 without plan approval AND context handoff** — summarize ACs, integration points, risks, and file order before writing code.
- **No Phase 4 (commit) without review passing** — `/review` launches 4 parallel sub-agents, auto-fixes blockers, and re-reviews in a loop until clean. Hooks BLOCK `git commit` until `review_passed`.
- **Never start coding without approved plan**

### Commands

| Command      | Purpose                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| `/implement` | Full feature workflow: discovery → plan → implement → review cycle → commit      |
| `/review`    | 4-track sub-agent review with automated fix loop until all blockers are resolved |

### Workflow Phase Tracking

Phase progression is automated via hooks in `.claude/settings.json` and tracked by `.claude/project/workflow-state.sh`:

```
none → discovery_started → discovery_complete → plan_created → plan_approved → implementation_in_progress → under_review ↔ changes_requested → review_passed → complete
```

- **Story file written** → advances to `discovery_complete`
- **Plan file written** → advances to `plan_created` (warns if no story file exists)
- **User says "approved"** → advances to `plan_approved`
- **Source file edited after approval** → advances to `implementation_in_progress`
- **Source file edited before approval** → warning displayed
- **`/review` run** → advances to `under_review`, launches the sub-agent review tracks
- **Review finds blockers** → advances to `changes_requested`, stores them, auto-fixes
- **Review passes** → advances to `review_passed`, clears findings
- **Git commit** → advances to `complete` (only from `review_passed`)

Two backward edges are allowed: `changes_requested → under_review` and
`review_passed → under_review`, both for re-review. Everything else is
forward-only, and an illegal transition exits nonzero instead of silently
doing nothing.

### The commit gate

`git commit` is allowed **only** at `review_passed` or `complete`, or when no
story is being tracked. Every other outcome blocks — including states the gate
cannot evaluate:

| Situation                        | Result                             |
| -------------------------------- | ---------------------------------- |
| `review_passed` / `complete`     | allowed                            |
| no active story                  | allowed                            |
| any other phase                  | blocked, with the phase named      |
| `jq` missing or broken           | blocked, with install instructions |
| state file corrupt or unreadable | blocked, with a recovery command   |
| unrecognised phase string        | blocked                            |

The match is unanchored, so `cd frontend && git commit` is caught too.

Stuck? `.claude/project/workflow-state.sh why-blocked` names the blockers. If
you genuinely need to commit anyway, arm a recorded one-shot bypass:

```bash
.claude/project/workflow-state.sh override "reason this is justified"
```

Run `.claude/project/workflow-state.sh clear` between stories to reset.

---

## Development Workflow

### For EVERY Feature:

1. ✅ **Read relevant skills** - Ask about the topic, Claude activates appropriate skill
2. ✅ **Review existing patterns** - Check similar code in the codebase
3. ✅ **Implement following standards** - Follow patterns from skills
4. ✅ **Write tests** - Follow testing patterns
5. ✅ **Verify quality gates pass** - Lint, test, build
6. ✅ **Commit with conventional format** - feat:, fix:, chore:, etc.

**If you deviate from standards:**

- Document WHY in code comments
- Propose update to the skill if pattern is better
- Get user approval for major changes

---

## Claude Code Agent Usage

### When to Use Specialized Agents

**DO use agents for:**

- Complex multi-step implementation
- Codebase exploration
- Security reviews
- Creating comprehensive test suites

**DON'T use agents for:**

- Reading a specific file path (use Read tool)
- Searching for specific class/function (use Glob/Grep)
- Single straightforward tasks

### Recommended Agents

- **Explore Agent** - Codebase navigation
- **backend-api-engineer** - API implementation
- **solution-architect** - Architectural decisions
- **qa-automation-engineer** - Testing strategy
- **security-privacy-engineer** - Security reviews

---

## Git Workflow

**Branching:** Feature branches (`feature/<description>`)

**Commits:** Conventional Commits format

```bash
git commit -m "feat: add [feature name]

- [Implementation detail]
- [Implementation detail]
"
```

**Types:** `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`

**IMPORTANT:** Never use `--no-verify` to bypass pre-commit hooks. Always fix the root cause.

---

## Project Structure

```
[PROJECT_NAME]/
├── CLAUDE.md                    # This file
├── .claude/
│   ├── settings.json            # Hooks for formatting, safety, workflow
│   ├── commands/                # Workflow commands
│   │   ├── implement.md         # Full 5-phase feature workflow
│   │   └── review.md            # Sub-agent review with auto-fix loop
│   ├── skills/                  # Interactive skills
│   │   ├── development-workflow/
│   │   ├── project-standards/
│   │   └── exploration-helpers/
│   └── project/                 # Project tracking
│       ├── features/            # User story specs (us-XXX-name.md)
│       ├── plans/               # Implementation plans (us-XXX-plan.md)
│       ├── hooks/               # One script per hook event
│       ├── workflow-state.sh    # Phase state machine
│       ├── high-level-user-stories.md  # Progress tracker
│       └── roadmap.md           # Project roadmap
└── [your source code...]
```

---

## Pre-Commit Verification Checklist

Before committing any changes:

1. **TYPE SAFETY**: Run type checking. Zero errors.
2. **LINT**: Run linter. Zero warnings.
3. **TESTS**: Run test suite. All pass. Never dismiss failures as "pre-existing" without proof.
4. **APPROACH**: Before modifying any config file or infrastructure code, state the intended change and WHY. Prefer minimal targeted fixes over broad refactors.

Only proceed with `git commit` (never use `--no-verify`) after ALL checks pass.

---

## Next Steps

1. **Customize CLAUDE.md** - Update project overview, tech stack, commands
2. **Add source code** - Create your src/, app/, lib/ directories
3. **Start implementing** - Run `/implement` to begin your first feature
4. **Customize skills** - Adapt skills to your specific tech stack

**Tip:** Ask Claude:

> "Help me customize these templates for [your-tech-stack]"

---

**This document will evolve as the project is implemented. Update it when new patterns emerge or architectural decisions are made.**
