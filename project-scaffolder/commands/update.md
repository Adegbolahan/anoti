---
description: Update an existing scaffolded project to the latest plugin version
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion, Edit
---

# Update Project

Bring an existing project up to date with this plugin.

**Since v3.0.0 there is almost nothing to update.** Workflow commands, skills,
hooks and the state machine live in the plugin and move with it. A project holds
only `CLAUDE.md`, its tracking files, and a shim. Upgrading the plugin upgrades
the workflow.

The one real migration is getting a pre-v3 project out of the old arrangement,
where those components were copied into the repo and drifted.

## Process

### Step 1: Determine Target

Check if the current directory has `.claude/settings.json`:

- Yes → use the current directory
- No → ask the user for the project path

### Step 2: Read the current version

Read `.claude/settings.json` and extract `scaffoldVersion` and `scaffoldDate`.

If `scaffoldVersion` is missing, this project predates version tracking. Treat it
as pre-v3 and run the migration below.

Read this plugin's version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

### Step 3: Compare

**Same version:** "Project is up to date (version X.Y.Z)." Stop.

**Project is NEWER than the plugin:** stop and say so. Do not downgrade:

> "This project was scaffolded by version X.Y.Z, which is newer than the
> installed plugin (A.B.C). Update the plugin first: `/plugin update`."

**Project is older:** report the gap and continue.

### Step 4: Pre-v3 migration (if scaffoldVersion is below 3.0.0)

This is the one that matters. Before v3, the workflow commands, skills, hooks and
state machine were **copied into the project**. The plugin now provides them, and
a copy left in place **shadows the plugin's version** — so the project would keep
running old, broken code while appearing to have upgraded.

**4a. Confirm first.** This deletes files from their repo:

**Use AskUserQuestion:**

```
This project has workflow files copied into it from an older version. The plugin
now provides these, and the copies would shadow it — you would keep running the
old versions.

I will move them to .claude/.backup-pre-v3/ and then remove them:
  .claude/commands/          (implement.md, review.md)
  .claude/skills/            (development-workflow, project-standards, exploration-helpers)
  .claude/project/hooks/     (if present)
  .claude/project/workflow-state.sh  (replaced by a shim)

Options:
1. Back up and migrate (recommended)
2. Show me the file list first
3. Cancel
```

**4b. Back up, then remove.**

```bash
mkdir -p .claude/.backup-pre-v3
for p in .claude/commands .claude/skills .claude/project/hooks .claude/project/workflow-state.sh; do
  [ -e "$p" ] && mv "$p" .claude/.backup-pre-v3/ 2>/dev/null
done
```

Print exactly what moved. Never remove anything silently.

**4c. Install the shim.** Copy `resources/templates/.claude/project/workflow-state.sh`,
replace `[PLUGIN_ROOT]` with `${CLAUDE_PLUGIN_ROOT}`, `chmod +x`, then verify:

```bash
.claude/project/workflow-state.sh --help >/dev/null && echo "state machine OK"
```

**4d. Strip hooks from settings.json.** Hooks now come from the plugin. Keep
`permissions` and anything the user added; remove the `hooks` block; update
`scaffoldVersion` and `scaffoldDate`.

If the project had **custom** hooks of its own, do not drop them. Show them to
the user and ask whether to keep them in `settings.json` — plugin hooks and user
hooks merge, so both will run.

**4e. Extend `.gitignore`:**

```
.claude/project/.workflow-state.json
.claude/project/.workflow-log.jsonl
.claude/project/.turn-touched
.claude/project/.workflow-state.lock/
```

Leave `.claude/project/reviews/` tracked — those reports are the evidence behind
each passed review.

**4f. Warn about CLAUDE.md.** It is never overwritten, so it may still describe
the old arrangement:

> "Your CLAUDE.md may reference `.claude/commands/` or `.claude/skills/`, which
> no longer exist in this project — the plugin provides them now. It may also
> describe a commit gate that never fired: before v2.2.0 it did not, and before
> v2.3.0 the agent could open it in two commands. Want me to update those
> sections?"

**4g. Behaviour changes to state plainly:**

> - The commit gate now blocks, including on states it cannot evaluate (missing
>   `jq`, corrupt state, unrecognised phase).
> - Passing review requires evidence: `advance review_passed --evidence <path>`.
> - `/review` no longer dispatches four sub-agents it never shipped.
> - Stuck? `.claude/project/workflow-state.sh why-blocked`, or arm a recorded
>   one-shot bypass with `workflow-state.sh override "<reason>"`.

### Step 5: Restart marker

Hook configuration is read at session start, so the new hooks are **not active in
the current session**:

```bash
date -u +%Y-%m-%dT%H:%M:%SZ > .claude/project/.upgrade-pending
```

Print loudly:

> **Restart Claude Code now.** Until you do, this session is running the old hook
> configuration. `SessionStart` clears this marker and confirms the new hooks are
> live.

### Step 6: Report

```markdown
## Update Complete

**Project:** <name>
**Updated:** X.Y.Z → A.B.C

### Moved to .claude/.backup-pre-v3/

- [list exactly what moved]

### Preserved

- [x] CLAUDE.md
- [x] .claude/project/ (stories, plans, roadmap)

### Action required

**Restart Claude Code.** Hooks load at session start.
```

## Safety Checks

1. **Never overwrite CLAUDE.md**
2. **Never touch `.claude/project/features/`, `plans/`, `roadmap.md` or `high-level-user-stories.md`**
3. **Never delete without backing up first, and always print what moved**
4. **Suggest committing before updating**
