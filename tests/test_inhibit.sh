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

# --- field review: destructive-SQL row must not fire on prose ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
run_inhibit() { printf '{"session_id":"fp","tool_name":"Bash","tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | "$ROOT/scripts/inhibit"; }
out="$(run_inhibit 'cat > notes.md <<EOF
We should truncate the log lines to 80 chars.
EOF')"
[ -z "$out" ]; assert_ok $? "prose containing 'truncate' in a heredoc is not destructive SQL"
out="$(run_inhibit 'git commit -m "truncate the summary field"')"
[ -z "$out" ]; assert_ok $? "commit message mentioning truncate is not destructive SQL"
out="$(run_inhibit 'psql -h db.prod.example.com -c "TRUNCATE TABLE users"')"
printf '%s' "$out" | grep -q '"deny"'; assert_ok $? "TRUNCATE via a DB client against a remote host is still denied"
out="$(run_inhibit 'echo "DROP DATABASE prod" | mysql -h 10.0.0.5')"
printf '%s' "$out" | grep -q '"deny"'; assert_ok $? "piped DROP DATABASE into a client is still denied"
out="$(run_inhibit 'psql -h localhost -c "TRUNCATE TABLE users"')"
[ -z "$out" ]; assert_ok $? "local target stays allowed (unchanged)"
out="$(run_inhibit 'psql -h db.prod.example.com <<SQL
TRUNCATE TABLE users;
SQL')"
printf '%s' "$out" | grep -q '"deny"'; assert_ok $? "heredoc SQL fed to a client is still denied"
); rm -rf "$tmp"

# --- the plugin's own templates are not memory organs ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti templates
out="$(printf '{"session_id":"tp","tool_name":"Edit","tool_input":{"file_path":"templates/GROUNDING.yaml"}}' | "$ROOT/scripts/inhibit")"
printf '%s' "$out" | grep -q '"deny"'; assert_ok $? "a consumer project's own templates/GROUNDING.yaml is STILL gated (exclusion scoped to the plugin root)"
out="$(cd "$ROOT" && printf '{"session_id":"tp","tool_name":"Edit","tool_input":{"file_path":"templates/GROUNDING.yaml"}}' | "$ROOT/scripts/inhibit")"
[ -z "$out" ]; assert_ok $? "the plugin's OWN templates/GROUNDING.yaml is a template, not an organ — not episode-gated"
out="$(printf '{"session_id":"tp","tool_name":"Edit","tool_input":{"file_path":"GROUNDING.yaml"}}' | "$ROOT/scripts/inhibit")"
printf '%s' "$out" | grep -q '"deny"'; assert_ok $? "the live store is still gated"
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti fakeplugin/scripts fakeplugin/templates live
cp "$ROOT"/scripts/inhibit "$ROOT"/scripts/anoti-dir fakeplugin/scripts/
printf 'schema_version: 3\n' > live/GROUNDING.yaml
ln -s "$tmp/live/GROUNDING.yaml" fakeplugin/templates/GROUNDING.yaml
cd fakeplugin
out="$(printf '{"session_id":"sl","tool_name":"Edit","tool_input":{"file_path":"templates/GROUNDING.yaml"}}' | ./scripts/inhibit)"
printf '%s' "$out" | grep -q '"deny"'; assert_ok $? "a symlinked leaf under templates/ that escapes the templates dir is STILL gated"
rm templates/GROUNDING.yaml && printf '# tpl\n' > templates/GROUNDING.yaml
out="$(printf '{"session_id":"sl","tool_name":"Edit","tool_input":{"file_path":"templates/GROUNDING.yaml"}}' | ./scripts/inhibit)"
[ -z "$out" ]; assert_ok $? "a real file inside the plugin's templates dir stays exempt"
); rm -rf "$tmp"
