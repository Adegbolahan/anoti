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
