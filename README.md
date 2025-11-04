# Getting Started with Claude Code

This repository contains templates and tools for scaffolding new projects with Claude Code documentation.

## 📦 What's Included

```
getting-started-claude/
├── README.md                    # This file
├── scaffold-project.py          # Scaffolding script
└── templates/
    ├── CLAUDE.md.EXAMPLE        # Minimal production-ready CLAUDE.md (421 lines)
    ├── CLAUDE.md.TEMPLATE       # Detailed teaching template (1397 lines)
    ├── .claude/
    │   └── commands/            # Slash commands for feature workflow
    │       ├── implement.md                    # Workflow orchestrator (all phases)
    │       ├── discovery.md                    # Phase 1+2: Requirements + Architecture
    │       ├── plan-and-validate.md            # Phase 3+3.5: Plan + Validation (MANDATORY)
    │       ├── start-implementation.md         # Phase 4: Execute implementation
    │       ├── review-implementation.md        # Phase 4.5: Review code (MANDATORY)
    │       └── next.md                         # Helper: Proceed to next phase
    └── docs/
        ├── git-workflow.md                     # Generic Git workflow
        ├── feature-development-process.md      # 10-step feature process
        ├── user-story-standards.md             # User story format & ID conventions
        ├── implementation-plan-template.md     # Template for implementation plans
        ├── high-level-user-stories.md          # Central progress tracker
        ├── documentation-standard.md           # Markdown & doc guidelines
        └── plans/
            └── .gitkeep                        # Implementation plans directory
```

## 📦 Installation

### Option 1: Automatic Installation (Recommended)

Run the install script to add global aliases:

```bash
cd $HOME/Code/getting-started-claude
./install.sh
```

This adds aliases to your shell config (`~/.zshrc` or `~/.bashrc`):
- `claude-scaffold <path>` - Full scaffolding
- `claude-scaffold-minimal <path>` - Minimal scaffolding

**After installation, reload your shell:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

**Then you can run from anywhere:**
```bash
claude-scaffold ~/Code/my-new-project
```

### Option 2: Manual Setup

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Claude Code Scaffolder
alias claude-scaffold='python3 $HOME/Code/getting-started-claude/scaffold-project.py'
alias claude-scaffold-minimal='python3 $HOME/Code/getting-started-claude/scaffold-project.py --minimal'
```

Then reload: `source ~/.zshrc`

### Option 3: Direct Execution (No Installation)

```bash
cd $HOME/Code/getting-started-claude
python scaffold-project.py /path/to/new-project
```

---

## 🚀 Quick Start

### Option 1: Scaffold a New Project

```bash
# If installed (recommended)
claude-scaffold /path/to/new-project
claude-scaffold-minimal /path/to/new-project

# Or direct execution
python $HOME/Code/getting-started-claude/scaffold-project.py /path/to/new-project
```

**What it creates:**
- `CLAUDE.md` - Main guidance file (based on CLAUDE.md.EXAMPLE)
- `.claude/commands/` - 8 slash commands for feature workflow orchestration
- `docs/` - Documentation directory with:
  - Generic docs (git-workflow, feature-development-process, user-story-standards)
  - Progress tracking (high-level-user-stories.md)
  - Implementation plan template
  - `features/` directory for user stories
  - `plans/` directory for implementation plans
  - Placeholders for project-specific docs (architecture, development, roadmap)
  - Placeholders for 11 pattern documents (need tech stack customization)
- `README-GETTING-STARTED.md` - Next steps checklist

### Option 2: Manually Copy Files

If you prefer manual setup:

```bash
# 1. Copy CLAUDE.md.EXAMPLE to your project
cp templates/CLAUDE.md.EXAMPLE /path/to/your-project/CLAUDE.md

