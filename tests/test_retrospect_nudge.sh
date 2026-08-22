#!/bin/bash
# Stop-hook retrospect nudge + SessionEnd abandoned keep (0.5.29; human ask 2026-08-22)
G="$ROOT/scripts/consolidation-gate"; C="$ROOT/scripts/cleanup-session"
rn_mkfx() { mkdir -p "$1/.anoti"; cp "$ROOT/tests/fixtures/store_valid.yaml" "$1/GROUNDING.yaml"; ( cd "$1" && git init -q -b main . && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null ); }
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rn_mkfx "$tmp"
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "trivial session (no state, no telemetry): no nudge"
"$ROOT/scripts/append-classification" t1 fast "tiny" >/dev/null
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "a fast-only session is trivial: no nudge"
"$ROOT/scripts/append-classification" t1 slow "real work" >/dev/null
out="$(printf '{"session_id":"t1"}' | "$G")"
assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "a slow classification makes the session nontrivial: Stop nudges"
printf '%s' "$out" | jq -r .reason | grep -qi "anything to skillify" && printf '%s' "$out" | jq -r .reason | grep -q "mark-retrospect t1 empty|filed"; assert_ok $? "nudge asks the skillify question and names the recording command with the session id"
[ -f .anoti/sessions/t1.retrospect-nudged ]; assert_ok $? "once-per-session marker written"
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "second Stop: no second nudge"
grep -q $'\tt1\tretrospect-nudge\tblock\tslow=1 frames=0 events=0$' .anoti/telemetry.log; assert_ok $? "telemetry: retrospect-nudge block with the trigger counts"
# the gate's own telemetry line must never count as a retrospective (cycle-2 HIGH 1)
rm -f .anoti/sessions/t1.retrospect-nudged
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "a retrospect-nudge telemetry line is not a retrospective: with the marker gone it nudges again"
# recorded retrospective -> no nudge even without a marker
rm -f .anoti/sessions/t1.retrospect-nudged
"$ROOT/scripts/mark-retrospect" t1 empty >/dev/null
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "a recorded retrospective (mark-retrospect) silences the nudge"
# stale re-arm: 40 more tool events after the mark -> one more reminder, then silence
for i in $(seq 1 40); do printf '2026-08-22T00:00:00Z\tt1\tpresence\trecall\tD001[]\n' >> .anoti/telemetry.log; done
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "a mark followed by NUDGE_EVENTS tool events is stale: reminded once more"
printf '%s' "$out" | jq -r .reason | grep -q "stale — 40 tool events since it"; assert_ok $? "stale reminder names the count"
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "stale reminder fires once per staleness window"
for i in $(seq 1 39); do printf '2026-08-22T00:00:00Z\tt1\tpresence\trecall\tD001[]\n' >> .anoti/telemetry.log; done
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "events keep growing while stale: no re-block every turn (39 more: still inside the window)"
printf '2026-08-22T00:00:00Z\tt1\tpresence\trecall\tD001[]\n' >> .anoti/telemetry.log
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "a full further window (40 more) re-arms the stale reminder once"
# a fresh mark, then a full window: the window restarts from the mark (skeptic P10)
"$ROOT/scripts/mark-retrospect" t1 filed >/dev/null
for i in $(seq 1 40); do printf '2026-08-22T00:00:00Z\tt1\tpresence\trecall\tD001[]\n' >> .anoti/telemetry.log; done
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "re-mark then 40 more events: stale again (window restarts at the fresh mark, not at the old marker count)"
"$ROOT/scripts/mark-retrospect" t1 filed >/dev/null
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "a fresh mark after the stale reminder: silent again"
printf '2026-08-22T00:00:00Z\tt1\tpresence\trecall\tD001[]\n' >> .anoti/telemetry.log
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "one event after the fresh mark is not stale"
# events in other columns never silence the nudge (column-anchored awk, not an ERE)
printf '2026-08-22T00:00:00Z\tother\tpresence\trecall\t\tt7\tretrospect\tfiled\n' >> .anoti/telemetry.log
"$ROOT/scripts/append-classification" t7 slow "w" >/dev/null
out="$(printf '{"session_id":"t7"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "a crafted line with the sid+retrospect in later columns does not count as a mark"
out="$(printf '{"session_id":"t8"}' | NUDGE_EVENTS=abc "$G" 2>&1)"; assert_eq "$out" "" "non-numeric NUDGE_EVENTS: silent fallback to 40, no stderr noise"
out="$(printf '{"session_id":"t8"}' | NUDGE_EVENTS=0 "$G" 2>&1)"; assert_eq "$out" "" "NUDGE_EVENTS=0 does not nudge every empty session"
out="$(printf '{"session_id":"t8"}' | NUDGE_EVENTS=99999999999999999999999 "$G" 2>&1)"; assert_eq "$out" "" "overlong numeric NUDGE_EVENTS: silent fallback, no integer-expression noise"
# event threshold: many presence/inhibit lines make a session nontrivial without a slow verdict
for i in $(seq 1 40); do printf '2026-08-22T00:00:00Z\tt2\tpresence\trecall\tD001[]\n' >> .anoti/telemetry.log; done
out="$(printf '{"session_id":"t2"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "40 presence/inhibit telemetry lines reach NUDGE_EVENTS: nudge"
for i in $(seq 1 39); do printf '2026-08-22T00:00:00Z\tt3\tinhibit\task\tx\n' >> .anoti/telemetry.log; done
out="$(printf '{"session_id":"t3"}' | "$G")"; assert_eq "$out" "" "39 lines stay under the default threshold: no nudge"
out="$(printf '{"session_id":"t3"}' | NUDGE_EVENTS=10 "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "NUDGE_EVENTS lowers the threshold"
# other sessions' telemetry never counts
out="$(printf '{"session_id":"t4"}' | "$G")"; assert_eq "$out" "" "another session's events do not make this one nontrivial"
# precedence: consolidation block first, then review debt, then the nudge
"$ROOT/scripts/append-classification" t5 slow "w" >/dev/null; "$ROOT/scripts/set-episode" t5 candidate-detected >/dev/null
"$ROOT/scripts/review-debt" add t5 "batch" >/dev/null
out="$(printf '{"session_id":"t5"}' | "$G")"; printf '%s' "$out" | jq -r .reason | grep -q "memory candidates"; assert_ok $? "precedence: consolidation block first"
[ -f .anoti/sessions/t5.retrospect-nudged ]; assert_eq "$?" "1" "…nudge marker untouched by the consolidation block"
out="$(printf '{"session_id":"t5"}' | "$G")"; printf '%s' "$out" | jq -r .reason | grep -q "adversarial review owed"; assert_ok $? "precedence: review-debt block second"
out="$(printf '{"session_id":"t5"}' | "$G")"; printf '%s' "$out" | jq -r .reason | grep -qi "anything to skillify"; assert_ok $? "precedence: retrospect nudge third"
out="$(printf '{"session_id":"t5","stop_hook_active":true}' | "$G")"; assert_eq "$out" "" "stop_hook_active: no nudge"
# malformed session state: fail open (no nudge from the yaml path)
printf 'not: [yaml' > .anoti/sessions/t6.yaml
out="$(printf '{"session_id":"t6"}' | "$G" 2>/dev/null)"; assert_eq "$out" "" "unreadable session state: nudge fails open"
); rm -rf "$tmp"

