# Repo Takeover: anoti replaces getting-started-claude (Plan)

**Spec:** none — authority: human directive 2026-08-13 (option C, four commands if they integrate) + decision record to follow

**Goal:** anoti 0.4.0 content ready to replace the remote
(github.com/Adegbolahan/getting-started-claude), deprecating
project-scaffolder while adopting its four commands (adapted) and its
release discipline (CI, CHANGELOG, marketplace manifest, README).

**Adopted commands (anoti-native adaptations):** `/anoti:new` (skillify
bootstrap wrapper: target wizard, never-into-plugin-dir, monorepo git
nuance, restart note); `/anoti:implement` (feature cascade driver:
discovery over docs/ROADMAP + HIGH-LEVEL-STORIES, mandatory spec gate via
the spec skill, plan via the plan skill, review-work cycle, direction-doc
updates); `/anoti:review-work` (pre-commit implementation review —
renamed to avoid colliding with the ratification ritual; keeps the
evidence-file contract, dimension applicability, zero-assertion blockers,
cycle cap 3); `/anoti:update` (skillify migration wrapper: version
compare, never downgrade, no silent upgrades).

**Also adopted:** CI workflow (tests, shellcheck, hook-schema, skill
frontmatter, version consistency, changelog-gated auto-tag release);
CHANGELOG.md backfilled 0.1.0→0.4.0; marketplace.json upgraded to the
schema'd storefront form (name: anoti, owner URL = the remote);
README as marketplace storefront with a scaffolder deprecation note
(old tags remain installable).

**Not adopted:** the workflow-state machine and commit-gate hook (anoti's
episode state + adversarial-handoff cover the role; a mechanical commit
gate is filed as a TODO candidate), bats test layout, per-project shims.

**Remote sequence (each push permission-gated; C ratified by the human):**
remote add → push HEAD to a new branch → make it default → delete old
main → rename branch to main. No force-push (anoti's own deny-list
forbids it; the branch swap achieves replacement within our rules). Old
tags (v3.x) survive, keeping pinned scaffolder installs working.

**Tasks:** RED tests for four new commands → author commands → CHANGELOG

- marketplace + README + CI → version 0.4.0 → suite green → commit →
  remote sequence → D017 decision record → episode close.
