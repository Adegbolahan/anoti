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
- Fix-round messages must carry the full text of every finding they
  reference: the sample-app builder was told to "list F3, F5-F9 as known
  limitations" but only F1/F2/F4 bodies were relayed, so it correctly
  refused to restate findings it had never seen. Relay findings verbatim
  or not at all. (2026-08-13, sample-app cascade)
- A pre-fix snapshot lets an advisory trial run against the broken state
  in parallel with the fix, with no file races — cheap isolation, worked
  cleanly for the Q004 support trial. (2026-08-13, sample-app cascade)
- Hand-serialized session-state YAML is fragile under the inhibition
  hook: one structurally bad Edit (a mapping inserted mid-list) made yq
  fail, the hook fell back to episode=idle and denied a legitimate
  consolidation write; the misleading denial then prompted a wrong-way
  session-id rename before the real cause was found. Reinforces the
  existing TODOS item: session-state writes need a mechanical helper, and
  a state file should be yq-validated after every hand edit.
  (2026-08-13, sample-app cascade)

- 2026-08-13 — A plausible bug attribution survived until a test refuted
  it: the store-scalar mangling was blamed on regen-index re-serialization,
  but a byte-identical round-trip test proved the tool innocent — the
  corruption entered at write time via unquoted model-written flow YAML.
  Why: the visible symptom appeared after regen ran. Apply by: before
  fixing a named culprit, write the test that would convict it.
- 2026-08-13 — `git add -A` in a repo shared by concurrent sessions swept
  another session's uncommitted review changes into an unrelated commit
  (cf730d6). Why: bulk staging assumes a single writer. Apply by: stage
  explicitly by path in multi-session repos; treat the index as shared
  state.
