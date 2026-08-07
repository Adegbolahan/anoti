# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-08-07

### Breaking Changes

**Workflow components moved out of scaffolded projects and into the plugin.**

Before this release the workflow commands, skills, hooks and state machine were
copied into every project. Copies drift. That is why `/update` carried a growing
chain of hand-written migrations, and why `marketplace.json` sat two releases
behind while a pre-push reminder existed the whole time.

They now ship with the plugin. **Upgrading the plugin upgrades every project.**

What a scaffolded project holds now — 6 files, down from 15:

```
CLAUDE.md
.claude/settings.json                  version tracking, no hooks
.claude/project/high-level-user-stories.md
.claude/project/roadmap.md
.claude/project/workflow-state.sh      a shim, not the state machine
.claude/project/{features,plans}/
```

`.claude/commands/`, `.claude/skills/` and `.claude/project/hooks/` are gone from
projects entirely.

### Added

- `hooks/hooks.json` registers all 7 hooks from the plugin using
  `${CLAUDE_PLUGIN_ROOT}`.
- `bin/workflow-state.sh` — the state machine, versioned with the plugin.
- A shim at `.claude/project/workflow-state.sh` so the invocation printed by the
  commit gate and the docs keeps working. It resolves the plugin via
  `$CLAUDE_PLUGIN_ROOT`, then a path baked in at scaffold time, then a search of
  `~/.claude/plugins`. No logic, nothing to drift.
- `SessionStart` confirms an upgrade took effect and clears the marker `/update`
  leaves behind. That message firing at all proves the new hooks are loaded,
  because it is one of them.
- CI now checks `hooks.json` instead of `settings.json`, asserts settings.json
  registers **no** hooks, and verifies every registered script actually exists.

### Changed

- **The pre-v3 migration is a tested script, not prose.** It deletes files from
  a user's repository, and a destructive operation described in markdown for a
  model to carry out is precisely the failure mode this plugin exists to
  prevent. `bin/migrate-pre-v3.sh` refuses to run outside a scaffolded project,
  supports `--dry-run`, moves rather than deletes, never touches `CLAUDE.md` or
  anything under `features/`, `plans/`, `roadmap.md` or
  `high-level-user-stories.md`, proves the installed shim actually reaches the
  plugin before reporting success, and is safe to run twice. 13 tests.
- `/update` collapsed its per-version migration chain into one pre-v3 migration.
  It backs up `.claude/commands/`, `.claude/skills/`, `.claude/project/hooks/`
  and the old `workflow-state.sh` to `.claude/.backup-pre-v3/`, prints exactly
  what moved, and never deletes silently. A copy left in place would **shadow**
  the plugin's version, so the project would keep running old code while
  appearing upgraded.
- `/new` scaffolds 6 files instead of 15, and verifies the shim resolves before
  reporting success.
- The test harness reads `hooks/hooks.json` and expands `${CLAUDE_PLUGIN_ROOT}`,
  mirroring how Claude Code actually loads them. Fixtures install a plugin at a
  separate path from the project, so the tests exercise the real arrangement.

### Migration

Run `/update`, then **restart Claude Code** — hook configuration is only read at
session start, so until you restart the session is still running the old hooks.

---

## [2.3.0] - 2026-08-07

2.2.0 made the gate block. It did not make the gate bind the agent it gates.

### Fixed

- **The gated agent could open its own gate in two commands.** `pre-bash.sh`
  blocks `git commit` but did not block the command that unblocks it, so:

  ```
  phase: implementation_in_progress
    git commit                                -> exit 2   BLOCKED
    workflow-state.sh advance under_review    -> allowed
    workflow-state.sh advance review_passed   -> allowed
    git commit                                -> exit 0   ALLOWED
  ```

  It was written to the audit log, but identically to a legitimate review pass,
  so the log could not tell a real review from the magic words. `override` was a
  recorded, deliberate, one-shot bypass; this was an unlimited one beside it.

### Added

- `advance review_passed` now **requires `--evidence <path>`**. The report must
  exist and be newer than the last source edit. Its path and a sha256 hash are
  recorded in state and in the audit log, so a pass is traceable to what
  produced it.
- `mark-source-edit`, called by `post-edit.sh` on every source edit, giving the
  evidence check a freshness baseline. Phase timestamps could not provide one:
  you can edit for an hour without re-entering a phase.
- `why-blocked` reports the evidence backing a pass, and says plainly when a
  pass has none.
- `schemaVersion` 2, with forward migration for `lastSourceEditEpoch` and
  `reviewEvidence`.
- 7 tests covering the evidence gate, including one that replays the original
  two-command bypass end to end and asserts the commit still blocks.

### Changed

- `is_commit()` moved into `_common.sh`. It was byte-identical in `pre-bash.sh`
  and `post-bash.sh`, and 2.2.0 knowingly accepted a false positive in that
  pattern — so it is a regex that will be tuned, and tuning one copy would have
  left the gate and the completion tracker disagreeing about what a commit is.
