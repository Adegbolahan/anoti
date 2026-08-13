tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"   # hermetic: no real global store
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
# Untrusted store: mentioned but not loaded
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "not yet trusted"
assert_ok $? "untrusted store is reported, not loaded"
# Trusted store: digest with counts inside untrusted-data envelope
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "REFERENCE DATA"; assert_ok $? "envelope marks digest as data, not instructions"
printf '%s' "$ctx" | grep -q "2 records"; assert_ok $? "digest reports record count"
printf '%s' "$ctx" | grep -q "1 awaiting ratification"; assert_ok $? "digest reports pending ratification"
# Tampered store loses trust
printf '\n# tampered\n' >> GROUNDING.yaml
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "not yet trusted"
assert_ok $? "modified store requires re-trust"
# Abandoned session surfaced
mkdir -p .anoti/sessions; printf 'episode: candidate-detected\n' > .anoti/sessions/x.abandoned.yaml
printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "abandoned session"
assert_ok $? "abandoned session state surfaced"
# Empty project: silent
rm -rf .anoti GROUNDING.yaml
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
assert_eq "$out" "" "nothing to say -> no output"
); rm -rf "$tmp"
