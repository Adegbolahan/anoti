---
name: direction
description: anoti direction-document standard — the required shape and management rules for docs/ROADMAP.md and docs/HIGH-LEVEL-STORIES.md. Invoke before drafting or amending either; both are human-owned.
---

# Direction documents

The two human-owned direction organs. Agents never edit them directly —
every change is a draft via policy-draft-for-ratification, and the
inhibition hook mechanically denies writes outside a consolidation flow.
The human merges; ownership never transfers.

## docs/ROADMAP.md — required shape

- Phases as `## Phase N — <question or outcome>` headings; exactly one
  carries the `← current` marker (the retrieval digest surfaces that one).
- Each phase: a one-line **Goal**, checkbox items, and a **Done when**
  that is observable. Closed items keep their date and evidence refs
  (`✅ YYYY-MM-DD — <what settled it>`); checked items are history, never
  deleted.
- Phase transitions are roadmap events: proposed as drafts, ratified by
  the human, and worth a decision record when they change strategy.

## docs/HIGH-LEVEL-STORIES.md — required shape

- One story per bullet, exactly this form:
  `As a <who>, I need <what>, so that <why>. Done means: <observable>.`
- Stories are testable value statements, never feature lists — "Done
  means" must name something a session could check or a grader could
  score.
- A story that can no longer be checked, or that no work has served in
  living memory, is a candidate for amendment — raised as a draft, not
  silently pruned.

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
