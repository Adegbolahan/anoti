# Coding Standards

This document defines coding conventions for the Getting Started with Claude project.

## Table of Contents

- [Python Standards](#python-standards)
- [Bash Standards](#bash-standards)
- [Markdown Standards](#markdown-standards)
- [File Organization](#file-organization)
- [Common Patterns](#common-patterns)

---

## Python Standards

### General Conventions

**Follow PEP 8:**
- 4 spaces for indentation (no tabs)
- Max line length: 88 characters (Black formatter default)
- 2 blank lines between top-level functions
- 1 blank line between methods

**Use Type Hints:**
```python
# ✅ CORRECT - type hints for clarity
def create_file(file_path: Path, content: str) -> None:
    """Create a file with the given content."""
    file_path.write_text(content)

# ❌ WRONG - no type hints
def create_file(file_path, content):
    file_path.write_text(content)
```

**Docstrings:**
```python
# ✅ CORRECT - clear docstring
def scaffold_project(target_dir: Path, minimal: bool = False) -> None:
    """
    Create project documentation structure.

    Args:
        target_dir: Directory where project will be scaffolded
        minimal: If True, create only essential files

    Returns:
        None. Files are created in target_dir.
    """
    pass

# ❌ WRONG - no docstring
def scaffold_project(target_dir, minimal=False):
    pass
```

### Path Handling

**Always use pathlib:**
```python
# ✅ CORRECT - pathlib for cross-platform paths
from pathlib import Path

templates_dir = Path(__file__).parent / 'templates'
claude_md = templates_dir / 'CLAUDE.md.EXAMPLE'

# Resolve to absolute path
absolute = claude_md.resolve()

# ❌ WRONG - string concatenation
import os
templates_dir = os.path.dirname(__file__) + '/templates'
claude_md = templates_dir + '/CLAUDE.md.EXAMPLE'
```

**Check existence before operations:**
```python
# ✅ CORRECT - check before reading
if template_file.exists():
    content = template_file.read_text()
else:
    print(f"Error: Template not found: {template_file}")
    return

# ❌ WRONG - no existence check
content = template_file.read_text()  # May raise FileNotFoundError
```

### Error Handling

**Be explicit and informative:**
```python
# ✅ CORRECT - specific error handling
try:
    content = template_file.read_text()
except FileNotFoundError:
    print(f"Error: Template file not found: {template_file}")
    print(f"Expected location: {template_file.resolve()}")
    sys.exit(1)
except PermissionError:
    print(f"Error: Permission denied reading: {template_file}")
    sys.exit(1)

# ❌ WRONG - bare except
try:
    content = template_file.read_text()
except:
    print("Error reading file")
```

### Imports

**Organize imports:**
```python
# ✅ CORRECT - organized imports
# Standard library
import sys
from pathlib import Path
from typing import List, Optional

# Third-party (if any)
# import requests

# Local modules
# from . import utils

# ❌ WRONG - unorganized
from pathlib import Path
import sys
from typing import List
import sys  # duplicate
```

**No external dependencies:**
```python
# ✅ CORRECT - stdlib only
from pathlib import Path
import shutil
import argparse

# ❌ WRONG - external packages (not allowed)
import click  # External CLI framework
import requests  # External HTTP library
```

### Naming Conventions

```python
# ✅ CORRECT naming patterns
CONSTANT_VALUE = 'template'        # UPPER_SNAKE_CASE for constants
def create_directory(path):        # snake_case for functions
class ProjectScaffolder:           # PascalCase for classes
    def __init__(self):
        self.target_dir = None     # snake_case for variables
```

### Print Statements

**User-facing output should be clear:**
```python
# ✅ CORRECT - clear progress indicators
print(f"Creating project structure in: {project_dir}")
print(f"  ✅ Created CLAUDE.md")
print(f"  ✅ Copied {len(generic_docs)} generic docs")
print(f"\n🎉 Project scaffolded successfully!")

# ❌ WRONG - cryptic or missing output
print("done")
# Silent operation with no feedback
```

---

## Bash Standards

### POSIX Compliance

**Use POSIX-compatible syntax:**
```bash
# ✅ CORRECT - POSIX compliant
if [ -n "$ZSH_VERSION" ]; then
    RC_FILE="$HOME/.zshrc"
fi

# ❌ WRONG - bash-specific double brackets
if [[ -n "$ZSH_VERSION" ]]; then
    RC_FILE="$HOME/.zshrc"
fi
```

### Quoting

**Always quote variables:**
```bash
# ✅ CORRECT - quoted variables
RC_FILE="$HOME/.zshrc"
if [ -f "$RC_FILE" ]; then
    cp "$RC_FILE" "$RC_FILE.backup"
fi

# ❌ WRONG - unquoted variables
RC_FILE=$HOME/.zshrc
if [ -f $RC_FILE ]; then
    cp $RC_FILE $RC_FILE.backup
fi
```

### Error Handling

**Set error handling flags:**
```bash
# ✅ CORRECT - exit on error
set -e  # Exit on command failure
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Or combined:
set -euo pipefail

# ❌ WRONG - no error handling
# (commands silently fail)
```

**Check command success:**
```bash
# ✅ CORRECT - check command results
if cp "$RC_FILE" "$RC_FILE.backup"; then
    echo "✅ Backup created"
else
    echo "❌ Failed to create backup"
    exit 1
fi

# ❌ WRONG - ignore failures
cp "$RC_FILE" "$RC_FILE.backup"
# Continue even if failed
```

### Functions

**Use functions for reusability:**
```bash
# ✅ CORRECT - functions for common tasks
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

SHELL_TYPE=$(detect_shell)

# ❌ WRONG - repeated code
if [ -n "$ZSH_VERSION" ]; then
    RC_FILE="$HOME/.zshrc"
fi
# ... later ...
if [ -n "$ZSH_VERSION" ]; then
    RC_FILE="$HOME/.zshrc"
fi
```

### Output

**Provide clear feedback:**
```bash
# ✅ CORRECT - informative messages
echo "🔧 Installing Claude Code scaffolder aliases..."
echo "   Detected shell: $SHELL_TYPE"
echo "   Config file: $RC_FILE"
echo "   Creating backup: $RC_FILE.backup"
echo "✅ Installation complete!"

# ❌ WRONG - silent or unclear
echo "Installing..."
echo "Done"
```

### File Operations

**Check before modifying:**
```bash
# ✅ CORRECT - check before writing
if grep -q "Claude Code Scaffolder Aliases" "$RC_FILE"; then
    echo "⚠️  Aliases already installed. Skipping."
    exit 0
fi

# Add aliases
echo "" >> "$RC_FILE"
echo "# Claude Code Scaffolder Aliases" >> "$RC_FILE"

# ❌ WRONG - no idempotency check
echo "# Claude Code Scaffolder Aliases" >> "$RC_FILE"
# Duplicates on every run
```

---

## Markdown Standards

### Emoji Markers

**Use consistent emoji for visual scanning:**

- 📋 Lists, documentation, content
- ✅ Correct examples, checkboxes, success
- ❌ Incorrect examples, anti-patterns, errors
- ⭐ Important items, highlights
- 🚨 Critical warnings, security issues
- 🔧 Configuration, tools, setup
- 📝 Writing, editing, documentation tasks
- 🎉 Success, completion
- ⚠️ Warnings, cautions

```markdown
<!-- ✅ CORRECT - consistent emoji usage -->
### Required Reading
- ⭐ `docs/coding-standards.md` - MANDATORY
- 📋 `docs/development.md` - Architecture guide

### Security Non-Negotiables
🚨 **CRITICAL:** Never commit secrets to the repository

<!-- ❌ WRONG - random or inconsistent emoji -->
### Required Reading
- 🎨 `docs/coding-standards.md`
- 🚀 `docs/development.md`
```

### Code Blocks

**Always specify language:**
```markdown
<!-- ✅ CORRECT - language specified -->
```python
def create_file(path: Path) -> None:
    path.write_text("content")
```

```bash
python3 scaffold-project.py /tmp/test
```

<!-- ❌ WRONG - no language identifier -->
```
def create_file(path):
    path.write_text("content")
```
```

**Show wrong vs right examples:**
````markdown
<!-- ✅ CORRECT - explicit comparison -->
```python
# ✅ CORRECT - type hints
def create_file(path: Path, content: str) -> None:
    pass

# ❌ WRONG - no type hints
def create_file(path, content):
    pass
```

<!-- ❌ WRONG - no context -->
```python
def create_file(path: Path, content: str) -> None:
    pass
```
````

### Headings

**Use hierarchical structure:**
```markdown
<!-- ✅ CORRECT - proper hierarchy -->
# Main Title (H1) - Only one per file

## Major Section (H2)

### Subsection (H3)

#### Detail Level (H4)

<!-- ❌ WRONG - skipping levels -->
# Main Title

### Subsection (skipped H2)
```

### Line Limits

**Keep files scannable:**

- **CLAUDE.md:** 300-400 lines (max 600)
- **Pattern docs:** 200-400 lines (max 500)
- **Development docs:** 150-300 lines (max 400)
- **README:** No strict limit (comprehensive guide)

```markdown
<!-- ✅ CORRECT - hub-and-spoke for long content -->
# Main Topic

Brief overview here (2-3 paragraphs).

For detailed information, see:
- `docs/topic-details.md` - In-depth coverage
- `docs/topic-examples.md` - Code examples

<!-- ❌ WRONG - 1000-line monolithic file -->
# Main Topic

(pages and pages of content...)
```

### Links

**Use descriptive link text:**
```markdown
<!-- ✅ CORRECT - descriptive links -->
See [coding standards](docs/coding-standards.md) for Python conventions.

For more details, refer to the [development guide](docs/development.md).

<!-- ❌ WRONG - vague link text -->
Click [here](docs/coding-standards.md) for standards.

See [this file](docs/development.md).
```

### Tables

**Use tables for structured data:**
```markdown
<!-- ✅ CORRECT - table for comparison -->
| File | Purpose | Lines | Priority |
|------|---------|-------|----------|
| CLAUDE.md | Main documentation | 350 | P0 |
| development.md | Dev guide | 250 | P0 |

<!-- ❌ WRONG - list for tabular data -->
- CLAUDE.md: Main documentation, 350 lines, P0 priority
- development.md: Dev guide, 250 lines, P0 priority
```

### Formatting

**Use bold for emphasis:**
```markdown
<!-- ✅ CORRECT - bold for key terms -->
**CRITICAL:** Read all standards before coding.

The **hub-and-spoke** pattern keeps docs maintainable.

<!-- ❌ WRONG - all caps or italics only -->
CRITICAL: Read all standards before coding.

The _hub-and-spoke_ pattern keeps docs maintainable.
```

---

## File Organization

### Directory Structure

```
project-root/
├── CLAUDE.md                 ← Hub (main index)
├── README.md                 ← User guide
├── QUICK-REFERENCE.md        ← Quick lookup
│
├── docs/                     ← Spokes (detailed docs)
│   ├── development.md
│   ├── coding-standards.md
│   └── contributing.md
│
├── templates/                ← Template files
│   ├── CLAUDE.md.EXAMPLE
│   └── docs/
│       ├── git-workflow.md
│       └── ...
│
└── scaffold-project.py       ← Main tool
```

### Naming Conventions

**File naming:**
- Use **kebab-case** for markdown: `coding-standards.md`
- Use **snake_case** for Python: `scaffold_project.py`
- Use **.sh extension** for Bash: `install.sh`

```bash
# ✅ CORRECT naming
docs/coding-standards.md
docs/feature-development-process.md
scaffold-project.py

# ❌ WRONG naming
docs/CodingStandards.md
docs/feature_development_process.md
scaffoldProject.py
```

---

## Common Patterns

### Progress Indicators

**Provide feedback during operations:**
```python
# ✅ CORRECT - show progress
print(f"Creating project structure in: {project_dir}")
print(f"  ✅ Created CLAUDE.md")
print(f"  ✅ Copied 3 generic docs")
print(f"  ✅ Created 10 placeholder files")

# ❌ WRONG - silent operation
create_files()  # No output
```

### Placeholder Syntax

**Use consistent placeholder format:**
```markdown
<!-- ✅ CORRECT - square bracket placeholders -->
**Project Name:** [your-project-name]
**Tech Stack:** [Python, TypeScript, etc.]

<!-- ❌ WRONG - inconsistent syntax -->
**Project Name:** {your-project-name}
**Tech Stack:** <fill this in>
```

### Error Messages

**Be specific and actionable:**
```python
# ✅ CORRECT - actionable error
print(f"Error: Template file not found: {template_path}")
print(f"Expected location: {template_path.resolve()}")
print(f"Please ensure you're running from the project root directory.")

# ❌ WRONG - vague error
print("File not found")
```

### Comments

**Explain WHY, not WHAT:**
```python
# ✅ CORRECT - explains reasoning
# Use pathlib instead of os.path for cross-platform compatibility
templates_dir = Path(__file__).parent / 'templates'

# ❌ WRONG - states the obvious
# Get templates directory
templates_dir = Path(__file__).parent / 'templates'
```

---

## Standards Checklist

Before committing code, verify:

**Python:**
- [ ] Follows PEP 8 conventions
- [ ] Uses type hints for function signatures
- [ ] Uses pathlib for all file operations
- [ ] Has docstrings for public functions
- [ ] No external dependencies (stdlib only)
- [ ] Includes error handling with specific exceptions

**Bash:**
- [ ] POSIX-compliant syntax (no bash-isms)
- [ ] All variables properly quoted
- [ ] Error handling with `set -e` or checks
- [ ] Functions for reusable logic
- [ ] Clear user-facing output

**Markdown:**
- [ ] Language specified for all code blocks
- [ ] Consistent emoji markers
- [ ] Hierarchical heading structure
- [ ] File under line limit for document type
- [ ] Descriptive link text
- [ ] Tables for tabular data

**General:**
- [ ] Consistent naming conventions
- [ ] Clear error messages
- [ ] Progress indicators for long operations
- [ ] Updated documentation for changes

---

## Examples from Codebase

### scaffold-project.py Excerpt
```python
def create_claude_md(project_dir: Path, templates_dir: Path) -> None:
    """
    Copy CLAUDE.md.EXAMPLE to project as CLAUDE.md.

    Args:
        project_dir: Target project directory
        templates_dir: Source templates directory
    """
    source = templates_dir / 'CLAUDE.md.EXAMPLE'
    target = project_dir / 'CLAUDE.md'

    if not source.exists():
        print(f"❌ Error: Template not found: {source}")
        return

    try:
        shutil.copy2(source, target)
        print(f"  ✅ Created CLAUDE.md")
    except PermissionError:
        print(f"❌ Error: Permission denied writing to: {target}")
    except Exception as e:
        print(f"❌ Error copying CLAUDE.md: {e}")
```

### install.sh Excerpt
```bash
#!/usr/bin/env bash

set -euo pipefail

detect_shell() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        echo "$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        echo "$HOME/.bashrc"
    else
        echo ""
    fi
}

RC_FILE=$(detect_shell)

if [ -z "$RC_FILE" ]; then
    echo "❌ Error: Unsupported shell"
    exit 1
fi

echo "🔧 Installing aliases to: $RC_FILE"
```

---

## Further Reading

- **PEP 8:** https://peps.python.org/pep-0008/
- **pathlib Guide:** https://docs.python.org/3/library/pathlib.html
- **POSIX Shell:** https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- **CommonMark Spec:** https://spec.commonmark.org/

---

**Questions about these standards?** Open an issue or propose updates to this document.
