---
description: Update Claude Code files in an existing scaffolded project to the latest version
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion, Edit
argument-hint: <project-path>
---

# Scaffold Update

Update Claude Code files in an existing project to the latest template version.

## Arguments

- `project-path` (required): Target directory with existing scaffold

## Process

### Step 1: Validate Target

**Check project has been scaffolded:**

```bash
# Must have .claude-plugin/plugin.json with scaffoldVersion field
# If missing: "This project wasn't scaffolded or uses an older version without tracking."
```

Read target's `.claude-plugin/plugin.json` and extract:

- `scaffoldVersion` (e.g., "1.0.0")
- `scaffoldDate` (e.g., "2024-01-15")

Read template's `.claude-plugin/plugin.json` from `${CLAUDE_PLUGIN_ROOT}/resources/templates/` and get current `scaffoldVersion`.

### Step 2: Compare Versions

**If versions match:**

```
Project is up to date (version X.X.X)
No updates needed.
```

**If project is older:**

```
Update available!

Current: X.X.X (scaffolded YYYY-MM-DD)
Latest:  Y.Y.Y

Changes in this update:
- [List changes based on version diff]
```

### Step 3: Show Update Options

**Use AskUserQuestion:**

```
What would you like to update?

Options:
1. All Claude Code files (recommended)
2. Hooks only (.claude/hooks/hooks.json)
3. Commands only (.claude/commands/*.md)
4. Skills only (.claude/skills/*)
5. Select specific files
6. Cancel
```

### Step 4: Identify Files to Update

**Always preserve (never overwrite):**

- CLAUDE.md (user customizations)
- .claude/project/\* (user stories, plans, roadmap)

**Safe to update (no user customizations expected):**

- .claude/hooks/hooks.json
- .claude/commands/\*.md
- .claude/skills/\*/SKILL.md
- .claude/skills/_/references/_.md

**Merge strategy for plugin.json:**

- Keep project's `name`, `version`, `description`
- Update `scaffoldVersion` and `scaffoldDate`
- Keep other custom fields

### Step 5: Perform Update

For each file being updated:

1. **Read current file** (for backup reference)
2. **Read template file** from `${CLAUDE_PLUGIN_ROOT}/resources/templates/`
3. **Replace placeholders** using project's existing values:
   - `[PROJECT_NAME]` → from existing CLAUDE.md or plugin.json
   - `[PROJECT_NAME_KEBAB]` → from existing plugin.json name
   - `[SCAFFOLD_DATE]` → today's date
4. **Write updated file**

### Step 6: Update Version Tracking

Update `.claude-plugin/plugin.json`:

- Set `scaffoldVersion` to latest
- Set `scaffoldDate` to today

### Step 7: Report Results

```markdown
## Update Complete

**Project:** <name>
**Updated from:** X.X.X → Y.Y.Y

### Files Updated

- [x] .claude/hooks/hooks.json
- [x] .claude/commands/implement.md
- [x] .claude/commands/discovery.md
- [x] ... (list all updated files)

### Files Preserved

- [x] CLAUDE.md (user customizations kept)
- [x] .claude/project/\* (tracking files kept)

### What's New

- Auto-increment US-XXX numbers
- Auto-update timestamps
- [Other changes in this version]

### Next Steps

Review the updated files to understand new features.
```

## Version History

Track changes between versions for the "What's New" section:

**1.0.0 → 1.1.0:**

- Added auto-increment for US-XXX user story numbers
- Added auto-timestamp updates for tracking files
- Added scaffoldVersion and scaffoldDate tracking

## Safety Checks

1. **Never overwrite CLAUDE.md** - Contains user customizations
2. **Never overwrite project tracking** - User stories, plans, roadmap
3. **Backup warning** - Suggest git commit before updating
4. **Preserve custom plugin.json fields** - Only update scaffold-related fields
