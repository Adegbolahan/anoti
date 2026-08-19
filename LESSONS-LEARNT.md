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

- 2026-08-13 — Benchmark traps must exceed the model's native competence:
  all three arms caught both traps, so the pilot measured the model, not
  the methodology. Why: traps were designed for a weaker baseline. Apply
  by: design traps the unaided model demonstrably fails (longer horizons,
  more facts, subtler contradictions) before sequence 2.
- 2026-08-13 — A harness pause that says "go do X elsewhere" without the
  full procedure inline will be acknowledged, not performed: both
  interactive points were skipped in both governed arms. Apply by: print
  the entire response script at the pause and require a typed 'done'
  (fixed in 66e0a98).
- 2026-08-13 — Silence is not a bootstrap strategy: retrieve said nothing
  in storeless projects, so governed sessions never learned anoti existed
  (arm B's empty shell). Apply by: empty-project git repos now get a
  one-line skillify offer (fixed in 66e0a98).

- 2026-08-13 — Agents were opening helper scripts just to learn calling
  conventions, burning tokens on what one line answers. Why: skills named
  scripts without signatures. Apply by: any skill that tells an agent to
  run a script carries the exact invocation inline (consolidate now has a
  quick-reference block); a signature in the skill is cheaper than a
  Read in every session.

- 2026-08-13 — yq's string == does wildcard matching: 'select(.id == strenv(ID))' with ID='c*' matches c1, c2, and c*. Why: ids are freeform LLM-chosen strings, so pattern chars will eventually appear. How to apply: never let untrusted-format strings reach a yq ==; resolve to indices by exact shell comparison first (scripts/session-consume is the reference)

- 2026-08-19 — Keep builder worktrees alive until the review cycle closes. Why: D011 says fix rounds resume the ORIGINAL builder, but a subagent whose worktree was removed at integration cannot be resumed — the fix round had to go to a fresh spawn that re-read everything at full cost (JIT-recall implementation, 2026-08-19). How to apply: after fast-forwarding a builder's branch, leave its worktree in place until the reviewer's verdict is COMPLIANT; remove worktrees at the end of the cascade, not at merge.

- 2026-08-19 — IFS=<tab> read collapses consecutive tabs: tab is IFS whitespace, so an empty middle field bracketed by two tabs vanishes and later fields shift left; a bare grep -q <id> on the output still passes. Why: it silently corrupted every non-global JIT-recall line while 962 tests stayed green (2026-08-19). How to apply: split TSV with awk -F'\t' or cut -f, never IFS=tab read; assert the rendered line SHAPE, not a substring.

- 2026-08-19 — Docker on Apple Silicon silently QEMU-emulates foreign-arch binaries: an x86_64 yq in an aarch64 container ran ~100x slower and made a perf test look like a regression. Why: wall-clock is meaningless unless the binary arch matches docker info's arch (2026-08-19, JIT-recall Task 15). How to apply: match the arch explicitly (yq_linux_arm64 on M-series hosts) before trusting any timing from a local container; CI's ubuntu-latest is x86_64 natively.