# 2. Copy generic docs
mkdir -p /path/to/your-project/docs
cp templates/docs/*.md /path/to/your-project/docs/

# 3. Customize CLAUDE.md (replace [placeholders])
```

### Option 3: Migrate Existing CLAUDE.md

If you have an existing CLAUDE.md and want to upgrade it:

```bash
# In your project directory, use Claude Code with this prompt:
claude code

# Then say:
"Migrate my existing CLAUDE.md to the improved structure in
$HOME/Code/getting-started-claude/templates/CLAUDE.md.EXAMPLE

IMPORTANT:
1. PRESERVE all existing project-specific content
2. ADD any missing sections from CLAUDE.md.EXAMPLE
3. UPDATE Required Reading to include all 11 pattern documents
4. REORGANIZE to match CLAUDE.md.EXAMPLE structure
5. Keep concise (~400-500 lines) - link to detailed docs"
```

## 📚 Template Documentation

### CLAUDE.md.EXAMPLE vs CLAUDE.md.TEMPLATE

**CLAUDE.md.EXAMPLE (421 lines)**
- ✅ Production-ready, minimal structure
- ✅ Uses `[placeholders]` for easy customization
- ✅ For Claude Code to COPY when creating CLAUDE.md
- ✅ Based on real-world successful implementation
- 📄 **Use this** when scaffolding new projects

**CLAUDE.md.TEMPLATE (1,397 lines)**
- 📖 Teaching/reference tool for humans
- 📖 Detailed explanations of WHY each section matters
- 📖 "Quick Guide" sections with best practices
- 📖 Section 12 with tons of code examples
- 📖 **Read this** to understand what makes a good CLAUDE.md

**Summary:**
- **Creating CLAUDE.md?** → Use **CLAUDE.md.EXAMPLE** (copy & customize)
- **Learning about CLAUDE.md?** → Read **CLAUDE.md.TEMPLATE** (understand WHY)

### Pattern Documents Hierarchy

**Generic (same across projects):**
- ✅ `git-workflow.md` - Git conventions and workflows
- ✅ `feature-development-process.md` - 10-step feature development SOP
- ✅ `user-story-standards.md` - User story format, acceptance criteria, and ID conventions
- ✅ `implementation-plan-template.md` - Template for comprehensive implementation plans
- ✅ `high-level-user-stories.md` - Central progress tracker for all user stories and plans
- ✅ `documentation-standard.md` - Markdown formatting and documentation guidelines

**Tech Stack-Specific (require customization):**
- 🔧 `coding-standards.md` - Language conventions for your stack
- 🔧 `component-patterns.md` - Framework-specific patterns
- 🔧 `state-management-patterns.md` - State library patterns
- 🔧 `styling-patterns.md` - CSS/styling approach
- 🔧 `api-patterns.md` - API design patterns
- 🔧 `database-patterns.md` - Database/ORM patterns
- 🔧 `testing-patterns.md` - Testing framework patterns

**Universal Runtime Patterns (generic but need code examples):**
- 🌐 `error-handling-patterns.md` - Error handling across stack
- 🌐 `performance-patterns.md` - Performance optimization
- 🌐 `async-patterns.md` - Async/await patterns
- 🌐 `logging-patterns.md` - Logging and observability

**Project-Specific (not templates):**
- 📝 `architecture.md` - Your system design
- 📝 `development.md` - Setup and dev commands
- 📝 `roadmap.md` - Implementation phases
- 📝 `implementation-notes.md` - Project gotchas
- 📁 `features/` - User story files (naming: `us-XXX-<name>.md`)
- 📁 `plans/` - Implementation plan files (naming: `us-XXX-plan.md`)

## 🎯 Workflow: Setting Up a New Project

### Step 1: Scaffold

```bash
python scaffold-project.py ~/Code/my-new-project
cd ~/Code/my-new-project
```

### Step 2: Customize CLAUDE.md

Replace all `[placeholders]`:

```markdown
# Before
**[Project Name]** is a [brief description]

# After
**TaskFlow** is a project management SaaS platform
```

Key placeholders to replace:
- `[Project Name]` → Your project name
- `[Python/TypeScript/etc]` → Your languages
- `[React/Vue/Svelte]` → Your frontend framework
- `[Redux/Pinia/Zustand]` → Your state management
- `[Tailwind/CSS-in-JS/etc]` → Your styling approach
- Remove optional sections if not applicable

### Step 3: Fill Pattern Documents

For each pattern doc in `docs/`, add tech stack-specific examples:

**Priority Order:**
1. **coding-standards.md** (P0 - affects all code)
2. **testing-patterns.md** (P0 - quality gates)
3. **api-patterns.md** (P0 - backend)
4. **component-patterns.md** (P0 - frontend)
5. **database-patterns.md** (P1 - if using database)
6. **error-handling-patterns.md** (P1)
7. **performance-patterns.md** (P1)
8. Remaining pattern docs (P2)

**Tip:** Ask Claude Code:
```
"Using CLAUDE.md.TEMPLATE Section 12 as reference, create
coding-standards.md for my [tech stack] with code examples"
```

### Step 4: Add Project-Specific Docs

Fill in:
- `architecture.md` - System design and data flow
- `development.md` - Setup instructions and commands
- `roadmap.md` - Implementation phases
- `high-level-user-stories.md` - User story tracker

### Step 5: Start Coding

```bash
claude code

# Tell Claude Code:
"Read CLAUDE.md and implement the user authentication feature following our standards"
```

Claude will:
1. Read CLAUDE.md to understand your project
2. Read relevant pattern docs before coding
3. Follow your conventions and standards
4. Generate quality code that fits your project

---

## 🎭 Feature Workflow with Slash Commands

The scaffolder creates 8 slash commands that orchestrate a comprehensive 4-phase feature development workflow:

### Available Commands

**Main Orchestrator:**
- `/implement` - Run complete workflow (all phases + mandatory reviews)

**Individual Phases:**
- `/discovery` - Phase 1+2: Requirements gathering + Architecture review
- `/plan-and-validate` - Phase 3+3.5: Create plan + Validate (⚠️ MANDATORY before coding)
- `/start-implementation` - Phase 4: Execute implementation from plan
- `/review-implementation` - Phase 4.5: Review code (⚠️ MANDATORY before commit)
- `/next` - Helper to proceed to next phase

### Complete Workflow

```
┌─────────────────────────────────────────────────────────┐
│ PHASE 1+2: DISCOVERY                                   │
│ Command: /discovery                                     │
│                                                         │
│ Requirements Gathering:                                │
│ • Explore current app state                            │
│ • Read user story documentation                        │
│ • Ask informed clarifying questions                    │
│                                                         │
│ Architecture Review:                                   │
│ • Read standards documents                             │
│ • Review database schema                               │
│ • Explore API layer patterns                           │
│ • Review component patterns                            │
│ • Present discovery summary                            │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ PHASE 3+3.5: PLAN & VALIDATE                           │
│ Command: /plan-and-validate                             │
│                                                         │
│ Create Plan:                                           │
│ • Create comprehensive implementation plan (10 sections)│
│ • Define database changes                              │
│ • Define API layer changes                             │
│ • Define component architecture                        │
│ • Identify edge cases and testing strategy             │
│                                                         │
│ Validate Plan (MANDATORY):                             │
│ • Validate against database schema                     │
│ • Validate type definitions                            │
│ • Validate standards compliance                        │
│ • Validate user story alignment                        │
│ • Auto-fix issues found                                │
│ • Present validated plan for approval                  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ PHASE 4: IMPLEMENTATION                                │
│ Command: /start-implementation                          │
│                                                         │
│ • Create todos from plan checklist                     │
│ • Implement database migrations                        │
│ • Implement API layer                                  │
│ • Implement components                                 │
│ • Add polish and accessibility                         │
│ • Test comprehensively                                 │
│ • Document and commit                                  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ PHASE 4.5: IMPLEMENTATION REVIEW (⚠️ OPTIONAL)         │
│ Command: /review-implementation                         │
│                                                         │
│ • Uses specialized agent for code review               │
│ • Validate against user story and plan                │
│ • Run tests and build                                  │
│ • List issues to fix before commit                    │
│ • Recommended before commit                            │
└─────────────────────────────────────────────────────────┘
```

### User Story ID Conventions

The templates enforce a specific case convention:

- **Use UPPERCASE** (`US-003`) for: tables, display text, documentation
- **Use lowercase** (`us-003`) for: filenames, file paths, directories

**Examples:**
```markdown
# Table entry (uppercase)
| US-003 | View Conversations | [Link](features/us-003-view-conversations.md) |

# File paths (lowercase)
docs/features/us-003-view-conversations.md
docs/plans/us-003-plan.md
```

See `docs/user-story-standards.md#user-story-id-conventions` for full details.

### Implementation Plans

Every feature gets a comprehensive implementation plan:

**Location:** `docs/plans/us-XXX-plan.md`

**Includes:**
1. Requirements Summary
2. Technical Approach
3. Database Changes
4. API Layer Implementation
5. Component Architecture
6. State Management
7. Edge Cases & Error Handling
8. Testing Strategy
9. Implementation Checklist (becomes todos)
10. Estimated Effort & Risks

**Plan Lifecycle:**
- Draft → Approved → In Progress → Complete

**Tracking:**
Plans are tracked alongside user stories in `docs/high-level-user-stories.md`:
```markdown
| ID | Feature | Story File | Plan File | Plan Status | Status | Commit |
|----|---------|------------|-----------|-------------|--------|--------|
| US-003 | View Conversations | [Link](features/us-003-name.md) | [Link](plans/us-003-plan.md) | ✅ Approved | 🚧 In Progress | - |
```

---

## 💡 Tips & Best Practices

### Keep CLAUDE.md Concise

- ✅ DO: Link to detailed docs in `/docs/`
- ❌ DON'T: Duplicate entire pattern docs in CLAUDE.md
- 🎯 Target: ~400-500 lines (like CLAUDE.md.EXAMPLE)

### Hub-and-Spoke Documentation

```
CLAUDE.md (hub)
    ├─→ docs/coding-standards.md
    ├─→ docs/component-patterns.md
    ├─→ docs/testing-patterns.md
    ├─→ docs/api-patterns.md
    └─→ ... (other pattern docs)
```

CLAUDE.md is the **index** - detailed patterns live in `/docs/`

### Pattern Doc Content

Each pattern doc should include:

1. **Overview** - What this pattern is
2. **Code Examples** - ❌ Wrong vs ✅ Correct
3. **Common Use Cases** - When to use this pattern
4. **Anti-Patterns** - What NOT to do
5. **Gotchas** - Edge cases and pitfalls

### Evolution

Update docs as your project grows:
- Add new gotchas to `implementation-notes.md`
- Update patterns when better approaches emerge
- Keep user story tracker current

## 🔧 Customizing the Scaffolder

### Add Your Own Templates

To add more generic docs:

1. Add template to `templates/docs/`
2. Update `GENERIC_DOCS` list in `scaffold-project.py`:

```python
GENERIC_DOCS = [
    ("docs/git-workflow.md", "docs/git-workflow.md"),
    ("docs/your-new-doc.md", "docs/your-new-doc.md"),  # Add here
]
```

### Modify for Your Organization

Fork this repo and customize:
- Update CLAUDE.md.EXAMPLE with company-specific sections
- Add organization-specific pattern docs
- Modify scaffolding script for your directory structure

## 📖 Resources

**Documentation:**
- [Claude Code Docs](https://docs.claude.com/en/docs/claude-code)
- [CLAUDE.md Best Practices](https://docs.claude.com/en/docs/claude-code/claude_code_docs_map.md)

**Examples:**
- TaadaB Logistics CLAUDE.md (reference implementation)
- See `templates/CLAUDE.md.TEMPLATE` for detailed explanations

## 🤝 Contributing

Improvements to templates or scaffolder:

1. Test changes on a new project
2. Ensure backward compatibility
3. Update this README
4. Share your improvements!

## 📝 Changelog

**v2.0** - Feature Workflow & Implementation Plans
- ✨ NEW: 8 slash commands for orchestrated feature workflow
- ✨ NEW: Implementation plans system (docs/plans/)
- ✨ NEW: User story ID conventions documentation
- ✨ NEW: Mandatory review gates (Phase 3.5 & 4.5) with specialized agents
- ✨ NEW: Central progress tracker (high-level-user-stories.md)
- ✨ NEW: Implementation plan template with 10 sections
- ✨ NEW: Documentation standards (documentation-standard.md)
- 🔄 Updated: feature-development-process.md with plan integration
- 🔄 Updated: user-story-standards.md with comprehensive ID conventions
- 🔄 Updated: Scaffolder to create .claude/commands/, docs/plans/, docs/features/

**v1.0** - Initial release
- CLAUDE.md.EXAMPLE (minimal, production-ready)
- CLAUDE.md.TEMPLATE (teaching tool)
- Generic docs (git-workflow, feature-development-process, user-story-standards)
- Scaffolding script with placeholders for 11 pattern docs

---

**Questions?** Check CLAUDE.md.TEMPLATE or ask Claude Code for help!
