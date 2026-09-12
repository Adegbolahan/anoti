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

# --- board mutations get the same default-branch protection as Write/Edit,
# and board approve always asks (recorded human decisions cannot be verified) ---
tmp="$(mktemp -d)"; (
mk() { git init -q -b main "$1" && git -C "$1" -c user.email=t@t.t -c user.name=t commit --allow-empty -m init -q; }
mk "$tmp/repo"; mkdir -p "$tmp/repo/.anoti"
cd "$tmp/repo"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified"}}')" "deny" "board work on main is denied"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board init Project"}}')" "deny" "board init on main is denied"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board approve work-0001 --packet X --note done"}}')" "deny" "board approve on main is denied (branch check wins over ask)"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board list"}}')" "allow" "board list (non-mutating) is not gated"
touch .anoti/allow-default-branch
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified"}}')" "allow" "human override file allows board mutation on main"
rm .anoti/allow-default-branch
git switch -q -c feature-x
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified"}}')" "allow" "board work on a feature branch is allowed"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board approve work-0001 --packet X --note done"}}')" "ask" "board approve on a feature branch still asks for human confirmation"
); rm -rf "$tmp"

# --- board mutation gate must not fire on prose that merely mentions
# "board" + a verb, only on an actual invocation (review finding) ---
tmp="$(mktemp -d)"; (
mk() { git init -q -b main "$1" && git -C "$1" -c user.email=t@t.t -c user.name=t commit --allow-empty -m init -q; }
mk "$tmp/repo"
cd "$tmp/repo"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"echo board work needed before shipping"}}')" "allow" "prose mentioning board+verb is not a board mutation"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"git commit -m \"board approve flow implemented\""}}')" "allow" "commit message mentioning board approve is not a board mutation"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"/path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified"}}')" "deny" "a real board work invocation on main is still denied"
# R7: a direct interpreter prefix bypassed the gate completely -- running an
# uninstalled script as `python3 <path>/board ...` is ordinary, not adversarial
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"python3 /path/to/anoti/scripts/board work Feature --description Scope --accept Verified"}}')" "deny" "python3-invoked board work on main is denied"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"sh /path/to/anoti/scripts/board approve work-0001 --packet X --note done"}}')" "deny" "sh-invoked board approve on main is denied"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"python3 /path/to/anoti/scripts/board list"}}')" "allow" "python3-invoked board list (non-mutating) is not gated"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"echo python3 board work needed before shipping"}}')" "allow" "prose naming an interpreter and board is not a mutation"
# R7 cycle 2: enumerate-don't-generalise left ordinary forms open
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"python3.11 /path/to/anoti/scripts/board work Feature --description Scope --accept Verified"}}')" "deny" "versioned interpreter (python3.11) board work on main is denied"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"pypy3 /path/to/anoti/scripts/board work Feature --description Scope --accept Verified"}}')" "deny" "alternate interpreter (pypy3) board work on main is denied"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"FOO=bar BAZ=qux python3 /path/to/anoti/scripts/board work F --description S --accept W"}}')" "deny" "two env assignments before the interpreter do not defeat the gate"
# R3 cycle 2: a quoted value containing a space truncated the segment into a
# fragment matching nothing, so the gate silently no-opped
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"MSG=\"hello world\" /path/to/anoti/scripts/anoti board work F --description S --accept W"}}')" "deny" "double-quoted env value with a space does not defeat the gate"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"NOTE='"'"'looks done'"'"' /path/to/anoti/scripts/anoti board approve work-0001 --packet X --note done"}}')" "deny" "single-quoted env value with a space does not defeat the gate"
assert_eq "$(d '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"A=1 B=\"x y\" /path/to/anoti/scripts/anoti board work F --description S --accept W"}}')" "deny" "bare and quoted env assignments together do not defeat the gate"
); rm -rf "$tmp"

# --- board mutation branch check must resolve the repo a leading `cd`
# actually targets, not this hook process's own $PWD (review finding) ---
tmp="$(mktemp -d)"; (
mk() { git init -q -b main "$1" && git -C "$1" -c user.email=t@t.t -c user.name=t commit --allow-empty -m init -q; }
mk "$tmp/main-repo"
mk "$tmp/feature-repo"; git -C "$tmp/feature-repo" switch -q -c feature-y
cd "$tmp/feature-repo"
assert_eq "$(d "$(printf '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"cd %s && /path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified"}}' "$tmp/main-repo")")" "deny" "cd into a sibling repo on main is denied even though session cwd is a feature branch"
# ...and the same with a quoted env value, which used to leave bd un-updated and
# silently fall back to the session cwd -- the #25/#24 class, via the stripper
# built with jq: printf would collapse the \" escapes and emit invalid JSON,
# which jq then drops -- an "allow" that proves nothing about the gate
j="$(jq -nc --arg c "MSG=\"a b\" cd $tmp/main-repo && /path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified" '{session_id:"b",tool_name:"Bash",tool_input:{command:$c}}')"
assert_eq "$(d "$j")" "deny" "quoted env value before a cd does not lose the target repo"
cd "$tmp/main-repo"
assert_eq "$(d "$(printf '{"session_id":"b","tool_name":"Bash","tool_input":{"command":"cd %s && /path/to/anoti/scripts/anoti board work Feature --description Scope --accept Verified"}}' "$tmp/feature-repo")")" "allow" "cd into a sibling repo on a feature branch is allowed even though session cwd is main"
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
