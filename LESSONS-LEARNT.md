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

- 2026-08-20 — awk -v var="$x" processes backslash escape sequences in the value, so a freeform string (C:\temp\new, a literal \n in prose) silently mutates before any comparison — dedupe and equality checks miss while looking correct. Why: -v values go through awk's string-constant unescaping; ENVIRON[] values do not. How to apply: any freeform value entering awk (ids, subjects, notes, paths) is exported and read via ENVIRON["VAR"]; -v is reserved for values this code controls (dates, counters, flags). Second occurrence in this codebase (skeptic-caught in review-debt add_row 2026-08-19; set_status had it right all along); graduate to a global claim on a third sighting or a second project.

- 2026-09-01 — Never write a date into prose that a dating helper will also stamp — the two disagree. The agent composes 'today' from the harness's LOCAL date; append-todo/append-lesson/append-pending stamp UTC, so a hand-written '(raised 2026-08-31)' landed beside the helper's '(raised 2026-09-01)' in one TODOS entry, self-contradicting. Why: 0.5.30 (#23) fixed this for the consolidate skill and /anoti:review note text by telling agents to take today from date -u +%F, but the prose appenders were not covered, and the gap is invisible until a session straddles UTC midnight. How to apply: in any text passed to a dating helper, omit the date entirely and let the helper stamp it; if a date must appear inside the prose, take it from date -u +%F, never from the session's sense of today.

- 2026-09-01 — Reading anoti's own memory documents poisons the presence matcher: scripts/presence:34 sets haystack="$tin $outcome", so a tool RESPONSE containing the store's text makes every trigger match its own record. Measured 2026-09-01: haystack = output of yq '.index' GROUNDING.yaml matched 22/26 records, versus 0/26 for an unrelated command (npm run build && docker compose up -d). All 5 recall injections in that session were this artifact, fired while attend was reading GROUNDING/ROADMAP/STORIES/specs. Why: it inflates the irrelevant-injection count that Q006's precision gate is measured on, so the gate is reading matcher noise rather than field precision. How to apply: exclude self-reads from presence matching (suppress when the resolved store paths, LESSONS-LEARNT.md, TODOS.md or docs/specs appear as the read target), and when auditing precision, discount injections whose haystack was a memory document.

- 2026-09-11 — Testing one member of an invariant's class gives false confidence about the class. The state-dir self-ignore (a .gitignore of '*' written inside the state dir) was pinned by a single test exercising append-classification, so scripts/presence shipped unseeded for eleven releases (0.5.21, unseeded from birth at fc6b786, through 0.5.31) and dropped an untracked .anoti/ into every repo that never adopted anoti. Why: a per-example test proves the example, and the gap was invisible in exactly the projects anoti is developed in, because adopted projects are covered twice over by bootstrap's gitignore fragment; an independent reviewer confirmed nothing structural would have stopped a further creator either. How to apply: when an invariant binds a CLASS of writers, assert it over the class (tests/test_helpers.sh now requires every script that calls mkdir and references $AD to contain the seed) and exempt no member — the exception list is the part that rots, so a member that provably cannot violate it should comply anyway rather than be documented as safe.

- 2026-09-12 — Across two review chains (R5 and R6, six cycles) every single blocker was either an unverified historical claim or a test assertion nobody had shown could fail — never the code and never the design. Why: the discipline this plugin imposes on feature code (write the falsifying check before trusting the artifact) was never turned inward on the spec-and-test-authoring step itself, so claims about the repo's own past shipped on memory. Concrete failures: presence attributed to 0.5.21 when git tag --contains says 0.5.22; 'conductor at line 59' when it was 51; a mandatory spawn count that silently omitted requirements-analyst; and grep -qv used as a presence check, which passes on any file and so could never fail. How to apply, two mechanical habits needing no new role, spawn or budget — (1) cite-check: any prose claim of the form 'at line N' or file:line against a past commit is re-derived at authoring time with git show <sha>:<path> | grep -n <anchor> before it ships, which is policy-epistemic's cited-claim rule applied to one's own historical assertions; (2) kill-check: any new grep-based assertion in tests/*.sh ships only after a deliberate mutation has shown it RED, which is policy-test-driven's RED-before-GREEN applied to whoever writes prose-linting assertions, not only to qa writing acceptance tests.