# --- SessionEnd: nontrivial + no retrospective -> state kept as abandoned; markers cleared ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rn_mkfx "$tmp"
"$ROOT/scripts/append-classification" e1 slow "work" >/dev/null; "$ROOT/scripts/set-episode" e1 committed >/dev/null
# the gate runs first (cycle-2 HIGH 1: its telemetry line must not read as a retrospective at SessionEnd)
printf '{"session_id":"e1"}' | "$G" >/dev/null; : > .anoti/sessions/e1.review-debt-blocked
printf '{"session_id":"e1"}' | "$C"
[ -f .anoti/sessions/e1.abandoned.yaml ] && [ ! -f .anoti/sessions/e1.yaml ]; assert_ok $? "SessionEnd: nontrivial + no retrospective -> state kept as abandoned (not deleted)"
[ ! -f .anoti/sessions/e1.retrospect-nudged ] && [ ! -f .anoti/sessions/e1.review-debt-blocked ]; assert_ok $? "SessionEnd clears the once-per-session markers"
grep -q $'\te1\tsummary\tslow=1\tframes=0\tretrospect_ran=false\tepisode=committed$' .anoti/telemetry.log; assert_ok $? "summary line records retrospect_ran=false"
out="$(printf '{"session_id":"x"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "abandoned session state found: .*e1.abandoned.yaml"; assert_ok $? "next session start: the digest surfaces the abandoned state"
"$ROOT/scripts/append-classification" e2 slow "work" >/dev/null; "$ROOT/scripts/set-episode" e2 committed >/dev/null
"$ROOT/scripts/mark-retrospect" e2 filed >/dev/null
printf '{"session_id":"e2"}' | "$C"
[ ! -f .anoti/sessions/e2.abandoned.yaml ] && [ ! -f .anoti/sessions/e2.yaml ]; assert_ok $? "SessionEnd: nontrivial WITH a recorded retrospective -> state removed as before"
"$ROOT/scripts/append-classification" e3 fast "tiny" >/dev/null
printf '{"session_id":"e3"}' | "$C"
[ ! -f .anoti/sessions/e3.abandoned.yaml ] && [ ! -f .anoti/sessions/e3.yaml ]; assert_ok $? "SessionEnd: trivial session -> state removed"
"$ROOT/scripts/append-classification" e4 slow "w" >/dev/null; "$ROOT/scripts/set-episode" e4 awaiting-approval >/dev/null
printf '{"session_id":"e4"}' | "$C"
[ -f .anoti/sessions/e4.abandoned.yaml ]; assert_ok $? "SessionEnd: in-flight episode still abandoned (unchanged path)"
# stale mark at SessionEnd -> kept as abandoned, summary says stale
"$ROOT/scripts/append-classification" e5 slow "w" >/dev/null; "$ROOT/scripts/set-episode" e5 committed >/dev/null
"$ROOT/scripts/mark-retrospect" e5 filed >/dev/null
for i in $(seq 1 40); do printf '2026-08-22T00:00:00Z\te5\tinhibit\task\tx\n' >> .anoti/telemetry.log; done
printf '{"session_id":"e5"}' | NUDGE_EVENTS=99999999999999999999999 "$C" 2>/dev/null
[ -f .anoti/sessions/e5.abandoned.yaml ]; assert_ok $? "overlong NUDGE_EVENTS at SessionEnd falls back to 40: a stale session is still kept (not recorded as ran)"
rm -f .anoti/sessions/e5.abandoned.yaml; "$ROOT/scripts/append-classification" e5 slow "w" >/dev/null; "$ROOT/scripts/set-episode" e5 committed >/dev/null
printf '{"session_id":"e5"}' | "$C"
[ -f .anoti/sessions/e5.abandoned.yaml ]; assert_ok $? "SessionEnd: a STALE retrospective keeps the state as abandoned"
grep -q $'\te5\tsummary\tslow=1\tframes=0\tretrospect_ran=stale\t' .anoti/telemetry.log; assert_ok $? "summary line records retrospect_ran=stale"
# events-only nudged session: marker cleaned even with no yaml
for i in $(seq 1 40); do printf '2026-08-22T00:00:00Z\te6\tpresence\trecall\tx\n' >> .anoti/telemetry.log; done
printf '{"session_id":"e6"}' | "$G" >/dev/null; [ -f .anoti/sessions/e6.retrospect-nudged ]; assert_ok $? "setup: events-only session nudged (marker exists, no yaml)"
printf '{"session_id":"e6"}' | "$C"
[ ! -f .anoti/sessions/e6.retrospect-nudged ]; assert_ok $? "SessionEnd clears the marker even when no session yaml exists"
# digest counts abandoned files and names the reopen path; resolve-abandoned closes them
out="$(printf '{"session_id":"x"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "abandoned session state found: 3 file(s), oldest sid e1 (.*e1.abandoned.yaml.*resolve-abandoned e1"; assert_ok $? "digest counts abandoned files, names the oldest SID (not just the path) and the reopen/resolve path"
"$ROOT/scripts/resolve-abandoned" "../../decoy" --skip r 2>/dev/null; assert_eq "$?" "1" "resolve-abandoned refuses a traversal sid"
"$ROOT/scripts/resolve-abandoned" "a b" --skip r 2>/dev/null; assert_eq "$?" "1" "resolve-abandoned refuses a sid with spaces"
"$ROOT/scripts/resolve-abandoned" e1 2>/dev/null; assert_eq "$?" "1" "resolve-abandoned refuses a sid with no retrospective recorded"
[ -f .anoti/sessions/e1.abandoned.yaml ]; assert_ok $? "…and leaves the file"
"$ROOT/scripts/mark-retrospect" e1 filed >/dev/null; "$ROOT/scripts/resolve-abandoned" e1 >/dev/null; assert_ok $? "after the reopen procedure's mark, resolve-abandoned exits 0"
[ ! -f .anoti/sessions/e1.abandoned.yaml ]; assert_ok $? "…and removes the abandoned file"
grep -q $'\te1\tabandoned\tresolved\tretrospected$' .anoti/telemetry.log; assert_ok $? "telemetry: abandoned resolved retrospected"
"$ROOT/scripts/resolve-abandoned" e4 --skip "" 2>/dev/null; assert_eq "$?" "1" "--skip without a reason is refused"
"$ROOT/scripts/resolve-abandoned" e4 --skip "scratch demo session, nothing to learn" >/dev/null; assert_ok $? "--skip with a reason resolves without a mark"
grep -q $'\te4\tabandoned\tresolved\tskipped scratch demo session, nothing to learn$' .anoti/telemetry.log; assert_ok $? "telemetry: abandoned resolved skipped <reason>"
"$ROOT/scripts/resolve-abandoned" nope 2>/dev/null; assert_eq "$?" "1" "unknown sid refused"
); rm -rf "$tmp"
