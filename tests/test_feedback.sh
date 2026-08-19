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
c2="$(grep -c '^T001' .anoti/presence-feedback.tsv 2>/dev/null)"; c2="${c2:-0}"
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

# --- item 1: three marks suppress; item 2: two marks don't ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out="$(printf '{"session_id":"s1a","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_ok $? "item 2: two marks (below threshold 3) -- T001 still injects"
! grep -q "presence.suppressed" .anoti/telemetry.log; assert_ok $? "item 2: no suppressed telemetry below threshold"
"$F" mark T001 "cd chain" >/dev/null   # now count=3
out="$(printf '{"session_id":"s1b","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "item 1: three marks (at threshold) -- T001 absent from additionalContext"
grep -qF -- $'presence\tsuppressed\tT001:cd chain' .anoti/telemetry.log; assert_ok $? "item 1: suppressed telemetry line names the pair"
# DEVIATION: the plan's literal grep here is file-wide, unscoped to a
# session -- s1a's EARLIER (correct, below-threshold) recall of T001 is
# already in the same .anoti/telemetry.log, so a bare "presence.recall.
# T001\[\]" pattern always matches regardless of s1b's own behavior.
# Scoped to the s1b firing's own telemetry line.
! grep -qE $'\ts1b\tpresence\trecall\t.*T001\\[\\]' .anoti/telemetry.log; assert_ok $? "item 1: no recall telemetry line for T001 this firing (fully suppressed)"
); rm -rf "$tmp"

# --- item 3: expired marks (last_marked > 30 days ago) don't count ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
old="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old" "$old" > .anoti/presence-feedback.tsv
out="$("$F" list)"
printf '%s' "$out" | grep -qE $'^T001\tcd chain\t3\t.*\tno$'; assert_ok $? "item 3: list shows suppressed=no for an expired row"
out="$(printf '{"session_id":"s3","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "item 3: an expired mark does not suppress -- T001 still injects"
); rm -rf "$tmp"

# --- item 4: other triggers still fire (T001 has TWO triggers: 'cd chain' suppressed, 'cd &&' not) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out="$(printf '{"session_id":"s4","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain and cd && both here"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "item 4: record still injects via its OTHER (unsuppressed) trigger"
grep -qE "presence.recall.T001\[\]" .anoti/telemetry.log; assert_ok $? "item 4: recall telemetry still names T001 (survived via 'cd &&')"
grep -qF -- $'presence\tsuppressed\tT001:cd chain' .anoti/telemetry.log; assert_ok $? "item 4: suppressed telemetry separately names ONLY the suppressed pair"
); rm -rf "$tmp"

# --- item 6: digest line, gated exactly like recall-coverage (PSTORE) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
printf 'T001\tcd chain\t3\t2026-08-19\t2026-08-17\nD009\tcurl\t3\t2026-08-19\t2026-08-17\n' > .anoti/presence-feedback.tsv
out="$("$ROOT/scripts/anoti" digest)"
! printf '%s' "$out" | grep -q "pairs suppressed"; assert_ok $? "digest gate: NO project store (PSTORE unset) -- line never shows even though the TSV exists"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$("$ROOT/scripts/anoti" digest)"
printf '%s' "$out" | grep -q "presence: 2 (record,trigger) pairs suppressed — anoti feedback list"
assert_ok $? "digest: N=2, exact count and text, project store now present"
rm .anoti/presence-feedback.tsv
out="$("$ROOT/scripts/anoti" digest)"
! printf '%s' "$out" | grep -q "pairs suppressed"; assert_ok $? "digest: N=0 (no feedback file) -- line omitted entirely (US-002)"
); rm -rf "$tmp"

# --- item 7: telemetry shape -- ONE line, comma-joined, two pairs across two records ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_triggers.yaml" GROUNDING.yaml
yq -i '.records += [{"id":"T020","date":"2026-08-19","type":"claim","topic":"test.two","statement":"A second suppressible record.","triggers":["second-marker"],"epistemic_status":"probable","ratification":"approved","source":{"type":"conversation"},"evidence":[],"events":[{"date":"2026-08-19","action":"created","by":"session"}]}]' GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
"$F" mark T020 "second-marker" >/dev/null; "$F" mark T020 "second-marker" >/dev/null; "$F" mark T020 "second-marker" >/dev/null
out="$(printf '{"session_id":"s7","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain here, second-marker too"},"tool_response":{}}' | "$ROOT/scripts/presence")"
c="$(grep -c 'presence.suppressed' .anoti/telemetry.log)"
assert_eq "$c" "1" "item 7: EXACTLY one suppressed telemetry line, never two separate lines"
grep -qF -- $'presence\tsuppressed\tT001:cd chain,T020:second-marker' .anoti/telemetry.log
assert_ok $? "item 7: comma-joined, both pairs on the one line"
); rm -rf "$tmp"

