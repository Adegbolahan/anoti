#!/usr/bin/env python3
"""
Claude Code Project Scaffolder

This script scaffolds a new project with:
- CLAUDE.md.EXAMPLE (ready for customization)
- Generic standards documents (git-workflow.md, feature-development-process.md, etc.)
- Directory structure for /docs/ and /docs/features/
- Placeholder files for project-specific docs

Usage:
    python scaffold-project.py /path/to/new-project
    python scaffold-project.py /path/to/new-project --minimal  # Only CLAUDE.md and essential docs
"""

import argparse
import shutil
import sys
from pathlib import Path
from typing import List

# Get the templates directory (same directory as this script)
TEMPLATES_DIR = Path(__file__).parent / "templates"

# Define which files to copy
ESSENTIAL_FILES = [
    ("CLAUDE.md.EXAMPLE", "CLAUDE.md"),
]

GENERIC_DOCS = [
    ("docs/git-workflow.md", "docs/git-workflow.md"),
    ("docs/feature-development-process.md", "docs/feature-development-process.md"),
    ("docs/user-story-standards.md", "docs/user-story-standards.md"),
    ("docs/documentation-standard.md", "docs/documentation-standard.md"),
    ("docs/implementation-plan-template.md", "docs/implementation-plan-template.md"),
    ("docs/plans/.gitkeep", "docs/plans/.gitkeep"),
]

# Placeholder files to create (project-specific)
PLACEHOLDER_DOCS = [
    "docs/architecture.md",
    "docs/development.md",
    "docs/roadmap.md",
    "docs/implementation-notes.md",
]

# Template files with customizable content (moved from placeholders)
CUSTOMIZABLE_TEMPLATES = [
    ("docs/high-level-user-stories.md", "docs/high-level-user-stories.md"),
]

# Pattern docs that need tech stack customization (create placeholders)
PATTERN_DOC_PLACEHOLDERS = [
    "docs/coding-standards.md",
    "docs/component-patterns.md",
    "docs/state-management-patterns.md",
    "docs/styling-patterns.md",
    "docs/api-patterns.md",
    "docs/database-patterns.md",
    "docs/testing-patterns.md",
    "docs/error-handling-patterns.md",
    "docs/performance-patterns.md",
    "docs/async-patterns.md",
    "docs/logging-patterns.md",
]


def create_directory_structure(target_dir: Path):
    """Create the necessary directory structure"""
    print(f"📁 Creating directory structure in {target_dir}")

    dirs = [
        target_dir / "docs",
        target_dir / "docs" / "features",
        target_dir / "docs" / "plans",
    ]

    for dir_path in dirs:
        dir_path.mkdir(parents=True, exist_ok=True)
        print(f"   ✓ Created {dir_path.relative_to(target_dir)}")


def copy_essential_files(target_dir: Path):
    """Copy essential files (CLAUDE.md.EXAMPLE → CLAUDE.md)"""
    print("\n📄 Copying essential files...")

    for src_file, dest_file in ESSENTIAL_FILES:
        src_path = TEMPLATES_DIR / src_file
        dest_path = target_dir / dest_file

        if not src_path.exists():
            print(f"   ⚠️  Warning: {src_file} not found in templates")
            continue

        shutil.copy2(src_path, dest_path)
        print(f"   ✓ Copied {src_file} → {dest_file}")


def copy_generic_docs(target_dir: Path):
    """Copy generic documentation that's the same across projects"""
    print("\n📚 Copying generic documentation...")

    for src_file, dest_file in GENERIC_DOCS:
        src_path = TEMPLATES_DIR / src_file
        dest_path = target_dir / dest_file

        if not src_path.exists():
            print(f"   ⚠️  Warning: {src_file} not found in templates")
            continue

        shutil.copy2(src_path, dest_path)
        print(f"   ✓ Copied {dest_file}")


def copy_customizable_templates(target_dir: Path):
    """Copy template files that need customization but have full structure"""
    print("\n📋 Copying customizable template files...")

    for src_file, dest_file in CUSTOMIZABLE_TEMPLATES:
        src_path = TEMPLATES_DIR / src_file
        dest_path = target_dir / dest_file

        if not src_path.exists():
            print(f"   ⚠️  Warning: {src_file} not found in templates")
            continue

        shutil.copy2(src_path, dest_path)
        print(f"   ✓ Copied {dest_file} (customize with your project data)")


def copy_claude_commands(target_dir: Path):
    """Copy Claude Code slash commands for feature workflow"""
    print("\n⚡ Copying Claude Code slash commands...")

    src_claude_dir = TEMPLATES_DIR / ".claude"
    dest_claude_dir = target_dir / ".claude"

    if not src_claude_dir.exists():
        print(f"   ⚠️  Warning: .claude directory not found in templates")
        return

    # Copy the entire .claude directory
    if dest_claude_dir.exists():
        shutil.rmtree(dest_claude_dir)

    shutil.copytree(src_claude_dir, dest_claude_dir)

    # Count command files
    command_files = list((dest_claude_dir / "commands").glob("*.md"))
    print(f"   ✓ Copied .claude/commands/ ({len(command_files)} slash commands)")
    print(f"   ✓ Feature workflow: /implement → /discovery → /plan-and-validate → /start-implementation → /review-implementation")


