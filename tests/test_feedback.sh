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

# --- FIX (IMPORTANT, D011 fix round, reviewer Task 12): TTL-expiry
# recall_cache purge was not transition-gated -- expired_ids was
# recomputed fresh from the TSV on EVERY firing and purged
# unconditionally, permanently defeating the N=10 dedupe window for any
# record with a soft-expired feedback row (spec §7: expired rows are
# never auto-deleted, so this was the PERMANENT steady state for any
# pair not manually cleared). Replaces the item-5 (extended) block that
# stood here: that block's own scenario (recall BEFORE any feedback row
# existed, then a row created ALREADY expired) never actually observed
# a genuine "was suppressed, now isn't" transition -- its final
# assertion ("the NEXT firing re-injects T001") is FALSE under the
# corrected model below, because a row that reads as
# count>=threshold+expired from the moment it is created never made any
# recall_cache entry stale in the first place; ordinary N=10 dedup
# already handles it correctly. That is exactly TEST A below.
# --- TEST A: a row already-expired from birth (never actively
# suppressing within this session) must behave EXACTLY like ordinary,
# never-suppressed N=10 dedup -- inject once, then dedupe (reviewer's
# own reproduction: "T001 row backdated 40 days (count=3), same trigger
# fired 3x in one session") ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
old="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old" "$old" > .anoti/presence-feedback.tsv
fireA() { printf '{"session_id":"sA","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence"; }
out1="$(fireA)"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_ok $? "TEST A fire 1: expired-from-birth row still injects once (cache empty, ordinary first-touch)"
out2="$(fireA)"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST A fire 2: MUST be deduped (ABSENT) -- no real transition ever occurred, so nothing should purge the cache set on fire 1 (the bug: the old unconditional-every-firing purge wiped it, re-injecting every time)"
out3="$(fireA)"
printf '%s' "$out3" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST A fire 3: reviewer's own required assertion -- third firing after expiry must be deduped (ABSENT)"
); rm -rf "$tmp"

# --- TEST A control: identical 3-firing sequence with NO feedback file
# at all -- proves the expired-from-birth path (above) now matches
# ordinary dedup exactly, not merely "happens to pass" (reviewer's own
# framing: "control without a feedback file dedupes correctly") ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
fireActl() { printf '{"session_id":"sActl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence"; }
out1="$(fireActl)"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_ok $? "TEST A control fire 1: injects (no feedback file at all)"
out2="$(fireActl)"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST A control fire 2: deduped (ABSENT) -- ordinary N=10 dedup, matches TEST A's now-fixed behavior"
out3="$(fireActl)"
printf '%s' "$out3" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST A control fire 3: deduped (ABSENT)"
); rm -rf "$tmp"

# --- TEST B: a GENUINE mid-session transition (actively suppressed,
# THEN ages past the 30-day cutoff) -- reviewer's other required
# assertion: "a fresh-expiry first firing must still purge+inject" ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
fireB() { printf '{"session_id":"sB","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence"; }
out1="$(fireB)"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST B fire 1: T001 actively suppressed (recent marks) -- absent, establishing a real suppression episode"
old="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old" "$old" > .anoti/presence-feedback.tsv
out2="$(fireB)"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_ok $? "TEST B fire 2 (the transition firing): purge+inject -- T001 re-appears the moment the pair ages out of suppression"
out3="$(fireB)"
printf '%s' "$out3" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST B fire 3: reviewer's own required assertion -- deduped (ABSENT), proving the purge fired ONCE (at the transition), not every firing thereafter"
); rm -rf "$tmp"

