tmp="$(mktemp -d)"; ( cd "$tmp"
# --- append-classification: creates state, appends safely, logs telemetry ---
"$ROOT/scripts/append-classification" s1 slow "ambiguous ask: needs frame, budget"
assert_ok $? "append-classification exits 0"
assert_eq "$(yq -r '.classifications | length' .anoti/sessions/s1.yaml)" "1" "one classification appended"
"$ROOT/scripts/append-classification" s1 fast "routine lookup, no consequence: none"
assert_eq "$(yq -r '.classifications | length' .anoti/sessions/s1.yaml)" "2" "second appended, no duplication"
assert_eq "$(yq -r '.classifications[0].reason' .anoti/sessions/s1.yaml)" "ambiguous ask: needs frame, budget" "colon/comma reason survives intact"
yq -e '.' .anoti/sessions/s1.yaml >/dev/null 2>&1; assert_ok $? "state file stays parseable"
[ -f .anoti/telemetry.log ] && [ "$(wc -l < .anoti/telemetry.log | tr -d ' ')" = "2" ]
assert_ok $? "telemetry log has one line per classification"
"$ROOT/scripts/append-classification" s1 bogus "x" 2>/dev/null
assert_eq "$?" "1" "invalid verdict rejected"
# --- set-episode ---
"$ROOT/scripts/set-episode" s1 candidate-detected
assert_ok $? "set-episode exits 0"
assert_eq "$(yq -r '.episode' .anoti/sessions/s1.yaml)" "candidate-detected" "episode transitioned"
"$ROOT/scripts/set-episode" s1 nonsense 2>/dev/null
assert_eq "$?" "1" "invalid episode rejected"
assert_eq "$(yq -r '.episode' .anoti/sessions/s1.yaml)" "candidate-detected" "state untouched on rejection"
# --- append-event: tricky note lands intact; store still validates ---
cp "$ROOT/tests/fixtures/store_valid.yaml" store.yaml
"$ROOT/scripts/append-event" store.yaml D001 promoted human "probable -> established: two sessions, distinct tasks"
assert_ok $? "append-event exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .events[-1].note' store.yaml)" "probable -> established: two sessions, distinct tasks" "tricky note survives intact"
"$ROOT/scripts/validate-workspace" store.yaml >/dev/null 2>&1; assert_ok $? "store validates after event append"
before="$(cat store.yaml)"
"$ROOT/scripts/append-event" store.yaml NOPE promoted human "x" 2>/dev/null
assert_eq "$?" "1" "unknown record id rejected"
assert_eq "$(cat store.yaml)" "$before" "store untouched on rejection"
# --- append-record: JSON in, validated + indexed + trusted store out ---
printf '%s' '{"id":"D099","date":"2026-08-13","type":"claim","topic":"helper.test","statement":"Statement with: colon, and comma","epistemic_status":"speculative","ratification":"pending","source":{"type":"observation","context":"helper test, tricky path"},"evidence":[],"events":[{"date":"2026-08-13","action":"created","by":"session"}]}' | "$ROOT/scripts/append-record" store.yaml
assert_ok $? "append-record exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D099") | .statement' store.yaml)" "Statement with: colon, and comma" "tricky statement survives intact"
assert_eq "$(yq -r '.index | length' store.yaml)" "$(yq -r '.records | length' store.yaml)" "index regenerated after append"
grep -qs "$(shasum -a 256 store.yaml | cut -d' ' -f1)" .anoti/trust; assert_ok $? "store re-trusted after append"
printf 'not json' | "$ROOT/scripts/append-record" store.yaml 2>/dev/null
assert_eq "$?" "1" "garbage JSON rejected"
"$ROOT/scripts/validate-workspace" store.yaml >/dev/null 2>&1; assert_ok $? "store still valid after rejected append"
); rm -rf "$tmp"

# --- append-evidence: mechanical evidence attach (gap found during backfill) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
"$ROOT/scripts/append-evidence" s.yaml D001 literature "canonical sources: attention, memory" "Miller (1956)" "Vaswani et al. (2017)"
assert_ok $? "append-evidence exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .evidence | length' s.yaml)" "1" "evidence entry appended"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .evidence[0].refs | length' s.yaml)" "2" "refs list carried intact"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1; assert_ok $? "store valid after evidence append"
"$ROOT/scripts/append-evidence" s.yaml NOPE literature x r 2>/dev/null
assert_eq "$?" "1" "unknown record id rejected"
); rm -rf "$tmp"

# --- configurable state dir: ANOTI_DIR > .claude/anoti.local.md > default ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
ANOTI_DIR=".claude/anoti" "$ROOT/scripts/append-classification" cfg fast "override test"
[ -f .claude/anoti/sessions/cfg.yaml ]; assert_ok $? "ANOTI_DIR override honored"
[ ! -d .anoti ]; assert_ok $? "default dir untouched under override"
mkdir -p .claude
printf -- '---\nstate_dir: .claude/anoti2\n---\n' > .claude/anoti.local.md
"$ROOT/scripts/append-classification" cfg2 fast "settings test"
[ -f .claude/anoti2/sessions/cfg2.yaml ]; assert_ok $? "settings-file state_dir honored"
rm .claude/anoti.local.md
"$ROOT/scripts/append-classification" cfg3 fast "default test"
[ -f .anoti/sessions/cfg3.yaml ]; assert_ok $? "default .anoti without any knob"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
ANOTI_DIR=".claude/anoti" "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$(printf '{"session_id":"cfg"}' | ANOTI_DIR=".claude/anoti" "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$out" | grep -q "2 records"; assert_ok $? "retrieve trust check honors ANOTI_DIR"
); rm -rf "$tmp"
