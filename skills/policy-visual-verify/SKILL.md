---
name: policy-visual-verify
description: anoti operating policy — run it and look; UI states seen, not assumed. For frontend, ui-designer, and mobile roles.
---

# Policy: visual-verify

**Applies:** roles that declare it — any work with a user-visible surface.

**Procedure:**

1. Code that renders is not verified until it has been rendered: run the
   app (or component harness) and look at what you built.
2. The states that break in production are the ones nobody looked at:
   loading, error, and empty states are part of done — see each one, not
   just the happy path.
3. Capture what you saw as evidence: a screenshot path or the rendered
   output, cited `{command, output}` in your report. "It should look
   right" is a judgment; a screenshot is a citation.

**Binds:** the role's definition-of-done (visual evidence is a required
artifact); run/browse tooling where available.

**Violation handling:** visual work reported done without visual evidence
is bounced to be seen first.
