# Quick Reference Guide

## File Purposes

### In This Repository

| File | Purpose | Who Uses It |
|------|---------|-------------|
| `CLAUDE.md.EXAMPLE` | Minimal production template (421 lines) | **Claude Code copies this** when creating CLAUDE.md |
| `CLAUDE.md.TEMPLATE` | Teaching tool with explanations (1,397 lines) | **Humans read this** to understand WHY |
| `scaffold-project.py` | Scaffolding script | **Developers run this** to set up new projects |
| `README.md` | Complete guide | **Developers read this** for instructions |
| `QUICK-REFERENCE.md` | This file | **Quick lookup** for common tasks |

### Scaffolded Project Structure

```
your-new-project/
├── CLAUDE.md                              # ⭐ Customize [placeholders]
├── README-GETTING-STARTED.md              # 📋 Your next steps checklist
├── .claude/
│   └── commands/                          # 🎭 6 slash commands for workflow
│       ├── implement.md                   # Orchestrator (all phases)
│       ├── discovery.md                   # Phase 1+2: Requirements + Architecture
│       ├── plan-and-validate.md           # Phase 3+3.5: Plan + Validate (MANDATORY)
│       ├── start-implementation.md        # Phase 4: Implementation
│       ├── review-implementation.md       # Phase 4.5: Code review (OPTIONAL)
│       └── next.md                        # Helper
└── docs/
    ├── features/                          # 📁 User stories (us-XXX-name.md)
    ├── plans/                             # 📁 Implementation plans (us-XXX-plan.md)
    │
    ├── Generic Docs (ready to use)
    │   ├── git-workflow.md                # ✅ Git conventions
    │   ├── feature-development-process.md # ✅ 10-step SOP with plan integration
    │   ├── user-story-standards.md        # ✅ User story format & ID conventions
    │   ├── implementation-plan-template.md# ✅ 10-section plan template
    │   ├── high-level-user-stories.md     # ✅ Central progress tracker
    │   └── documentation-standard.md      # ✅ Markdown guidelines
    │
    ├── Project-Specific (TODO: fill in)
    │   ├── architecture.md                # 📝 Your system design
    │   ├── development.md                 # 📝 Setup & commands
    │   ├── roadmap.md                     # 📝 Implementation phases
    │   └── implementation-notes.md        # 📝 Project gotchas
    │
    └── Pattern Docs (TODO: customize for your stack)
        ├── coding-standards.md            # 🔧 P0 - Language conventions
        ├── testing-patterns.md            # 🔧 P0 - Test patterns
        ├── api-patterns.md                # 🔧 P0 - API design
        ├── component-patterns.md          # 🔧 P0 - UI patterns
        ├── database-patterns.md           # 🔧 P1 - DB patterns
        ├── state-management-patterns.md   # 🔧 P1 - State patterns
        ├── styling-patterns.md            # 🔧 P1 - CSS patterns
        ├── error-handling-patterns.md     # 🔧 P1 - Error patterns
        ├── performance-patterns.md        # 🔧 P2 - Performance
        ├── async-patterns.md              # 🔧 P2 - Async patterns
        └── logging-patterns.md            # 🔧 P2 - Logging
```

## Installation (One-Time Setup)

```bash
cd $HOME/Code/getting-started-claude
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

Now you can run `claude-scaffold` from anywhere!

---

## Feature Workflow Commands

Run `/implement` to execute the complete 4-phase workflow with mandatory reviews:

```bash
# In Claude Code
/implement

# Or run phases individually
/discovery               # Phase 1+2: Requirements + Architecture
/plan-and-validate       # Phase 3+3.5: Plan + Validate (MANDATORY)
/start-implementation    # Phase 4: Execute implementation
/review-implementation   # Phase 4.5: Review code (OPTIONAL)
/next                    # Helper: Proceed to next phase
```

### User Story ID Convention

- **UPPERCASE** (`US-003`) for: tables, display text, documentation
- **lowercase** (`us-003`) for: filenames, file paths

```markdown
# ✅ Correct
| US-003 | Feature | [Link](features/us-003-name.md) |

# ❌ Wrong
| us-003 | Feature | [Link](features/US-003-name.md) |
```

See `docs/user-story-standards.md#user-story-id-conventions` for details.

---

## Common Tasks

### Create a New Project

```bash
# If installed (recommended)
claude-scaffold ~/Code/my-new-project
cd ~/Code/my-new-project

# Or without installation
python $HOME/Code/getting-started-claude/scaffold-project.py ~/Code/my-new-project
cd ~/Code/my-new-project
```

### Minimal Scaffolding (Just Essentials)

```bash
# If installed
claude-scaffold-minimal ~/Code/my-new-project

# Or without installation
python $HOME/Code/getting-started-claude/scaffold-project.py ~/Code/my-new-project --minimal
```

### Migrate Existing CLAUDE.md

```bash
# In your project directory
claude code

# Prompt:
"Migrate my CLAUDE.md to the structure in
$HOME/Code/getting-started-claude/templates/CLAUDE.md.EXAMPLE
PRESERVE all existing content, ADD missing sections, keep concise"
```

### Generate a Pattern Doc