# --- item 8: corrupt file, warn-once ACROSS TWO SEPARATE PROCESS INVOCATIONS ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
printf 'T001\tcd chain\tNOT-A-NUMBER\t2026-08-19\t2026-08-17\n' > .anoti/presence-feedback.tsv
out1="$(printf '{"session_id":"s8","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -qi "not parseable"
assert_ok $? "item 8: first (separate) process invocation warns about the corrupt file"
grep -q "presence.warn.feedback" .anoti/telemetry.log; assert_ok $? "item 8: first invocation logs presence warn feedback"
yq -e '.warned.feedback == true' .anoti/sessions/s8.presence.yaml >/dev/null 2>&1
assert_ok $? "item 8: warned.feedback is PERSISTED to disk (IMPORTANT 2 write-back fix), not just an in-memory flag"
# second invocation: a FRESH process (new printf | presence pipeline), same sid -- reads warned.feedback=true from disk
out2="$(printf '{"session_id":"s8","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything else"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -qi "not parseable"
assert_eq "$?" "1" "item 8: SECOND process invocation is silent on the same warning"
c="$(grep -c "presence.warn.feedback" .anoti/telemetry.log)"
assert_eq "$c" "1" "item 8: exactly one warn telemetry line across two separate invocations"
); rm -rf "$tmp"

# --- item 9: perf, extends the shipped 2.5s bound (tests/test_presence.sh:255-256) to cover match_trigger_pairs + the suppression filter pass ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti" .anoti
gen() {
  { printf 'meta: { schema_version: 3, scope: project, policy: { entries_immutable: true, events_append_only: true, reverify_after_days: 180 } }\nindex: []\nrecords:\n'
    i=1; while [ "$i" -le 300 ]; do
      printf -- '- { id: %s%03d, date: 2026-08-19, type: claim, topic: bulk.t%d, statement: "bulk record %d", triggers: ["bulk-kw-%d"], epistemic_status: established, ratification: approved, events: [] }\n' "$2" "$i" "$i" "$i" "$i"
      i=$((i+1))
    done
    printf 'open_questions: []\n'
  } > "$1"
}
gen GROUNDING.yaml P
gen "$HOME/.claude/anoti/GROUNDING.yaml" G
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/GROUNDING.yaml" >/dev/null
i=1; while [ "$i" -le 200 ]; do
  printf 'P%03d\tbulk-kw-%d\t1\t2026-08-19\t2026-08-19\n' "$i" "$i" >> .anoti/presence-feedback.tsv
  i=$((i+1))
done
start="$(date +%s.%N)"
printf '{"session_id":"perf2","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"bulk-kw-1 bulk-kw-2"},"tool_response":{}}' | "$ROOT/scripts/presence" >/dev/null
end="$(date +%s.%N)"
elapsed="$(awk -v a="$start" -v b="$end" 'BEGIN{printf "%.3f", b-a}')"
awk -v e="$elapsed" 'BEGIN{exit !(e < 2.5)}'
assert_ok $? "item 9: perf pin UNCHANGED at 2.5s, now with match_trigger_pairs + suppression filter + a 200-row feedback file in the mix (got ${elapsed}s)"
); rm -rf "$tmp"

# --- item 12: feedback_threshold override ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
printf -- '---\nfeedback_threshold: 5\n---\n' > .claude/anoti.local.md.tmp 2>/dev/null || { mkdir -p .claude; printf -- '---\nfeedback_threshold: 5\n---\n' > .claude/anoti.local.md; }
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out="$("$F" list)"; printf '%s' "$out" | grep -qE $'^T001\tcd chain\t3\t.*\tno$'
assert_ok $? "item 12: threshold override=5 -- 3 marks still shows suppressed=no"
out2="$(printf '{"session_id":"s12a","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "item 12: 3 marks under a threshold of 5 still injects normally"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out3="$("$F" list)"; printf '%s' "$out3" | grep -qE $'^T001\tcd chain\t5\t.*\tyes$'
assert_ok $? "item 12: 5 marks under threshold=5 -- now suppressed=yes"
); rm -rf "$tmp"

# --- item 5 (extended, MINOR 13): recall_cache purge on natural TTL expiry, at read time ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
# inject once, unsuppressed, so recall_cache holds a pre-suppression entry
printf '{"session_id":"sttl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain first time"},"tool_response":{}}' | "$ROOT/scripts/presence" >/dev/null
yq -e '.recall_cache | has("T001")' .anoti/sessions/sttl.presence.yaml >/dev/null 2>&1
assert_ok $? "TTL setup: recall_cache holds a pre-expiry entry for T001"
old="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old" "$old" > .anoti/presence-feedback.tsv   # at/above threshold, but last_marked is EXPIRED
out="$(printf '{"session_id":"sttl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything else"},"tool_response":{}}' | "$ROOT/scripts/presence")"
yq -e '.recall_cache | has("T001")' .anoti/sessions/sttl.presence.yaml >/dev/null 2>&1
assert_eq "$?" "1" "TTL expiry: the stale recall_cache entry is purged at the firing that finds it expired (§4.5.2 point 2)"
out2="$(printf '{"session_id":"sttl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "TTL expiry: the NEXT firing re-injects T001 (the purge actually restores reversibility)"
); rm -rf "$tmp"
