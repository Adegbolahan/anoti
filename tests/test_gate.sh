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

# unreadable session state must be reported, not silently treated as idle
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti/sessions
printf 'episode: [broken\n  yaml' > .anoti/sessions/bad.yaml
err="$(printf '{"session_id":"bad","stop_hook_active":false}' | "$ROOT/scripts/consolidation-gate" 2>&1 >/dev/null)"
printf '%s' "$err" | grep -qi "unreadable"; assert_ok $? "gate reports unreadable state on stderr"
err="$(printf '{"session_id":"bad","tool_name":"Write","tool_input":{"file_path":"GROUNDING.yaml"}}' | "$ROOT/scripts/inhibit" 2>&1 >/dev/null)"
printf '%s' "$err" | grep -qi "unreadable"; assert_ok $? "inhibit reports unreadable state on stderr"
); rm -rf "$tmp"