# --- TEST C (D011 cycle 3, mutation-proven coverage hole): a STALE
# recall_cache entry that PREDATES suppression must be REPLACED at the
# transition, not merely left alone -- A/B never created such an entry. ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
fireC() { printf '{"session_id":"sC","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence"; }
fireC >/dev/null   # inject once, unsuppressed -- cache holds T001 at the OLD (pre-suppression) tool_calls value
old_cached="$(yq -r '.recall_cache.T001' .anoti/sessions/sC.presence.yaml)"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out_sup="$(fireC)"   # now suppressed -- excluded entirely; cache must stay untouched (still the stale entry)
printf '%s' "$out_sup" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "TEST C: suppressed firing is silent"
mid_cached="$(yq -r '.recall_cache.T001' .anoti/sessions/sC.presence.yaml)"
assert_eq "$mid_cached" "$old_cached" "TEST C: cache entry untouched while suppressed (still stale)"
old40="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old40" "$old40" > .anoti/presence-feedback.tsv
out_trans="$(fireC)"   # transition firing: must inject AND replace the stale entry
printf '%s' "$out_trans" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_ok $? "TEST C: transition firing injects T001"
new_cached="$(yq -r '.recall_cache.T001' .anoti/sessions/sC.presence.yaml)"
[ "$new_cached" != "$old_cached" ]; assert_ok $? "TEST C: stale pre-suppression cache entry REPLACED with the new tool_calls value (old=$old_cached new=$new_cached)"
); rm -rf "$tmp"

# --- issue #23: writers stamp UTC, readers must compute cutoffs on the SAME calendar ---
# Etc/GMT-14 (UTC+14) and Etc/GMT+12 (UTC-12) are 26h apart: at any instant at least one
# of them has a local date different from UTC's, so a local-calendar cutoff would move.
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
on="$(date -u -v-30d +%F 2>/dev/null || date -u -d '30 days ago' +%F)"          # exactly 30 days ago, UTC: still inside the window
off="$(date -u -v-31d +%F 2>/dev/null || date -u -d '31 days ago' +%F)"         # 31 days ago, UTC: expired
printf 'T001\tcd chain\t3\t%s\t%s\nT001\tcd &&\t3\t%s\t%s\n' "$on" "$on" "$off" "$off" > .anoti/presence-feedback.tsv
for tz in Etc/GMT-14 Etc/GMT+12; do
  tzs="$(printf '%s' "$tz" | tr '/+' '_p')"   # sids must not contain / (they name a session file)
  out="$(TZ=$tz "$F" list)"
  printf '%s' "$out" | grep -qE $'^T001\tcd chain\t3\t.*\tyes$'; assert_ok $? "#23 list under TZ=$tz: a row stamped exactly 30 UTC-days ago is still suppressed (cutoff on the writers' calendar)"
  printf '%s' "$out" | grep -qE $'^T001\tcd &&\t3\t.*\tno$'; assert_ok $? "#23 list under TZ=$tz: a row stamped 31 UTC-days ago has expired"
  out="$(printf '{"session_id":"tz-%s","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain"},"tool_response":{}}' "$tzs" | TZ=$tz "$ROOT/scripts/presence" | jq -r '.hookSpecificOutput.additionalContext // ""')"
  printf '%s' "$out" | grep -q "T001"; assert_eq "$?" "1" "#23 presence under TZ=$tz: the 30-day-old suppression still silences T001 on 'cd chain'"
  out="$(printf '{"session_id":"tz2-%s","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd &&"},"tool_response":{}}' "$tzs" | TZ=$tz "$ROOT/scripts/presence" | jq -r '.hookSpecificOutput.additionalContext // ""')"
  printf '%s' "$out" | grep -q "T001"; assert_ok $? "#23 presence under TZ=$tz: the expired (31-day) suppression no longer silences T001 on 'cd &&'"
