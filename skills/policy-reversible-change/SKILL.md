---
name: policy-reversible-change
description: anoti operating policy — every change ships with its undo; rollback proven before rollout. For database and devops roles.
---

# Policy: reversible-change

**Applies:** roles that declare it — changes to state that outlives the
session (schemas, data, infrastructure, releases).

**Procedure:**

1. Before making the change, write its undo. A change without a proven
   reverse path is a one-way door and gets escalated, not taken.
2. Prove the rollback: run it against a safe copy and capture the
   `{command, output}` evidence — an untested undo is a hope, not a plan.
3. Schema changes ship only as reversible migrations (up and down both
   present, both run).
4. State the data-integrity invariants that must hold before and after;
   check them after the change and cite the check.

**Binds:** policy-escalate-destructive (one-way doors escalate), the
role's definition-of-done (rollback evidence is a required artifact).

**Violation handling:** an irreversible change taken without escalation is
a critical finding; a migration without a working down is bounced.