```bash
claude code

# Prompt:
"Using CLAUDE.md.TEMPLATE Section 12 as reference, create
coding-standards.md for [Python + FastAPI / TypeScript + React / etc]
with ❌ wrong vs ✅ correct code examples"
```

## Priority Checklist for New Projects

### Day 1: Core Setup
- [ ] Run scaffolder: `python scaffold-project.py <project-path>`
- [ ] Customize CLAUDE.md (replace all `[placeholders]`)
- [ ] Fill in `docs/architecture.md` (tech stack, system design)
- [ ] Fill in `docs/development.md` (setup commands)

### Week 1: Pattern Docs (P0)
- [ ] `docs/coding-standards.md` (affects ALL code)
- [ ] `docs/testing-patterns.md` (quality gates)
- [ ] `docs/api-patterns.md` (if building APIs)
- [ ] `docs/component-patterns.md` (if building UI)

### Week 2: Pattern Docs (P1)
- [ ] `docs/database-patterns.md` (if using database)
- [ ] `docs/error-handling-patterns.md`
- [ ] `docs/performance-patterns.md`
- [ ] `docs/state-management-patterns.md` (if complex state)
- [ ] `docs/styling-patterns.md` (if custom UI)

### Week 3: Project Docs & Workflow
- [ ] `docs/roadmap.md` (implementation phases)
- [ ] Update `docs/high-level-user-stories.md` (central tracker is pre-created)
- [ ] Add user story specs to `docs/features/` (format: `us-XXX-name.md`)
- [ ] Try `/implement` workflow for first feature
- [ ] Review implementation plans in `docs/plans/`

### Ongoing
- [ ] Use `/implement` for all new features
- [ ] Update `docs/high-level-user-stories.md` with plan status
- [ ] Update `docs/implementation-notes.md` with gotchas
- [ ] Add remaining pattern docs (async, logging) as needed
- [ ] Track actual vs estimated effort in plans

## When to Use What

### Use CLAUDE.md.EXAMPLE When:
- ✅ Creating CLAUDE.md for a new project
- ✅ You want a minimal starting point (<500 lines)
- ✅ You'll customize `[placeholders]` for your project

### Use CLAUDE.md.TEMPLATE When:
- ✅ Learning what makes a good CLAUDE.md
- ✅ Understanding WHY each section matters
- ✅ Getting detailed examples and "Quick Guide" tips
- ✅ Generating content for pattern docs (Section 12)

### Use Scaffolder When:
- ✅ Starting a brand new project
- ✅ You want complete directory structure
- ✅ You need all 11 pattern doc placeholders

### Manual Setup When:
- ✅ Adding Claude Code to existing project
- ✅ You only need CLAUDE.md (not full scaffolding)
- ✅ Your project has unusual structure

## Pattern Doc Priority

**P0 (Must Have)** - Blocks development:
- coding-standards.md
- testing-patterns.md
- api-patterns.md (if backend)
- component-patterns.md (if frontend)

**P1 (Should Have)** - Improves quality:
- database-patterns.md
- error-handling-patterns.md
- performance-patterns.md
- state-management-patterns.md
- styling-patterns.md

**P2 (Nice to Have)** - Useful but not blocking:
- async-patterns.md
- logging-patterns.md

## Code Examples Format

All pattern docs should follow this format:

```markdown
### [Pattern Name]

**[Brief description of when to use]**

```[language]
# ❌ WRONG - [what's wrong]
[bad code example]

# ✅ CORRECT - [why this is better]
[good code example]
```

**Why this matters:** [Explanation]
```

## Troubleshooting

### "Templates directory not found"
- Make sure you're running `scaffold-project.py` from the `getting-started-claude` directory
- Or specify full path: `python /path/to/scaffold-project.py <target>`

### "CLAUDE.md too long"
- Link to detailed docs instead of duplicating content
- Move code examples to pattern docs
- Target: 400-500 lines (like CLAUDE.md.EXAMPLE)

### "Pattern docs are empty"
- They're placeholders - you need to fill them with tech stack-specific examples
- Ask Claude Code: "Create [pattern-doc-name].md for [tech stack]"
- See CLAUDE.md.TEMPLATE Section 12 for examples

### "Generic docs need customization"
- git-workflow.md works for most projects (adjust branching if needed)
- feature-development-process.md is universal (can use as-is)
- user-story-standards.md is universal (can use as-is)

## File Size Guidelines

| File | Target Size | Max Size |
|------|------------|----------|
| CLAUDE.md | 400-500 lines | 600 lines |
| Pattern docs | 200-400 lines | 500 lines |
| Project docs | 100-300 lines | 400 lines |
| Generic docs | 300-500 lines | N/A (stable) |

**If CLAUDE.md exceeds 600 lines:** Extract sections to separate docs and link from CLAUDE.md

## Resources

- **Claude Code Docs:** https://docs.claude.com/en/docs/claude-code
- **This Repo:** `$HOME/Code/getting-started-claude`
- **Example Implementation:** `$HOME/Code/taadablogistics/CLAUDE.md`

---

**Pro Tip:** Keep this file open in a second window when setting up a new project!
