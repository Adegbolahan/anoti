# Lessons Learnt

<!-- Process lessons. A lesson that becomes falsifiable and gathers
     evidence graduates into a GROUNDING claim later. -->

- A test whose extraction step can yield nothing asserts nothing: the
  role-policy resolution check silently skipped every role whose
  `policies:` list the formatter had wrapped to multiple lines (6 of 10
  core roles since c5329f7, then 12 of 13 v1.1 roles), while the suite
  stayed green. Guard every extract-then-assert loop with a nonzero
  extraction assertion so it can never no-op silently. Found by the
  adversarial reviewer spawn, 2026-08-13; fixed in tests/test_roles.sh
  the same day.
- Write-ordering matters under the inhibition hook: workspace-doc updates
  (TODOS.md) belong at episode close, inside the consolidation flow — a
  tick attempted before candidates were queued was correctly denied.
  (2026-08-13)
