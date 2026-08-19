# Roadmap Amendment Draft — JIT Recall / Presence Hook (Phase 4)

**Spec:** none — authority: docs/plans/2026-08-18-jit-recall-cascade.md (cascade spawn #2, draft-for-ratification)

**Status:** DRAFT — proposed by `product-manager` (cascade spawn #2,
`docs/plans/2026-08-18-jit-recall-cascade.md:389`). Not applied to any
human-owned organ; ownership does not transfer
(`skills/policy-draft-for-ratification/SKILL.md:14-15`). The human
ratifies, amends, or rejects
(`skills/policy-draft-for-ratification/SKILL.md:19-22`).

**Decision asked of the human, in one sentence:** ratify, amend, or
reject one new open Phase 4 deliverable line for the JIT-recall
presence-hook mechanism (Part 1), and separately choose between two
options for flagging US-001's tool-use-time gap in
`docs/HIGH-LEVEL-STORIES.md` — a dated re-verification note (my
recommendation) or a new story (Part 2).

**Frame trace:** this draft is exactly the artifact cascade spawn #2 was
dispatched to produce (`docs/plans/2026-08-18-jit-recall-cascade.md:389`,
row "Roadmap amendment draft | **product-manager**"); its content traces
to the cascade's §1 grep-proved gap
(`docs/plans/2026-08-18-jit-recall-cascade.md:52-71`) and §0's frame goal
(`docs/plans/2026-08-18-jit-recall-cascade.md:17-22`).

---

## Part 1 — New Phase 4 deliverable line (`docs/ROADMAP.md`)

**What it replaces:** nothing — pure addition. Verified by direct grep:
`grep -n -i "recall\|trigger\|just-in-time\|jit\b" docs/ROADMAP.md`
returns no output
(`docs/plans/2026-08-18-jit-recall-cascade.md:52-55`) — no existing
roadmap line covers this work, so there is no line to amend, only one to
add.

**Insertion point:** `docs/ROADMAP.md`, Phase 4 "Key Deliverables" list,
after the existing "Longitudinal audits" bullet (`docs/ROADMAP.md:94-95`),
before `**Dependencies:**` (`docs/ROADMAP.md:97`). The Phase 4 row in
`## Phases Overview` (`docs/ROADMAP.md:22`) and its `← current` marker
(`docs/ROADMAP.md:78`) are unaffected — this is a new deliverable inside
the already-current, already-in-progress phase, not a phase-status
change.

**Current text (`docs/ROADMAP.md:93-96`):**

```
- [ ] v1.1 roles validated at working scale
- [ ] Longitudinal audits (weekly from 2026-08-20) accumulating evidence
      per the pre-registered protocol
```

**Proposed addition (new bullet, same list):**

```
- [ ] Just-in-time recall (presence hook) — planned, not yet built:
      design spec is the next step, blocked on this ratification
      (docs/plans/2026-08-18-jit-recall-cascade.md). PostToolUse
      presence hook with four duties (JIT recall + frame re-anchoring +
      evidence-kind nudge + telemetry), querying global + project +
      LESSONS-LEARNT per tool call; `anoti recall` CLI (same matcher,
      second entry point); append-only `triggers:` field; recall-miss +
      adherence metrics added to the longitudinal protocol; three-tier
      wake architecture (Tier 1 built by this deliverable; Tiers 2-3
      evidence-gated on Tier 1's own telemetry, not built now)
```

**Status honesty check (labeled judgment, mechanically grounded):**
`[ ]` open, no verified date attached. Per the direction skill's
guardrail, "a status without a verified date is invalid — status is
only as authoritative as its date" (`skills/direction/SKILL.md:19-21`).
Nothing has settled yet: the design spec (cascade spawn #4) has not been
written, let alone adversarially reviewed (spawn #5) or built (a
follow-on cascade, not yet dispatched)
(`docs/plans/2026-08-18-jit-recall-cascade.md:392-393,395-404`). Marking
this anything but open would misstate where the work stands.

---

## Part 2 — US-001 flag: two options for the human (`docs/HIGH-LEVEL-STORIES.md`)

Presented as options, not resolved on the human's behalf — drafting
direction content is this role's job; ruling on it is not
(`roles/product-manager.md:24-25`, advisory boundary: "never acceptance
authority").

**Shared premise (cited):** US-001's `✅ 2026-08-13` status verifies
SessionStart digest delivery (`docs/HIGH-LEVEL-STORIES.md:19,30-32`:
"Done means: the digest arrives unasked") — that remains true today. The
field review shows a _different_ moment — tool-use time — is where the
same knowledge fails to arrive: global `G004`/`G005`/`G008` existed and
never surfaced during three concrete mid-task failures (cd-chain, stale
Vite modules, popover z-index)
(`docs/plans/2026-08-18-jit-recall-cascade.md:17-22`). The cascade plan
itself names this gap without resolving it, deliberately leaving the
choice to the roadmap-gate step
(`docs/plans/2026-08-18-jit-recall-cascade.md:73-79,469-475`).

### Option A — dated re-verification note (an `## Audit` section)

Per the direction skill's anti-decay guardrail: "a periodic dated audit
section supersedes any older cells it contradicts"
(`skills/direction/SKILL.md:48-50`).

**Insertion point:** `docs/HIGH-LEVEL-STORIES.md`, new `## Audit`
section appended **after** `## Stories`
(`docs/HIGH-LEVEL-STORIES.md:28-52`, end of file) — this preserves the
direction skill's required document order (`## Overview` →
`## Register` → `## Stories`, `skills/direction/SKILL.md:38-44`) rather
than inserting mid-document.

**Proposed text:**

```
## Audit — 2026-08-18

US-001's ✅ 2026-08-13 status verifies SessionStart digest delivery
(docs/HIGH-LEVEL-STORIES.md:19,30-32) — still true. The field review
(docs/plans/2026-08-18-jit-recall-cascade.md:17-22) shows the same
knowledge does not arrive at tool-use time: global G004/G005/G008
existed and never surfaced during three concrete mid-task failures
(cd-chain, stale Vite modules, popover z-index). This audit does not
change US-001's status cell — the SessionStart claim is unaffected — it
notes the gap the Phase 4 "Just-in-time recall" deliverable (Part 1
above) is scoped to close. Re-verify this note once that deliverable
ships and tool-use-time delivery has live evidence.
```

**Value/cost (labeled judgment):** cheap — one appended section, zero
register churn, keeps US-001 as the single canonical "knowledge in
context unasked" story and lets its two delivery moments (session-start,
tool-use) be verified independently over time without minting a second
ID for what may be the same underlying need surfacing at a second
moment.

### Option B — new story (`US-009`)

**Insertion points:** Register table, new row after `US-008`
(`docs/HIGH-LEVEL-STORIES.md:17-26`); Stories list, new entry after
`US-008` (`docs/HIGH-LEVEL-STORIES.md:50-52`); Overview count table
updated from 8 to 9 with a new "not verified" row
(`docs/HIGH-LEVEL-STORIES.md:8-10`).

**Proposed register row:**

```
| US-009 | Knowledge in context at tool-use time | 🔴 Critical | ⬜ Not started — 2026-08-18 | (none yet — spec-gated, see Phase 4 draft above) |
```

**Proposed story statement:**

```
- **US-009** — As a developer mid-task, I need relevant memory to
  surface at the moment a tool call touches something a past record
  warns about, so the mid-task failures the digest can't reach
  (cd-chain, stale Vite modules, popover z-index) don't repeat. Done
  means: matched triggers surface via PostToolUse additionalContext,
  silent when nothing matches.
```

**Value/cost (labeled judgment):** cleanly separates a genuinely
distinct, testable value claim — "at tool-use time" is a different
moment than "at session start," and its Done-means is independently
falsifiable (additionalContext injection vs. digest presence) — at the
cost of register growth (9th row, new priority/evidence bookkeeping to
maintain) and a disambiguation burden on future readers who must tell
US-001 and US-009 apart by title alone.

### My recommendation (labeled judgment, not binding)

Option A fits better today. The cascade plan's own §1 judgment already
leans this way ("US-001's evidence line may be due a dated
re-verification note," `docs/plans/2026-08-18-jit-recall-cascade.md:76-79`),
and nothing has shipped yet to justify a testably-distinct new story —
Option B becomes the stronger choice once the presence hook exists and
needs independent status tracking separate from US-001's
already-verified SessionStart claim.

---

## Part 3 — Rationale (value vs. cost)

**Value:** the field review names three concrete, already-occurred
failures — cd-chain, stale Vite modules, popover z-index — where global
records `G004`/`G005`/`G008` existed but never surfaced
(`docs/plans/2026-08-18-jit-recall-cascade.md:17-22`), exposing a
structural gap between two adjacent stages of D001's staged pipeline:
"Attention & selection" and "Retrieval & response — stored knowledge
recalled to decide/act, generating feedback that restarts the cycle"
(`GROUNDING.yaml:142,146`) — today's recall fires only at SessionStart
(US-001, `docs/HIGH-LEVEL-STORIES.md:19,30-32`) and once at task-start
(attend), never at the moment D001's own model says knowledge is
actually consumed. Closing that gap serves Phase 4's stated goal,
"anoti usable beyond this repo, honestly marketed by its evidence"
(`docs/ROADMAP.md:80-81`) — a memory system that goes inert exactly when
it matters is not honestly marketable. **Cost:** what this draft prices
is the roadmap line itself, near-zero — one bullet, no code, no
schema change — not the mechanism; the mechanism's real cost is the
downstream design spec (spawn #4), its mandatory adversarial review
(spawn #5), and a follow-on implementation cascade not yet dispatched
or budgeted here (`docs/plans/2026-08-18-jit-recall-cascade.md:379-404`).
**Sequencing:** a new Phase 4 line costs less than the alternatives —
reopening the closed Phase 1 or opening a new phase is judged a bigger
move than this work needs
(`docs/plans/2026-08-18-jit-recall-cascade.md:63-64`) — because the
mechanism serves the existing vision, "governed... memory" that "proves
its worth by experiment" (`docs/ROADMAP.md:11-13`), rather than changing
the bet; that is also why this arrives as a `product-manager`
prioritization draft rather than a `visionary` phase-change draft
(`skills/direction/SKILL.md:54-55`).

---

## Questions/doubts

- **Option A vs. B is a real fork, not a formality.** I recommend A on
  cost grounds, but the human may weight the independent-falsifiability
  argument for B more heavily than I did — both are fully drafted above
  so either can be ratified without a second spawn.
- **Phase 4 currently carries no `**User Stories:**` line**, unlike
  Phases 1–3 (`docs/ROADMAP.md:28,43,60` vs. the Phase 4 section at
  `docs/ROADMAP.md:78-97`, which has none). I did not add one — out of
  scope for what was asked — but if the human ratifies this deliverable,
  Phase 4 may be due a `**User Stories:** US-001` (or `US-001, US-009` if
  Option B is chosen) line to match the other three phases' shape. Flagged,
  not fixed.
- **The `⬜ Not started — 2026-08-18` status glyph in Option B is my own
  invention.** Every existing Register row is `✅ YYYY-MM-DD`
  (`docs/HIGH-LEVEL-STORIES.md:19-26`) — there is no documented
  not-yet-verified convention to match, so I improvised one visually
  parallel to the existing `✅`/`🔴`/`🟠` glyphs. If Option B is chosen,
  the human may prefer different wording.
- **I placed the Option A `## Audit` section at the end of the file**
  (after `## Stories`) rather than between `## Overview` and
  `## Register`, reasoning that the direction skill's numbered structure
  (`skills/direction/SKILL.md:38-44`) describes required order, and
  appending preserves it exactly; the skill doesn't explicitly bless or
  forbid an extra top-level section either way, so this placement is a
  judgment, not a citation of an explicit placement rule.
- **I did not re-verify D001's citation chain itself** (its literature
  refs, `GROUNDING.yaml:134,138`) — I read and cited its `sequence:`
  field directly (`GROUNDING.yaml:139-146`), which is sufficient for
  citing the pipeline-stage framing, but I did not re-audit whether
  D001's `established` status still holds; that's outside this draft's
  scope and not something a roadmap amendment should be re-litigating.
- **Whether the human wants this deliverable split into two roadmap
  lines** (e.g., separating the presence hook from the
  `anoti recall` CLI) rather than one combined bullet is a granularity
  call I made in favor of the cascade plan's own explicit judgment ("the
  cleanest fit is a new Phase 4 deliverable line," singular,
  `docs/plans/2026-08-18-jit-recall-cascade.md:65-66`) — cheap to split
  later if the human disagrees.
