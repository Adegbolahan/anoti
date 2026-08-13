---
name: policy-test-driven
description: anoti operating policy — failing test before implementation, RED evidence before GREEN. For builder roles.
---

# Policy: test-driven

**Applies:** roles that declare it — any work with testable behavior.

**Procedure:**

1. Write the test that describes the wanted behavior first.
2. Run it and capture the failure (**RED evidence**: command + failing
   output + why that failure was expected). A test never seen failing
   proves nothing.
3. Implement the minimum that makes it pass.
4. Run again and capture the pass (**GREEN evidence**: command + output).
5. Both runs go in your report as `{command, output}` citations — this is
   the epistemic policy's hypothesis-before-test applied to code.

**Binds:** policy-epistemic (RED/GREEN are its predictions and evidence);
the role's definition-of-done (GREEN output is a required artifact).

**Violation handling:** implementation without RED evidence is bounced —
retrofitting a test after the code is not TDD and is reported as such.
