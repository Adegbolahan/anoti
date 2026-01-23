---
description: Update Claude Code files in an existing scaffolded project to the latest version
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion, Edit
---

# Update Project

Update Claude Code files in an existing project to the latest template version.

## Process

### Step 1: Determine Target

Check if current directory has `.claude/settings.json`:
- If yes → Use current directory
- If no → Ask user for project path

### Step 2: Validate Project

**Check project has been scaffolded:**

Read `.claude/settings.json` and extract:
- `scaffoldVersion` (e.g., "1.0.0")
- `scaffoldDate` (e.g., "2024-01-15")

If missing: "This project wasn't scaffolded or uses an older version without tracking."

Read template's `.claude/settings.json` from `${CLAUDE_PLUGIN_ROOT}/resources/templates/` and get current `scaffoldVersion`.

### Step 3: Compare Versions

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
```

### Step 4: Show Update Options

**Use AskUserQuestion:**
```
What would you like to update?

Options:
1. All Claude Code files (recommended)
2. Settings only (.claude/settings.json)
3. Commands only (.claude/commands/*.md)
4. Skills only (.claude/skills/*)
5. Cancel
```

### Step 5: Identify Files to Update

**Always preserve (never overwrite):**
- CLAUDE.md (user customizations)
- .claude/project/* (user stories, plans, roadmap)

**Safe to update:**
- .claude/settings.json (merge: keep custom settings, update scaffoldVersion)
- .claude/commands/*.md
- .claude/skills/*/SKILL.md
- .claude/skills/*/references/*.md

### Step 6: Perform Update

For each file being updated:

1. Read template file from `${CLAUDE_PLUGIN_ROOT}/resources/templates/`
2. Replace placeholders using project's existing values
3. Write updated file

### Step 7: Update Version Tracking

Update `.claude/settings.json`:
- Set `scaffoldVersion` to latest
- Set `scaffoldDate` to today

### Step 8: Report Results

```markdown
## Update Complete

**Project:** <name>
**Updated from:** X.X.X → Y.Y.Y

### Files Updated

- [x] .claude/settings.json
- [x] .claude/commands/*.md
- [x] ... (list updated files)

### Files Preserved

- [x] CLAUDE.md
- [x] .claude/project/*

### What's New

- [List changes in this version]
```

## Safety Checks

1. **Never overwrite CLAUDE.md**
2. **Never overwrite project tracking files**
3. **Suggest git commit before updating**
