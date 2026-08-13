inh="$ROOT/scripts/inhibit"
d() { # print decision, or "allow" when inhibit stays silent
  local o; o="$(printf '%s' "$1" | "$inh")"
  if [ -z "$o" ]; then echo allow; else printf '%s' "$o" | jq -r '.hookSpecificOutput.permissionDecision'; fi
}
tmp="$(mktemp -d)"; ( cd "$tmp"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"ls -la"}}')" "allow" "benign command allowed"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}')" "deny" "rm -rf / denied"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"rm -rf ~/stuff"}}')" "deny" "rm -rf ~ denied"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}')" "deny" "force-push to main denied"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"psql -h db.prod.example.com -c \"DROP DATABASE app\""}}')" "deny" "remote DROP DATABASE denied"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"psql -h localhost -c \"DROP DATABASE app\""}}')" "allow" "local DROP DATABASE allowed"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"git push origin feature"}}')" "ask" "plain push asks"
assert_eq "$(d '{"session_id":"s","tool_name":"Write","tool_input":{"file_path":"src/app.js"}}')" "allow" "ordinary write allowed"
assert_eq "$(d '{"session_id":"s","tool_name":"Write","tool_input":{"file_path":"GROUNDING.yaml"}}')" "deny" "memory-organ write denied outside consolidation"
mkdir -p .anoti/sessions; printf 'episode: awaiting-approval\n' > .anoti/sessions/s.yaml
assert_eq "$(d '{"session_id":"s","tool_name":"Write","tool_input":{"file_path":"GROUNDING.yaml"}}')" "allow" "memory-organ write allowed during consolidation"
printf 'garbage' | "$inh" >/dev/null 2>&1; assert_ok $? "fails open on garbage input"
); rm -rf "$tmp"

# deny row 2 must not fire across command boundaries (gh api -f false positive)
tmp="$(mktemp -d)"; ( cd "$tmp"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"git push origin --delete main && gh api -X POST repos/o/r/branches/b/rename -f new_name=main"}}')" "ask" "branch-delete + gh api -f asks, not denies"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}')" "deny" "real force-push still denied"
assert_eq "$(d '{"session_id":"s","tool_name":"Bash","tool_input":{"command":"git push -f origin main"}}')" "deny" "short-flag force-push still denied"
); rm -rf "$tmp"
