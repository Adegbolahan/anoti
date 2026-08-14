---
description: Set up a project with the anoti workspace — governed memory, direction documents, and the cognitive workflow.
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion
---

# New Project

Set up a project to use anoti. What lands in the repo is deliberately
small: the workspace documents and memory store. Skills, agents, hooks,
and helpers ship in the plugin and upgrade with it.

## Process

1. **Determine target.** Ask where to create the project (current
   directory or a path). Derive the display name from the folder name.
2. **Validate target.** Never scaffold into the plugin's own directory —
   if the target contains or equals `${CLAUDE_PLUGIN_ROOT}`, stop with an
   error. If the target has existing Claude Code files, ask: merge (add
   missing only) / overwrite (confirm twice) / abort.
3. **Bootstrap via the skillify skill** — load `skills/skillify/SKILL.md`
   and follow its contract exactly (idempotent, create-only, templates
   from the plugin, `validate-workspace` + `regen-index` + `trust` on the
   new store, gitignore fragment for the state dir).
4. **Git insurance.** Everything downstream assumes a repository (trust
   hashes, retrieval, commit history as the record):
   - `git rev-parse --show-toplevel` prints the target → already a repo.
   - Prints a path ABOVE the target → the project is inside a monorepo.
     **Do not `git init`** — that would nest repos and detach history.
     Tell the user which repo encloses it.
   - Prints nothing → `git init` and say so plainly.
5. **Report** what was created, what was skipped (merge mode), and:
   **restart Claude Code** — hooks load at session start, so the
   retrieval digest and gates are not active in this session.
   After the restart, point the session at the **demo skill** for
   orientation — the workflows, when to use what, and a runnable tour.

## Safety

1. Never scaffold into the plugin directory.
2. Preserve existing source — touch only workspace files.
3. Confirm before any overwrite.
