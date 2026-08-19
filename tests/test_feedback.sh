F="$ROOT/scripts/feedback"
fb_mkfx() { # $1=dir -- lay down a trusted project store from store_triggers.yaml (same fixture Task 1/4 use: T001 has triggers ["cd chain","cd &&"])
  mkdir -p "$1/.anoti"
  cp "$ROOT/tests/fixtures/store_triggers.yaml" "$1/GROUNDING.yaml"
  ( cd "$1" && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null )
}

# --- scripts/feedback mark/list (spec §4.4) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
out="$("$F" list)"
assert_eq "$out" "feedback: no presence-feedback.tsv yet (nothing suppressed)" "list: missing file message, exit 0"
"$F" mark D001 "cd chain" >/dev/null; assert_ok $? "mark exits 0"
"$F" mark D001 "cd chain" >/dev/null
"$F" mark D001 "cd chain" >/dev/null
out="$("$F" list)"
printf '%s' "$out" | grep -qE $'^D001\tcd chain\t3\t.*\tyes$'; assert_ok $? "three marks: count=3, suppressed=yes"
"$F" mark D009 "curl" >/dev/null
"$F" mark D009 "curl" >/dev/null
out="$("$F" list)"
printf '%s' "$out" | grep -qE $'^D009\tcurl\t2\t.*\tno$'; assert_ok $? "two marks: count=2, suppressed=no"
c="$(grep -c $'^D001\tcd chain' .anoti/presence-feedback.tsv)"
assert_eq "$c" "1" "mark increments a row in place, never appends a duplicate"
); rm -rf "$tmp"

# --- scripts/feedback clear: with/without trigger, refusal on absent, recall_cache purge (spec §4.4, §4.5.2 point 1) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
"$F" mark T001 "cd &&" >/dev/null
# inject once BEFORE clear so recall_cache in the session's presence-state file holds a pre-suppression entry for T001 (MINOR 13 fix-round extension)
printf '{"session_id":"fbclr","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd &&"},"tool_response":{}}' | "$ROOT/scripts/presence" >/dev/null
yq -e '.recall_cache | has("T001")' .anoti/sessions/fbclr.presence.yaml >/dev/null 2>&1
assert_ok $? "setup: recall_cache holds a pre-clear entry for T001"
"$F" clear T001 "cd chain"; assert_ok $? "clear (with trigger) exits 0"
c="$(grep -c $'^T001\tcd chain' .anoti/presence-feedback.tsv 2>/dev/null)"; c="${c:-0}"
assert_eq "$c" "0" "clear removed exactly the named (id,trigger) row"
c2="$(grep -c '^T001' .anoti/presence-feedback.tsv 2>/dev/null || echo 0)"
assert_eq "$c2" "1" "clear left the OTHER trigger's row for the same id untouched"
yq -e '.recall_cache | has("T001")' .anoti/sessions/fbclr.presence.yaml >/dev/null 2>&1
assert_eq "$?" "1" "clear purges the stale recall_cache entry for the cleared id (MINOR 13 fix)"
"$F" clear T001 "no-such-trigger" 2>/dev/null
assert_eq "$?" "1" "clear refuses an absent (id,trigger) pair"
"$F" clear T001 >/dev/null; assert_ok $? "clear without trigger removes ALL rows for the id"
c3="$(grep -c '^T001' .anoti/presence-feedback.tsv 2>/dev/null)"; c3="${c3:-0}"
assert_eq "$c3" "0" "clear (no trigger) removed every row for T001, including 'cd &&'"
"$F" clear T001 2>/dev/null; assert_eq "$?" "1" "clear on an already-empty id refuses (G004: clear always distinguishes cleared vs nothing-there)"
); rm -rf "$tmp"
