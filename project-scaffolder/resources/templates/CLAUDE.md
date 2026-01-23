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

## ⚠️ CRITICAL: Read Skills BEFORE Coding

**BEFORE implementing ANY feature, Claude will automatically activate relevant skills based on context.**

### 📖 Available Skills

Skills are interactive documentation that Claude activates on-demand:

1. **`.claude/skills/development-workflow/`** ⭐ CORE
   - Feature development process (10-step SOP)
   - Git workflow and conventions
   - Implementation planning templates
   - **Triggers:** "How do I implement features?", "Git workflow?", "Create implementation plan"

2. **`.claude/skills/project-standards/`** (Full mode only)
   - User story format and acceptance criteria
   - Documentation conventions
   - Code review standards
   - **Triggers:** "User story format?", "Documentation standards?", "Acceptance criteria?"

3. **`.claude/skills/exploration-helpers/`** (Full mode only)
   - Database exploration patterns
   - Codebase navigation guidance
   - Type validation approaches
   - **Triggers:** "Explore the database", "Understand codebase", "Validate TypeScript types"

### 🚨 Why Skills Matter

- **On-demand:** Claude activates them when context matches
- **Interactive:** Ask questions, get detailed guidance
- **Maintainable:** Update skills as patterns evolve
- **Consistent:** Same knowledge base for all development

---

## Quick Start for Claude

### Key Files & Purposes

| File/Directory               | Purpose                                     |
| ---------------------------- | ------------------------------------------- |
| `CLAUDE.md`                  | This file - project hub and quick reference |
| `.claude-plugin/plugin.json` | Plugin manifest (points to .claude/)        |
| `.claude/commands/`          | Workflow commands for feature development   |
| `.claude/hooks/hooks.json`   | Enforces story → plan → approve → build     |
| `.claude/skills/`            | Interactive skills for guidance             |
| `.claude/project/`           | Project tracking (features, plans, roadmap) |

### Project Tracking

All project management files are in `.claude/project/`:

| File                         | Purpose                                                   |
| ---------------------------- | --------------------------------------------------------- |
| `high-level-user-stories.md` | ⭐ **START HERE** - Progress tracker for all user stories |
| `roadmap.md`                 | Phased implementation plan                                |
| `features/`                  | User story specifications (`us-XXX-name.md`)              |
| `plans/`                     | Implementation plans (`us-XXX-plan.md`)                   |

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

This project enforces a structured workflow via hooks:

```
1. Story  → Create in .claude/project/features/
2. Plan   → Create in .claude/project/plans/
3. Approve → Get user approval before coding
4. Build  → Implement following the plan
```

**When you ask to build a feature, Claude will first create the story and plan.**

### 🚀 Quick Start with `/implement`

Run `/implement` to start the complete workflow:

```
/implement
```

This orchestrates all phases automatically with approval gates.

### 📋 Individual Phase Commands

1. **Phase 1+2: Discovery** → `/discovery`
   - Explores current app state
   - Reads documentation and standards
   - Asks clarifying questions

2. **Phase 3: Plan & Validate** → `/plan-and-validate`
   - Creates detailed implementation plan
   - Validates against schema and types
   - Presents plan for approval

3. **Phase 4: Implementation** → `/start-implementation`
   - Implements from approved plan
   - Tests comprehensively
   - Documents and commits

4. **Phase 4.5: Review** → `/review-implementation`
   - Reviews code quality
   - Checks standards compliance
   - Validates test coverage

### ⚡ Navigation Helper

Use `/next` to automatically proceed to the next phase.

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

---

## Project Structure

```
[PROJECT_NAME]/
├── CLAUDE.md                    # This file
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (points to .claude/)
├── .claude/
│   ├── commands/                # Workflow commands
│   │   ├── implement.md
│   │   ├── discovery.md
│   │   ├── plan-and-validate.md
│   │   ├── start-implementation.md
│   │   ├── review-implementation.md
│   │   └── next.md
│   ├── hooks/
│   │   └── hooks.json           # Workflow enforcement
│   ├── skills/                  # Interactive skills
│   │   ├── development-workflow/
│   │   ├── project-standards/   # Full mode only
│   │   └── exploration-helpers/ # Full mode only
│   └── project/                 # Project tracking
│       ├── features/            # User story specs (us-XXX-name.md)
│       ├── plans/               # Implementation plans (us-XXX-plan.md)
│       ├── high-level-user-stories.md  # Progress tracker
│       └── roadmap.md           # Project roadmap
└── [your source code...]
```

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
