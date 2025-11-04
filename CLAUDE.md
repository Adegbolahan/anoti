# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Getting Started with Claude** is a project scaffolding framework and template library that helps developers create well-documented codebases optimized for AI-assisted development with Claude Code.

**Vision:** "Every new project starts with comprehensive, maintainable documentation that enables both humans and AI to understand and contribute effectively."

**Problem Solved:** Developers often start new projects without proper documentation standards, leading to inconsistent patterns, unclear architecture, and difficulty onboarding both developers and AI assistants. This tool provides:
- Pre-built documentation templates (CLAUDE.md) with best practices
- Standard operating procedures for feature development
- Pattern documents for common tech stacks (testing, API design, database, etc.)
- Automated scaffolding to quickly set up documentation structure

**Current State:** This repository is **production-ready** and actively used for scaffolding new projects. The core tools (installer, scaffolder, templates) are stable and follow their own documentation standards.

### Target Users

**Primary Market:** Software developers and engineering teams starting new projects who want:
- AI-assisted development workflows with Claude Code
- Consistent documentation standards across projects
- Structured feature development processes
- Quick project setup without documentation boilerplate

**Usage Modes:**
- **Full Mode (80% of users):** Complete project structure with all pattern document placeholders
- **Minimal Mode (20% of users):** Essential docs only (CLAUDE.md, git-workflow, feature-process)

**Why This Matters:**
- Developers waste time reinventing documentation structures
- Inconsistent patterns lead to confusion for both humans and AI
- Quality gates and standards prevent technical debt
- Traceability between code and requirements improves maintainability

---

## ⚠️ CRITICAL: Read Standards BEFORE Coding

**BEFORE implementing ANY feature, you MUST read these standards documents:**

### 📖 Required Reading (Priority Order)

1. **`docs/development.md`** ⭐ MANDATORY (P0)
   - Project architecture and file structure
   - How the scaffolder works
   - Setup instructions and development workflow
   - Testing and validation procedures
   - **Read this FIRST before modifying any code**

2. **`docs/coding-standards.md`** ⭐ MANDATORY (P0)
   - Python conventions (PEP 8, pathlib, type hints)
   - Bash script conventions (POSIX compliance, error handling)
   - Markdown formatting standards (emoji markers, code blocks, line limits)
   - File naming and organization patterns
   - **Read before writing any Python, Bash, or Markdown**

3. **`docs/contributing.md`** (P1)
   - How to contribute changes
   - Pull request process
   - Template modification guidelines
   - Testing requirements before submitting
   - **Read before submitting contributions**

### 🚨 Why This Matters

- **Consistency:** All generated templates follow the same patterns
- **Quality:** Following standards ensures templates work correctly
- **Maintainability:** Clear patterns make the codebase easy to understand
- **Efficiency:** Don't reinvent the wheel - patterns are established

---

## Quick Start for Claude

When working on this project, here's what you need to know:

### Key Files & Purposes

