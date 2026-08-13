---
name: direction
description: anoti direction-document standard — the required shape and management rules for docs/ROADMAP.md and docs/HIGH-LEVEL-STORIES.md. Invoke before drafting or amending either; both are human-owned.
---

# Direction documents

The two human-owned direction organs. Agents never edit them directly —
every change is a draft via policy-draft-for-ratification, and the
inhibition hook mechanically denies writes outside a consolidation flow.
The human merges; ownership never transfers.

## docs/ROADMAP.md — required shape (adopted 2026-08-13)

Structure (adopted external template, hardened with anoti guardrails):

1. `# Project Roadmap` + project name; format pointer comment.
2. `## Vision` — one sentence: what the project achieves when complete.
3. `## Phases Overview` — table: Phase | Name | Status | Verified date.
   **Guardrail: a status without a verified date is invalid** — status is
   only as authoritative as its date.
4. One `## Phase N: <name>` section per phase, each with: **Goal** (one
   line), **User Stories** (US-ids in scope), **Key Deliverables**,
   **Dependencies**, and dated closures with evidence refs
   (`✅ YYYY-MM-DD — <what settled it>`). Exactly one phase heading
   carries the `← current` marker (the retrieval digest surfaces it).
5. `## Success Criteria` — observable, per-phase and project-level.
6. `## Risks & Mitigations` — table.
7. `**Last Updated:** YYYY-MM-DD` — stale beyond a phase transition means
   the document is due an audit, not silent trust.

Checked items keep their dates and evidence; history is never deleted.

## docs/HIGH-LEVEL-STORIES.md — required shape (adopted 2026-08-13)

A story register plus full statements:

1. `## Overview` — status-count table (dated) and the audit rule below.
2. `## Register` — table: ID (`US-nnn`) | Title | Priority | Status +
   verified date | Evidence ref (a GROUNDING record, trial doc, or grade
   file — the anoti replacement for spec links).
3. `## Stories` — one entry per ID, exactly:
   `As a <who>, I need <what>, so that <why>. Done means: <observable>.`
   Testable value statements, never feature lists.

**Anti-decay guardrails (learned from the sample this format came from,
whose own header warns its status column went stale):** every status
cell carries its verification date; a periodic dated audit section
supersedes any older cells it contradicts; a story nothing has served in
living memory is amended by draft, not silently pruned.

## Management (which hats, which policies)

- **`visionary`** drafts vision-scale changes (new phases, changed bets);
  **`product-manager`** drafts prioritization and sequencing changes;
  **`requirements-analyst`** decomposes ratified stories downward — none
  of them merges.
- Policies binding all direction work: `draft-for-ratification`
  (mandatory), `epistemic` (a proposed change cites what motivated it —
  evidence, lesson, or ratified decision), `trace-to-frame`.
- The **conductor** cites both documents in every cascade plan (roadmap
  needed/exists; which stories the work serves); **attend** traces every
  frame's `roadmap_ref` and `story_ref` here. The retrieval digest
  surfaces the current phase and the story count each session.