- **`/review` no longer dispatches four sub-agents.** It dispatched
  `backend-api-engineer`, `frontend-spa-engineer`, `qa-automation-engineer` and
  `security-privacy-engineer` — agent types the plugin never shipped — so it
  failed on every machine that did not happen to have them installed.

  Replaced with a documented **contract** plus one dependency-free reference
  reviewer. The gate checks that the phase is `review_passed` with valid
  evidence; it does not care what produced it. Any reviewer can satisfy it —
  the bundled one, a deeper tool the team already runs, or a human reading the
  diff. The bundled reviewer now also picks the dimensions that apply to the
  diff instead of reviewing frontend concerns on a CLI tool.

- `/review` writes its report to `.claude/project/reviews/` and passes it as
  evidence.
- README, scaffolding-guidance and the scaffolded CLAUDE.md now state the
  ceiling plainly: this is a guardrail against drift and accident, not an
  adversarial control. Anything that can write a file can satisfy the check.
  What it buys is that skipping review becomes an explicit act leaving a forged
  artifact in the diff, instead of a silent shortcut.

### Migration

`advance review_passed` without `--evidence` now exits 1. Any script or command
calling it bare must be updated. `/review` and `/implement` are updated here.

---

## [2.2.0] - 2026-08-07

The commit gate did not work. This release makes it work, and adds the test
suite that proves it.

### Fixed

- **The commit gate never fired.** Nothing advanced the phase to
  `implementation_in_progress`, so after plan approval it sat at
  `plan_approved`, the gate's `case` fell through, and `git commit` succeeded
  unreviewed. A source edit after approval now advances the phase.
- **The gate was anchored to `^git commit`** while every safety blocker beside
  it was unanchored, so `cd frontend && git commit` walked straight past it.
  Now unanchored, matching the blockers.
- **Missing or broken `jq` silently disabled the gate.** `workflow-state.sh`
  exited nonzero, callers swallowed it with `|| echo none`, and the commit was
  allowed. The gate now fails closed on any state it cannot confirm: missing
  jq, corrupt state, unreadable state, or an unrecognised phase. Each blocks
  with an explanation and a recovery command.
- **`review_passed` was a permanent pardon.** Post-pass edits could not be
  re-reviewed. `review_passed -> under_review` is now an allowed edge.
- **`advance` silently no-opped** on an illegal transition and exited 0. It now
  exits nonzero with a message.
- **The source-edit gate only matched `*/src/*`**, so it never fired on a
  Next.js `app/`, a Go `cmd/`, or a root-level Python package.
- **The secrets blocker missed** `.envrc`, extensionless keys (`id_rsa`),
  `terraform.tfvars`, java keystores, and the package-manager rc files that
  hold auth tokens.
- **`npx prettier` ran on every edit** with stderr discarded, which in a
  project without prettier meant a silent network fetch per edit. The formatter
  is now detected once and skipped when absent.
- **`npx tsc --noEmit` ran on every `.ts` edit** under a 30s timeout that real
  projects blow past. Typechecking moved to the `Stop` hook, runs only when a
  TS file was touched that turn, and uses `--incremental`.
- **The review auto-fix loop was unbounded.** It now caps at 3 cycles and
  reports what is not converging instead of spinning.
- Removed an invalid `Bash(.claude/project/**)` permission entry. Bash
  permissions are command prefixes, not path globs.
- Concurrent state writes could silently drop a transition. Writes are now
  serialised with a portable `mkdir` lock and a stale-lock timeout.

### Added

- **Test suite** (`test/`) built on bats-core. 26 tests covering the gate,
  including regression tests for each defect above and a bystander test
  asserting the gate stays out of repositories that were never scaffolded.
- **CI** (`.github/workflows/ci.yml`): hook tests, shellcheck, hook-schema
  validation, and a version-consistency gate across `plugin.json`,
  `marketplace.json`, the settings template, and this file.
- `workflow-state.sh override <reason>` — a one-shot, recorded commit bypass.
  Previously the only way past a stuck gate was deleting the state file.
- `workflow-state.sh why-blocked` — names the blockers holding the gate closed.
- A phase bar in `next-action`, so you can see where you are without asking.
- `.workflow-log.jsonl` — an append-only audit trail of transitions, gate
  decisions, and overrides.
- `schemaVersion` in the state file, with forward migration and a refusal to
  touch a file written by a newer version.

### Changed

- **Hook bodies moved out of `settings.json` into scripts** under
  `.claude/project/hooks/`, one per event. `settings.json` now holds one-line
  invocations. `PreToolUse` went from 4 hook groups to 2 and `PostToolUse` from
  3 to 2 — those groups ran in parallel, could not see each other, and raced on
  the state file.
- Every hook opens with a scope guard that exits silently when the project is
  not scaffolded, before any gating logic runs.