| File | Purpose | Lines | Critical? |
|------|---------|-------|-----------|
| **scaffold-project.py** | Main scaffolding tool (Python 3) | 410 | ✅ Core |
| **install.sh** | Bash installer for shell integration | 113 | ✅ Core |
| **templates/CLAUDE.md.EXAMPLE** | Production template for generated projects | 421 | ✅ Core |
| **templates/CLAUDE.md.TEMPLATE** | Teaching reference with explanations | 1,397 | Reference |
| **templates/docs/git-workflow.md** | Generic git conventions | 478 | Template |
| **templates/docs/feature-development-process.md** | 10-step SOP with plan integration | 416 | Template |
| **templates/docs/user-story-standards.md** | User story format & ID conventions | 420 | Template |
| **templates/docs/implementation-plan-template.md** | Comprehensive 10-section plan | 439 | Template |
| **templates/docs/high-level-user-stories.md** | Central progress tracker | 165 | Template |
| **templates/.claude/commands/** | 8 slash commands for workflow | ~1200 | ✅ Core |

### Tech Stack

**Runtime:**
- **Python 3** (stdlib only - NO external dependencies)
  - `pathlib` for cross-platform paths
  - `shutil` for file operations
  - `argparse` for CLI interface

**Scripting:**
- **Bash** (POSIX-compliant for macOS/Linux)
  - Shell detection (zsh/bash)
  - File manipulation with sed

**Documentation:**
- **Markdown** (GitHub-flavored)
  - CommonMark specification
  - Emoji markers for visual scanning
  - Code blocks with language identifiers

**No build tools, no package managers, no external dependencies.**

### Common Tasks

**Run the scaffolder:**
```bash
python3 scaffold-project.py /path/to/new/project
python3 scaffold-project.py /path/to/new/project --minimal
```

**Install shell integration:**
```bash
bash install.sh
# Adds aliases: claude-scaffold, claude-scaffold-minimal
```

**Modify templates:**
1. Edit files in `templates/` directory
2. Test by running scaffolder on a test project
3. Verify generated files match expectations
4. Update version in changelog if significant

**Add new template file:**
1. Create file in `templates/docs/`
2. Update `GENERIC_DOCS` list in `scaffold-project.py`
3. Test scaffolding with new file
4. Document in README.md

---

## Development Workflow

### For EVERY change:

1. ✅ **Read relevant standards** - Review `docs/coding-standards.md` for language conventions
2. ✅ **Understand current behavior** - Test the scaffolder before modifying
3. ✅ **Make changes** - Follow established patterns in the codebase
4. ✅ **Test locally** - Run scaffolder on test project, verify output
5. ✅ **Validate** - Check no breaking changes to existing templates
6. ✅ **Document** - Update README.md or QUICK-REFERENCE.md if user-facing

**If you deviate from standards:**
- Document WHY in code comments
- Propose update to the standard document
- Get user approval for pattern changes

---

## Architecture & Design

### Hub-and-Spoke Documentation Pattern

This project demonstrates the **hub-and-spoke** documentation model it teaches:

- **Hub:** `CLAUDE.md` (this file) - Main index and quick reference
- **Spokes:** Topic-specific documents in `/docs/`:
  - `docs/development.md` - Architecture and setup
  - `docs/coding-standards.md` - Language conventions
  - `docs/contributing.md` - Contribution guidelines

**Why this works:**
- Keeps main file under 600 lines
- Detailed information lives in focused documents
- Easy to navigate with clear links
- Follows the same pattern we teach users

### Scaffolding Architecture

**Two-phase operation:**

1. **Directory Creation:**
   - Creates `/docs/` and `/docs/features/` structure
   - Uses `pathlib` for cross-platform compatibility

2. **File Generation:**
   - **Copy as-is:** Generic docs (git-workflow, feature-process, user-story-standards)
   - **Copy with rename:** CLAUDE.md.EXAMPLE → CLAUDE.md
   - **Generate placeholders:** Project-specific and pattern docs with TODO markers

**Design Principles:**
- No external dependencies (pure Python stdlib)
- Idempotent operations (can run multiple times safely)
- Clear error messages for missing templates
- Progress indicators for user feedback

---

## Testing Strategy

**Manual Testing Required:**

Since this is a scaffolding tool, automated tests would be complex. Follow this manual testing checklist:

```bash
# Create test directory
mkdir -p /tmp/test-scaffold

# Test full mode
python3 scaffold-project.py /tmp/test-scaffold/full-test

# Verify:
# - CLAUDE.md exists and has proper content
# - All generic docs copied correctly
# - Placeholder files have TODO markers
# - README-GETTING-STARTED.md generated

# Test minimal mode
python3 scaffold-project.py /tmp/test-scaffold/minimal-test --minimal

# Verify:
# - Only essential files created
# - No placeholder spam

# Clean up
rm -rf /tmp/test-scaffold
```

**Template Validation:**

When modifying templates:
1. Check line counts (keep CLAUDE.md.EXAMPLE under 500 lines)
2. Verify markdown formatting (use VSCode markdown preview)
3. Check for broken internal links
4. Ensure placeholder syntax is consistent: `[placeholder]`

---

## Git Workflow

**Branching:** Feature branches (`feature/<description>`)

**Commits:** Conventional Commits format with attribution

**Example:**
```bash
git commit -m "feat: add database-patterns template

- Created new template for PostgreSQL patterns
- Includes RLS examples and query patterns
- Added to GENERIC_DOCS list in scaffolder

```

**Commit Types:**
- `feat:` - New features (new templates, scaffolder features)
- `fix:` - Bug fixes (template errors, scaffolder bugs)
- `docs:` - Documentation updates (README, QUICK-REFERENCE)
- `refactor:` - Code improvements without behavior changes
- `chore:` - Maintenance (version bumps, dependencies)

**Pre-commit Checklist:**
- [ ] Test scaffolder on sample project
- [ ] Verify no syntax errors in templates
- [ ] Update README.md if user-facing changes
- [ ] Check line counts on template files

---

## Claude Code Agent Recommendations

### When to Use Specialized Agents

**DO use agents for:**
- Exploring template structure and organization
- Creating comprehensive new template files
- Security review of generated file permissions
- Documentation writing for new features

**DON'T use agents for:**
- Reading specific template files (use Read tool)
- Simple text edits (use Edit tool)
- Running the scaffolder (use Bash tool)

### Recommended Agents for This Project

**Explore Agent** - For template discovery
- Finding template files by pattern
- Understanding template organization
- Searching for specific template sections

**technical-documentation-writer** - For template creation
- Writing new pattern documentation templates
- Creating comprehensive examples
- Ensuring markdown formatting consistency

**solution-architect** - For template design
- Deciding what templates to include
- Structuring new documentation patterns
- Evaluating template organization

---

## Documentation Standards

This project follows its own documentation standards:

### File Size Limits

- **CLAUDE.md:** 300-400 lines (this file)
- **CLAUDE.md.EXAMPLE:** 400-500 lines (production template)
- **Pattern templates:** 200-400 lines
- **Generic docs:** 300-500 lines
- **README.md:** No strict limit (comprehensive user guide)

### Markdown Conventions

**Emoji Markers:**
- 📋 Lists and documentation
- ✅ Correct examples and checkboxes
- ❌ Incorrect examples and anti-patterns
- ⭐ Important items
- 🚨 Critical warnings
-  AI-generated attribution

**Code Blocks:**
- Always specify language: ```python, ```bash, ```markdown
- Show wrong vs right: `❌ WRONG` and `✅ CORRECT`
- Include comments explaining patterns

**Structure:**
- Use hierarchical headings (# > ## > ###)
- Keep sections focused (single topic per section)
- Link to spokes instead of duplicating
- Table of contents for files over 200 lines

### Content Organization

**Hub-and-Spoke Pattern:**
- Main index in CLAUDE.md (this file)
- Detailed docs in `/docs/` directory
- Cross-reference with links, don't duplicate

**Progressive Disclosure:**
- Summary in hub (CLAUDE.md)
- Details in spokes (individual docs)
- Examples and code in pattern docs

---

## Detailed Documentation

### Development & Setup
- **`docs/development.md`** - Project architecture, scaffolder internals, testing procedures

### Standards & Patterns
- **`docs/coding-standards.md`** - Python, Bash, and Markdown conventions
- **`docs/contributing.md`** - How to contribute to this project

### User Documentation
- **`README.md`** - Complete user guide (installation, usage, customization)
- **`QUICK-REFERENCE.md`** - Fast lookup for common tasks
- **`INSTALL.md`** - Step-by-step installation instructions

### Templates
- **`templates/CLAUDE.md.EXAMPLE`** - Production template (copied to projects)
- **`templates/CLAUDE.md.TEMPLATE`** - Teaching reference (with explanations)
- **`templates/docs/`** - Reusable generic documentation files

---

## Next Steps for Development

To contribute to this project:

1. **Set Up Environment** - Clone repo, test scaffolder locally
2. **Read Standards** - Review all docs in `/docs/` (see Required Reading above)
3. **Understand Templates** - Read existing templates to understand patterns
4. **Make Changes** - Follow coding standards and test thoroughly
5. **Document** - Update README.md or add to docs/ as needed
6. **Submit** - Follow git workflow and pre-commit checklist

**Common Contributions:**

1. **New Template Files** - Add new pattern docs to `templates/docs/`
2. **Template Improvements** - Enhance existing templates with better examples
3. **Scaffolder Features** - Add CLI options or generation logic
4. **Documentation** - Improve README, create tutorials, add examples

**Implementation Priority:**

1. Create missing docs/ files (development.md, coding-standards.md, contributing.md)
2. Add automated template validation
3. Create example projects showcasing different tech stacks
4. Build test suite for scaffolder logic

---

## Documentation Index

**Essential Reading:**
- ⭐ `docs/development.md` - **Development guide** (START HERE for contributors)
- ⭐ `docs/coding-standards.md` - Code conventions (MANDATORY before coding)
- ⭐ `docs/contributing.md` - Contribution process

**User Documentation:**
- `README.md` - Complete user guide
- `QUICK-REFERENCE.md` - Quick lookup
- `INSTALL.md` - Installation guide

**Templates:**
- `templates/CLAUDE.md.EXAMPLE` - Production template
- `templates/CLAUDE.md.TEMPLATE` - Teaching reference
- `templates/docs/` - Generic reusable docs
  - `git-workflow.md` - Git conventions and branching strategy
  - `feature-development-process.md` - 10-step SOP for features
  - `user-story-standards.md` - User story format and standards
  - `documentation-standard.md` - Documentation conventions and writing guidelines

---

**This document follows the same standards it teaches. Update it when new patterns emerge or architectural decisions are made.**
