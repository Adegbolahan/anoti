---
description: Scaffold a new project with CLAUDE.md, workflow commands, skills, and project tracking
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion
---

# New Project

Add Claude Code documentation, workflow commands, skills, and project tracking to a project.

## Process

### Step 1: Determine Target

Ask the user where to create the project:

**Use AskUserQuestion:**
```
Where would you like to create the project?

Options:
1. Current directory (.)
2. Specify a path
```

If user selects "Specify a path", ask for the path.

Derive project name from the folder name (convert to Title Case for display).

### Step 2: Validate Target

**Check if target is the plugin directory:**
- If target path contains/equals ${CLAUDE_PLUGIN_ROOT}, STOP with error

**Check if target exists:**
- If directory doesn't exist → Create it, proceed to Step 3
- If directory exists with Claude Code files → Proceed to Step 2b

### Step 2b: Handle Existing Directory

**Scan for existing Claude Code files:**
- CLAUDE.md
- .claude/settings.json
- .claude/commands/
- .claude/skills/
- .claude/project/

**Use AskUserQuestion:**
```
Found existing Claude Code files in this directory.

How would you like to proceed?

Options:
1. Merge (skip existing files, add missing only)
2. Overwrite (replace all Claude Code files)
3. Abort (cancel)
```

### Step 3: Create Directories

```
<path>/
└── .claude/
    ├── commands/
    ├── skills/{development-workflow,project-standards,exploration-helpers}/
    └── project/{features,plans}/
```

### Step 4: Copy Templates

Copy from `${CLAUDE_PLUGIN_ROOT}/resources/templates/`:

| Source                 | Destination            | Skip if exists (merge) |
| ---------------------- | ---------------------- | ---------------------- |
| CLAUDE.md              | CLAUDE.md              | Yes                    |
| .claude/settings.json  | .claude/settings.json  | Yes                    |
| .claude/commands/*.md  | .claude/commands/*.md  | Yes                    |
| .claude/skills/*       | .claude/skills/*       | Yes                    |
| .claude/project/*      | .claude/project/*      | Yes                    |

### Step 5: Replace Placeholders

In all copied files:

- `[PROJECT_NAME]` → project name (Title Case)
- `[DESCRIPTION]` → "A new project"
- `[PROJECT_NAME_KEBAB]` → kebab-case name
- `[SCAFFOLD_DATE]` → today's date (YYYY-MM-DD)
- `[DATE]` → today's date (YYYY-MM-DD)

### Step 6: Report Results

```markdown
## Project Created

**Project:** <name>
**Location:** <path>

### Files Created

- [x] CLAUDE.md
- [x] .claude/settings.json
- [x] .claude/commands/ (6 workflow commands)
- [x] .claude/skills/ (3 skills)
- [x] .claude/project/ (tracking files)

### Next Steps

1. Review and customize CLAUDE.md
2. Start building with `/implement`

**Tip:** Ask "Help me customize for [your-tech-stack]"
```

## Safety Checks

1. **Never scaffold into plugin directory**
2. **Preserve existing source code** - Only touch `.claude/`
3. **Confirm before overwrite**
