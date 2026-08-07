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
- .claude/project/\* (user stories, plans, roadmap)

**Safe to update:**

- .claude/settings.json (merge: keep custom hooks, update scaffoldVersion + add new workflow hooks)
- .claude/commands/\*.md (old commands like discovery.md, plan-and-validate.md, etc. will be removed; replaced by implement.md + review.md)
- .claude/skills/\*/SKILL.md
- .claude/skills/_/references/_.md
- .claude/project/workflow-state.sh (new in v2.0.0 — add if missing)
- .claude/project/hooks/\*.sh (new in v2.2.0 — add if missing)

### Step 5b: v2.0.0 Migration (if upgrading from v1.x)

If the project's current version is 1.x.x:

1. **Delete old commands:** Remove `discovery.md`, `plan-and-validate.md`, `start-implementation.md`, `review-implementation.md`, `next.md` from `.claude/commands/`
2. **Add new files:** Copy `workflow-state.sh` to `.claude/project/` and make it executable
3. **Add .gitignore entry:** Append `.claude/project/.workflow-state.json` to `.gitignore`
4. **Warn about CLAUDE.md:** "Your CLAUDE.md may reference old commands (/discovery, /plan-and-validate, etc.). Consider updating the Feature Development Workflow section to reference /implement and /review only."

### Step 5c: v2.1.0 Migration (if upgrading from v2.0.x)

If the project's current version is 2.0.x:

1. **Update workflow-state.sh:** Replace with new version that adds review cycle states (`under_review`, `changes_requested`, `review_passed`), backward transition support, `set-findings`, `get-findings`, `review-cycle` commands, and `reviewCycle`/`reviewFindings` in state JSON
2. **Update settings.json hooks:** Add commit gate (blocks `git commit` unless `review_passed`), add `under_review` warning to source edit hook, add fix tracking during `changes_requested`, gate completion to only advance from `review_passed`
3. **Update review.md:** Replace with the review cycle and automated fix loop
4. **Update implement.md:** Phase 3 changes from "Validate" to "Review Cycle" with mandatory test categories and `/review` integration
5. **Warn about CLAUDE.md:** "Your CLAUDE.md may reference the old Phase 3 (Validate). Consider updating to document the review cycle: Phase 3 now runs a review with an automated fix loop, and commits are BLOCKED by hooks until review passes."

### Step 5d: v2.2.0 Migration (if upgrading from 2.0.x or 2.1.x)

The commit gate did not work before 2.2.0. This migration is what makes it work,
so do not skip it.

1. **Add the hook scripts:** copy `.claude/project/hooks/` from the templates and
   `chmod +x .claude/project/hooks/*.sh`.

2. **Replace `settings.json` wholesale.** Hook bodies moved out of JSON and into
   those scripts. The old file had 4 `PreToolUse` groups and 3 `PostToolUse`
   groups; hooks in the same event run in parallel and race on the state file.
   The new file registers exactly one hook per event.

   If the project added custom hooks of its own, carry them over by hand and
   tell the user which ones you moved. Do not silently drop them.

3. **Replace `workflow-state.sh`.** New in this version: named accessors
   (`get-phase`, `get-story`, `get-findings-count`, `get-review-cycle`) replacing
   the generic `get-field`, a `snapshot` command, a `mkdir` write lock,
   `schemaVersion` with forward migration, `override`, and `why-blocked`.

4. **Fix callers of the removed `get-field`.** It is gone. Search the project for
   it and rewrite: `get-field activeStory` becomes `get-story`, `get-field phase`
   becomes `get-phase`. `/review` and `/implement` are updated by this migration,
   but a customized copy may have its own callers.

5. **Extend `.gitignore`:**

   ```
   .claude/project/.workflow-log.jsonl
   .claude/project/.turn-touched
   .claude/project/.workflow-state.lock/
   ```

   (`.workflow-state.json` should already be there from v2.0.0.)

6. **Warn the user that behaviour changes:**

   > "The commit gate now actually blocks. Before 2.2.0 it never fired, because
   > nothing advanced the phase to `implementation_in_progress`. It also blocks
   > on states it cannot evaluate — missing `jq`, a corrupt state file, an
   > unrecognised phase. If you get stuck, run
   > `.claude/project/workflow-state.sh why-blocked`, or arm a recorded one-shot
   > bypass with `workflow-state.sh override "<reason>"`."

7. **Tell them to restart Claude Code.** Hook configuration is read at session
   start, so the new hooks do not take effect in the current session.

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
- [x] .claude/commands/\*.md
- [x] ... (list updated files)

### Files Preserved

- [x] CLAUDE.md
- [x] .claude/project/\*

### What's New

- [List changes in this version]
```

## Safety Checks

1. **Never overwrite CLAUDE.md**
2. **Never overwrite project tracking files**
3. **Suggest git commit before updating**
