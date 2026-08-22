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
printf '%s' "$out" | jq -r .reason | grep -q "Anything to skillify" && printf '%s' "$out" | jq -r .reason | grep -q "mark-retrospect t1 empty|filed"; assert_ok $? "nudge asks the skillify question and names the recording command with the session id"
[ -f .anoti/sessions/t1.retrospect-nudged ]; assert_ok $? "once-per-session marker written"
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "second Stop: no second nudge"
grep -q $'\tt1\tretrospect-nudge\tblock\tslow=1 frames=0 events=0$' .anoti/telemetry.log; assert_ok $? "telemetry: retrospect-nudge block with the trigger counts"
# recorded retrospective -> no nudge even without a marker
rm -f .anoti/sessions/t1.retrospect-nudged
"$ROOT/scripts/mark-retrospect" t1 empty >/dev/null
out="$(printf '{"session_id":"t1"}' | "$G")"; assert_eq "$out" "" "a recorded retrospective (mark-retrospect) silences the nudge"
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
out="$(printf '{"session_id":"t5"}' | "$G")"; printf '%s' "$out" | jq -r .reason | grep -q "Anything to skillify"; assert_ok $? "precedence: retrospect nudge third"
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
: > .anoti/sessions/e1.retrospect-nudged; : > .anoti/sessions/e1.review-debt-blocked
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
); rm -rf "$tmp"
