# every plan declares its governing authority: a spec file or an explicit none+authority
for f in "$ROOT"/docs/plans/*.md; do
  grep -qE '^\*\*Spec:\*\*' "$f"
  assert_ok $? "plan declares its spec: $(basename "$f")"
done
# declared spec files must exist (when a path is given)
for f in "$ROOT"/docs/plans/*.md; do
  ref="$(grep -m1 -oE 'docs/specs/[a-zA-Z0-9._-]+\.md' "$f" | head -1)"
  if [ -n "$ref" ]; then
    [ -f "$ROOT/$ref" ]; assert_ok $? "declared spec exists: $(basename "$f") -> $ref"
  fi
done
grep -q "Cross-project citations" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md" && \
  grep -qE "2026-08-13 — amended" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "longitudinal spec carries the dated seventh-source amendment"
grep -qE "2026-08-13 — recall metric" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "#4a longitudinal metric clarified by dated amendment"

# --- jit-recall spec §4.9: review-work checklist gains Evidence kind ---
grep -q "Evidence kind" "$ROOT/commands/review-work.md" && grep -q "G004/G008" "$ROOT/commands/review-work.md"
assert_ok $? "review-work checklist carries the Evidence kind dimension"
# anchored to the bulleted checklist items specifically -- "Frontend" also
# appears unrelatedly in the Step 4 report-format template
# (commands/review-work.md:68), which a bare /Frontend/ pattern would
# match instead of the intended checklist bullet.
awk '/^- \*\*Frontend\*\*/{a=NR} /^- \*\*Evidence kind\*\*/{b=NR} END{exit !(a && b && a<b)}' "$ROOT/commands/review-work.md"
assert_ok $? "Evidence kind bullet follows the Frontend bullet"

# --- jit-recall spec §4.10: longitudinal protocol dated amendment ---
grep -q "Recall MISS" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md" && \
  grep -q "Frame adherence" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md" && \
  grep -q "Retrospect adherence" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "longitudinal spec carries the three new jit-recall metrics"
grep -q "## Tier-1 gate (pre-registered, frozen 2026-08-19)" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "longitudinal spec carries the pre-registered Tier-1 gate"
grep -qE "2026-08-19 — amended per .docs/specs/2026-08-19-jit-recall-design" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "dated changelog entry for the jit-recall amendment"
grep -q "## Execution routing" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "backfilled Execution routing section present"
awk '/^## Decision rules/{a=NR} /^## Tier-1 gate/{b=NR} /^## Cadence/{c=NR} END{exit !(a && b && c && a<b && b<c)}' "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "Tier-1 gate sits between Decision rules and Cadence, per spec"

# --- jit-recall spec §4.1 / §7 (SKILL-MAP currency deferred to this plan's follow-on pass) ---
grep -q "presence" "$ROOT/docs/SKILL-MAP.md"
assert_ok $? "SKILL-MAP names the presence hook as an entry point"
grep -q "anoti recall" "$ROOT/docs/SKILL-MAP.md"
assert_ok $? "SKILL-MAP names the anoti recall CLI"

# --- jit-recall spec §4.1: README names the presence hook ---
grep -qi "presence hook" "$ROOT/README.md"
assert_ok $? "README names the presence hook"
# recall command names the mechanical anoti recall pre-check (spec: jit-recall §4.4, Task 7)
grep -q "anoti recall <topic-keywords>" "$ROOT/commands/recall.md"
assert_ok $? "recall command names the mechanical pre-check as step 0"
awk '/Mechanical pre-check/{a=NR} /^1\. Query both stores/{b=NR} END{exit !(a && b && a<b)}' "$ROOT/commands/recall.md"
assert_ok $? "step 0 precedes the existing step 1"

# --- D025 orientation currency: every command is routed in the demo; every skill is mapped ---
# (skeptic 2026-08-19: `false; break` is swallowed — break's own status is 0 — so these
# gates were dead; a flag variable makes them real)
ok=1; for c in "$ROOT"/commands/*.md; do
  n="$(basename "$c" .md)"
  grep -q -- "$n" "$ROOT/skills/demo/SKILL.md" || { echo "demo routing table missing command: $n" >&2; ok=0; }
done; [ "$ok" = 1 ]
assert_ok $? "D025: every /anoti command appears in the demo's routing table"
ok=1; for d in "$ROOT"/skills/*/; do
  n="$(basename "$d")"; bare="${n#policy-}"   # SKILL-MAP's policy table uses bare names (its own stated convention)
  grep -qE -- "\| *($n|$bare) *\|" "$ROOT/docs/SKILL-MAP.md" || { echo "SKILL-MAP missing skill: $n" >&2; ok=0; }
done; [ "$ok" = 1 ]
assert_ok $? "D025: every skill appears in SKILL-MAP"
ok=1; help_out="$("$ROOT/scripts/anoti" help)"
for s in "$ROOT"/scripts/*; do
  n="$(basename "$s")"; [ -x "$s" ] && [ "$n" != "anoti" ] || continue
  printf '%s' "$help_out" | grep -q -- "$n" || { echo "anoti help missing: $n" >&2; ok=0; }
done; [ "$ok" = 1 ]
assert_ok $? "D025: every helper is listed by anoti help"
grep -qi "fail open\|fails open\|fail-open" "$ROOT/README.md" && grep -qi "never to a block\|never block" "$ROOT/README.md"
assert_ok $? "README states the fail-open guarantee in one sentence"
grep -qi "fail open\|fails open\|fail-open" "$ROOT/skills/demo/SKILL.md"
assert_ok $? "demo states the fail-open guarantee"
