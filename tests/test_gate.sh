g="$ROOT/scripts/consolidation-gate"
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti/sessions
printf 'episode: idle\n' > .anoti/sessions/s.yaml
assert_eq "$(printf '{"session_id":"s","stop_hook_active":false}' | "$g")" "" "idle -> silent pass"
printf 'episode: candidate-detected\n' > .anoti/sessions/s.yaml
out="$(printf '{"session_id":"s","stop_hook_active":false}' | "$g")"
assert_eq "$(printf '%s' "$out" | jq -r '.decision')" "block" "candidate-detected -> block once"
assert_eq "$(yq -r '.episode' .anoti/sessions/s.yaml)" "awaiting-approval" "episode advanced"
assert_eq "$(printf '{"session_id":"s","stop_hook_active":false}' | "$g")" "" "awaiting-approval -> no second block"
printf 'episode: candidate-detected\n' > .anoti/sessions/s.yaml
assert_eq "$(printf '{"session_id":"s","stop_hook_active":true}' | "$g")" "" "stop_hook_active guard -> silent"
rm .anoti/sessions/s.yaml
assert_eq "$(printf '{"session_id":"s","stop_hook_active":false}' | "$g")" "" "no state file -> silent"
); rm -rf "$tmp"
