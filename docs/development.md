# Development Guide

This document explains how to work on the Getting Started with Claude project itself.

## Table of Contents

- [Project Architecture](#project-architecture)
- [File Structure](#file-structure)
- [Setup](#setup)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Common Tasks](#common-tasks)
- [Release Process](#release-process)

---

## Project Architecture

### Overview

This is a **scaffolding framework** that generates documentation structure for new projects. It consists of:

1. **Scaffolder** (`scaffold-project.py`) - Python tool that creates project structure
2. **Installer** (`install.sh`) - Bash script that adds shell aliases
3. **Templates** (`templates/`) - Documentation files copied to new projects

### Design Principles

**No External Dependencies:**
- Pure Python 3 stdlib (no pip packages)
- POSIX-compliant Bash (no GNU-specific features)
- Self-contained templates (no build step)

**Idempotent Operations:**
- Safe to run scaffolder multiple times
- Checks for existing files before overwriting
- Clear error messages when files exist

**Cross-Platform Compatibility:**
- Uses `pathlib` for platform-independent paths
- Shell installer detects zsh/bash automatically
- Works on macOS and Linux

### Hub-and-Spoke Documentation Pattern

This project demonstrates the pattern it teaches:

- **Hub:** `CLAUDE.md` - Main index (300-400 lines)
- **Spokes:** `/docs/*.md` - Detailed topic-specific docs (150-500 lines each)

Benefits:
- Keeps main file scannable
- Deep detail available via links
- Easy to navigate and maintain

---

## File Structure

```
$HOME/Code/getting-started-claude/
├── CLAUDE.md                              ← Hub documentation (this project)
├── README.md                              ← User guide (comprehensive)
├── QUICK-REFERENCE.md                     ← Quick lookup
├── INSTALL.md                             ← Installation instructions
│
├── scaffold-project.py                    ← Main scaffolding tool (330 lines)
├── install.sh                             ← Shell integration (113 lines)
│
├── .claude/
│   └── settings.local.json                ← Claude Code permissions
│
├── docs/                                  ← Spoke documentation (this project)
│   ├── development.md                     ← This file
│   ├── coding-standards.md                ← Language conventions
│   └── contributing.md                    ← Contribution guide
│
└── templates/                             ← Files copied to new projects
    ├── CLAUDE.md.EXAMPLE                  ← Production template (421 lines)
    ├── CLAUDE.md.TEMPLATE                 ← Teaching reference (1,397 lines)
    └── docs/
        ├── git-workflow.md                ← Generic reusable
        ├── feature-development-process.md ← Generic reusable
        └── user-story-standards.md        ← Generic reusable
```

### Key Files Explained

**scaffold-project.py** (330 lines)
- Main scaffolding logic
- Creates directory structure
- Copies templates to target project
- Generates placeholder files
- Two modes: full and minimal

**install.sh** (113 lines)
- Detects shell type (zsh/bash)
- Adds aliases to shell config
- Backs up config before modifying
- POSIX-compliant Bash

**templates/CLAUDE.md.EXAMPLE** (421 lines)
- Production-ready template
- Copied to new projects as `CLAUDE.md`
- Uses `[placeholder]` syntax
- Minimal, focused content

**templates/CLAUDE.md.TEMPLATE** (1,397 lines)
- Teaching reference (not copied)
- Explains WHY each section matters
- Comprehensive with examples
- Used as learning resource

**templates/docs/** (3 files)
- Generic, reusable documents
- Copied as-is to all projects
- No customization needed
- Standards for git, features, user stories

---

## Setup

### Prerequisites

- **Python 3.7+** (no external packages needed)
- **Bash** (for installer, macOS/Linux)
- **Git** (for version control)
- **Text Editor** (VSCode recommended for markdown preview)

### Clone and Test

```bash
# Clone repository
git clone <repo-url> getting-started-claude
cd getting-started-claude

# Test scaffolder (creates test project)
python3 scaffold-project.py /tmp/test-project

# Verify output
ls -la /tmp/test-project
cat /tmp/test-project/CLAUDE.md

# Test minimal mode
python3 scaffold-project.py /tmp/test-minimal --minimal

# Clean up
rm -rf /tmp/test-project /tmp/test-minimal
```

### Install Shell Integration (Optional)

```bash
# Adds aliases to your shell config
bash install.sh

# Restart shell or source config
source ~/.zshrc  # or ~/.bashrc

# Test aliases
claude-scaffold /tmp/test
claude-scaffold-minimal /tmp/test-min
```

---

## Development Workflow

### Making Changes

1. **Understand Current Behavior**
   ```bash
   # Test before modifying
   python3 scaffold-project.py /tmp/before-test
   ```

2. **Make Code Changes**
   - Edit `scaffold-project.py` for scaffolder logic
   - Edit `templates/` for template content
   - Edit `install.sh` for shell integration

3. **Test Your Changes**
   ```bash
   # Test after modifying
   python3 scaffold-project.py /tmp/after-test

   # Compare results
   diff -r /tmp/before-test /tmp/after-test
   ```

4. **Validate Templates**
   - Check line counts (keep CLAUDE.md.EXAMPLE under 500 lines)
   - Preview markdown in VSCode
   - Verify no broken links
   - Check placeholder syntax consistency

5. **Update Documentation**
   - Update `README.md` for user-facing changes
   - Update `QUICK-REFERENCE.md` for new tasks
   - Update this file (`docs/development.md`) for architecture changes

---

## Testing

Since this is a scaffolding tool, testing is primarily manual. Follow this checklist:

### Pre-Commit Testing Checklist

```bash
# 1. Test full scaffolding mode
mkdir -p /tmp/test-scaffold
python3 scaffold-project.py /tmp/test-scaffold/full-test

# 2. Verify full mode output
[ -f /tmp/test-scaffold/full-test/CLAUDE.md ] && echo "✅ CLAUDE.md created"
[ -f /tmp/test-scaffold/full-test/docs/git-workflow.md ] && echo "✅ Generic docs copied"
[ -f /tmp/test-scaffold/full-test/docs/architecture.md ] && echo "✅ Placeholders created"
[ -f /tmp/test-scaffold/full-test/README-GETTING-STARTED.md ] && echo "✅ README generated"

# 3. Test minimal mode
python3 scaffold-project.py /tmp/test-scaffold/minimal-test --minimal

# 4. Verify minimal mode output
[ -f /tmp/test-scaffold/minimal-test/CLAUDE.md ] && echo "✅ CLAUDE.md created"
[ ! -f /tmp/test-scaffold/minimal-test/docs/architecture.md ] && echo "✅ No placeholders"

# 5. Clean up
rm -rf /tmp/test-scaffold

echo "✅ All tests passed"
```

### Template Validation

When modifying template files:

```bash
# Check line counts
wc -l templates/CLAUDE.md.EXAMPLE  # Should be ~400-500
wc -l templates/CLAUDE.md.TEMPLATE # Should be ~1300-1400
wc -l templates/docs/*.md          # Should be 200-500 each

# Validate markdown (use VSCode or markdown-cli)
# Check for:
# - Broken internal links
# - Missing code block language identifiers
# - Inconsistent heading hierarchy
# - Placeholder syntax: [placeholder] not {placeholder}
```

### Installer Testing

```bash
# Test installer in dry-run mode (review changes before applying)
bash install.sh  # Check output, cancel before applying

# If safe, apply and test
bash install.sh
source ~/.zshrc

# Verify aliases work
claude-scaffold --help
```

---

## Common Tasks

### Add New Generic Template

To add a new reusable document to `templates/docs/`:

1. **Create template file**
   ```bash
   # Create new file
   touch templates/docs/deployment-guide.md

   # Write content following coding-standards.md
   ```

2. **Update scaffolder**
   ```python
   # Edit scaffold-project.py
   # Find GENERIC_DOCS list, add new file:

   GENERIC_DOCS = [
       'git-workflow.md',
       'feature-development-process.md',
       'user-story-standards.md',
       'deployment-guide.md',  # NEW
   ]
   ```

3. **Test scaffolding**
   ```bash
   python3 scaffold-project.py /tmp/test
   ls /tmp/test/docs/deployment-guide.md  # Should exist
   ```

4. **Update documentation**
   - Add to README.md "What Gets Created" section
   - Add to CLAUDE.md.EXAMPLE "Documentation Index"

### Modify CLAUDE.md Template

To update the production template:

1. **Edit template**
   ```bash
   # Edit production template
   code templates/CLAUDE.md.EXAMPLE
   ```

2. **Test scaffolding**
   ```bash
   python3 scaffold-project.py /tmp/test
   cat /tmp/test/CLAUDE.md  # Verify changes
   ```

3. **Check line count**
   ```bash
   wc -l templates/CLAUDE.md.EXAMPLE  # Keep under 500
   ```

4. **Consider teaching template**
   - If adding new section, also update `CLAUDE.md.TEMPLATE`
   - Add explanatory comments in teaching version

### Add Scaffolder Feature

To add new CLI options or generation logic:

1. **Modify scaffold-project.py**
   ```python
   # Example: Add --dry-run option
   parser.add_argument(
       '--dry-run',
       action='store_true',
       help='Show what would be created without creating files'
   )
   ```

2. **Implement feature**
   ```python
   if args.dry_run:
       print(f"Would create: {file_path}")
   else:
       create_file(file_path, content)
   ```

3. **Test both modes**
   ```bash
   python3 scaffold-project.py /tmp/test --dry-run
   python3 scaffold-project.py /tmp/test
   ```

4. **Update help text and README**

---

## Release Process

### Version Tracking

- Versions noted in README.md changelog
- Major changes warrant version bumps
- Use semantic versioning (major.minor.patch)

### Release Checklist

1. **Test thoroughly**
   ```bash
   # Run full test suite (manual checklist)
   # Test on both macOS and Linux if possible
   ```

2. **Update documentation**
   - Update README.md changelog
   - Bump version number
   - Document breaking changes

3. **Commit and tag**
   ```bash
   git commit -m "chore: release v1.1.0"
   git tag v1.1.0
   git push origin main --tags
   ```

4. **Announce changes**
   - Update GitHub release notes
   - Document migration steps for breaking changes

---

## Troubleshooting

### Scaffolder Issues

**Problem:** "Templates directory not found"
```bash
# Check templates directory exists
ls templates/

# Run from project root
cd $HOME/Code/getting-started-claude
python3 scaffold-project.py /tmp/test
```

**Problem:** Files not being created
```bash
# Check permissions
ls -la /path/to/target/

# Run with verbose output (add print statements)
python3 scaffold-project.py /tmp/test 2>&1 | tee debug.log
```

### Installer Issues

**Problem:** Aliases not working after install
```bash
# Check which shell you're using
echo $SHELL

# Source the config
source ~/.zshrc  # or ~/.bashrc

# Check if alias was added
grep claude-scaffold ~/.zshrc
```

**Problem:** Permission denied running installer
```bash
# Make installer executable
chmod +x install.sh

# Run with bash explicitly
bash install.sh
```

---

## Architecture Deep Dive

### Scaffolder Internals

**Two-Phase Operation:**

**Phase 1: Directory Creation**
```python
# Creates directory structure
docs_dir = project_dir / 'docs'
docs_dir.mkdir(parents=True, exist_ok=True)

features_dir = docs_dir / 'features'
features_dir.mkdir(exist_ok=True)
```

**Phase 2: File Generation**

1. **Copy with rename:** `CLAUDE.md.EXAMPLE` → `CLAUDE.md`
2. **Copy as-is:** Generic docs from `templates/docs/`
3. **Generate placeholders:** Project-specific docs with TODO content

**File Resolution:**
```python
# Uses pathlib for cross-platform paths
templates_dir = Path(__file__).parent / 'templates'
template_file = templates_dir / 'CLAUDE.md.EXAMPLE'

# Resolves to absolute path
absolute_path = template_file.resolve()
```

**Error Handling:**
- Checks if templates directory exists
- Reports missing template files
- Validates target directory is writable

### Installer Internals

**Shell Detection:**
```bash
# Detects current shell
if [ -n "$ZSH_VERSION" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    RC_FILE="$HOME/.bashrc"
fi
```

**Safe Modification:**
```bash
# Creates backup before modifying
cp "$RC_FILE" "$RC_FILE.backup"

# Uses marker comments to prevent duplicates
# Claude Code Scaffolder Aliases
# (aliases here)
```

**Idempotency:**
- Checks for existing marker comments
- Skips if already installed
- Can be run multiple times safely

---

## Further Reading

- **`docs/coding-standards.md`** - Language-specific conventions
- **`docs/contributing.md`** - How to contribute changes
- **`README.md`** - User-facing documentation
- **`QUICK-REFERENCE.md`** - Common task reference

---

**Questions or need help?** Open an issue or reach out to project maintainers.