def create_placeholder_docs(target_dir: Path):
    """Create placeholder files for project-specific docs"""
    print("\n📝 Creating placeholder files for project-specific docs...")

    for doc_path in PLACEHOLDER_DOCS:
        dest_path = target_dir / doc_path
        doc_name = Path(doc_path).stem

        content = f"""# {doc_name.replace('-', ' ').title()}

TODO: Fill in project-specific content.

This document is project-specific and should be customized for your project.
"""

        dest_path.write_text(content)
        print(f"   ✓ Created placeholder: {doc_path}")


def create_pattern_doc_placeholders(target_dir: Path):
    """Create placeholders for pattern docs that need tech stack customization"""
    print("\n🔧 Creating placeholders for pattern documents...")
    print("   (These require tech stack-specific customization)")

    for doc_path in PATTERN_DOC_PLACEHOLDERS:
        dest_path = target_dir / doc_path
        doc_name = Path(doc_path).stem

        content = f"""# {doc_name.replace('-', ' ').title()}

TODO: Customize this pattern document for your tech stack.

This document should define {doc_name.replace('-', ' ')} for your project.

## Recommended Content

See CLAUDE.md.TEMPLATE (Section 12: Common Implementation Patterns) for examples of what to include.

**For tech stack-specific examples:**
- Language/framework conventions
- Library-specific patterns
- Code examples showing ❌ wrong vs ✅ correct

**Generic patterns you can reference:**
- See other projects using similar tech stacks
- Check framework documentation
- Adapt patterns from CLAUDE.md.TEMPLATE

## Structure Suggestion

1. **Overview** - What this pattern is and when to use it
2. **Basic Patterns** - Common use cases with code examples
3. **Anti-Patterns** - What NOT to do (❌ examples)
4. **Best Practices** - Recommended approaches (✅ examples)
5. **Advanced Patterns** - Complex scenarios
6. **Common Gotchas** - Edge cases and pitfalls
"""

        dest_path.write_text(content)
        print(f"   ✓ Created placeholder: {doc_path}")


