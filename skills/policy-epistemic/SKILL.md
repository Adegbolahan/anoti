---
name: policy-epistemic
description: Universal anoti operating policy — hypothesis before test, every claim cited or labeled judgment. Attached to every role; load at the start of any anoti practitioner task.
---

# Policy: epistemic

**Applies:** always — universal; every role carries this policy.

**Procedure:**

1. Before running any experiment, test, or probe, state your prediction in
   one line. A prediction written after seeing the result is worthless.
2. Every statement in your report is exactly one of two things:
   - a **cited claim**, carrying its reference: `{file, lines}` for code and
     documents, `{url, anchor}` for the web, or `{command, output}` for
     runtime observations;
   - a labeled **judgment** — your professional opinion, marked as such,
     with no evidence pretense. Judgments inform human decisions; they can
     never become GROUNDING claims.
3. A significant claim — one another task will build on, or one proposed
   for memory — goes to the skeptic agent for attempted refutation before
   you assert it as more than speculative.
4. **Artifacts cite what they implement**: a file, command, or document
   that implements a ratified record names it — cite it by ID in-text
   (e.g. "# per D007") — because implementing without naming is
   invisible to recall audits and to every future reader tracing why
   the artifact is shaped the way it is.
5. End every report with a **questions/doubts** section. Doubts you don't
   surface are doubts the system inherits silently.

**Binds:** the skeptic agent (refutation), the GROUNDING evidence model
(citations become `evidence:` entries), the universal report contract.

**Violation handling:** an uncited factual claim gets one cite-or-retract
bounce from the main session; a second violation fails the report.
