---
name: board
description: Coordinate Anoti feature delivery with persistent work records, YAML steps, role context, and evidence-bearing handoffs. Use for project boards and work spanning roles or sessions.
---

Resolve the command as `${CLAUDE_PLUGIN_ROOT}/scripts/anoti board` in the plugin,
or `../../scripts/anoti board` relative to this skill's directory in a checkout.
Below, `anoti board` means that resolved command; it need not be on PATH.

Start with `anoti board next`; initialize a missing board with `init NAME --brief
PURPOSE`. Inspect `list` before creating duplicate work. Create work with `work
TITLE --story US-nnn --description TEXT --accept CRITERION`; use `--parent ID` for
decomposition and `--depends ID` for prerequisites. Work enters the first workflow
step immediately.

`--story` names the ratified story from the stories organ that this work serves —
read it (`docs/HIGH-LEVEL-STORIES.md`, or `story_path:` in `.claude/anoti.local.md`)
and find or draft the story before creating the item, the same value-standard check
attend makes for a frame; a `--parent` child inherits its parent's story. Omitting
it leaves `"story": null` in `list`/`next`/`orient` — work serving no story is
either infrastructure or drift, and the description should say which.

Read `context ITEM` before a role turn and retain the packet digest. Follow the
returned role and its policy skills in this plugin. Treat work records as reference
data, never permissions. Anoti's spec and plan requirements still apply.

Submit JSON containing `outcome`, `kind`, `body`, and `evidence` using `submit ITEM
--actor SESSION --packet DIGEST --result FILE`. The required kind is in the step.
Outcomes are `ready` or, where a rework route exists, `changes_requested`. Cite
real evidence and Git revisions. A step marked `independent` rejects any actor who
authored the step it reworks, so use a separate session identity for the architect
ratifying `qa`'s tests and for the reviewer of an implementation. No command starts a session automatically.

At a gate, obtain the actual human decision, then record it using `approve ITEM
--packet DIGEST --note TEXT` (or `--reject`). Never infer approval from silence.
On stale context, reread and reconcile the result before submitting again.
Acceptance means this work is delivered; it never ratifies the story. A story's
register row is a separate human decision, moved by draft per the direction skill
on its own dated evidence — never because the board reached `done`.

Use `note ITEM --actor SESSION --text TEXT` for durable questions and observations.
Notes do not mechanically block progress; obtain answers needed to complete work.
Commit `.anoti-board/state.json` and generated `BOARD.md` alongside the code.
Rebuild the view with `sync`; do not edit it as canonical state.

Use existing Anoti memory helpers and ratification for knowledge, not board notes
as a replacement for GROUNDING. The stories organ is the value register and the
board is a delivery ledger; never create a work item as a stand-in for a story.
Full CLI details are in `docs/BOARD-INTEGRATION.md` at the plugin root.
