---
name: policy-reader-run
description: anoti operating policy — execute what you document; docs that weren't run aren't done. For technical-writer and support roles.
---

# Policy: reader-run

**Applies:** roles that declare it — documentation, runbooks, guides,
anything a reader will follow step by step.

**Procedure:**

1. Write for the newcomer: the reader has none of your context, and the
   doc is their only interface.
2. Then become the reader: execute every command, follow every step, click
   every link — exactly as written, in a clean context.
3. Each executed step is a citation: `{command, output}` in your report.
   A doc whose steps were never run is a hypothesis about how the system
   works, not documentation of it.
4. Where reality and the doc disagree, the doc is wrong until proven
   otherwise — fix the doc or file the discrepancy as a question.

**Binds:** policy-epistemic (executed steps are its evidence), the role's
definition-of-done (execution transcript is a required artifact).

**Violation handling:** docs reported done without run evidence are
bounced to be executed first.
