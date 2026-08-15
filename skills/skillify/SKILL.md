---
name: skillify
description: anoti workspace bootstrap and maintenance — scaffold the document system into a project, adopt brownfield docs, migrate schema versions. Invoke to set up or maintain an anoti workspace.
---

# Skillify

The organ-maintenance function: creates and maintains the externalized
workspace (GROUNDING.yaml, ROADMAP.md, HIGH-LEVEL-STORIES.md, TODOS.md,
LESSONS-LEARNT.md, specs/, plans/).

## Bootstrap contract

- **Idempotent:** re-running creates only what is missing; it NEVER
  overwrites an existing file. Safe to run twice by construction.
- **Dry-run first when asked:** `--dry-run` prints the plan (what would be
  created, what exists and is left alone) without touching anything.
- Source of truth is `templates/` in the plugin; project root is the git
  toplevel (or CWD with a warning if not a repo).
- Git hygiene: append `templates/gitignore-fragment` (`.anoti/`) to the
  project `.gitignore` if missing; workspace files themselves are
  committed — shared ground truth deserves history.
- After creating GROUNDING.yaml from the template: run
  `scripts/validate-workspace`, `scripts/regen-index`, then
  `scripts/trust` so retrieval loads it from the first session.

## Brownfield adoption

Existing docs map onto organs; only gaps are created; existing content is
referenced in place, never rewritten. An existing CLAUDE.md is left as the
instruction layer — retrieval belongs to the SessionStart hook, so skillify
adds at most a short documentation note, never a retrieval pointer.

## Migration

**Adopted organ homes (issue #16):** before scaffolding `docs/specs/`
or `docs/plans/`, look for existing spec/plan homes (a `.claude/project/`
tree, a `specs/` dir, wherever the project already files them). If found,
DO NOT scaffold the default directories — record the adopted homes as
`spec_dir:`/`plan_dir:` in `.claude/anoti.local.md` frontmatter (the
same file that carries `state_dir:`), and the spec/plan skills will file
there. The bootstrap record states **exactly what it created** — a
record claiming "only X was created" while the scaffold also minted
organ directories is the store disagreeing with the filesystem, the
exact failure mode this system exists to prevent.

**Case-insensitive collision check (issue #11):** before creating any
organ file, list the target directory and compare names exactly. If an
existing file matches an organ name only case-insensitively (a project's
own `roadmap.md` vs the `ROADMAP.md` organ), STOP — on a
case-insensitive filesystem the template write would silently target the
project's file. Report the collision and let the human rule: adopt the
existing file as the organ (brownfield), rename one, or skip that organ.
Adoption is always explicit, never accidental.

The workspace records the plugin/schema version that scaffolded it. On
mismatch: take a dated backup of each affected file into
`<state-dir>/backups/` (gitignored with the state dir; copy one out and
commit it if the project wants it tracked — opt-in, never default),
produce the migration as a proposed diff, and the human ratifies before
anything is applied — no silent upgrades. The update report states the
backup location. Grandfathering rule for evidence-less `established`
claims: demote to `probable` with a `{action: demoted, note: grandfathered;
evidence pending}` event.

## Maintenance map (which document updates on which event)

- Design accepted → `docs/specs/YYYY-MM-DD-<topic>-design.md` (format: the spec skill)
- Implementation planned → `docs/plans/` (format: the plan skill)
- Direction changes → ROADMAP.md (format: the direction skill; draft-for-ratification; human merges)
- Scope of "good" changes → HIGH-LEVEL-STORIES.md (format: the direction skill; same gate)
- Work begun/finished → TODOS.md (checked items are history; never delete)
- Process lesson learned → LESSONS-LEARNT.md
- Discovery made → GROUNDING.yaml via the consolidate skill only

## Uninstall

The workspace is plain files and simply remains — designed degradation.
Offer (never force) removal of `.anoti/` ephemera.
