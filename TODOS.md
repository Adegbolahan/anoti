# TODOS

Deferred work with enough context to pick up cold. Added by `/plan-ceo-review` on 2026-08-07.

---

## T-001 — `/new` dry-run tree preview

**Priority:** P3 · **Effort:** S (human ~2h / CC ~10min) · **Depends on:** T12 (plugin relocation)

**What:** Have `/new` print the exact tree it will create, and wait for confirmation, before writing anything.

**Why:** `/new` writes into a directory that may already contain the user's source code. Its
only current safety net is an after-the-fact merge/overwrite/abort prompt in Step 2b, which
fires only when Claude Code files are already present. A user scaffolding into a populated
directory has no way to see what will land before it lands.

**Pros:** Removes the last blind write in the scaffolding flow. Cheap to build. Makes the
merge/overwrite decision concrete instead of abstract.

**Cons:** Adds a third prompt to a flow that already asks two questions, and `/new`'s whole
pitch is "no arguments, Claude asks what it needs."

**Context:** Blocked on T12 because Approach C shrinks the scaffold surface from five copy
edges to two (`CLAUDE.md` and `.claude/project/`). Building the preview before T12 means
previewing a tree that is about to change. Start in
`project-scaffolder/commands/new.md` Step 3, between directory creation and template copy.

---

## T-002 — CHANGELOG history cleanup

**Priority:** P3 · **Effort:** S (human ~1h / CC ~10min) · **Depends on:** T25 (version reconciliation)

**What:** Fix `CHANGELOG.md`: the `v1.0.0` entry documents a Python CLI product that no longer
exists, it carries the same `2026-01-22` date as `v2.0.0`, and there is no `2.1.0` entry at all
despite `plugin.json` shipping that version.

**Why:** The CHANGELOG is the second thing a marketplace visitor reads after the README. Two
releases sharing a date is not credible, and a missing entry for the currently-shipping version
suggests the project is not maintained.

**Pros:** The file most likely to be read by a prospective installer becomes trustworthy.
T25 already opens this file to reconcile version numbers, so the marginal cost is near zero.

**Cons:** Rewriting history entries is judgment-heavy rather than mechanical. Correcting the
`v1.0.0` date requires digging through git history to find what actually happened when.

**Context:** T25 reconciles versions across `plugin.json`, `marketplace.json`, the
`settings.json` template, and `CHANGELOG.md`, and adds a CI check that fails the build when
they disagree. Fold this in during that pass. Also needs a `3.0.0` entry describing the
breaking change (workflow components move from scaffolded copies to plugin components) and
the `.claude/.backup-v2/` migration from T13.

---

## T-003 — SessionEnd hook to clean stale locks

**Priority:** P3 · **Effort:** S (human ~1h / CC ~10min) · **Depends on:** E11 and the mkdir lock landing first

**What:** A `SessionEnd` hook that removes any lock directory left behind by a crashed
or killed hook process.

**Why:** Eng review decision 8 adds a `mkdir`-based lock around state writes, with a
stale-lock timeout as the safety net. If a hook is killed mid-write, the lock directory
survives and the next state write waits out the full timeout for no reason. `SessionEnd`
is a supported hook event this plugin does not currently use.

**Pros:** Turns a timeout wait into an instant cleanup, for roughly a dozen lines.
Uses an event that already exists.

**Cons:** `SessionEnd` is not guaranteed to fire on a hard kill (SIGKILL, power loss),
so the timeout remains the real safety net and this is strictly an optimization.
Adds a seventh hook event to the suite.

**Context:** Added by `/plan-eng-review` on 2026-08-07. Deliberately kept out of
Phase A, which is the low-risk phase — the timeout already handles the correctness
case, so this is purely about how a crashed session feels to the next one. Land it in
Phase B alongside the relocation, when `hooks/hooks.json` is being authored anyway.
Hook event reference: `hook-development/SKILL.md:266`.
