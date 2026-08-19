tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
printf '{"session_id":"abc"}' | "$ROOT/scripts/persist-session"
assert_ok $? "persist-session exits 0"
[ -f .anoti/sessions/abc.yaml ]; assert_ok $? "state file created"
assert_eq "$(yq -r '.episode' .anoti/sessions/abc.yaml)" "idle" "new state starts idle"
[ -n "$(yq -r '.session.flushed' .anoti/sessions/abc.yaml)" ]; assert_ok $? "flush timestamp stamped"
# cleanup removes idle/committed, marks others abandoned
printf '{"session_id":"abc"}' | "$ROOT/scripts/cleanup-session"
[ ! -f .anoti/sessions/abc.yaml ]; assert_ok $? "idle state removed on SessionEnd"
printf '{"session_id":"def"}' | "$ROOT/scripts/persist-session"
yq '.episode = "candidate-detected"' .anoti/sessions/def.yaml > t && mv t .anoti/sessions/def.yaml
printf '{"session_id":"def"}' | "$ROOT/scripts/cleanup-session"
[ -f .anoti/sessions/def.abandoned.yaml ]; assert_ok $? "in-flight state marked abandoned"
printf 'not json' | "$ROOT/scripts/persist-session" 2>/dev/null
assert_ok $? "persist-session fails open on garbage input"
); rm -rf "$tmp"

# --- persist-session compacted_at stamp (spec §4.7 fallback signal) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
printf '{"session_id":"pc"}' | "$ROOT/scripts/persist-session"
grep -q "compacted_at" .anoti/sessions/pc.yaml
assert_ok $? "persist-session stamps compacted_at"
yq -e '.session.compacted_at' .anoti/sessions/pc.yaml >/dev/null 2>&1
assert_ok $? "compacted_at is valid, readable YAML"
); rm -rf "$tmp"
