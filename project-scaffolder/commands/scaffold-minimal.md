---
description: Scaffold minimal project with CLAUDE.md, commands, hooks, and core workflow skill only
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion
argument-hint: <project-path> [--name "Name"] [--author "Author"]
---

# Scaffold Minimal Project

Add essential Claude Code files to a project. Use for quick prototypes or existing repos.

## Arguments

- `project-path` (required): Target directory
- `--name`: Project name (default: folder name)
- `--author`: Author name

## What's Included

| Component                            | Included |
| ------------------------------------ | -------- |
| CLAUDE.md                            | Yes      |
| .claude-plugin/plugin.json           | Yes      |
| .claude/commands/ (6 files)          | Yes      |
| .claude/hooks/hooks.json             | Yes      |
| .claude/skills/development-workflow/ | Yes      |
| .claude/skills/project-standards/    | No       |
| .claude/skills/exploration-helpers/  | No       |
| .claude/project/ (tracking)          | Yes      |

## Process

### Step 1: Validate Target

**Check if target is the plugin directory:**

```bash
# If target path contains/equals ${CLAUDE_PLUGIN_ROOT}, STOP
# Error: "Cannot scaffold into the plugin's own directory"
```

**Check if target exists:**

- If directory doesn't exist → Create it, proceed to Step 2
- If directory exists → Proceed to Step 1b

### Step 1b: Handle Existing Directory

**Scan for existing Claude Code files:**

```bash
# Check for these paths in target:
# - CLAUDE.md
# - .claude-plugin/
# - .claude/commands/
# - .claude/hooks/
# - .claude/skills/
# - .claude/project/
```

**Use AskUserQuestion to show status and ask:**

```
Found existing directory: <path>

Existing files detected:
- CLAUDE.md: [Yes/No]
- .claude-plugin/: [Yes/No]
- .claude/commands/: [Yes/No]
- .claude/hooks/: [Yes/No]
- .claude/skills/: [Yes/No]
- .claude/project/: [Yes/No]

How would you like to proceed?

Options:
1. Merge (skip existing files, add missing only)
2. Overwrite (replace all Claude Code files)
3. Abort (cancel scaffolding)
```

### Step 2: Create Directories

```
<path>/
├── .claude-plugin/
└── .claude/
    ├── commands/
    ├── hooks/
    ├── skills/development-workflow/
    └── project/{features,plans}/
```

### Step 3: Copy Templates (Minimal Set)

Copy from `${CLAUDE_PLUGIN_ROOT}/resources/templates/`:

| Source                               | Destination                          |
| ------------------------------------ | ------------------------------------ |
| CLAUDE.md                            | CLAUDE.md                            |
| .claude-plugin/plugin.json           | .claude-plugin/plugin.json           |
| .claude/commands/\*.md               | .claude/commands/\*.md               |
| .claude/hooks/hooks.json             | .claude/hooks/hooks.json             |
| .claude/skills/development-workflow/ | .claude/skills/development-workflow/ |
| .claude/project/\*                   | .claude/project/\*                   |

**NOT copied (full mode only):**

- .claude/skills/project-standards/
- .claude/skills/exploration-helpers/

### Step 4: Replace Placeholders

In all copied files:

- `[PROJECT_NAME]` → project name
- `[DESCRIPTION]` → description (or "A new project")
- `[PROJECT_NAME_KEBAB]` → kebab-case name

### Step 5: Report Results

```markdown
## Minimal Scaffolding Complete

**Project:** <name>
**Location:** <path>

### Files Created

- [x] CLAUDE.md
- [x] .claude-plugin/plugin.json
- [x] .claude/commands/ (6 workflow commands)
- [x] .claude/hooks/hooks.json
- [x] .claude/skills/development-workflow/
- [x] .claude/project/ (tracking files)

### Not Included (use /scaffold for full)

- [ ] .claude/skills/project-standards/
- [ ] .claude/skills/exploration-helpers/

### Next Steps

1. Customize CLAUDE.md for your project
2. Run `/implement` to start a feature

**Want full skills?** Run `/scaffold <path>` with overwrite option.
```

## Use Cases

- Quick prototypes
- Adding workflow to existing repos
- Projects where you'll add skills manually
- Lightweight documentation setup
