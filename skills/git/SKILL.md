---
name: git
description: anoti git craft standard — branches, worktrees, finishing, commit messages, staging discipline. Invoke before any implementation work that will commit; the rules bind every builder.
---

# Git craft

Version control is the trail the whole methodology audits — treat it as
memory, because the longitudinal protocol literally reads it as memory.

## Branches

- **Never implement on main/master without the human's explicit consent.**
  Feature work gets a branch named by intent (kebab-case, scope-first:
  `plugin-substrate`, `global-memory-tier`). One branch, one deliverable.
- Branch from the freshest base; a branch that outlives its deliverable
  is drift — finish it or say why it stays.
- **Mechanically enforced** (per D020): the inhibition hook denies
  Edit/Write/NotebookEdit actions on tracked files while HEAD is on the
  default branch (main/master or origin/HEAD). Gitignored paths (the
  state dir) and episode-gated organ writes pass through; the human's
  consent escape is `touch <state-dir>/allow-default-branch` — durable,
  per checkout, and as gitignored as the rest of the state dir.

## Worktrees

- When work must not disturb the current checkout — parallel workstreams,
  benchmark arms, risky migrations — use `git worktree add`, not a second
  clone and never stash-juggling.
- anoti isolates per-worktree automatically: the state dir resolves per
  working directory, so each worktree carries its own session state,
  telemetry, and trust file. A fresh worktree must therefore **re-trust
  the project store** before retrieval loads it — that is provenance per
  checkout working as designed, not a bug to route around.
- Remove worktrees when their branch finishes; a stale worktree is an
  abandoned session at directory scale.

## Finishing a branch

- The suite runs green **on the exact tree being integrated** — a green
  run only proves the tree it ran on; earlier runs are memory, not
  evidence.
- **Integration is the human's decision, every time.** Present the
  options — merge locally / push for PR / keep as-is — and wait. Never
  merge, push, or delete on inference; pushes are outward-facing and
  escalate-gated (policy-escalate-destructive).
- After a ratified local merge: delete the merged branch, remove its
  worktree, run the suite once more on the merged result.
- Never force-push (the inhibition deny-list enforces this for
  main/master; treat it as the norm everywhere). Amend only commits that
  have never been pushed.

## Commit messages

- Conventional prefix (`feat:`/`fix:`/`docs:`/`chore:`/`data:`),
  imperative subject ≤ 72 chars, body explaining **why** with evidence
  refs (record ids, review verdicts, prior commit hashes) — the message
  is a trail entry, write it for the auditor.
- One logical change per commit; commit at each green TDD cycle (the
  plan skill's task boundaries are commit boundaries).
- **Never ADD attribution trailers** (`Co-Authored-By:` or similar)
  unless the human explicitly asks for them. **Never strip or rewrite
  existing trailer lines** (any casing) when amending, validating, or
  linting — what's in the record stays in the record; what isn't asked
  for stays out.

## Staging discipline

- **Stage explicitly by path.** Never `git add -A` or `git add .` in a
  repo any other session might touch — bulk staging swept a concurrent
  session's uncommitted work into an unrelated commit once (cf730d6),
  and the index is shared state.
- Look before overwriting: `git status` before staging, and anything
  unexpected in the tree belongs to someone — investigate, never absorb.

## Tags and releases

- Tags are cut by CI's release job from the changelog, never by hand —
  the changelog section is the release note, and version consistency is
  a build gate. Bump versions only with their changelog entry.
