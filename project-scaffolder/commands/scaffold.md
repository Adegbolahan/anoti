---
description: Scaffold a new project with CLAUDE.md, workflow commands, skills, and project tracking
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion
argument-hint: <project-path> [--name "Name"] [--author "Author"] [--description "Desc"] [--tech-stack "stack"]
---

# Scaffold Project

Add Claude Code documentation, workflow commands, skills, and project tracking to a project.

## Arguments

- `project-path` (required): Target directory
- `--name`: Project name (default: folder name)
- `--author`: Author name
- `--description`: Project description
- `--tech-stack`: Tech stack for customization hints

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

- **Merge**: Only create files that don't exist
- **Overwrite**: Replace all Claude Code files (backup warning)
- **Abort**: Exit without changes

### Step 2: Create Directories

```
<path>/
├── .claude-plugin/
└── .claude/
    ├── commands/
    ├── hooks/
    ├── skills/{development-workflow,project-standards,exploration-helpers}/
    └── project/{features,plans}/
```

### Step 3: Copy Templates

Copy from `${CLAUDE_PLUGIN_ROOT}/resources/templates/`:

| Source                     | Destination                | Skip if exists (merge) |
| -------------------------- | -------------------------- | ---------------------- |
| CLAUDE.md                  | CLAUDE.md                  | Yes                    |
| .claude-plugin/plugin.json | .claude-plugin/plugin.json | Yes                    |
| .claude/commands/\*.md     | .claude/commands/\*.md     | Yes                    |
| .claude/hooks/hooks.json   | .claude/hooks/hooks.json   | Yes                    |
| .claude/skills/\*          | .claude/skills/\*          | Yes                    |
| .claude/project/\*         | .claude/project/\*         | Yes                    |

### Step 4: Replace Placeholders

In all copied files:

- `[PROJECT_NAME]` → project name
- `[DESCRIPTION]` → description (or "A new project")
- `[PROJECT_NAME_KEBAB]` → kebab-case name

### Step 5: Report Results

**On success, show:**

```markdown
## Scaffolding Complete

**Project:** <name>
**Location:** <path>

### Files Created

- [x] CLAUDE.md
- [x] .claude-plugin/plugin.json
- [x] .claude/commands/ (6 workflow commands)
- [x] .claude/hooks/hooks.json
- [x] .claude/skills/ (3 skills)
- [x] .claude/project/ (tracking files)

### Files Skipped (already existed)

- [ ] <list any skipped files>

### Next Steps

1. Review and customize CLAUDE.md
2. Update tech stack section
3. Run `/implement` to start your first feature

**Tip:** Ask "Help me customize these templates for [your-tech-stack]"
```

## Safety Checks

1. **Never scaffold into plugin directory** - Prevent `${CLAUDE_PLUGIN_ROOT}` as target
2. **Preserve existing source code** - Only touch `.claude/` and `.claude-plugin/`
3. **Confirm before overwrite** - Always ask before replacing existing files
4. **Show what will change** - List files before any modifications