- `get-field` replaced with named accessors (`get-phase`, `get-story`,
  `get-findings-count`, `get-review-cycle`). The old form interpolated its
  argument straight into a jq program.
- Added `snapshot`, which returns every gate-relevant field in one jq call.
  The gate runs on every Bash tool call; three accessor round-trips was roughly
  six process spawns each time.
- `set-findings` validates its input and holds the phase at `under_review` on
  failure, rather than silently storing nothing and reporting zero blockers.

### Removed

- `.githooks/pre-push` — used an interactive `read -p` that hangs any non-TTY
  push (CI, an IDE push button, an agent). Replaced by the CI version job.
- `scripts/bump-version.sh` — wrote 2 of the 4 places a version lives, which is
  how `marketplace.json` got stranded two releases behind.
- `template-customizer` agent — 171 lines of hardcoded React/Python/Go/Rust/Node
  conventions that a current model already knows. Ask Claude directly instead:
  "help me customize these templates for [your stack]".

### Migration

Run `/update`. Existing projects gain `.claude/project/hooks/` and a rewritten
`settings.json`. Add these to `.gitignore`:

```
.claude/project/.workflow-state.json
.claude/project/.workflow-log.jsonl
.claude/project/.turn-touched
.claude/project/.workflow-state.lock/
```

---

## [2.1.0] - 2026-02-17

Shipped in `plugin.json` but never documented here. Reconstructed from the
migration notes in `/update`.

### Added

- Review cycle states: `under_review`, `changes_requested`, `review_passed`.
- Backward transition support for the review cycle, plus `set-findings`,
  `get-findings`, and `review-cycle` commands.
- `reviewCycle` and `reviewFindings` in the state file.
- A commit gate in `settings.json` intended to block `git commit` unless the
  phase was `review_passed`. **It did not work** — see 2.2.0.

### Changed

- `/review` became a 4-track sub-agent review (backend, frontend, tests,
  security) with an automated fix loop.
- `/implement` Phase 3 changed from "Validate" to "Review Cycle".

---

## [2.0.0] - 2026-02-17

### Breaking Changes

This release represents a complete architectural shift from a Python CLI tool to a native Claude Code plugin system.

### Removed

- `scaffold-project.py` - Python CLI scaffolding tool
- `install.sh` - Bash installer for shell aliases
- `docs/` directory - Standalone documentation files
  - `docs/development.md`
  - `docs/coding-standards.md`
  - `docs/contributing.md`
- `templates/` directory - Old template structure
  - `templates/CLAUDE.md.EXAMPLE`
  - `templates/CLAUDE.md.TEMPLATE`
  - `templates/docs/*.md`
  - `templates/.claude/commands/*.md`
- `INSTALL.md` - Old installation guide
- `QUICK-REFERENCE.md` - Quick reference card
- `WORKFLOW-OPTIMIZATION.md` - Workflow documentation

### Added

- **Plugin Marketplace** (`marketplace/`)
  - `marketplace.json` - Registry for discovering and installing plugins
  - Extensible architecture for community plugins

- **Project Scaffolder Plugin** (`project-scaffolder/`)
  - `/scaffold` command - Full project scaffolding
  - `/scaffold-minimal` command - Essential files only
  - `template-customizer` agent - Adapts templates for tech stacks
  - Workflow enforcement hooks
  - `scaffolding-guidance` skill

- **New Template Structure**
  - Templates now live in `project-scaffolder/resources/templates/`
  - Includes workflow commands, hooks, skills, and project tracking
  - Enforces story → plan → approve → build workflow

### Changed

- **Architecture**: Migrated from Python CLI to Claude Code plugin system
- **Installation**: Now uses `/plugin install` instead of shell aliases
- **Documentation**: CLAUDE.md rewritten for plugin architecture
- **Scaffolded Output**: New projects get `.claude/` directory structure instead of `docs/`

### Migration Guide

If you previously used `scaffold-project.py`:

1. Install the plugin: `/plugin install project-scaffolder@getting-started-claude-marketplace`
2. Use `/scaffold <path>` instead of `python3 scaffold-project.py <path>`
3. Use `/scaffold-minimal <path>` instead of `--minimal` flag

The scaffolded output structure has changed significantly. New projects now receive:

- `.claude/commands/` - Workflow commands
- Workflow enforcement hooks, defined inline in `.claude/settings.json`
  (this entry originally claimed a `.claude/hooks/` directory, which 2.0.0
  never created; hook scripts arrived in 2.2.0 under `.claude/project/hooks/`)
- `.claude/skills/` - Interactive documentation
- `.claude/project/` - Feature and plan tracking

---

## [1.0.0] - 2025-11-04

### Added

- Initial release of Python scaffolding framework
- `scaffold-project.py` - Main CLI tool
- `install.sh` - Shell integration installer
- Template library with CLAUDE.md examples
- Documentation templates for git workflow, feature development, user stories
- 8 workflow slash commands
