b="$ROOT/benchmark"
# answer key: parses, 8 facts, exactly 2 revisions, labels cover every prompt
jq -e '.' "$b/answer-key.json" >/dev/null 2>&1; assert_ok $? "answer key is valid JSON"
assert_eq "$(jq -r '.facts | length' "$b/answer-key.json" 2>/dev/null)" "8" "answer key has 8 facts"
assert_eq "$(jq -r '[.facts[] | select(.revised_in != null)] | length' "$b/answer-key.json" 2>/dev/null)" "2" "exactly 2 facts are revised"
# sessions: S1..S6 present; every prompt id labeled in the key
jq -e '.' "$b/sessions.json" >/dev/null 2>&1; assert_ok $? "sessions script is valid JSON"
assert_eq "$(jq -r '.sessions | length' "$b/sessions.json" 2>/dev/null)" "6" "six sessions defined"
missing=0
for pid in $(jq -r '.sessions[].prompts[].id' "$b/sessions.json" 2>/dev/null); do
  jq -e --arg p "$pid" '.labels[$p]' "$b/answer-key.json" >/dev/null 2>&1 || missing=$((missing+1))
done
assert_eq "$missing" "0" "every prompt id carries a trivial/nontrivial label"
assert_eq "$(jq -r '[.sessions[].prompts[] | select(.interactive == true)] | length' "$b/sessions.json" 2>/dev/null)" "2" "exactly two interactive points"
# traps reference the planted facts
jq -r '.sessions[3].prompts[0].text' "$b/sessions.json" 2>/dev/null | grep -qi "delete"; assert_ok $? "S4 trap targets deletion policy"
jq -r '.sessions[5].prompts[0].text' "$b/sessions.json" 2>/dev/null | grep -qi "90"; assert_ok $? "S6 trap uses the stale retention value"
# fixture template
for f in config.py storage.py api.py README.md; do
  [ -s "$b/fixture/$f" ]; assert_ok $? "fixture file exists: $f"
done
grep -q "tombstone" "$b/fixture/README.md" 2>/dev/null; assert_ok $? "fixture embeds the deletion policy"
grep -q "RETENTION_DAYS = 90" "$b/fixture/config.py" 2>/dev/null; assert_ok $? "fixture embeds initial retention"
# arm-C builder produces instructions-only CLAUDE.md
tmpc="$(mktemp -d)"
"$b/build-arm-c" "$tmpc" >/dev/null 2>&1; assert_ok $? "build-arm-c exits 0"
[ -s "$tmpc/CLAUDE.md" ]; assert_ok $? "arm C CLAUDE.md created"
grep -qi "attention frame" "$tmpc/CLAUDE.md"; assert_ok $? "arm C carries anoti skill content"
rm -rf "$tmpc"
# runner dry-run: lists sessions, never invokes claude
out="$("$b/run-arm" --dry-run A "$(mktemp -d)" 2>&1)"; assert_ok $? "run-arm dry-run exits 0"
assert_eq "$(printf '%s\n' "$out" | grep -c 'session S')" "6" "dry-run lists six sessions"
printf '%s' "$out" | grep -qi "would run"; assert_ok $? "dry-run does not invoke claude"
