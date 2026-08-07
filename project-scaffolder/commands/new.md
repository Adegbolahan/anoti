---
description: Scaffold a new project with CLAUDE.md, project tracking, and the enforced workflow
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion
---

# New Project

Set up a project to use the enforced development workflow.

**What gets copied is deliberately small.** The workflow commands, skills, hooks
and state machine ship inside this plugin and are versioned with it. Only the
genuinely project-specific files land in the repo, so there is almost nothing to
migrate when the plugin updates.

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

Derive the project name from the folder name (Title Case for display).

### Step 2: Validate Target

**Check the target is not this plugin's own directory:**

- If the target path contains or equals `${CLAUDE_PLUGIN_ROOT}`, STOP with an error.

**Check if the target exists:**

- Directory does not exist → create it, go to Step 3
- Directory exists with Claude Code files → Step 2b

### Step 2b: Handle Existing Directory

Scan for `CLAUDE.md` and `.claude/`.

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
    └── project/
        ├── features/
        └── plans/
```

No `commands/`, `skills/` or `hooks/` directories. Those live in the plugin.

### Step 4: Copy Templates

Copy from `${CLAUDE_PLUGIN_ROOT}/resources/templates/`:

| Source                                     | Destination           | Skip if exists (merge) |
| ------------------------------------------ | --------------------- | ---------------------- |
| CLAUDE.md                                  | CLAUDE.md             | Yes                    |
| .claude/settings.json                      | .claude/settings.json | Yes                    |
| .claude/project/high-level-user-stories.md | same                  | Yes                    |
| .claude/project/roadmap.md                 | same                  | Yes                    |
| .claude/project/workflow-state.sh          | same                  | No — always refresh    |
| .claude/project/{features,plans}/.gitkeep  | same                  | Yes                    |

`workflow-state.sh` is a shim, not the state machine. It is always refreshed
because it contains the resolved plugin path and no user content.

### Step 5: Replace Placeholders

In all copied files:

- `[PROJECT_NAME]` → project name (Title Case)
- `[DESCRIPTION]` → "A new project"
- `[PROJECT_NAME_KEBAB]` → kebab-case name
- `[SCAFFOLD_DATE]` → today's date (YYYY-MM-DD)
- `[DATE]` → today's date (YYYY-MM-DD)
- `[PLUGIN_ROOT]` → the value of `${CLAUDE_PLUGIN_ROOT}` (shim only)

### Step 5b: Post-Copy Setup

1. **Make the shim executable:**

   ```bash
   chmod +x .claude/project/workflow-state.sh
   ```

2. **Verify it resolves.** If this fails, the shim has the wrong plugin path and
   every workflow command in the docs will fail for the user:

   ```bash
   .claude/project/workflow-state.sh --help >/dev/null && echo "state machine OK"
   ```

3. **Add the runtime state files to .gitignore** (create it if needed). These are
   per-developer working state, never shared:

   ```
   .claude/project/.workflow-state.json
   .claude/project/.workflow-log.jsonl
   .claude/project/.turn-touched
   .claude/project/.workflow-state.lock/
   ```

   `.claude/project/reviews/` holds review reports. Leave those **tracked** —
   they are the evidence behind each passed review and belong in history.

### Step 6: Report Results

```markdown
## Project Created

**Project:** <name>
**Location:** <path>

### Files Created

- [x] CLAUDE.md
- [x] .claude/settings.json (version tracking)
- [x] .claude/project/ (tracking files + workflow-state shim)

Workflow commands, skills and hooks come from the plugin — nothing to maintain
in this repo.

### Important

**Restart Claude Code** before starting work. Hook configuration is read at
session start, so the workflow gates are not active in this session.

### Next Steps

1. Review and customize CLAUDE.md
2. Restart Claude Code
3. Start building with `/implement`

**Tip:** ask "help me customize this for [your tech stack]"
```

## Safety Checks

1. **Never scaffold into the plugin directory**
2. **Preserve existing source code** — only touch `CLAUDE.md` and `.claude/`
3. **Confirm before overwrite**
