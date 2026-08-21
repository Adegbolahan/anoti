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

# --- adaptive-suppression spec §9: SKILL-MAP entry-point row for scripts/feedback ---
grep -qF "filtered by adaptive suppression" "$ROOT/docs/SKILL-MAP.md"
assert_ok $? "SKILL-MAP presence-hook row names adaptive-suppression filtering"
grep -qF '`scripts/feedback` (list/clear)' "$ROOT/docs/SKILL-MAP.md"
assert_ok $? "SKILL-MAP gains a scripts/feedback entry-point row"
sma="$(grep -n 'PostToolUse/PostToolUseFailure hook' "$ROOT/docs/SKILL-MAP.md" | head -1 | cut -d: -f1)"
smb="$(grep -nF '`scripts/feedback` (list/clear)' "$ROOT/docs/SKILL-MAP.md" | head -1 | cut -d: -f1)"  # -F: GNU grep reads \` as start-of-buffer
[ -n "$sma" ] && [ -n "$smb" ] && [ "$sma" -lt "$smb" ]
assert_ok $? "scripts/feedback row sits directly after the presence-hook row it extends"

# --- adaptive-suppression spec §4.8/§4.9: Q006 gate reorder + KEEP/telemetry-only/REVERT ---
LONG="$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
grep -qF "AFTER adaptive" "$LONG" && grep -qF "docs/specs/2026-08-19-adaptive-suppression-design.md" "$LONG"
assert_ok $? "longitudinal spec Q006 gate reworded to name adaptive suppression specifically"
grep -qE "2026-08-19 \(later still\) — amended per" "$LONG"
assert_ok $? "dated changelog entry for the adaptive-suppression amendment"
grep -qF "Adaptive suppression KEEP/telemetry-only/REVERT" "$LONG"
assert_ok $? "new pre-registered KEEP/telemetry-only/REVERT subsection present"
grep -qF "15 percentage points higher" "$LONG"
assert_ok $? "KEEP bar states the exact 15-point threshold"
grep -qF "10 percentage points" "$LONG" && grep -qi "LOWER" "$LONG"
assert_ok $? "REVERT bar states the exact 10-point regression threshold"
grep -qi "telemetry-only" "$LONG"
assert_ok $? "three-way outcome includes telemetry-only, not just KEEP/REVERT"
grep -qi "weaker inference" "$LONG"
assert_ok $? "fallback baseline path is labeled as carrying weaker inference"
la="$(grep -n 'Presence precision (added 2026-08-19, field review)' "$LONG" | head -1 | cut -d: -f1)"
lb="$(grep -n 'Adaptive suppression KEEP/telemetry-only/REVERT' "$LONG" | head -1 | cut -d: -f1)"
lc="$(grep -n 'Tier 3 justified' "$LONG" | head -1 | cut -d: -f1)"
[ -n "$la" ] && [ -n "$lb" ] && [ -n "$lc" ] && [ "$la" -lt "$lb" ] && [ "$lb" -lt "$lc" ]
assert_ok $? "adaptive-suppression subsection sits between Presence-precision and Tier-3-justified, inside the Tier-1 gate section"

# --- D011 fix round (reviewer MINOR): the §4.8 replacement bullet's
# continuation line must keep its 2-space list-continuation indent,
# byte-for-byte against spec:900 -- whitespace-squeezed matching above
# cannot see this, so this checks the raw file directly, anchored at
# column 1 ---
grep -qE '^  N` telemetry\) over the `presence recall` lines\.' "$LONG"
assert_ok $? "longitudinal spec §4.8 bullet: telemetry-line continuation keeps its 2-space indent (byte-verbatim vs spec:900)"

# --- organ-home currency (field report 2026-08-21): a command or skill that names a
# default organ path must also name the .claude/anoti.local.md key that overrides it
# (issues #16/#18). Skills whose whole subject is the default format (spec, plan,
# direction) and the bootstrap skill name the keys explicitly; everything else must too.
for f in "$ROOT"/commands/*.md "$ROOT"/skills/*/SKILL.md; do
  rel="${f#"$ROOT"/}"
  case "$rel" in skills/skillify/SKILL.md|skills/feedback/SKILL.md|commands/audit.md) continue ;; esac
  ok=1
  # a citation of one of THIS repo's dated design documents (docs/specs/2026-…) is a reference, not an organ home
  grep -E 'docs/specs/' "$f" | grep -qvE 'docs/specs/[0-9]{4}-[0-9]{2}-[0-9]{2}-' && ! grep -q 'spec_dir' "$f" && ok=0
  grep -q 'docs/plans/' "$f" && ! grep -q 'plan_dir' "$f" && ok=0
  grep -q 'docs/reviews/' "$f" && ! grep -q 'reviews_dir' "$f" && ok=0
  grep -q 'docs/HIGH-LEVEL-STORIES.md' "$f" && ! grep -q 'story_path' "$f" && ok=0
  grep -q 'docs/ROADMAP.md' "$f" && ! grep -q 'roadmap_path' "$f" && ok=0
  [ "$ok" -eq 1 ]; assert_ok $? "organ-home currency: $rel names the override key for every default organ path it mentions"
done
grep -q 'reviews_dir' "$ROOT/skills/skillify/SKILL.md"; assert_ok $? "skillify adoption map lists reviews_dir"
grep -q 'reviews_dir' "$ROOT/commands/review-work.md"; assert_ok $? "review-work resolves the reviews home via reviews_dir"
grep -q 'story_path' "$ROOT/commands/implement.md" && grep -q 'spec_dir' "$ROOT/commands/implement.md"; assert_ok $? "implement resolves organ homes from .claude/anoti.local.md"

