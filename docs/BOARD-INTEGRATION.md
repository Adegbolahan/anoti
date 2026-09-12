# Anoti board

The board is a native Python script behind `scripts/anoti board`. It uses the
existing yq executable to read YAML. Python 3.9+ and Unix file locking are required.
There is no compiled runtime, separate application, database, or model runner.

From any project:

```sh
/path/to/anoti/scripts/anoti board init "Project name" --brief "Purpose"
/path/to/anoti/scripts/anoti board work "Feature" --story US-004 --description "Scope" --accept "Expected behavior"
/path/to/anoti/scripts/anoti board next
/path/to/anoti/scripts/anoti board context work-0001
```

Initialization snapshots `templates/board-workflow.yaml` and the referenced native
Anoti roles. Use `init --workflow FILE` for a custom ordered workflow. The default
mirrors `/anoti:implement`'s delivery phases: requirements
(`requirements-analyst`) → design (`architect`, the interface contract) → human plan
approval → acceptance tests (`qa`) → test ratification (`architect`) → implementation
→ independent review → human acceptance. There is no conductor step: feature work is
architect-led, and the conductor plans non-feature cascades.

Two steps carry `independent:`, which makes the board refuse a submission from any
actor who authored the step it reworks — the architect ratifying the tests cannot be
whoever wrote them, and the reviewer cannot be an implementation author. That
separation is checked, not merely advised — though actor names are recorded
assertions rather than authentication, so the check raises the cost of collapsing
the two roles rather than making it impossible, and it compares the actor string
exactly. A rejected ratification returns to the tests, a
rejected review or acceptance to implementation, and a builder disputing a test
routes through the ratification step instead of editing it. `ui-designer` is not in
the default and the implementation role defaults to `backend`: a fixed workflow
cannot be conditional, so UI-heavy or non-backend projects supply their own with
`init --workflow FILE`.

Submit a JSON result with `outcome` (`ready` or `changes_requested`), `kind` (the
step's output name), `body`, and a nonempty `evidence` list:

```sh
/path/to/anoti/scripts/anoti board submit work-0001 --actor builder-session-1 --packet DIGEST --result result.json
/path/to/anoti/scripts/anoti board approve work-0001 --packet DIGEST --note "Human approved the plan"
```

Use the digest from `context`; stale submissions are rejected. `approve --reject`
returns to the configured rework step. This is a trusted local CLI: actor names and
human approval are recorded assertions, not authentication. Agents must obtain the
actual human decision. Evidence references are not proof that checks ran.

Use `work --story US-nnn` to name the ratified story the item serves,
`--parent ID` for decomposition, `--depends ID` for prerequisites, and
`note ID --actor SESSION --text TEXT` to record questions or decisions. Notes do not
automatically block work. Children and dependencies must finish before acceptance.
`list` includes all work; `next`/`orient` show outstanding steps. Roles are guidance,
not process permissions. Separate sessions are needed for independent review.

`.anoti-board/state.json` is canonical; mutations are locked and atomically replaced.
Its per-item history records contributions and decisions. Commit it to Git with the
code. `BOARD.md` is generated; `sync` rebuilds it after a failed view write. The local
lock is ignored. The workflow and role snapshots remain fixed for this board.
Separate clones require manual Git conflict reconciliation; there is no distributed
scheduler, automatic session spawning, retry loop, or old-board migration.

The stories organ (`docs/HIGH-LEVEL-STORIES.md`, or `story_path:`) is the value
register; the board is a delivery ledger. Omitting `--story` leaves the item
untraced, which `list`, `next`, and `orient` report as `"story": null` so the gap
is visible rather than silent; a `--parent` child inherits its parent's story
unless it names its own, so decomposition stays under the story it serves. Work
that serves no story is either infrastructure or drift — say which in the
description, rather than encoding it as a third state. The id is shape-checked
only — the board never reads the stories organ, and a `US-nnn` here is an
assertion like any other actor name.

Board acceptance is not story ratification. The acceptance gate records that this
work is delivered; a story's register row is a dated claim about delivered value
that only the human merges, by draft, per the direction skill. They are two
different human decisions and one never implies the other. Never create a board
item as a stand-in for a story, and never move a register row because the board
says `done`.

GROUNDING and Anoti's ratification helpers still own governed knowledge. Board
history contains delivery evidence, not another knowledge store. Kivo remains
separate and no synchronization has been added. This split is permanent by
design, not a pending integration: the board has its own schema, atomic
writes, and locking because work items and role handoffs are a different
shape of data from governed claims/decisions/policies, and unifying the two
stores would trade the board's minimal, dependency-free implementation for a
coupling neither side needs. Do not add a bridge or shared validator between
them (commands/implement.md: "Do not create a second independent task
lifecycle or memory store" — that rule is about scope, not storage format).

The plugin exposes `/anoti:board` and its board skill. For Codex, read that skill
from this checkout; automatic Codex installation is not included in this version.

Check with `python3 -m unittest discover -s tests -p 'test_board.py' -v` and
`bash tests/run.sh`.
