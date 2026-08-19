---
description: Update an existing anoti workspace to the installed plugin version — migration by ratified diff, never silent.
allowed-tools: Write, Bash, Read, Glob, AskUserQuestion, Edit
---

# Update Workspace

Bring a project's anoti workspace up to date with the installed plugin.
There is deliberately little to update: skills, agents, hooks, and
helpers live in the plugin and move with it; the project holds only its
workspace documents and memory store.

## Process

1. **Read versions.** The workspace's scaffold version (recorded by
   skillify at bootstrap) versus the plugin's
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` version.
2. **Compare.**
   - Same → "Workspace is up to date (X.Y.Z)." Stop.
   - Workspace NEWER than the installed plugin → stop; **never
     downgrade**: "This workspace was scaffolded by a version newer than
     the installed plugin. Update the plugin first."
   - Older → report the gap and continue.
3. **Migrate via the skillify skill's migration contract:** dated backup
   of each affected file, the migration produced as a **proposed diff**,
   the human ratifies before anything applies — no silent upgrades.
   Schema migrations follow the grandfathering rule (evidence-less
   `established` claims demote to `probable` with a dated event).
4. **Verify:** `scripts/validate-workspace`, `regen-index`, `trust` on
   the store; then run the digest once and show it —
   `scripts/anoti digest` (the operator-runnable form of the SessionStart
   hook; plain text, no envelope).
4b. **Recall coverage (0.5.22+):** JIT recall surfaces only records that
   carry `triggers:`, and a store written before 0.5.22 has none — report
   `N/M project records carry triggers` (and the global store's count)
   every run, and when a migration crosses 0.5.22 say plainly that the
   feature is inert until triggers exist. Backfilling is a judgment
   task, never mechanical: consolidate step 2b's encoding-time question
   ("what would a future session need to see to be reminded of this?"),
   applied record by record via `scripts/anoti append-trigger`, ideally
   starting with the records the audit shows were missed.
5. **Report** what moved, what was backed up, and anything queued for
   `/anoti:review`.