def create_readme(target_dir: Path):
    """Create a README with next steps"""
    readme_path = target_dir / "README-GETTING-STARTED.md"

    content = """# Getting Started with Claude Code

This project has been scaffolded with Claude Code documentation.

## ✅ What's Been Set Up

- **CLAUDE.md** - Main guidance file for Claude Code (customize the `[placeholders]`)
- **Slash commands** - `.claude/commands/` with 6 feature workflow commands:
  - `/implement` - Full workflow orchestrator
  - `/discovery` - Phase 1+2: Requirements gathering + Architecture review
  - `/plan-and-validate` - Phase 3+3.5: Create plan + Validate (MANDATORY)
  - `/start-implementation` - Phase 4: Execute implementation
  - `/review-implementation` - Phase 4.5: Review completed code (optional)
  - `/next` - Auto-proceed to next phase
- **Generic docs:** git-workflow.md, feature-development-process.md, user-story-standards.md, documentation-standard.md, implementation-plan-template.md
- **Tracking docs:** high-level-user-stories.md (progress tracker with plan-story linking)
- **Placeholder docs:** architecture.md, development.md, roadmap.md, implementation-notes.md
- **Pattern doc placeholders:** 11 pattern documents (need tech stack customization)
- **Directories:** docs/features/ (user stories), docs/plans/ (implementation plans)

## 📋 Next Steps

### 1. Customize CLAUDE.md (Required)

Edit `CLAUDE.md` and replace all `[placeholders]`:

- `[Project Name]` → Your project name
- `[Python/TypeScript/etc]` → Your backend language
- `[React/Vue/etc]` → Your frontend framework
- `[Redux/Pinia/etc]` → Your state management library
- Remove optional sections if not applicable (e.g., multi-tenant security)

### 2. Fill in Project-Specific Docs

Create content for these placeholder files:

- **`docs/architecture.md`** - Your system architecture and tech stack
- **`docs/development.md`** - Setup instructions and dev commands
- **`docs/roadmap.md`** - Implementation phases
- **`docs/implementation-notes.md`** - Project-specific gotchas

**Customize tracking docs:**

- **`docs/high-level-user-stories.md`** - Add your user stories to the progress tracker
  - This file is pre-populated with a tracking table template
  - Add rows for each user story with links to `/docs/features/` and `/docs/plans/`
  - Update status as you progress through implementation

### 3. Customize Pattern Documents (High Priority)

These 11 pattern docs need tech stack-specific examples:

**Must customize for your stack:**
- `docs/coding-standards.md` - Language conventions for your stack
- `docs/component-patterns.md` - Framework-specific patterns
- `docs/state-management-patterns.md` - State library patterns
- `docs/styling-patterns.md` - CSS/styling approach patterns
- `docs/api-patterns.md` - API design patterns
- `docs/database-patterns.md` - Database and ORM patterns
- `docs/testing-patterns.md` - Testing framework patterns

**Can use generic patterns:**
- `docs/error-handling-patterns.md` - Error handling across stack
- `docs/performance-patterns.md` - Performance optimization
- `docs/async-patterns.md` - Async/await patterns
- `docs/logging-patterns.md` - Logging and observability

**Tip:** See `CLAUDE.md.TEMPLATE` (Section 12) for code examples you can adapt.

### 4. Review Generic Docs (Optional)

The generic docs work for most projects, but you may want to customize:

- `docs/git-workflow.md` - Adjust if you use different branching strategy
- `docs/feature-development-process.md` - Modify if you have custom workflow
- `docs/user-story-standards.md` - Adapt if you use different story format
- `docs/documentation-standard.md` - Review and adapt documentation conventions

## 🚀 Start Using Claude Code

Once CLAUDE.md is customized:

```bash
# Start a new feature
claude code

# Use the feature workflow commands:
/implement
```

### ⚡ Feature Workflow Commands

This project includes slash commands for a comprehensive 4-phase development workflow:

**Quick Start:**
- `/implement` - Full workflow (requirements → architecture → planning → implementation)
- `/next` - Auto-proceed to next phase

**Individual Phases:**
- `/discovery` - Phase 1+2: Requirements gathering + Architecture review
- `/plan-and-validate` - Phase 3+3.5: Create plan + Validate (MANDATORY)
- `/start-implementation` - Phase 4: Guided implementation with todos
- `/review-implementation` - Phase 4.5: Review completed code (optional)

**Benefits:**
- ✅ Ensures thorough requirements gathering before coding
- ✅ Forces standards review (reads relevant docs in `/docs/`)
- ✅ Creates detailed plans with edge cases identified
- ✅ Tracks progress with TodoWrite
- ✅ Prevents skipping tests, error handling, edge cases

### Manual Approach (Alternative)

You can also work without slash commands:

```bash
# Tell Claude Code:
"Read CLAUDE.md and implement US-001 user authentication feature"
```

Claude Code will:
1. Read CLAUDE.md to understand your project
2. Check docs/high-level-user-stories.md for the feature
3. Read relevant pattern docs before coding
4. Follow your standards and conventions
5. Generate quality code that fits your project

## 📚 Reference

- **CLAUDE.md.TEMPLATE** - Detailed explanations and examples (in templates/)
- **CLAUDE.md.EXAMPLE** - Your CLAUDE.md is based on this
- **Claude Code Docs:** https://docs.claude.com/en/docs/claude-code

## 🤝 Need Help?

- Check CLAUDE.md.TEMPLATE for explanations
- See examples in other projects using Claude Code
- Ask Claude Code: "What should I include in [pattern-doc-name].md?"

---

**Delete this file once you've completed the setup steps.**
"""

    readme_path.write_text(content)
    print(f"\n📖 Created {readme_path.name} with next steps")


def main():
    parser = argparse.ArgumentParser(
        description="Scaffold a new project with Claude Code documentation"
    )
    parser.add_argument(
        "target_dir",
        type=Path,
        help="Path to the new project directory"
    )
    parser.add_argument(
        "--minimal",
        action="store_true",
        help="Only create CLAUDE.md and essential docs (skip placeholders)"
    )

    args = parser.parse_args()
    target_dir = args.target_dir.resolve()

    # Validate templates directory exists
    if not TEMPLATES_DIR.exists():
        print(f"❌ Error: Templates directory not found at {TEMPLATES_DIR}")
        print("   Make sure you're running this script from the getting-started-claude directory")
        sys.exit(1)

    # Create target directory if it doesn't exist
    if not target_dir.exists():
        print(f"📁 Creating project directory: {target_dir}")
        target_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n🚀 Scaffolding Claude Code project in {target_dir}\n")
    print("=" * 60)

    # Run scaffolding steps
    create_directory_structure(target_dir)
    copy_essential_files(target_dir)
    copy_generic_docs(target_dir)
    copy_customizable_templates(target_dir)
    copy_claude_commands(target_dir)

    if not args.minimal:
        create_placeholder_docs(target_dir)
        create_pattern_doc_placeholders(target_dir)

    create_readme(target_dir)

    print("\n" + "=" * 60)
    print("✅ Scaffolding complete!\n")
    print(f"Next steps:")
    print(f"  1. cd {target_dir}")
    print(f"  2. Read README-GETTING-STARTED.md")
    print(f"  3. Customize CLAUDE.md (replace [placeholders])")
    print(f"  4. Fill in pattern docs in docs/")
    print(f"\n Then you're ready to use Claude Code!")


if __name__ == "__main__":
    main()