done
# the 14-day review nudge, pinned on the writers' calendar under both zones.
#
# Why the base store's probables are demoted first: store_valid ships a
# probable (D001, 2026-08-12) and `oldest` is the min date over ALL
# probables, so with it in place the nudge fires whatever the record under
# test is dated -- the assertion could not fail (G004). Demoting makes the
# precondition true by construction instead of by assumption. The comment
# that stood here claimed "store_valid carries no probables", which was
# false, and that is exactly what made this block a time bomb: it passed
# while d14 fell on or before 2026-08-12, and has failed since
# 2026-08-27 for reasons having nothing to do with what it tests.
# (On 2026-08-26 d14 == 2026-08-12 == oldest, so it still passed.)
# To be precise about the old block's power: it was HALF falsifiable, not
# non-falsifiable. A cutoff skewed EARLY (d14-1, which #23 produced under
# Etc/GMT+12 for UTC hours 00:00-11:59) did make it fail; a cutoff skewed
# LATE (d14+1) did not. The rebuild catches both directions.
#
# Why two cases and not one: Etc/GMT-14 (UTC+14) and Etc/GMT+12 (UTC-12)
# are 26h apart, so they are never on the same calendar date (verified
# across all 24 hours of a day). A local-calendar cutoff therefore skews at
# least one of them off the UTC boundary at every instant -- but which one
# depends on the time of day, so a single case catches the regression only
# part of the day. "Exactly 14 days old fires" catches the zone skewed
# late; "13 days old does not fire" catches the zone skewed early.
nudge_store() {  # $1 = date carried by the sole probable in the store
  cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
  yq -i '(.records[] | select(.epistemic_status == "probable") | .epistemic_status) = "established"' GROUNDING.yaml
  printf '{"id":"P14","date":"%s","type":"claim","topic":"t.p14","statement":"probable at the review-nudge boundary","epistemic_status":"probable","ratification":"approved","source":{"type":"observation","context":"x"},"events":[{"date":"%s","action":"created","by":"session"}]}' "$1" "$1" | "$ROOT/scripts/append-record" GROUNDING.yaml >/dev/null
  assert_ok $? "#23 nudge fixture: sole probable dated $1 appended"
  "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
}
nudge_line() {   # $1 = TZ; prints the PROJECT nudge line, empty if it did not fire
  # grep -v '\[global\]' matters: the same wording appears for the global
  # store, and a developer's real ~/.claude/anoti store carries probables.
  # The block's HOME isolation already prevents that leak, but relying on
  # it silently is how this assertion would go green for the wrong reason
  # (skeptic, R3 cycle 1).
  printf '{"session_id":"tz3"}' | TZ="$1" "$ROOT/scripts/retrieve" \
    | jq -r '.hookSpecificOutput.additionalContext // ""' \
    | grep -v '\[global\]' \
    | grep -E 'review recommended: [0-9]+ probable record' || true
}
# The two zones must actually resolve to different calendar dates, or the
# whole design collapses: an unresolvable TZ silently becomes UTC on some
# platforms (a runner without tzdata), both columns agree, and a broken
# local-calendar cutoff passes every assertion below. Assert the
# precondition rather than assume it (skeptic, R3 cycle 1).
[ "$(TZ=Etc/GMT-14 date +%F)" != "$(TZ=Etc/GMT+12 date +%F)" ]
assert_ok $? "#23 precondition: Etc/GMT-14 and Etc/GMT+12 resolve to different calendar dates (tzdata present)"
d14="$(date -u -v-14d +%F 2>/dev/null || date -u -d '14 days ago' +%F)"
d13="$(date -u -v-13d +%F 2>/dev/null || date -u -d '13 days ago' +%F)"
nudge_store "$d14"
for tz in Etc/GMT-14 Etc/GMT+12; do
  printf '%s' "$(nudge_line "$tz")" | grep -q "oldest $d14"
  assert_ok $? "#23 digest under TZ=$tz: a probable exactly 14 UTC-days old triggers the review nudge"
done
nudge_store "$d13"
for tz in Etc/GMT-14 Etc/GMT+12; do
  [ -z "$(nudge_line "$tz")" ]
  assert_ok $? "#23 digest under TZ=$tz: a probable only 13 UTC-days old does NOT trigger the nudge"
done
); rm -rf "$tmp"
