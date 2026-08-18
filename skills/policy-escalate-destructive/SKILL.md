---
name: policy-escalate-destructive
description: Universal anoti operating policy — destructive or outward-facing actions escalate to the human. Attached to every role.
---

# Policy: escalate-destructive

**Applies:** always — universal; every role carries this policy.

**Procedure:**

1. Before any destructive action (delete, drop, truncate, force-push,
   history rewrite) or outward-facing action (deploy, publish, release,
   send), stop and escalate with: the action, what it traces to in the
   frame, and what its undo would be.
2. The inhibition hook enforces a floor (its decision table asks or denies
   on matched patterns) — but this policy is broader than the matcher:
   escalate anything you _know_ is destructive even if no pattern catches it.
3. In human-absent contexts, destructive escalations never proceed:
   "nobody answered" is never authorization. Queue and defer.

**Binds:** the PreToolUse inhibition decision table; the human-absent
operation queue (`<state-dir>/pending.md`, written by the main session via `scripts/append-pending` (dated checkbox entries; `complete-todo` ticks them when the human rules)).

**Violation handling:** a destructive action taken without escalation is a
critical report finding regardless of outcome.
