---
name: policy-adversarial-handoff
description: anoti operating policy — finished work goes to a reviewer spawn before it counts as done. For builder roles.
---

# Policy: adversarial-handoff

**Applies:** roles that declare it — builder work whose failure would be
expensive to discover late.

**Procedure:**

1. "Done" is a claim, and claims need adversarial testing: when your work
   satisfies your role's definition-of-done, report it as
   _ready-for-review_, not done.
2. The main session dispatches a reviewer spawn (practitioner in a
   reviewer-class role) against your diff and your evidence.
3. The judge never edits: the reviewer returns findings with evidence;
   fixes come back to the builder. One hat at a time, clean separation.
4. Work counts as done only when the reviewer's findings are fixed or
   explicitly adjudicated by the main session.

**Binds:** the practitioner agent (reviewer-class roles), the universal
report contract (findings carry citations).

**Violation handling:** builder work merged without its handoff is
reopened; self-review never substitutes for the adversarial pass.
